`timescale 1ns / 1ps
module top_my_watch #(
    parameter COUNT_100HZ = 1_000_000,
    parameter MSEC_MAX = 100,
    parameter SEC_MAX = 60,
    parameter MIN_MAX = 60,
    parameter HOUR_MAX = 24
) (
    input clk,
    input reset,
    input hs_mod_sw,
    input watch_mod_sw,
    input btnU,
    input btnL,
    input btnR,
    input btnD,
    output [3:0] fnd_comm,
    output [7:0] fnd_font,
    output [3:0] mod_indicate_led
);

    wire btn_sec;
    wire btn_min;
    wire btn_hour;
    assign btn_sec  = btnD;
    assign btn_min  = btnL;
    assign btn_hour = btnU;

    mod_indicator U_Mod_Indicator (
        .hs_mod_sw(hs_mod_sw),
        .watch_mod_sw(watch_mod_sw),
        .led(mod_indicate_led)
    );

    wire [$clog2(MSEC_MAX)-1:0] stopwatch_msec;
    wire [ $clog2(SEC_MAX)-1:0] stopwatch_sec;
    wire [ $clog2(MIN_MAX)-1:0] stopwatch_min;
    wire [$clog2(HOUR_MAX)-1:0] stopwatch_hour;
    stopwatch #(
        .COUNT_100HZ(COUNT_100HZ),
        .MSEC_MAX(MSEC_MAX),
        .SEC_MAX(SEC_MAX),
        .MIN_MAX(MIN_MAX),
        .HOUR_MAX(HOUR_MAX)
    ) U_Stopwatch (
        .clk(clk),
        .reset(reset),
        .btn_run_stop(btnL),
        .btn_clear(btnR),
        .watch_mod_sw(watch_mod_sw),
        .w_msec(stopwatch_msec),
        .w_sec(stopwatch_sec),
        .w_min(stopwatch_min),
        .w_hour(stopwatch_hour)
    );

    wire [$clog2(MSEC_MAX)-1:0] watch_msec;
    wire [ $clog2(SEC_MAX)-1:0] watch_sec;
    wire [ $clog2(MIN_MAX)-1:0] watch_min;
    wire [$clog2(HOUR_MAX)-1:0] watch_hour;
    watch #(
        .COUNT_100HZ(COUNT_100HZ),
        .MSEC_MAX(MSEC_MAX),
        .SEC_MAX(SEC_MAX),
        .MIN_MAX(MIN_MAX),
        .HOUR_MAX(HOUR_MAX)
    ) U_Watch (
        .clk(clk),
        .reset(reset),
        .btn_sec(btnD),
        .btn_min(btnL),
        .btn_hour(btnU),
        .watch_mod_sw(watch_mod_sw),
        .w_msec(watch_msec),
        .w_sec(watch_sec),
        .w_min(watch_min),
        .w_hour(watch_hour)
    );

    wire [$clog2(MSEC_MAX)-1:0] w_msec;
    wire [ $clog2(SEC_MAX)-1:0] w_sec;
    wire [ $clog2(MIN_MAX)-1:0] w_min;
    wire [$clog2(HOUR_MAX)-1:0] w_hour;

    watch_mod_mux #(
        .COUNT_100HZ(COUNT_100HZ),
        .MSEC_MAX(MSEC_MAX),
        .SEC_MAX(SEC_MAX),
        .MIN_MAX(MIN_MAX),
        .HOUR_MAX(HOUR_MAX)
    ) U_W_Mod_Mux (
        .i_watch_mod_sw(watch_mod_sw),
        .stopwatch_msec(stopwatch_msec),
        .stopwatch_sec(stopwatch_sec),
        .stopwatch_min(stopwatch_min),
        .stopwatch_hour(stopwatch_hour),
        .watch_msec(watch_msec),
        .watch_sec(watch_sec),
        .watch_min(watch_min),
        .watch_hour(watch_hour),
        .o_msec(w_msec),
        .o_sec(w_sec),
        .o_min(w_min),
        .o_hour(w_hour)
    );

    fnd_controller #(
        .MSEC_MAX(MSEC_MAX),
        .SEC_MAX(SEC_MAX),
        .MIN_MAX(MIN_MAX),
        .HOUR_MAX(HOUR_MAX),
        .COUNT_100HZ(COUNT_100HZ)
    ) U_fnd_cntl (
        .clk(clk),
        .reset(reset),
        .hs_mod_sw(hs_mod_sw),
        .msec(w_msec),
        .sec(w_sec),
        .min(w_min),
        .hour(w_hour),
        .fnd_font(fnd_font),
        .fnd_comm(fnd_comm)
    );

endmodule

module mod_indicator (
    input hs_mod_sw,
    input watch_mod_sw,
    output reg [3:0] led
);
    wire sw = {hs_mod_sw, watch_mod_sw};
    always @(*) begin
        case (sw)
            2'b00:   led = 4'b0001;
            2'b01:   led = 4'b0010;
            2'b10:   led = 4'b0100;
            2'b11:   led = 4'b1000;
            default: led = 0;
        endcase
    end

endmodule

module watch_mod_mux #(
    parameter COUNT_100HZ = 1_000_000,
    parameter MSEC_MAX = 100,
    parameter SEC_MAX = 60,
    parameter MIN_MAX = 60,
    parameter HOUR_MAX = 24
) (
    input i_watch_mod_sw,

    input [$clog2(MSEC_MAX)-1:0] stopwatch_msec,
    input [ $clog2(SEC_MAX)-1:0] stopwatch_sec,
    input [ $clog2(MIN_MAX)-1:0] stopwatch_min,
    input [$clog2(HOUR_MAX)-1:0] stopwatch_hour,

    input [$clog2(MSEC_MAX)-1:0] watch_msec,
    input [ $clog2(SEC_MAX)-1:0] watch_sec,
    input [ $clog2(MIN_MAX)-1:0] watch_min,
    input [$clog2(HOUR_MAX)-1:0] watch_hour,

    output [$clog2(MSEC_MAX)-1:0] o_msec,
    output [ $clog2(SEC_MAX)-1:0] o_sec,
    output [ $clog2(MIN_MAX)-1:0] o_min,
    output [$clog2(HOUR_MAX)-1:0] o_hour
);

    reg [$clog2(MSEC_MAX)-1:0] w_msec;
    reg [ $clog2(SEC_MAX)-1:0] w_sec;
    reg [ $clog2(MIN_MAX)-1:0] w_min;
    reg [$clog2(HOUR_MAX)-1:0] w_hour;
    always @(*) begin
        if (i_watch_mod_sw) begin
            w_msec = watch_msec;
            w_sec  = watch_sec;
            w_min  = watch_min;
            w_hour = watch_hour;
        end else begin
            w_msec = stopwatch_msec;
            w_sec  = stopwatch_sec;
            w_min  = stopwatch_min;
            w_hour = stopwatch_hour;
        end
    end

    assign o_msec = w_msec;
    assign o_sec  = w_sec;
    assign o_min  = w_min;
    assign o_hour = w_hour;

endmodule
