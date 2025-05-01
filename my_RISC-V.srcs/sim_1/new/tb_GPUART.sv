`timescale 1ns / 1ps

interface GP_UART_interface (
    input logic clk,
    input logic reset
);
    // APB Interface Signals
    logic [ 3:0] PADDR;
    logic [31:0] PWDATA;
    logic        PWRITE;
    logic        PENABLE;
    logic        PSEL;
    logic [31:0] PRDATA;
    logic        PREADY;
    // inout signals
    logic        rx;
    logic        tx;
endinterface  //GP_UART_interface

module tb_GPUART ();
    logic clk, reset;
    GP_UART_interface intf (.*);
    GP_UART u_GP_UART (
        .PCLK   (clk),
        .PRESET (reset),
        .PADDR  (intf.PADDR),
        .PWDATA (intf.PWDATA),
        .PWRITE (intf.PWRITE),
        .PENABLE(intf.PENABLE),
        .PSEL   (intf.PSEL),
        .PRDATA (intf.PRDATA),
        .PREADY (intf.PREADY),
        .rx     (intf.rx),
        .tx     (intf.tx)
    );

    task initialize_intf();
        intf.PADDR = 0;
        intf.PWDATA = 0;
        intf.PWRITE = 0;
        intf.PENABLE = 0;
        intf.PSEL = 0;
        intf.PRDATA = 0;
        intf.PREADY = 0;
        intf.rx = 1;
        intf.tx = 0;
    endtask  //

    task gp_run(logic write, logic [31:0] WDATA);
        @(posedge clk) #1;
        intf.PADDR   <= (write) ? 0: 4;
        intf.PWDATA  <= WDATA;
        intf.PWRITE  <= write;
        intf.PENABLE <= 1'b0;
        intf.PSEL    <= 1'b1;

        @(posedge clk) #1;
        intf.PENABLE <= 1'b1;
        intf.PSEL    <= 1'b1;

        wait (intf.PREADY) #1;
        intf.PENABLE <= 1'b0;
        intf.PSEL    <= 1'b0;
    endtask  //

    always #5 clk = ~clk;
    initial begin
        clk = 0;
        reset = 1;
        initialize_intf();
        #10 reset = 0;

        #100 $finish;
    end
endmodule
