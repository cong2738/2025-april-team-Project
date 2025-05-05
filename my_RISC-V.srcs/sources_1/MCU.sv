`timescale 1ns / 1ps

module MCU (
    input  logic       clk,
    input  logic       reset,
    inout  logic [7:0] GPIOC,
    inout  logic [3:0] GPIOD,
    inout  logic       DHT11_DATA,
    output logic [3:0] fndCom,
    output logic [7:0] fndFont
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

  GPIO_Periph U_GPOA (
      .*,
      .PSEL(PSEL[1]),
      .PRDATA(PRDATA[1]),
      .PREADY(PREADY[1]),
      .inoutPort(GPIOA)
  );

  GPIO_Periph U_GPIB (
      .*,
      .PSEL(PSEL[2]),
      .PRDATA(PRDATA[2]),
      .PREADY(PREADY[2]),
      .inoutPort(GPIOB)
  );

  GPIO_Periph U_GPIOC (
      .*,
      .PSEL(PSEL[3]),
      .PRDATA(PRDATA[3]),
      .PREADY(PREADY[3]),
      .inoutPort(GPIOC)
  );

  GPIO_Periph U_GPIOD (
      .*,
      .PSEL(PSEL[4]),
      .PRDATA(PRDATA[4]),
      .PREADY(PREADY[4]),
      .inoutPort(GPIOD)
  );

  fnd_Periph u_fnd_pp (
      .*,
      .PSEL   (PSEL[5]),
      .PRDATA (PRDATA[5]),
      .PREADY (PREADY[5]),
      .fndFont(fndFont),
      .fndCom (fndCom),
      .sim_bcd(),
      .sim_dp ()
  );

  DHT11_Periph U_DHT11 (
      .*,
      .PSEL   (PSEL[6]),
      .PRDATA (PRDATA[6]),
      .PREADY (PREADY[6]),
      .DATA_IO(DHT11_DATA),
      .start_trigger(start_trigger)
  );

endmodule
