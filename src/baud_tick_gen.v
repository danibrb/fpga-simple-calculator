/*
 * baud tick generator
 */

module baud_tick_gen (
    input  wire clk,
    input  wire rstb,
    output reg  tick,
    output reg  half_bit_tick
);

    localparam integer BAUD_RATE       = 19200;
    localparam integer CLOCK_FREQ      = 50_000_000;
    localparam integer TICKS_PER_BAUD  = CLOCK_FREQ / BAUD_RATE;   // = 2604
    localparam integer COUNTER_WIDTH   = 12;   // 2^12 = 4096 > 2603

    localparam integer HALF_POINT      = (TICKS_PER_BAUD - 1) / 2; // = 1301

    reg [COUNTER_WIDTH-1:0] counter;

    always @(posedge clk or negedge rstb) begin
        if (!rstb) begin
            counter        <= {COUNTER_WIDTH{1'b0}};
            tick           <= 1'b0;
            half_bit_tick  <= 1'b0;
        end else begin
            if (counter == TICKS_PER_BAUD - 1) begin
                counter <= {COUNTER_WIDTH{1'b0}};
                tick    <= 1'b1;
            end else begin
                counter <= counter + 1'b1;
                tick    <= 1'b0;
            end

            // pulse at the middle of the bit period (for start-bit sampling)
            if (counter == HALF_POINT) begin
                half_bit_tick <= 1'b1;
            end else begin
                half_bit_tick <= 1'b0;
            end
        end
    end

endmodule
