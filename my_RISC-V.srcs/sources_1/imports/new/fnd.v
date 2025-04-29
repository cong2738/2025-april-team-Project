`timescale 1ns / 1ps

module counter_4 (  //10hz
    input clk,
    input reset,
    output [1:0] o_sel
);
    reg [1:0] r_counter;
    assign o_sel = r_counter;
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            r_counter <= 0;
        end else begin
            r_counter <= r_counter + 1;  //0,1,2,3,0,1,2,3....
        end

    end
endmodule

module clock_div (
    input  clk,
    input  reset,
    output o_clk
);  parameter FCOUNT = 1_00_000;
    reg [$clog2(FCOUNT)-1:0] r_counter;
    reg r_clk;
    assign o_clk = r_clk;
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            r_counter <= 0;
            r_clk <= 1'b0;
        end else begin
            if (r_counter == FCOUNT - 1) begin
                r_counter <= 0;
                r_clk <= 1;
            end else begin
                r_counter <= r_counter + 1;
                r_clk <= 1'b0;
            end
        end
    end
endmodule
module decoder_2x4 (
    input [1:0] seg_sel,
    output reg [3:0] seg_comm
);
    always @(seg_sel) begin
        case (seg_sel)
            2'b00:   seg_comm = 4'b1110;
            2'b01:   seg_comm = 4'b1101;
            2'b10:   seg_comm = 4'b1011;
            2'b11:   seg_comm = 4'b0111;
            default: seg_comm = 4'b1111;
        endcase
    end
endmodule

module digit_splitter (
    input  [15:0] sum,
    output [3:0] digit_1,
    output [3:0] digit_10,
    output [3:0] digit_100,
    output [3:0] digit_1000
);
    assign digit_1 = sum[15:8] % 10;
    assign digit_10 = sum[15:8] / 10 % 10;
    assign digit_100 = sum[7:0] / 10;
    assign digit_1000 = sum[7:0] / 10 % 10;

endmodule

module mux_4x1 (
    input  [3:0] sel,
    input  [3:0] digit_1,
    input  [3:0] digit_10,
    input  [3:0] digit_100,
    input  [3:0] digit_1000,
    output [3:0] bcd
);
    reg [3:0] r_bcd;
    assign bcd = r_bcd;
    always @(sel, digit_1, digit_10, digit_100, digit_1000) begin
        case (sel)
            4'b1110: r_bcd = digit_1;
            4'b1101: r_bcd = digit_10;
            4'b1011: r_bcd = digit_100;
            4'b0111: r_bcd = digit_1000;
            default: r_bcd = 4'bx;
        endcase
    end
endmodule

module fnd_controlloer (  //control anod segments
    input clk,
    input reset,
    input [15:0] count,
    output [7:0] seg_out,
    output [3:0] seg_comm
);
    wire [3:0] digit_1, digit_10, digit_100, digit_1000;
    wire [3:0] splited_bcd;
    wire [1:0] w_seg_sel;
    wire o_clk;

    clock_div u_clock_div (
        .clk  (clk),
        .reset(reset),
        .o_clk(o_clk)
    );

    counter_4 u0 (
        .clk  (o_clk),
        .reset(reset),
        .o_sel(w_seg_sel)
    );

    decoder_2x4 U_sellection (
        .seg_sel (w_seg_sel),
        .seg_comm(seg_comm)
    );

    digit_splitter U_splitter (
        .sum(count),
        .digit_1(digit_1),
        .digit_10(digit_10),
        .digit_100(digit_100),
        .digit_1000(digit_1000)
    );

    mux_4x1 U_Mux_4x1 (
        .sel(seg_comm),
        .digit_1(digit_1),
        .digit_10(digit_10),
        .digit_100(digit_100),
        .digit_1000(digit_1000),
        .bcd(splited_bcd)
    );

    bcdtoseg U_bcdToSeg (
        .bcd(splited_bcd),
        .seg_out(seg_out)
    );

endmodule

module bcdtoseg (
    input [3:0] bcd,
    output reg [7:0] seg_out
);
    always @(bcd) begin
        case (bcd)
            4'h0: seg_out = 8'hC0;
            4'h1: seg_out = 8'hF9;
            4'h2: seg_out = 8'hA4;
            4'h3: seg_out = 8'hB0;
            4'h4: seg_out = 8'h99;
            4'h5: seg_out = 8'h92;
            4'h6: seg_out = 8'h82;
            4'h7: seg_out = 8'hf8;
            4'h8: seg_out = 8'h80;
            4'h9: seg_out = 8'h90;
            4'hA: seg_out = 8'h88;
            4'hB: seg_out = 8'h83;
            4'hC: seg_out = 8'hC6;
            4'hD: seg_out = 8'hA1;
            4'hE: seg_out = 8'h86;
            4'hF: seg_out = 8'h8E;
            default: seg_out = 8'hff;
        endcase
    end
endmodule
