// UART receiver, 8N1 (1 start, 8 data LSB-first, 1 stop). Expects idle high.
// Samples each bit at its centre. DATA is valid while VALID = 1 (one-clock pulse).
module uart_rx (
    input  wire       CLK,        // system clock
    input  wire       RSTb,       // asynchronous, active low
    input  wire       RX,         // asynchronous serial input
    output wire [7:0] DATA,       // received byte
    output wire       VALID       // one-clock pulse when DATA is valid
);

    localparam IDLE = 2'd0, START = 2'd1, BITS = 2'd2, STOP = 2'd3;

    reg [1:0]  state;              // current state
    reg [11:0] cnt;                // clocks inside the current bit period
    reg [2:0]  bit_num;            // index of the data bit being received, 0..7
    reg [7:0]  shift_reg;          // received data, LSB first
    reg [7:0]  data_r;             // registered output
    reg        valid_r;
    reg        rxq, rxs;           // 2-FF synchronizer for the asynchronous RX input


    `ifdef QUESTA	// pre-defined macro in QuestaSim
        localparam CLKS_PER_BIT = 10;
    `else
        localparam CLKS_PER_BIT = 50_000_000 / 19_200;   // 50 MHz / 19200 baud = 2604
    `endif

    localparam HALF_BIT = CLKS_PER_BIT / 2 - 1;    // start-bit middle sample point
    localparam BIT_END  = CLKS_PER_BIT - 1;        // one full bit period

    always @(posedge CLK or negedge RSTb) begin
        if (!RSTb) begin
            state     <= IDLE;
            cnt       <= 12'd0;
            bit_num   <= 3'd0;
            shift_reg <= 8'd0;
            data_r    <= 8'd0;
            valid_r   <= 1'b0;
            rxq       <= 1'b1;             // idle high
            rxs       <= 1'b1;
        end
        else begin
            rxq    <= RX;                  // 2-FF synchronizer
            rxs    <= rxq;
            valid_r <= 1'b0;               // VALID pulses one clock only
            case (state)
            IDLE:                              // waiting for falling edge = start bit
                if (!rxs) begin
                    cnt   <= 12'd0;
                    state <= START;
                end
            START:                             // half bit period: confirm start bit at its middle
                if (cnt == HALF_BIT) begin
                    cnt <= 12'd0;
                    if (!rxs) begin
                        state <= BITS;         // start bit confirmed
                        bit_num <= 3'd0;       // restart the bit index for every frame
                    end
                    else
                        state <= IDLE;         // error, back to idle
                end
                else
                    cnt <= cnt + 12'd1;
            BITS:                              // one sample per data bit, at its middle
                if (cnt == BIT_END) begin
                    cnt <= 12'd0;
                    shift_reg <= {rxs, shift_reg[7:1]};   // shift in LSB first
                    if (bit_num == 3'd7)
                        state <= STOP;
                    else
                        bit_num <= bit_num + 3'd1;
                end
                else
                    cnt <= cnt + 12'd1;
            STOP:                              // middle of stop bit: frame complete
                if (cnt == BIT_END) begin
                    cnt     <= 12'd0;
                    state   <= IDLE;
                    if (rxs) begin               // stop bit must be high
                        data_r  <= shift_reg;
                        valid_r <= 1'b1;
                    end
                end
                else
                    cnt <= cnt + 12'd1;
            endcase
        end
    end

    assign DATA  = data_r;
    assign VALID = valid_r;

endmodule