`timescale 10ns / 1ns
//기본클럭 100Mhz -> 10ns 기준으로 단위시간, 정확도는1ns(1ns주기 틱으로 샘플링)

module tb_stopwatch ();
    reg clk;
    reg reset;
    reg hs_mod_sw;
    reg watch_mod_sw;
    reg btnU;
    reg btnL;
    reg btnR;
    reg btnD;
    wire [3:0] fnd_comm;
    wire [7:0] fnd_font;

    top_my_watch #(
        .COUNT_100HZ(1_000_000),
        .MSEC_MAX(100),
        .SEC_MAX(60),
        .MIN_MAX(60),
        .HOUR_MAX(24)
    ) DUT (
        .clk(clk),
        .reset(reset),
        .hs_mod_sw(hs_mod_sw),
        .watch_mod_sw(watch_mod_sw),
        .btnU(btnU),
        .btnL(btnL),
        .btnR(btnR),
        .btnD(btnD),
        .fnd_comm(fnd_comm),
        .fnd_font(fnd_font),
        .mod_indicate_led()
    );

    always #1 clk = ~clk;

    initial begin
        clk = 0;
        reset = 1;
        #10;
        reset = 0;
    end

endmodule
