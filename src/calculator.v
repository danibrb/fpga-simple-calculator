// calculator fsm

module calculator (
    input  wire       CLK,          // system clock
    input  wire       RSTb,         // asynchronous, active low
    input  wire [7:0] RX_DATA,      // received byte from uart_rx
    input  wire       RX_VALID,     // one-clock pulse when RX_DATA is valid
    output reg  [7:0] RESULT,       // parallel data to transmit to uart_tx
    output reg        RESULT_VALID  // start transmission to uart_tx
);

    // register

    reg [14:0] op_a;                // operand a
    reg [14:0] op_b;                // operand b
    reg [2:0]  dig_cnt;             // counter digits

    reg operator;                   // 0 = add, 1 = sub
    reg [3:0] digit;                // digit received

    reg [3:0] state;                 // state of the FSM


    // state

    localparam S_IDLE      = 4'd0;
    localparam S_DIGIT_A   = 4'd1;
    localparam S_OPERATOR  = 4'd2;
    localparam S_DIGIT_B   = 4'd3;
    localparam S_EQUAL     = 4'd4;
    localparam S_SEND      = 4'd5;


    // ASCII table

    localparam ASCII_0      = 8'h30; 
    localparam ASCII_9      = 8'h39; 
    localparam ASCII_ADD    = 8'h2B; 
    localparam ASCII_SUB    = 8'h2D; 
    localparam ASCII_EQ     = 8'h3D; 
    localparam ASCII_CR     = 8'h0D; 
    localparam ASCII_LF     = 8'h0A; 
 

    // FSM

    always @(posedge CLK or negedge RSTb) begin

        if(!RSTb) begin
            op_a <= 15'd0;
            op_b <= 15'd0;
            dig_cnt <= 3'd0;
            operator <= 1'b0;
            digit <= 4'd0;
            state <= S_IDLE;
        end

        else begin
            case(state)

                S_IDLE: begin
                    if(RX_VALID) begin
                        if(RX_DATA >= ASCII_0 && RX_DATA <= ASCII_9) begin
                            op_a <= RX_DATA - ASCII_0;
                            dig_cnt <= 3'd1;
                            state <= S_DIGIT_A;
                        end
                    end
                end

                S_DIGIT_A: begin
                    if(RX_VALID) begin
                        if((RX_DATA >= ASCII_0 && RX_DATA <= ASCII_9) && dig_cnt < 3'd4) begin
                            op_a <= op_a * 10 + (RX_DATA - ASCII_0);
                            dig_cnt <= dig_cnt + 3'd1;
                        end
                        else if(RX_DATA == ASCII_ADD) begin
                            operator <= 1'b0; // add
                            dig_cnt <= 3'd0;
                            state <= S_OPERATOR;
                        end
                        else if(RX_DATA == ASCII_SUB) begin
                            operator <= 1'b1; // sub
                            dig_cnt <= 3'd0;
                            state <= S_OPERATOR;
                        end
                    end
                end
        
    end
