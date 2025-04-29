`timescale 1ns / 1ps `timescale 1ns / 1ps

module GP_UART (
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
    // inport signals
    inout  logic [ 7:0] inoutPort
);

    logic [7:0] moder;
    logic [7:0] idr;
    logic [7:0] odr;

    APB_SlaveIntf_UART U_APB_Intf_GPIO (.*);

endmodule

module APB_SlaveIntf_UART (
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
    output logic        mode,
    input  logic [ 7:0] idr,
    output logic [ 7:0] odr
);
    logic [31:0] slv_reg0, slv_reg1, slv_reg2;  // ,slv_reg3;

    assign mode          = slv_reg0[0];
    assign slv_reg1[7:0] = idr;
    assign odr           = slv_reg2[7:0];

    always_ff @(posedge PCLK, posedge PRESET) begin
        if (PRESET) begin
            slv_reg0 <= 0;
            //slv_reg1 <= 0;
            slv_reg2 <= 0;
            // slv_reg3 <= 0;
        end else begin
            if (PSEL && PENABLE) begin
                PREADY <= 1'b1;
                if (PWRITE) begin
                    case (PADDR[3:2])
                        2'd0: slv_reg0 <= PWDATA;
                        2'd1: ;
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


module FIFO_IP (
    // global signal
    input  logic        PCLK,
    input  logic        PRESET,
    // internal signals
    input  logic        mode,
    output logic [ 7:0] txdr,
    input  logic [ 7:0] rxdr,
    output logic        done
);
    uart u_uart (
        .clk            (PCLK),
        .rst            (PRESET),
        .tx_start_triger(tx_start_triger),
        .tx_data        (tx_data),
        .rx             (rx),
        .tx             (tx),
        .tx_busy        (tx_busy),
        .rx_data        (rx_data),
        .rx_done        (rx_done)
    );
    fifo u_fifo_TX(
        .clk   (PCLK   ),
        .reset (PRESET ),
        .wr_en (wr_en ),
        .rd_en (rd_en ),
        .wData (wData ),
        .rData (rData ),
        .full  (full  ),
        .empty (empty )
    );
    fifo u_fifo_RX(
        .clk   (PCLK   ),
        .reset (PRESET ),
        .wr_en (wr_en ),
        .rd_en (rd_en ),
        .wData (wData ),
        .rData (rData ),
        .full  (full  ),
        .empty (empty )
    );
endmodule