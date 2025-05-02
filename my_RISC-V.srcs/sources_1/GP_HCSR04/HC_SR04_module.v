`timescale 1ns / 1ps
// top_sensor.v
// 초음파 센서와 fnd를 제어하는 상위 모듈
module HC_SR04_module (
    input  clk,
    input  reset,
    input  start_trigger,  // 버튼 입력 (트리거 신호 생성)
    input  data,           // 초음파 센서 Echo 신호 입력
    output start_tick,
    output[15:0] o_data,
    output done
);
    wire w_tick;  // 1us 주기 클럭 신호

    // 센서 제어 FSM (거리 측정 및 거리 계산 처리)
    HC_SR04_cu U_senor_cu (
        .clk(clk),
        .reset(reset),
        .tick(w_tick),
        .start_trigger(start_trigger),
        .data(data),
        .start_tick(start_tick),
        .o_data(o_data),
        .done(done)
    );

    // 1us 주기 클럭 생성기
    tick_gen_1us U_tick_gen_1us (
        .clk  (clk),
        .reset(reset),
        .tick (w_tick)
    );

endmodule

// 초음파 센서 FSM 제어 모듈
module HC_SR04_cu (
    input clk,
    input reset,
    input tick,  // 1us 클럭 신호 입력
    input start_trigger,  // 거리 측정 시작 트리거 입력
    input data,  // Echo 신호 입력
    output start_tick,  // Trigger 출력 신호 (초음파 펄스 송출)
    output [15:0] o_data,  // 거리 측정 결과 출력
    output reg done
);
    // FSM state
    parameter IDLE = 0, START = 1, WAIT = 2, DATA = 3;

    parameter MAX_DISTANCE = 250;  //측정 최대 범위 400cm

    reg [3:0] state, next;
    reg [5:0] tick_count, tick_count_next;
    reg [15:0] data_reg, data_next;
    reg start_tick_reg, start_tick_next;
    reg done_next;

    // Echo 신호의 High 레벨 시간을 이용해 거리(cm)로 환산 (Echo시간(us)/58)
    assign o_data = data_reg / 58;
    assign start_tick = start_tick_reg;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            state <= 0;
            tick_count <= 0;
            data_reg <= 0;
            start_tick_reg <= 0;
            done <= 0;
        end else begin
            state <= next;
            tick_count <= tick_count_next;
            data_reg <= data_next;
            start_tick_reg <= start_tick_next;
            done <= done_next;
        end
    end

    always @(*) begin
        next = state;
        data_next = data_reg;
        tick_count_next = tick_count;
        start_tick_next = start_tick_reg;
        done_next = 0;
        case (state)
            // 대기 상태
            IDLE:
            if (start_trigger == 1) begin
                next = START;  // 트리거가 들어오면 측정 시작
            end

            // 초음파 발신 시작 신호 생성 (10us 유지)
            START:
            if (tick == 1) begin
                data_next = 0;  // 거리 데이터 초기화
                start_tick_next = 1;  // Trigger 신호 활성화
                tick_count_next = tick_count + 1;
                if (tick_count_next == 10) begin    // 10us 지나면 발신 종료
                    next = WAIT;
                    start_tick_next = 0;
                    tick_count_next = 0;
                end
            end

            // Echo 신호 수신을 기다림
            WAIT:
            if (data == 1) begin
                next = DATA;     // Echo 신호가 High로 오면 데이터 수신 시작
            end else begin
                next = state;
            end

            // Echo 신호 High 시간 측정 (거리 계산을 위한 시간 측정)
            DATA:
            if (data == 1) begin
                if (tick == 1) begin
                    data_next = data_reg + 1;
                    if (data_next == MAX_DISTANCE * 58) begin
                        next = IDLE;  // 최대 거리 초과시 IDLE로 복귀
                    end
                end

            end else if (data == 0) begin
                done_next = 1;
                next = IDLE;
            end


        endcase
    end
endmodule

// 1us 주기 클럭 생성기
module tick_gen_1us (
    input  clk,
    input  reset,
    output tick
);

    localparam BAUD_COUNT = 100;
    reg [$clog2(BAUD_COUNT)-1:0] count_reg, count_next;

    reg tick_reg, tick_next;

    assign tick = tick_reg;

    always @(posedge clk, posedge reset) begin
        if (reset == 1) begin
            count_reg <= 0;
            tick_reg  <= 0;
        end else begin
            count_reg <= count_next;
            tick_reg  <= tick_next;
        end
    end

    always @(*) begin
        count_next = count_reg;
        tick_next  = tick_reg;
        if (count_reg == BAUD_COUNT - 1) begin
            count_next = 0;
            tick_next  = 1;  // 1us마다 tick 생성
        end else begin
            count_next = count_reg + 1;
            tick_next  = 0;
        end
    end

endmodule
