`timescale 1ns / 1ps

module tb_fifo ();
    logic clk;
    logic reset;
    logic wr_en;
    logic rd_en;
    logic [7:0] wData;
    logic [7:0] rData;
    logic full;
    logic empty;

    fifo u_fifo (.*);

    always #5 clk = ~clk;

    initial begin
        clk   = 0;
        reset = 1;
        rd_en = 0;
        wr_en = 0;
        #10 reset = 0;

        @(posedge clk) #1;
        wr_en = 1;
        wData = 1;
        @(posedge clk) #1;
        wr_en = 1;
        wData = 2;
        @(posedge clk) #1;
        wr_en = 1;
        wData = 3;
        @(posedge clk) #1;
        wr_en = 1;
        wData = 4;
        @(posedge clk) #1;
        wr_en = 1;
        wData = 5;

        @(posedge clk) #1;
        wr_en = 0;
        wData = 2'bxx;
        rd_en = 1;
        @(posedge clk) #1;
        @(posedge clk) #1;
        @(posedge clk) #1;
        @(posedge clk) #1;
        
        @(posedge clk) #20 $finish;
    end
endmodule
