module uart_tx (
    input        CLK,
    input        RSTb,
    input        LD,
    input        SHIFT,
    input  [7:0] DIN,
    output       DOUT
);

    reg [9:0] shift_reg;

    always @(posedge CLK or negedge RSTb) begin
        if (!RSTb)
            shift_reg <= 10'h3FF;            // idle high
        else if (LD)
            shift_reg <= {1'b1, DIN, 1'b0};  // stop, data LSB-first, start
        else if (SHIFT) begin
            shift_reg <= shift_reg >> 1;
            shift_reg[9] <= 1'b1;              // idle high
        end
    end

    assign DOUT = shift_reg[0];              // LSB out, UART order

endmodule