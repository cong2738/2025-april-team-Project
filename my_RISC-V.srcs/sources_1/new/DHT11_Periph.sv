`timescale 1ns / 1ps
// DHT11_Periph.sv

module DHT11_Periph (
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
    // DHT11
    inout  logic        DATA_IO
);

  logic [7:0] rh_int, t_int;
  logic finish_int;
  logic [7:0] rh_reg, t_reg;

  APB_SlaveIntf_DHT11 U_APB_Intf (
      .PCLK      (PCLK),
      .PRESET    (PRESET),
      .PADDR     (PADDR),
      .PWDATA    (PWDATA),
      .PWRITE    (PWRITE),
      .PENABLE   (PENABLE),
      .PSEL      (PSEL),
      .PRDATA    (PRDATA),
      .PREADY    (PREADY),
      // 센서 모듈에서
      .rh_int    (rh_int),
      .t_int     (t_int),
      .finish_int(finish_int),
      // 캡처된/쓰기된 값
      .RH_REG    (rh_reg),
      .T_REG     (t_reg)
  );
  
  DHT11_module U_DHT11_IP (
      .clk          (PCLK),
      .reset        (PRESET),
      .data         (DATA_IO),
      .rh           (rh_int),
      .t            (t_int),
      .w_finish_tick(finish_int)
  );
endmodule

module APB_SlaveIntf_DHT11 (
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
    // 센서 모듈로부터 받아야 할 것들
    input  logic [ 7:0] rh_int,
    input  logic [ 7:0] t_int,
    input  logic        finish_int,
    // 외부로 내보낼 캡처된 값
    output logic [ 7:0] RH_REG,
    output logic [ 7:0] T_REG
);

  logic [31:0] slv_reg0, slv_reg1; //slv_reg2, slv_reg3;

  assign RH_REG = slv_reg0[7:0];
  assign T_REG  = slv_reg1[7:0];

  always_ff @(posedge PCLK, posedge PRESET) begin
    if (PRESET) begin
      slv_reg0 <= 0;
      slv_reg1 <= 0;
      PREADY   <= 1'b0;
      // slv_reg2 <= 0;
      // slv_reg3 <= 0;
    end else begin
      // 센서 완료 펄스가 올라오면 자동으로 캡처
      if (finish_int) begin
        slv_reg0 <= {24'd0, rh_int};
        slv_reg1 <= {24'd0, t_int};
        // slv_reg0 <= {24'd0, rh_int};
        // slv_reg1 <= {24'd0, t_int};
      end
      if (PSEL && PENABLE) begin
        PREADY <= 1'b1;
        if (PWRITE) begin
          case (PADDR[3:2])
            2'd0: slv_reg0 <= PWDATA;
            2'd1: slv_reg1 <= PWDATA;
            // 2'd2: slv_reg2 <= PWDATA;
            // 2'd3: slv_reg3 <= PWDATA;
          endcase
        end else begin
          case (PADDR[3:2])
            2'd0: PRDATA <= slv_reg0;
            2'd1: PRDATA <= slv_reg1;
            // 2'd2: PRDATA <= slv_reg2;
            // 2'd3: PRDATA <= slv_reg3;
          endcase
        end
      end else begin
        PREADY <= 1'b0;
      end
    end
  end
endmodule
