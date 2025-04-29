module watch #(
    parameter COUNT_100HZ = 1_000_000,
    parameter MSEC_MAX = 100,
    parameter SEC_MAX = 60,
    parameter MIN_MAX = 60,
    parameter HOUR_MAX = 24
) (
    input clk,
    input reset,
    input btn_sec,
    input btn_min,
    input btn_hour,
    input watch_mod_sw,
    output [$clog2(MSEC_MAX)-1:0] w_msec,
    output [$clog2(SEC_MAX)-1:0] w_sec,
    output [$clog2(MIN_MAX)-1:0] w_min,
    output [$clog2(HOUR_MAX)-1:0] w_hour
);
    wire d_sec_add;
    btn_debounce U_BTN_Debounce_Sec (
        .clk  (clk),
        .reset(reset),
        .i_btn(btn_sec),   // from btn
        .o_btn(d_sec_add)  // to control unit
    );
    wire d_min_add;
    btn_debounce U_BTN_Debounce_Min (
        .clk  (clk),
        .reset(reset),
        .i_btn(btn_min),   // from btn
        .o_btn(d_min_add)  // to control unit
    );
    wire d_hour_add;
    btn_debounce U_BTN_Debounce_Hour (
        .clk  (clk),
        .reset(reset),
        .i_btn(btn_hour),   // from btn
        .o_btn(d_hour_add)  // to control unit
    );

    wire [2:0] w_hms;
    watch_control_unit U_watch_CU (
        .clk(clk),
        .reset(reset),
        .sec_add(d_sec_add),
        .min_add(d_min_add),
        .hour_add(d_hour_add),
        .i_mod(watch_mod_sw),
        .o_hms(w_hms)
    );

    watch_dp #(
        .COUNT_100HZ(COUNT_100HZ),
        .MSEC_MAX(MSEC_MAX),
        .SEC_MAX(SEC_MAX),
        .MIN_MAX(MIN_MAX),
        .HOUR_MAX(HOUR_MAX)
    ) U_watch_DP (
        .clk  (clk),
        .reset(reset),
        .hms  (w_hms),
        .msec (w_msec),
        .sec  (w_sec),
        .min  (w_min),
        .hour (w_hour)
    );
endmodule

module watch_control_unit (
    input clk,
    input reset,
    input sec_add,
    input min_add,
    input hour_add,
    input i_mod,
    output reg [2:0] o_hms
);
    parameter STOP = 3'b000, SEC = 3'b001, MIN = 3'b010, HOUR = 3'b100;

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
    reg [2:0] i_hms;
    always @(*) begin
        i_hms = {sec_add, min_add, hour_add};
        next  = state;
        if (i_mod) begin
            case (state)
                STOP: begin
                    case (i_hms)
                        SEC: begin
                            next = SEC;
                        end
                        MIN: begin
                            next = MIN;
                        end
                        HOUR: begin
                            next = HOUR;
                        end
                    endcase
                end

                SEC: begin
                    if (i_hms == STOP) begin
                        next = STOP;
                    end else next = state;
                end

                MIN: begin
                    if (i_hms == STOP) begin
                        next = STOP;
                    end else next = state;
                end

                HOUR: begin
                    if (i_hms == STOP) begin
                        next = STOP;
                    end else next = state;
                end

                default: begin
                    next = state;
                end
            endcase
        end else next = state;
    end

    // combinational output logic
    always @(*) begin
        // 초기화 필요.
        o_hms = 0;
        case (state)
            SEC: begin
                o_hms = SEC;
            end

            MIN: begin
                o_hms = MIN;
            end

            HOUR: begin
                o_hms = HOUR;
            end

            default: begin
                o_hms = STOP;
            end
        endcase
    end
endmodule
