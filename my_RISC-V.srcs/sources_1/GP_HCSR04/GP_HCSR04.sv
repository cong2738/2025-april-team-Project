`timescale 1ns / 1ps

module GP_HCSR04 (
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
    input  logic [ 7:0] echo_data
);
    logic [15:0] idr;
    logic [15:0] distance;
    logic        done;

    APB_HCSR04Intf U_APB_Intf_GPIO (.*);

    clk_devider #(
        .MAX_COUNT(100_000)
    ) u_clk_devider (
        .PCLK  (PCLK),
        .PRESET(PRESET),
        .en    (1),
        .clear (0),
        .tick  (start_tick)
    );

    HCSR04_buffer u_HCSR04_buffer (
        .clk     (PCLK),
        .reset   (PRESET),
        .done    (done),
        .distance(distance),
        .o_data  (idr)
    );

    HC_SR04_module u_HC_SR04_module (
        .clk          (PCLK),
        .reset        (PRESET),
        .start_trigger(start_trigger),
        .data         (echo_data),
        .start_tick   (start_tick),
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
    input  logic [15:0] idr
);
    logic [31:0] slv_reg0;  // ,slv_reg3;

    assign slv_reg0 = idr;

    always_ff @(posedge PCLK, posedge PRESET) begin
        if (PRESET) begin
            slv_reg0 <= 0;
        end else begin
            if (PSEL && PENABLE) begin
                PREADY <= 1'b1;
                if (~PWRITE) begin
                    PRDATA <= 32'bx;
                    case (PADDR[3:2])
                        2'd0: PRDATA <= slv_reg0;
                        default: ;
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
