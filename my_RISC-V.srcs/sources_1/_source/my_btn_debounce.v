`timescale 1ns / 1ps

module btn_debounce (
    input  clk,
    input  reset,
    input  i_btn,
    output o_btn
);
    //1khz CLK생성 - w_1khz
    wire w_1khz;
    m_1khz U_1khz (
        .clk(clk),
        .reset(reset),
        .o_1khz(w_1khz)
    );

    // reg    state  next
    reg [7:0] q_reg, q_next;  //shift register
    
    //state logic, 1khz clk
    always @(posedge w_1khz, posedge reset) begin
        if (reset) begin
            q_reg <= 0;
        end else begin
            q_reg <= q_next;
        end
    end

    //next logic
    always @(i_btn, w_1khz) begin  // event i_btn, r_1khz
        //나머지 좌짝으로 시프트하고 첫비트에 입력을 넣는다
        //poooo n -> p oooon
        //시프트 한 상태를 "다음상태"로 세팅한다.
        q_next = {i_btn, q_reg[7:1]};
    end

    // 8input AND gate
    wire btn_debounce;
    assign btn_debounce = &q_reg;

    //ege_detector, 100Mhz clk
    reg  edge_detect;
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            edge_detect <= 0;
        end else begin
            edge_detect <= btn_debounce;
        end
    end


    // 최종 출력
    assign o_btn = btn_debounce & (~edge_detect);

endmodule

module m_1khz #(parameter COUNT_MAX = 100_000)(
    input  clk,
    input  reset,
    output o_1khz
);
    // 1khz clk
    //state
    reg [$clog2(COUNT_MAX) - 1:0] counter;
    reg r_1khz;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            counter <= 0;
            r_1khz  <= 0;
        end else begin
            if (counter == COUNT_MAX) begin
                counter <= 0;
                r_1khz  <= 1'b1;
            end else begin
                counter <= counter + 1;
                r_1khz  <= 1'b0;
            end
        end
    end

    assign o_1khz = r_1khz;
endmodule
