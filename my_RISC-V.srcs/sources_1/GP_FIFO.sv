`timescale 1ns / 1ps

module GP_FIFO (
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
    // inout signals
    input  logic        rx,
    output  logic       tx
);
    logic [7:0] FWD;
    logic [7:0] FRD;
    logic wr_en, rd_en;
    logic full, empty;

    APB_SlaveIntf_GPFIFO U_APB_Intf_GP_FIFO (.*);
    fifo u_fifo(
        .clk   (PCLK   ),
        .reset (PRESET ),
        .wr_en (wr_en ),
        .rd_en (rd_en ),
        .wData (FWD ),
        .rData (FRD ),
        .full  (full  ),
        .empty (empty )
    );
endmodule

module APB_SlaveIntf_GPFIFO (
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
    input  logic        full,
    input  logic        empty,
    output logic [ 7:0] FWD,
    input  logic [ 7:0] FRD,
    output logic        wr_en,
    output logic        rd_en
);
    typedef enum logic [1:0] {
        STOP,
        ACCESS,
        READ,
        SEND
    } fifoIntf_state_e;

    fifoIntf_state_e state, next;
    logic wr_reg, wr_next;
    logic rd_reg, rd_next;
    logic [31:0] slv_reg0, slv_next0;
    logic [31:0] slv_reg1, slv_next1;

    assign wr_en    = wr_reg;
    assign rd_en    = rd_reg;
    assign FWD      = slv_reg0[7:0];
    assign slv_reg1 = FRD;

    always_ff @(posedge PCLK, posedge PRESET) begin
        if (PRESET) begin
            state      <= STOP;
            rd_reg     <= 0;
            wr_reg     <= 0;
            slv_reg0   <= 0;
        end else begin
            state      <= next;
            wr_reg     <= wr_next;
            rd_reg     <= rd_next;
            slv_reg0   <= slv_next0;
        end
    end
    always_comb begin : next_logic
        next        = state;
        wr_next     = wr_reg;
        rd_next     = rd_reg;
        slv_next0   = slv_reg0;
        slv_next1   = slv_reg1;
        PREADY = 0;
        case (state)
            STOP: begin
                wr_next = 0;
                rd_next = 0;
                if (PSEL && PENABLE) begin
                    next = ACCESS;
                end
            end
            ACCESS: begin
                if (PWRITE) begin
                    rd_next = 0;
                    case (PADDR[3:2])
                        2'd0: begin
                            wr_next = ~full;
                            slv_next0 <= PWDATA[7:0];
                        end
                        default: ;
                    endcase
                end else begin
                    wr_next = 0;
                    PRDATA = 32'dx;
                    case (PADDR[3:2])
                        2'd0: PRDATA <= slv_reg0;
                        2'd1: begin
                            rd_next = ~empty;
                            PRDATA <= slv_reg1;
                        end
                    endcase
                end
                next = SEND;
            end
            SEND: begin
                PREADY  = 1;
                wr_next = 0;
                rd_next = 0;
                next = STOP;
            end
        endcase
    end
endmodule
