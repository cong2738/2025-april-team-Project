`timescale 1ns / 1ps

interface HCSR04_interface (
    input logic clk,
    input logic reset
);
    logic [ 3:0] PADDR;
    logic [31:0] PWDATA;
    logic        PWRITE;
    logic        PENABLE;
    logic        PSEL;
    logic [31:0] PRDATA;
    logic        PREADY;
    logic        echo_data;
    logic        echo_start;
endinterface  //HCSR04_interface


module tb_HCSR04 ();
    logic clk, reset;
    HCSR04_interface intf (
        clk,
        reset
    );
    GP_HCSR04 #(
        .MAX_COUNT(10)
    ) u_GP_HCSR04 (
        .PCLK      (clk),
        .PRESET    (reset),
        .PADDR     (intf.PADDR),
        .PWDATA    (intf.PWDATA),
        .PWRITE    (intf.PWRITE),
        .PENABLE   (intf.PENABLE),
        .PSEL      (intf.PSEL),
        .PRDATA    (intf.PRDATA),
        .PREADY    (intf.PREADY),
        .echo_data (intf.echo_data),
        .echo_start(intf.echo_start)
    );

    parameter IDLE = 0, START = 1, WAIT = 2, DATA = 3;
    logic sensorTick;
    logic[3:0] state;
    assign sensorTick = u_GP_HCSR04.u_HC_SR04_module.w_tick;
    assign state = u_GP_HCSR04.u_HC_SR04_module.U_senor_cu.state;

    always #5 clk = ~clk;

    task intf_init();
        intf.PADDR = 0;
        intf.PWDATA = 0;
        intf.PWRITE = 0;
        intf.PENABLE = 0;
        intf.PSEL = 0;
        intf.PRDATA = 0;
        intf.PREADY = 0;
        intf.echo_data = 0;
        intf.echo_start = 0;
    endtask  //

    task sensorData_Send(integer T);
        integer time_count = 0;
        while (time_count != T+1) begin
            @(negedge sensorTick) time_count = time_count + 1;
            intf.echo_data = 1;
        end
        intf.echo_data = 0;
    endtask  //

    initial begin
        intf_init();
        clk   = 0;
        reset = 1;
        #5 reset = 0;
        wait(state == WAIT) sensorData_Send(580);
        #1000 $finish;
    end

endmodule
