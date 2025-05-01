`timescale 1ns / 1ps

module fifo #(
    parameter FIFO_UNIT = 8,
    parameter FIFO_CAP = 2**2
) (
    input              clk,
    input              reset,
    input  logic       wr_en,
    input  logic       rd_en,
    input  logic [7:0] wData,
    output logic [7:0] rData,
    output logic       full,
    output logic       empty
);
    logic [$clog2(FIFO_CAP)-1:0] wr_ptr;
    logic [$clog2(FIFO_CAP)-1:0] rd_ptr;

    fifo_ram u_fifo_ram (
        .clk   (clk),
        .wr_ptr(wr_ptr),
        .wData (wData),
        .wr_en (wr_en & ~full),
        .rd_ptr(rd_ptr),
        .rData (rData)
    );

    fifo_CU u_fifo_CU (.*);


endmodule

module fifo_ram #(
    parameter FIFO_UNIT = 8,
    parameter FIFO_CAP = 2**2
) (
    input clk,
    input logic [$clog2(FIFO_CAP)-1:0] wr_ptr,
    input logic [7:0] wData,
    input logic wr_en,
    input logic [$clog2(FIFO_CAP)-1:0] rd_ptr,
    output logic [7:0] rData
);
    logic [FIFO_UNIT-1:0] mem[0:FIFO_CAP-1];

    always @(posedge clk) begin
        if (wr_en) begin
            mem[wr_ptr] <= wData;
        end
    end

    assign rData = mem[rd_ptr];
endmodule

module fifo_CU #(
    parameter FIFO_UNIT = 8,
    parameter FIFO_CAP = 2**2
) (
    input  logic       clk,
    input  logic       reset,
    // write side
    input  logic       wr_en,
    output logic [$clog2(FIFO_CAP)-1:0] wr_ptr,
    output logic       full,
    // read side
    input  logic       rd_en,
    output logic [$clog2(FIFO_CAP)-1:0] rd_ptr,
    output logic       empty
);
    typedef enum logic [1:0] {
        IDLE = 2'b00,
        WRITE = 2'b01,
        READ = 2'b10,
        RW = 2'b11
    } state_e;

    logic [1:0] fifo_state;
    logic [$clog2(FIFO_CAP)-1:0] wr_ptr_reg, wr_ptr_next;
    logic [$clog2(FIFO_CAP)-1:0] rd_ptr_reg, rd_ptr_next;
    logic full_reg, full_next;
    logic empty_reg, empty_next;

    assign fifo_state = {rd_en, wr_en};
    assign wr_ptr = wr_ptr_reg;
    assign rd_ptr = rd_ptr_reg;
    assign full = full_reg;
    assign empty = empty_reg;

    always_ff @(posedge clk, posedge reset) begin : state_logic
        if (reset) begin
            wr_ptr_reg <= 0;
            rd_ptr_reg <= 0;
            full_reg   <= 0;
            empty_reg  <= 1;
        end else begin
            wr_ptr_reg <= wr_ptr_next;
            rd_ptr_reg <= rd_ptr_next;
            full_reg   <= full_next;
            empty_reg  <= empty_next;
        end
    end

    always_comb begin : fifo_control
        wr_ptr_next = wr_ptr_reg;
        rd_ptr_next = rd_ptr_reg;
        full_next   = full_reg;
        empty_next  = empty_reg;
        case (fifo_state)
            IDLE: begin

            end
            WRITE: begin
                if (!full_reg) begin
                    empty_next  = 0;
                    wr_ptr_next = wr_ptr_reg + 1;
                    if (wr_ptr_next == rd_ptr_reg) full_next = 1;
                end
            end
            READ: begin
                if (!empty_reg) begin
                    full_next   = 0;
                    rd_ptr_next = rd_ptr + 1;
                    if (rd_ptr_next == wr_ptr_reg) empty_next = 1;
                end
            end
            RW: begin
                if (empty_reg) begin
                    empty_next  = 0;
                    wr_ptr_next = wr_ptr_reg + 1;
                end else if (full_reg) begin
                    full_next   = 0;
                    rd_ptr_next = rd_ptr + 1;
                end else begin
                    wr_ptr_next = wr_ptr_reg + 1;
                    rd_ptr_next = rd_ptr + 1;
                end
            end
        endcase
    end
endmodule
