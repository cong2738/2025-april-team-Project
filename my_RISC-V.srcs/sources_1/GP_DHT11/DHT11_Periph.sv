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
    logic [39:0] DHT11_data;
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
      .DHT11_data(DHT11_data),
      .finish_int(finish_int)
  );

  DHT11_module U_DHT11_IP (
      .clk          (PCLK),
      .reset        (PRESET),
      .data         (DATA_IO),
      .o_data       (DHT11_data),
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
    input  logic [39:0] DHT11_data,
    input  logic        finish_int

);
  

  logic [31:0] slv_reg0, slv_reg1;

  always_ff @(posedge PCLK, posedge PRESET) begin
        if (PRESET) begin
            slv_reg0 <= 0;
            slv_reg1 <= 0;
        end else begin
            if(finish_int) begin
                slv_reg0 <= DHT11_data[39:32];
                slv_reg1 <= DHT11_data[23:16];
            end
            if (PSEL && PENABLE) begin
                PREADY <= 1'b1;
                if (PWRITE) begin
                    case (PADDR[3:2])
                        2'd0: ;
                        2'd1: ;
                    endcase
                end else begin
                    // PRDATA <= 32'bx;
                    PRDATA <= 32'd0; //수정
                    case (PADDR[3:2])
                        2'd0: PRDATA <= slv_reg0;
                        2'd1: PRDATA <= slv_reg1;
                    endcase
                end
            end else begin
                PREADY <= 1'b0;
            end
        end
    end
endmodule

module DHT11_buffer (
    input  logic        clk,
    input  logic        reset,
    input  logic        done,
    input  logic [39:0] i_data,
    output logic [39:0] o_data
);
    always_ff @(posedge clk, posedge reset) begin : BUFFER
        if (reset) o_data <= 0;
        else if (done) o_data <= i_data;
    end
endmodule
