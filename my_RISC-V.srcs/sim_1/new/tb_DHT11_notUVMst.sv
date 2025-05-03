`timescale 1ns / 1ps
// tb_DHT11_notUVMst.sv
module DHT11_module (
    input  logic        clk,
    input  logic        reset,
    inout  logic        data,
    output logic [7:0]  rh,
    output logic [7:0]  t,
    output logic        w_finish_tick
);
    // 고정된 값으로. reset 후 rh=0xA5, t=0x5A, w_finish_tick=1 (가짜센서)
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            rh            <= 8'h00;
            t             <= 8'h00;
            w_finish_tick <= 1'b0;
        end else begin
            rh            <= 8'hA5;
            t             <= 8'h5A;
            w_finish_tick <= 1'b1;
        end
    end
endmodule


module tb_DHT11_notUVMst;

    logic         PCLK;
    logic         PRESET;
    // APB Interface Signals
    logic  [3:0]  PADDR;
    logic [31:0]  PWDATA;
    logic         PWRITE;
    logic         PENABLE;
    logic         PSEL;
    logic [31:0]  PRDATA;
    logic         PREADY;
    
    wire         DATA_IO;

    // 시뮬레이션용
    logic  [7:0]  sim_rh;
    logic  [7:0]  sim_t;
    logic         sim_finish;

    DHT11_Periph DUT (
        .PCLK       (PCLK),
        .PRESET     (PRESET),
        .PADDR      (PADDR),
        .PWDATA     (PWDATA),
        .PWRITE     (PWRITE),
        .PENABLE    (PENABLE),
        .PSEL       (PSEL),
        .PRDATA     (PRDATA),
        .PREADY     (PREADY),
        .DATA_IO    (DATA_IO),
        .sim_rh     (sim_rh),
        .sim_t      (sim_t),
        .sim_finish (sim_finish)
    );

    initial begin
        PCLK = 0;
        forever #5 PCLK = ~PCLK;
    end

    initial begin
        PRESET = 1;
        #20;
        PRESET = 0;
    end

    // APB Interface Signals 초기화
    initial begin
        PSEL    = 0;
        PENABLE = 0;
        PWRITE  = 0;
        PADDR   = 4'h0;
        PWDATA  = 32'h0;
    end

    // APB read
    task automatic apb_read(input logic [3:0] addr);
        begin
            @(negedge PCLK);
            PADDR   = addr;
            PWRITE  = 1'b0; // read 모드
            PSEL    = 1'b1;
            PENABLE = 1'b0;
            @(negedge PCLK);
            PENABLE = 1'b1;
            wait (PREADY);
            @(negedge PCLK);
            $display("[time=%0t] READ @ 0x%0h -> PRDATA=0x%0h  (rh=0x%0h, t=0x%0h, finish=%b)",
                     $time, addr, PRDATA, sim_rh, sim_t, sim_finish);
            // 종료
            PSEL    = 1'b0;
            PENABLE = 1'b0;
            @(negedge PCLK);
        end
    endtask

    // 시나리오
    initial begin
        @(negedge PRESET);
        #20;

        apb_read(4'h0); // RH 레지스터 읽기
        apb_read(4'h4); // T 레지스터 읽기
        apb_read(4'h8); // finish 읽기

        #50;
        $finish;
    end

endmodule
