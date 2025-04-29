`timescale 1ns / 1ps

module ram_ip_seq #(
    parameter ADDR_WIDTH = 4,  // 주소 폭 (4비트 -> 16개의 주소)
    parameter DATA_WIDTH = 8  // 데이터 폭 (8비트)
) (
    input clk,                              // 클럭 신호
    input [ADDR_WIDTH-1:0] addr,            // 주소 입력
    input [DATA_WIDTH-1:0] wdata,           // 쓰기 데이터 입력
    input wr,                               // 쓰기 활성화 신호 (1이면 쓰기)
    output reg [DATA_WIDTH-1:0] rdata       // 읽기 데이터 출력
);

    // RAM 메모리 선언 (2^ADDR_WIDTH 크기)
    reg [DATA_WIDTH-1:0] ram [0:(1<<ADDR_WIDTH)-1];

    // 동기식 쓰기 및 읽기
    always @(posedge clk) begin
        if (wr) begin
            ram[addr] <= wdata;  // 쓰기 동작
        end else begin
            rdata <= ram[addr];  // 읽기 동작
        end
    end

endmodule

module ram_comb #(
    parameter ADDR_WIDTH = 4,  // 주소 폭 (4비트 -> 16개의 주소)
    parameter DATA_WIDTH = 8  // 데이터 폭 (8비트)
) (
    input clk,                              // 클럭 신호
    input [ADDR_WIDTH-1:0] addr,            // 주소 입력
    input [DATA_WIDTH-1:0] wdata,           // 쓰기 데이터 입력
    input wr,                               // 쓰기 활성화 신호 (1이면 쓰기)
    output [DATA_WIDTH-1:0] rdata           // 읽기 데이터 출력
);

    // RAM 메모리 선언 (2^ADDR_WIDTH 크기)
    reg [DATA_WIDTH-1:0] ram [0:(1<<ADDR_WIDTH)-1];

    // 쓰기 동작 (동기식)
    always @(posedge clk) begin
        if (wr) begin
            ram[addr] <= wdata;  // 쓰기 동작
        end
    end

    // 읽기 동작 (조합논리)
    assign rdata = ram[addr];  // 주소에 해당하는 데이터 출력

endmodule