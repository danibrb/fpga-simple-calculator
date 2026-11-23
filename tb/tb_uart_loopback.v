`timescale 1ns/1ns

module tb_uart_loopback;

parameter ck_period = 20;
parameter ck_half_period = ck_period / 2;
parameter ck_hold  = 1;    // data hold time

    reg Master_clock, Master_resetB, START_sig;
    reg [7:0] DATA_in;
    wire TX_sig, BUSY_sig;
    wire [7:0] DATA_out;
    wire VALID_sig;

// Loopback: TX output drives RX input
uart_tx TX_DUT(
    .CLK(Master_clock),
    .RSTb(Master_resetB),
    .START(START_sig),
    .DATA(DATA_in),
    .TX(TX_sig),
    .BUSY(BUSY_sig)
    );

uart_rx RX_DUT(
    .CLK(Master_clock),
    .RSTb(Master_resetB),
    .RX(TX_sig),
    .DATA(DATA_out),
    .VALID(VALID_sig)
    );

// Time 0 values
    initial
    begin
        Master_clock = 0;
        Master_resetB = 1;
        START_sig = 0;
        DATA_in = 8'h00;
    end

// Main test vectors
// execute a: "run -all" command in QuestaSim
    initial
    begin
        Sleep(2);
        issue_RESET;

        send_byte(8'h01);
        Sleep(4);
        send_byte(8'h0A);
        Sleep(4);
        send_byte(8'h55);
        Sleep(4);

        $display("# End Simulation @%0t ns",$stime);
        $stop();
    end

// Print every byte received
    always @(posedge Master_clock)
        if (VALID_sig)
            $display("# Received %b (%h) @%0t ns", DATA_out, DATA_out, $stime);

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

// Send one byte: apply DATA, one START pulse, then wait for BUSY to fall
task send_byte;
input [7:0] data;
begin
    $display("# Sending %b @%0t ns", data, $stime);
    DATA_in = data;
    #ck_period START_sig = 1;
    #ck_period START_sig = 0;

    wait (!BUSY_sig);
end
endtask // send_byte

endmodule