`timescale 1ns / 1ps `timescale 1ns / 1ps

module fnd_Periph (
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
    // export signals
    output logic [ 3:0] fndCom,
    output logic [ 7:0] fndFont
);
    logic        FCR;
    logic [13:0] FDR;
    logic [ 3:0] DP;  //FPR
    APB_SlaveIntf_fnd U_APB_Intf_GPIO (.*);
    GPfnd U_GPIO_IP (.*);
endmodule

module APB_SlaveIntf_fnd (
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
    output logic        FCR,
    output logic [13:0] FDR,
    output logic [ 3:0] DP
);
    logic [31:0] slv_reg0, slv_reg1, slv_reg2;  // ,slv_reg3;

    assign FCR = slv_reg0[0];
    assign FDR = slv_reg1[13:0];
    assign DP  = slv_reg2[3:0];

    always_ff @(posedge PCLK, posedge PRESET) begin
        if (PRESET) begin
            slv_reg0 <= 0;
            slv_reg1 <= 0;
            slv_reg2 <= 0;
            // slv_reg3 <= 0;
        end else begin
            if (PSEL && PENABLE) begin
                PREADY <= 1'b1;
                if (PWRITE) begin
                    case (PADDR[3:2])
                        2'd0: slv_reg0 <= PWDATA;
                        2'd1: slv_reg1 <= PWDATA;
                        2'd2: slv_reg2 <= PWDATA;
                        // 2'd3: slv_reg3 <= PWDATA;
                    endcase
                end else begin
                    PRDATA <= 32'bx;
                    case (PADDR[3:2])
                        2'd0: PRDATA <= slv_reg0;
                        2'd1: PRDATA <= slv_reg1;
                        2'd2: PRDATA <= slv_reg2;
                        // 2'd3: PRDATA <= slv_reg3;
                    endcase
                end
            end else begin
                PREADY <= 1'b0;
            end
        end
    end

endmodule

module GPfnd (
    input  logic        PCLK,
    input  logic        PRESET,
    input  logic        FCR,
    input  logic [13:0] FDR,
    input  logic [ 3:0] DP,
    output logic [ 3:0] fndCom,
    output logic [ 7:0] fndFont
);
    logic [3:0] comm;
    
    fndController fnd (
        .clk(PCLK),
        .reset(PRESET),
        .fndData(FDR),
        .fndDot(DP),
        .fndCom(comm),
        .fndFont(fndFont)
    );
    assign fndCom = FCR ? comm : 4'b1111;
endmodule
