`timescale 1ns/1ns

module tb_uart_rx;

parameter ck_period = 20;
parameter ck_half_period = ck_period / 2;
parameter ck_hold  = 1;	// data hold time

    reg Master_clock, Master_resetB, RX_sig;
    wire [7:0] DATA_sig;
    wire VALID_sig;

uart_rx DUT(
    .CLK(Master_clock),
    .RSTb(Master_resetB),
    .RX(RX_sig),
    .DATA(DATA_sig),
    .VALID(VALID_sig)
    );

    `ifdef QUESTA
        localparam CLKS_PER_BIT = 10;
    `else
        localparam CLKS_PER_BIT = 50_000_000 / 19_200;   // 2604
    `endif

// Time 0 values
    initial
    begin
        Master_clock = 0;
        Master_resetB = 1;
        RX_sig = 1;	// idle high
    end
    
// Main test vectors
// execute a: "run -all" command in QuestaSim
    initial
    begin
        Sleep(2);
        issue_RESET;

        send_frame(8'h01);	// just the LSB set
        Sleep(4);
        send_frame(8'h0A);	// 1010
        Sleep(4);
        send_frame(8'h55);
        Sleep(4);
        send_frame(8'hFF);
        Sleep(4);

        $display("# End Simulation @%0t ns",$stime);
        $stop();
    end

// Clock generator: free running
    initial
    begin
        #(ck_period-ck_hold)	Master_clock <= ~Master_clock;
        forever
            #ck_half_period	Master_clock <= ~Master_clock;
    end

// Utility tasks
task Sleep;
input [31:0] waittime;
begin
    repeat(waittime)
        #ck_period;
end
endtask // Sleep
 
task issue_RESET;
begin
    $display("# Reset @%0t ns",$stime);
    #ck_period Master_resetB = 0;
    #ck_period;
    #ck_period;
    #ck_period;
    #ck_period Master_resetB = 1;
    #ck_period;
end
endtask // issue_RESET

// Hold the RX line for n bit periods
task hold_bit;
input [31:0] bits;
begin
    repeat(bits * CLKS_PER_BIT)
        #ck_period;
end
endtask // hold_bit

// Bit-bang one 8N1 frame onto RX (idle -> start, 8 data LSB-first, stop)
task send_frame;
input [7:0] data;
integer k;
begin
    $display("# Sending %b @%0t ns", data, $stime);
    RX_sig = 0;              // start bit
    hold_bit(1);
    for (k = 0; k < 8; k = k + 1)
    begin
        RX_sig = data[k];    // data bits, LSB first
        hold_bit(1);
    end
    RX_sig = 1;              // stop bit
    hold_bit(1);
end
endtask // send_frame

    
endmodule