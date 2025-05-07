`timescale 1ns / 1ps `timescale 1ns / 1ps `timescale 1ns / 1ps

module GP_Timer (
    // global signal
    input  logic        PCLK,
    input  logic        PRESET,
    // APB Interface Signals
    input  logic [ 3:0] PADDR,
    input  logic [31:0] PWDATA,
    input  logic        PWRITE,
    input  logic        PENABLE,
    input  logic        PSEL,
    output logic [31:0] PRDATA,
    output logic        PREADY
);
    logic [1:0] TCR;
    logic [31:0] TCNT, PSC, ARR;

    APB_GP_TimerIntf U_APB_GP_TimerIntf (.*);
    IP_counter u_IP_counter (.*);
endmodule

module APB_GP_TimerIntf (
    // global signal
    input  logic        PCLK,
    input  logic        PRESET,
    // APB Interface Signals
    input  logic [ 3:0] PADDR,
    input  logic [31:0] PWDATA,
    input  logic        PWRITE,
    input  logic        PENABLE,
    input  logic        PSEL,
    output logic [31:0] PRDATA,
    output logic        PREADY,
    // internal signals
    output logic [ 1:0] TCR,
    input  logic [31:0] TCNT,
    output logic [31:0] PSC,
    output logic [31:0] ARR
);
    logic [31:0] slv_reg[0:3];

    assign TCR        = slv_reg[0][1:0];
    assign slv_reg[1] = TCNT;
    assign PSC        = slv_reg[2];
    assign ARR        = slv_reg[3];

    always_ff @(posedge PCLK, posedge PRESET) begin
        if (PRESET) begin
            slv_reg[0] <= 0;
            // slv_reg[1] <= 0;
            slv_reg[2] <= 0;
            slv_reg[3] <= 0;
        end else begin
            if (PSEL && PENABLE) begin
                PREADY <= 1'b1;
                if (PWRITE) begin
                    case (PADDR[3:2])
                        2'd0: slv_reg[0] <= PWDATA;
                        2'd1: ;
                        2'd2: slv_reg[2] <= PWDATA;
                        2'd3: slv_reg[3] <= PWDATA;
                    endcase
                end else begin
                    PRDATA <= 32'bx;
                    case (PADDR[3:2])
                        2'd0: PRDATA <= slv_reg[0];
                        2'd1: PRDATA <= slv_reg[1];
                        2'd2: PRDATA <= slv_reg[2];
                        2'd3: PRDATA <= slv_reg[3];
                    endcase
                end
            end else begin
                PREADY <= 1'b0;
            end
        end
    end

endmodule

module IP_counter (
    input logic PCLK,
    input logic PRESET,
    input logic [1:0] TCR,
    output logic [31:0] TCNT,
    input logic [31:0] PSC,
    input logic [31:0] ARR
);
    logic tick;
    logic en, clear;
    assign {clear, en} = TCR;
    clk_div u_clk_div (.*);
    counter u_counter (.*);
endmodule

module clk_div (
    input logic PCLK,
    input logic PRESET,
    input logic en,
    input logic clear,
    input logic [31:0] PSC,
    output logic tick
);
    logic [31:0] count_num;
    always_ff @(posedge PCLK, posedge PRESET) begin : blockName
        if (PRESET) begin
            count_num <= 0;
            tick <= 0;
        end else if (clear) begin
            count_num <= 0;
            tick <= 0;
        end else if (PCLK & en) begin
            if (count_num == PSC - 1) begin
                count_num <= 0;
                tick <= 1;
            end else begin
                count_num <= count_num + 1;
                tick <= 0;
            end
        end
    end
endmodule

module counter (
    input  logic        PCLK,
    input  logic        PRESET,
    input  logic        en,
    input  logic        tick,
    input  logic        clear,
    input  logic [31:0] ARR,
    output logic [31:0] TCNT
);
    always_ff @(posedge PCLK, posedge PRESET) begin : COUNTER
        if (PRESET) TCNT <= 0;
        else if (clear) TCNT <= 0;
        else if (en) begin
            if (tick) begin
                if (TCNT == ARR) TCNT <= 0;
                else TCNT <= TCNT + 1;
            end
        end
    end
endmodule

