`timescale 1ns / 1ps
module btn_debounce (
    input  i_btn,
    input  clk,
    input  reset,
    output o_btn
);

    reg [7:0] q_reg, q_next;
    wire btn_debounce;
    reg [7:0] edge_detect;
    reg [$clog2(100_000):0] counter;
    reg r_1khz;


    always @(posedge r_1khz, posedge reset) begin
        if (reset) begin
            q_reg <= 0;
        end else begin
            q_reg <= q_next;
        end
    end

    always @(i_btn, r_1khz) begin  // event i_btn, r_1khz
        // q_reg 현재의 상위 7비트를 다음 하위 7비트에 넣고 최상에는 i_btn을 넣음음
        q_next = {i_btn, q_reg[7:1]};  //shfit 동작 설명명
    end


    always @(posedge clk, posedge reset) begin  // 1khz clock
        if (reset) begin
            counter <= 0;
            r_1khz <=0;
        end else begin
            if (counter == 100_000 - 1) begin
                counter <= 0;
                r_1khz  <= 1'b1;
            end else begin
                counter <= counter + 1;
                r_1khz  <= 1'b0;
            end
        end
    end


    //8input and gate
    assign btn_debounce = &q_reg;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
                edge_detect <= 0;
            end 
            else begin
            edge_detect <= btn_debounce;
        end

    end
    assign o_btn = btn_debounce & (~edge_detect);
endmodule
