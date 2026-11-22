`timescale 1ns/1ns

module uart_tx_testbench;

parameter ck_period = 20;
parameter ck_half_period = ck_period / 2;
parameter ck_hold  = 1;	// data hold time

    reg Master_clock, Master_resetB, LD_sig, SHIFT_sig;
    reg [7:0] DIN_sig;
    wire DOUT_sig;

uart_tx DUT(
    .CLK(Master_clock),
    .RSTb(Master_resetB),
    .LD(LD_sig),
    .SHIFT(SHIFT_sig),
    .DIN(DIN_sig),
    .DOUT(DOUT_sig)
    );

// Time 0 values
    initial
    begin
        Master_clock = 0;
        Master_resetB = 1;
        LD_sig = 0;
        SHIFT_sig = 0;
        DIN_sig = 8'h00;
    end
    
// Main test vectors
// execute a: "run -all" command in QuestaSim
    initial
    begin
        Sleep(2);
        issue_RESET;

        send_byte(8'h01);	// just the LSB set
        Sleep(10);
        send_byte(8'h0A);	// 1010
        Sleep(10);
        send_byte(8'h55);

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

// Send one byte: apply DIN, LD pulse, then 10 SHIFT pulses
task send_byte;
input [7:0] data;
integer k;
begin
    $display("# Sending %b @%0t ns", data, $stime);
    DIN_sig = data;
    #ck_period LD_sig = 1;
    #ck_period LD_sig = 0;
    for (k = 0; k < 10; k = k + 1)
    begin
        #ck_period SHIFT_sig = 1;
        #ck_period SHIFT_sig = 0;
    end
end
endtask // send_byte
    
endmodule