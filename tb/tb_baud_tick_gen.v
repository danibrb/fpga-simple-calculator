
`timescale 1ns/1ns

module tb_baud_tick_gen;

parameter ck_period      = 20;
parameter ck_half_period = ck_period / 2;
parameter ck_hold       = 1;

parameter CLOCK_FREQ    = 50000000;
parameter BAUD_RATE    = 19200;
parameter TICKS_PER_BAUD = CLOCK_FREQ / BAUD_RATE;
parameter HALF_POINT   = (TICKS_PER_BAUD - 1) / 2;

reg Master_clock;
reg Master_resetB;

wire tick;
wire half_bit_tick;


// DUT

baud_tick_gen DUT (
    .clk           (Master_clock),
    .rstb          (Master_resetB),
    .tick           (tick),
    .half_bit_tick  (half_bit_tick)
);


// Time 0 values

initial
begin
    Master_clock  = 0;
    Master_resetB = 1;
end

// Main test vectors

initial
begin
    Sleep(2);

    issue_RESET;

    $display("# Starting baud tick test @ %0t ns", $stime);

    // Wait for first baud tick
    Sleep(TICKS_PER_BAUD);

    // Observe several baud periods
    Sleep(TICKS_PER_BAUD * 5);

    $display("# End simulation @ %0t ns", $stime);
    $stop;
end

// Clock generator: free running

initial
begin
    #(ck_period-ck_hold) Master_clock <= ~Master_clock;

    forever
        #ck_half_period Master_clock <= ~Master_clock;
end

// Monitor

always @(posedge Master_clock)
begin
    if (Master_resetB) begin
        if (tick)
            $display("# tick pulse @ %0t ns", $stime);

        if (half_bit_tick)
            $display("# half_bit_tick pulse @ %0t ns", $stime);
    end
end

// Utility tasks

task Sleep;
input [31:0] waittime;
begin
    repeat(waittime)
        #ck_period;
end
endtask

task issue_RESET;
begin
    $display("# Reset @ %0t ns", $stime);

    #ck_period Master_resetB = 0;
    #ck_period;
    #ck_period;
    #ck_period Master_resetB = 1;
    #ck_period;

    $display("# Reset released @ %0t ns", $stime);
end
endtask

endmodule
