module stopwatch #(
    parameter COUNT_100HZ = 1_000_000,
    parameter MSEC_MAX = 100,
    parameter SEC_MAX = 60,
    parameter MIN_MAX = 60,
    parameter HOUR_MAX = 24
) (
    input clk,
    input reset,
    input d_run_stop,
    input d_clear,
    input watch_mod_sw,
    output [$clog2(MSEC_MAX)-1:0] w_msec,
    output [$clog2(SEC_MAX)-1:0] w_sec,
    output [$clog2(MIN_MAX)-1:0] w_min,
    output [$clog2(HOUR_MAX)-1:0] w_hour
);
    wire w_run_stop, w_clear;

    stopwatch_control_unit U_Stopwatch_CU (
        .clk(clk),
        .reset(reset),
        .i_run_stop(d_run_stop),  // input 
        .i_clear(d_clear),
        .i_mod(watch_mod_sw),
        .o_run_stop(w_run_stop),
        .o_clear(w_clear)
    );

    stopwatch_dp #(
        .COUNT_100HZ(COUNT_100HZ),
        .MSEC_MAX(MSEC_MAX),
        .SEC_MAX(SEC_MAX),
        .MIN_MAX(MIN_MAX),
        .HOUR_MAX(HOUR_MAX)
    ) U_Stopwatch_DP (
        .clk(clk),
        .reset(reset),
        .i_run_stop(w_run_stop),
        .i_clear(w_clear),
        .msec(w_msec),
        .sec(w_sec),
        .min(w_min),
        .hour(w_hour)
    );
endmodule

module stopwatch_control_unit (
    input clk,
    input reset,
    input i_run_stop,  // input 
    input i_clear,
    input i_mod,  //0:stopwatch, 1:watch
    output reg o_run_stop,
    output reg o_clear
);
    parameter STOP = 3'b000, RUN = 3'b001, CLEAR = 3'b010;
    // state 관리
    reg [2:0] state, next;

    // state sequencial logic
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            state <= STOP;
        end else begin
            state <= next;
        end
    end

    // next combinational logic
    always @(*) begin
        next = state;
        case (state)
            STOP: begin
                if (!i_mod) begin
                    if (i_run_stop == 1'b1) begin
                        next = RUN;
                    end else if (i_clear == 1'b1) begin
                        next = CLEAR;
                    end
                end else next = state;
            end
            RUN: begin
                if (!i_mod) begin
                    if (i_run_stop == 1'b1) begin
                        next = STOP;
                    end
                end else next = state;
            end
            CLEAR: begin
                if (i_clear == 1'b0) begin
                    next = STOP;
                end else next = state;
            end
            default: begin
                next = state;
            end
        endcase
    end

    // combinational output logic
    always @(*) begin
        // 초기화 필요.
        o_run_stop = 1'b0;
        o_clear = 1'b0;
        case (state)
            STOP: begin
                o_run_stop = 1'b0;
                o_clear = 1'b0;
            end
            RUN: begin
                o_run_stop = 1'b1;
                o_clear = 1'b0;
            end
            CLEAR: begin
                o_clear = 1'b1;
            end
            default: begin
                o_run_stop = 1'b0;
                o_clear = 1'b0;
            end
        endcase
    end
endmodule
