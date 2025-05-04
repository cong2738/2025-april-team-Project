`timescale 1ns / 1ps

module GP_calculator(
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
    logic [7:0] MOD;
    logic [7:0] DATA;
    logic [7:0] OPDATA;
    logic [7:0] RESULT;

    APB_calculatorIntf U_APB_Intf (.*);
    calculator U_calculator (.*);
endmodule

module APB_calculatorIntf (
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
    output  logic [7:0] MOD,
    output  logic [7:0] DATA,
    output  logic [7:0] OPDATA,
    input   logic [7:0] RESULT
);
    logic [31:0] slv_reg0, slv_reg1, slv_reg2, slv_reg3;  // ,slv_reg3;

    assign MOD         = slv_reg0[7:0];
    assign DATA          = slv_reg1[7:0];
    assign OPDATA       = slv_reg2[7:0];
    assign slv_reg3[7:0] = RESULT;

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
                        2'd3: PRDATA <= slv_reg3;
                    endcase
                end
            end else begin
                PREADY <= 1'b0;
            end
        end
    end

endmodule

module calculator (
    input  logic [7:0] MOD,
    input  logic [7:0] DATA,
    input  logic [7:0] OPDATA,
    output logic [7:0] RESULT
);
    always_comb begin : CAL
        RESULT = DATA;
        case (MOD)
            37: RESULT = DATA % OPDATA; // '%'
            42: RESULT = DATA * OPDATA; // '*'
            47: RESULT = DATA / OPDATA; // '/'
        endcase
    end
        
endmodule
