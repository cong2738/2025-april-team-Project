`timescale 1ns / 1ps

module MCU (
    input  logic       clk,
    input  logic       reset,
    output logic [3:0] fndCom,
    output logic [7:0] fndFont,
    output logic       tx,
    input  logic       rx,
    output logic       tx_full,
    output logic       tx_empty,
    output logic       rx_full,
    output logic       rx_empty,
    input  logic       echo_data,
    output logic       echo_start
);
    logic        PCLK;
    logic        PRESET;

    logic [31:0] PADDR;
    logic [31:0] PWDATA;
    logic        PWRITE;
    logic        PENABLE;
    logic [15:0] PSEL;
    logic [31:0] PRDATA       [0:15];
    logic [15:0] PREADY;

    logic        transfer;
    logic        ready;
    logic [31:0] addr;
    logic [31:0] wdata;
    logic [31:0] rdata;
    logic        write;
    logic        dataWe;
    logic [31:0] dataAddr;
    logic [31:0] dataWData;
    logic [31:0] dataRData;

    logic [31:0] instrCode;
    logic [31:0] instrMemAddr;

    assign PCLK = clk;
    assign PRESET = reset;
    assign addr = dataAddr;
    assign wdata = dataWData;
    assign dataRData = rdata;
    assign write = dataWe;

    rom U_ROM (
        .addr(instrMemAddr),
        .data(instrCode)
    );

    RV32I_Core U_Core (.*);

    APB_Master U_APB_Master (.*);

    ram U_RAM (
        .*,
        .PSEL  (PSEL[0]),
        .PRDATA(PRDATA[0]),
        .PREADY(PREADY[0])
    );

    fnd_Periph u_fnd_pp (
        .*,
        .PSEL   (PSEL[1]),
        .PRDATA (PRDATA[1]),
        .PREADY (PREADY[1]),
        .fndFont(fndFont),
        .fndCom (fndCom)
    );

    GP_UART #(
        .BAUD_RATE(9600)
    ) u_GP_UART (
        .*,
        .PSEL    (PSEL[2]),
        .PRDATA  (PRDATA[2]),
        .PREADY  (PREADY[2]),
        .rx      (rx),
        .tx      (tx),
        .tx_full (tx_full),
        .tx_empty(tx_empty),
        .rx_full (rx_full),
        .rx_empty(rx_empty)

    );

    GP_HCSR04 u_GP_HCSR04 (
        .PSEL     (PSEL[3]),
        .PRDATA   (PRDATA[3]),
        .PREADY   (PREADY[3]),
        .echo_data(echo_data),
        .echo_start(echo_start)
    );

endmodule
