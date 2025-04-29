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
    input [7:0] cmd,
    output [3:0] fnd_comm,
    output [7:0] fnd_font,
    output [3:0] mod_indicate_led
);

    wire btn_run_stop;
    wire btn_clear;
    wire btn_sec;
    wire btn_min;
    wire btn_hour;
    assign btn_run_stop = btnL;
    assign btn_clear = btnR;
    assign btn_sec = btnD;
    assign btn_min = btnL;
    assign btn_hour = btnU;

    mod_indicator U_Mod_Indicator (
        .hs_mod_sw(hs_mod_sw),
        .watch_mod_sw(watch_mod_sw),
        .led(mod_indicate_led)
    );

    wire run_stop_cmd;
    wire clear_cmd;
    wire sec_add_cmd;
    wire min_add_cmd;
    wire hour_add_cmd;
    cmd_sig_box U_cmdBox (
        .clk     (clk),
        .rst     (reset),
        .cmd     (cmd),
        .run_stop(run_stop_cmd),
        .clear   (clear_cmd),
        .sec_add (sec_add_cmd),
        .min_add (min_add_cmd),
        .hour_add(hour_add_cmd)
    );

    stopwatch_BD U_Stopwatch_BD (
        .clk(clk),
        .reset(reset),
        .btn_run_stop(btn_run_stop),
        .btn_clear(btn_clear),
        .d_run_stop(d_run_stop),
        .d_clear(d_clear)
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
        .d_run_stop(d_run_stop|run_stop_cmd),
        .d_clear(d_clear|clear_cmd),
        .watch_mod_sw(watch_mod_sw),
        .w_msec(stopwatch_msec),
        .w_sec(stopwatch_sec),
        .w_min(stopwatch_min),
        .w_hour(stopwatch_hour)
    );

    watch_BD U_Watch_BD (
        .clk(clk),
        .reset(reset),
        .btn_sec(btn_sec),
        .btn_min(btn_min),
        .btn_hour(btn_hour),
        .d_sec_add(d_sec_add),
        .d_min_add(d_min_add),
        .d_hour_add(d_hour_add)
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
        .d_sec_add(d_sec_add),
        .d_min_add(d_min_add),
        .d_hour_add(d_hour_add),
        .watch_mod_sw(watch_mod_sw),
        .w_msec(watch_msec),
        .w_sec(watch_sec|sec_add_cmd),
        .w_min(watch_min|min_add_cmd),
        .w_hour(watch_hour|hour_add_cmd)
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

module stopwatch_BD (
    input  clk,
    input  reset,
    input  btn_run_stop,
    input  btn_clear,
    output d_run_stop,
    output d_clear
);
    btn_debounce U_BTN_Debounce_RUN_STOP (
        .clk(clk),
        .reset(reset),
        .i_btn(btn_run_stop),  // from btn
        .o_btn(d_run_stop)  // to control unit
    );
    btn_debounce U_BTN_Debounce_CLEAR (
        .clk(clk),
        .reset(reset),
        .i_btn(btn_clear),  // from btn
        .o_btn(d_clear)  // to control unit
    );

endmodule

module watch_BD (
    input  clk,
    input  reset,
    input  btn_sec,
    input  btn_min,
    input  btn_hour,
    output d_sec_add,
    output d_min_add,
    output d_hour_add
);
    btn_debounce U_BTN_Debounce_Sec (
        .clk  (clk),
        .reset(reset),
        .i_btn(btn_sec),   // from btn
        .o_btn(d_sec_add)  // to control unit
    );
    btn_debounce U_BTN_Debounce_Min (
        .clk  (clk),
        .reset(reset),
        .i_btn(btn_min),   // from btn
        .o_btn(d_min_add)  // to control unit
    );
    btn_debounce U_BTN_Debounce_Hour (
        .clk  (clk),
        .reset(reset),
        .i_btn(btn_hour),   // from btn
        .o_btn(d_hour_add)  // to control unit
    );

endmodule

module cmd_CU (
    input clk,
    input rst,
    input [7:0] cmd_char,
    output state_tick
);
    reg state, next;
    reg [7:0] cmd_reg, cmd_next;  //상태변화 확인을 위한 reg

    assign state_tick = state;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            state   = 0;
            cmd_reg = 0;
        end else begin
            state   = next;
            cmd_reg = cmd_next;
        end
    end

    always @(*) begin
        next = 0;
        cmd_next = cmd_reg;
        case (state)
            0: begin
                if (cmd_reg != cmd_char) begin
                    next = 1;
                    cmd_next = cmd_char;
                end
            end
            1: begin
                next = 0;
            end
        endcase
    end

endmodule

module cmd_sig_box (
    input        clk,
    input        rst,
    input  [7:0] cmd,
    output       run_stop,
    output       clear,
    output       sec_add,
    output       min_add,
    output       hour_add
);
    localparam  IDLE = 0, 
                RUNSTOP = 1, 
                CLEAR = 2, 
                ADDH = 3, 
                ADDM = 4, 
                ADDS = 5, 
                ADDMS = 6;

    reg [3:0] uart_state;

    always @(*) begin
        case (cmd)
            "R": begin
                uart_state = RUNSTOP;
            end
            "r": begin
                uart_state = RUNSTOP;
            end
            "C": begin
                uart_state = CLEAR;
            end
            "c": begin
                uart_state = CLEAR;
            end
            "H": begin
                uart_state = ADDH;
            end
            "h": begin
                uart_state = ADDH;
            end
            "M": begin
                uart_state = ADDM;
            end
            "m": begin
                uart_state = ADDM;
            end
            "S": begin
                uart_state = ADDS;
            end
            "s": begin
                uart_state = ADDS;
            end
            default: begin
                uart_state = IDLE;
            end
        endcase
    end

    wire tick;
    cmd_CU U_CU (
        .clk(clk),
        .rst(rst),
        .cmd_char(cmd),
        .state_tick(tick)
    );

    assign run_stop =(uart_state == RUNSTOP) & tick;
    assign clear    =(uart_state == CLEAR) & tick;
    assign sec_add  =(uart_state == ADDS) & tick;
    assign min_add  =(uart_state == ADDM) & tick;
    assign hour_add =(uart_state == ADDH) & tick;

endmodule
