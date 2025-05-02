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
    inout  logic        DATA_IO
);

  logic [7:0] rh_int, t_int;
  logic finish_int;

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
      .rh_int    (rh_int),
      .t_int     (t_int),
      .finish_int(finish_int)
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
    input  logic [ 7:0] rh_int,
    input  logic [ 7:0] t_int,
    input  logic        finish_int

);
  

  logic [31:0] slv_reg0, slv_reg1, slv_reg2, slv_reg3;

  assign slv_reg0[7:0] = rh_int;
  assign slv_reg1[7:0] = t_int;
  assign slv_reg2[0] = finish_int;
  

  always_ff @(posedge PCLK, posedge PRESET) begin
        if (PRESET) begin
            //slv_reg0 <= 0;
            //slv_reg1 <= 0;
            //slv_reg2 <= 0;
            // slv_reg3 <= 0;
            // PREADY <= 1'b0;
            // PRDATA <= 32'd0;
        end else begin
            if (PSEL && PENABLE) begin
                PREADY <= 1'b1;
                if (PWRITE) begin
                    case (PADDR[3:2])
                        2'd0: ;
                        2'd1: ;
                        2'd2: ;
                        // 2'd3: ;
                        // 2'd3: slv_reg3 <= PWDATA;
                    endcase
                end else begin
                    PRDATA <= 32'bx;
                    case (PADDR[3:2])
                        2'd0: PRDATA <= slv_reg0;
                        2'd1: PRDATA <= slv_reg1;
                        2'd2: PRDATA <= slv_reg2;
                        // 2'd3: PRDATA <= slv_reg3;
                        // 2'd3: PRDATA <= slv_reg3;
                    endcase
                end
            end else begin
                PREADY <= 1'b0;
            end
        end
    end
endmodule
