`timescale 1ns / 1ps

module fifo #(
    ADDR_WIDTH = 4,
    DATA_WIDTH = 8
) (
    input clk,
    input rst,
    input [DATA_WIDTH-1:0] wdata,
    input wr,
    input rd,
    output [DATA_WIDTH-1:0] rdata,
    output empty,
    output full
);

    wire [ADDR_WIDTH-1:0] w_waddr, w_raddr;


    register_file uregister (
        .clk(clk),
        .waddr(w_waddr),
        .wdata(wdata),
        .raddr(w_raddr),
        .wr(wr & ~full),
        .rd(rd & ~empty),
        .rdata(rdata)
    );


    fifo_cu ufifo_cu (
        .clk(clk),
        .rst(rst),
        .wr(wr),
        .rd(rd),
        .waddr(w_waddr),
        .raddr(w_raddr),
        .full(full),
        .empty(empty)
    );

endmodule


module register_file #(
    ADDR_WIDTH = 4,
    DATA_WIDTH = 8
) (
    input clk,
    input [ADDR_WIDTH-1:0] waddr,
    input [DATA_WIDTH-1:0] wdata,
    input [ADDR_WIDTH-1:0] raddr,
    input wr,
    input rd,
    output [DATA_WIDTH-1:0] rdata
);
    reg [DATA_WIDTH-1:0] ram[0:2**ADDR_WIDTH-1];
    reg [DATA_WIDTH-1:0] w_rdata;
    
    assign rdata = ram[raddr];

    always @(posedge clk) begin
        if (wr) begin
            ram[waddr] = wdata;
        end
        // if (rd) begin
        //     w_rdata = ram[raddr];
        // end
    end

endmodule


module fifo_cu #(
    ADDR_WIDTH = 4,
    DATA_WIDTH = 8
) (
    input clk,
    input rst,
    input wr,
    input rd,
    output [ADDR_WIDTH-1:0] waddr,
    output [ADDR_WIDTH-1:0] raddr,
    output full,
    output empty
);

    reg full_reg, full_next, empty_reg, empty_next;
    reg [ADDR_WIDTH-1:0] w_ptr, w_ptr_next, r_ptr, r_ptr_next;
    assign empty = empty_reg;
    assign full  = full_reg;
    assign waddr = w_ptr;
    assign raddr = r_ptr;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            w_ptr <= 0;
            r_ptr <= 0;
            full_reg <= 0;
            empty_reg <= 1;
        end else begin
            full_reg <= full_next;
            empty_reg <= empty_next;
            w_ptr <= w_ptr_next;
            r_ptr <= r_ptr_next;
        end
    end

    always @(*) begin
        full_next  = full_reg;
        empty_next = empty_reg;
        w_ptr_next = w_ptr;
        r_ptr_next = r_ptr;
        case ({
            wr, rd
        })  // state 입력은 외부에서서
            2'b01: begin
                if (empty_reg == 0) begin
                    r_ptr_next = r_ptr + 1;
                    full_next  = 1'b0;
                    if (w_ptr_next == r_ptr_next) begin
                        empty_next = 1'b1;
                    end
                end
            end
            2'b10: begin
                if (full_reg == 0) begin
                    w_ptr_next = w_ptr + 1;
                    empty_next = 1'b0;
                    if (w_ptr_next == r_ptr_next) begin
                        full_next = 1'b1;
                    end
                end
            end

            2'b11: begin
                if(empty_reg == 1'b1) begin // 동시에 들어올때 empty면 read는 무시
                    w_ptr_next = w_ptr + 1;
                    empty_next = 1'b0;
                end else if (full_reg == 1'b1) begin
                    r_ptr_next = r_ptr + 1;
                    full_next  = 1'b0;
                end else begin
                    r_ptr_next = r_ptr + 1;
                    w_ptr_next = w_ptr + 1;
                end
            end

        endcase
    end

endmodule
