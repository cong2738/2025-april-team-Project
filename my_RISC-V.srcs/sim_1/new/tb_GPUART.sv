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
    GP_UART #(1_000_000) u_GP_UART (
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

    localparam R_IDLE = 4'h0, START = 4'h1, DATA_STATE = 4'h2, STOP = 4'h3;

    logic uart_baudrate;
    logic[3:0] rx_state;
    integer rx_data_count;

    assign uart_baudrate = u_GP_UART.u_uart.tick;
    assign rx_state = u_GP_UART.u_uart.U_Rx.state;
    assign rx_data_count = u_GP_UART.u_uart.U_Rx.data_count;
    assign rx_done = u_GP_UART.u_uart.U_Rx.rx_done;

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

    task rx_Send(logic [7:0] data);
        intf.rx = 0;
        wait (rx_state == DATA_STATE);
        while (rx_state == DATA_STATE) begin
            intf.rx = data[rx_data_count];
            @(posedge uart_baudrate);
        end
        intf.rx = 1;
        @(negedge rx_done);
    endtask  //

    always #5 clk = ~clk;
    initial begin
        clk   = 0;
        reset = 1;
        initialize_intf();
        #10 reset = 0;
        rx_Send("a");
        rx_Send("b");
        rx_Send("c");
        rx_Send("d");
        #10 $finish;
    end
endmodule
