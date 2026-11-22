// UART transmitter, 8N1 (1 start, 8 data LSB-first, 1 stop). TX idles high.

module uart_tx (
    input  wire       CLK,        // system clock
    input  wire       RSTb,       // asynchronous, active low
    input  wire       START,      // start transmission
    input  wire [7:0] DATA,       // parallel data to transmit
    output wire       TX,         // serial line, idle = 1
    output wire       BUSY        // high during transmission (10 bits)
);

    reg [9:0]  shift_reg;          // {stop=1, data[7:0], start=0}
    reg [11:0] cnt;                // clocks inside the current bit period
    reg [3:0]  bit_num;            // index of the current bit 0..9
    reg        busy;

    
    `ifdef QUESTA	// pre-defined macro in QuestaSim
		localparam CLKS_PER_BIT = 10;
    `else
		localparam CLKS_PER_BIT = 50_000_000 / 19_200;   // 50 MHz / 19200 baud = 2604
    `endif

    always @(posedge CLK or negedge RSTb) begin
        if (!RSTb) begin
            shift_reg <= 10'h3FF;            // all ones = idle high
            cnt       <= 12'd0;
            bit_num   <= 4'd0;
            busy      <= 1'b0;
        end
        else if (!busy) begin
            if (START) begin                 // load frame, start bit visible next cycle
                shift_reg <= {1'b1, DATA, 1'b0};
                cnt       <= 12'd0;
                bit_num   <= 4'd0;
                busy      <= 1'b1;
            end
        end
        else begin                           // transmitting
            if (cnt == CLKS_PER_BIT - 1) begin
                cnt <= 12'd0;          // end of one bit period
                shift_reg <= {1'b1, shift_reg[9:1]};   // shift right, fill with idle '1'
                if (bit_num == 4'd9)
                    busy <= 1'b0;            // stop bit period complete, frame done
                else
                    bit_num <= bit_num + 4'd1;
            end
            else
                cnt <= cnt + 12'd1;
        end
    end

    assign TX = shift_reg[0];    // LSB out, UART order
    assign BUSY = busy;

endmodule