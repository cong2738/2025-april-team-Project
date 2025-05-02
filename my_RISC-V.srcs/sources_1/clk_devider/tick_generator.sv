`timescale 1ns / 1ps

module tick_generator #(parameter MAX_COUNT = 100_000_000)(
    input logic PCLK,
    input logic PRESET,
    output logic tick
);
    logic [31:0] count_num;
    always_ff @(posedge PCLK, posedge PRESET) begin : blockName
        if (PRESET) begin
            count_num <= 0;
            tick <= 0;
        end else if (PCLK) begin
            if (count_num == MAX_COUNT - 1) begin
                count_num <= 0;
                tick <= 1;
            end else begin
                count_num <= count_num + 1;
                tick <= 0;
            end
        end
    end
endmodule
