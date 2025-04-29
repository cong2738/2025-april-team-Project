`timescale 1ns / 1ps

module Top_UART_String (
    input  clk,
    input  rst,
    input  rx,
    output tx
);
    wire [7:0] w_rx_data;
    wire [7:0] w_rxmem_data;
    wire [7:0] w_txmem_data;
    wire w_rx_done;
    wire w_rxmem_empty;
    wire w_txmem_full;
    wire w_txmem_empty;
    wire w_tx_busy;

    uart #(
        .BAUD_RATE(9600)
    ) U_UART (
        .clk(clk),
        .rst(rst),
        .tx_start_triger(~w_txmem_empty),
        .tx_data(w_txmem_data),
        .rx(rx),
        .tx(tx),
        .tx_busy(w_tx_busy),
        .rx_data(w_rx_data),
        .rx_done(w_rx_done)
    );
   
    fifo U_Rx_Mem (
        .clk(clk),
        .reset(rst),
        .wr_en(w_rx_done),
        .rd_en(~w_txmem_full),
        .wData(w_rx_data),
        .rData(w_rxmem_data),
        .full(),
        .empty(w_rxmem_empty)
    );

    fifo U_Tx_Mem (
        .clk(clk),
        .reset(rst),
        .wr_en(~w_rxmem_empty),
        .rd_en(~w_tx_busy),
        .wData(w_rxmem_data),
        .rData(w_txmem_data),
        .full(w_txmem_full),
        .empty(w_txmem_empty)
    );


endmodule
