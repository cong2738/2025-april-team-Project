`timescale 1ns / 1ps

module GP_HCSR04 #(parameter MAX_COUNT = 100_000_000) (
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
    input  logic        echo_data,
    output logic        echo_start
);
    logic [15:0] distance;
    logic [15:0] IDR;

    APB_HCSR04Intf U_APB_Intf_GPIO (.*);

    HCSR04_buffer u_HCSR04_buffer(
        .clk      (PCLK      ),
        .reset    (PRESET    ),
        .done     (done     ),
        .distance (distance ),
        .o_data   (IDR   )
    );


    HC_SR04_module #(
        .MAX_COUNT(MAX_COUNT)
    ) u_HC_SR04_module (
        .clk          (PCLK),
        .reset        (PRESET),
        .start_trigger(start_trigger),
        .data         (echo_data),
        .start_tick   (echo_start),
        .o_data       (distance),
        .done         (done)
    );

endmodule

module APB_HCSR04Intf (
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
    input  logic [15:0] IDR
);
    logic [31:0] slv_reg0;
    assign slv_reg0 = IDR;

    always_ff @(posedge PCLK, posedge PRESET) begin
        if (PRESET) begin
            slv_reg1 <= 0;
        end else begin
            if (PSEL && PENABLE) begin
                PREADY <= 1'b1;
                if (~PWRITE) begin
                    PRDATA <= 32'bx;
                    case (PADDR[3:2])
                        2'd0: PRDATA <= slv_reg0;
                    endcase
                end
            end else begin
                PREADY <= 1'b0;
            end
        end
    end

endmodule

module HCSR04_buffer (
    input  logic        clk,
    input  logic        reset,
    input  logic        done,
    input  logic [15:0] distance,
    output logic [15:0] o_data
);
    always_ff @(posedge clk, posedge reset) begin : BUFFER
        if (reset) o_data <= 0;
        else if (done) o_data <= distance;
    end
endmodule
