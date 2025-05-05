`timescale 1ns / 1ps

module GP_Watch (
    // global signal
    input  logic        PCLK,
    input  logic        PRESET,
    // APB Interface Signals
    input  logic [ 4:0] PADDR,
    input  logic [31:0] PWDATA,
    input  logic        PWRITE,
    input  logic        PENABLE,
    input  logic        PSEL,
    output logic [31:0] PRDATA,
    output logic        PREADY
);
    // inport signals
    logic [31:0] msec;
    logic [31:0] sec;
    logic [31:0] min;
    logic [31:0] hour;
    logic [31:0] set_msec;
    logic [31:0] set_sec;
    logic [31:0] set_min;
    logic [31:0] set_hour;
    logic        setSig;

    APB_watchIntf U_APB_Intf (.*);
    watch_dp u_watch_dp (
        .clk     (PCLK),
        .reset   (PRESET),
        .hms     (hms),
        .msec    (msec),
        .sec     (sec),
        .min     (min),
        .hour    (hour),
        .set_msec(set_msec),
        .set_sec (set_sec),
        .set_min (set_min),
        .set_hour(set_hour),
        .setSig  (setSig)
    );


endmodule

module APB_watchIntf (
    // global signal
    input  logic        PCLK,
    input  logic        PRESET,
    // APB Interface Signals
    input  logic [ 4:0] PADDR,
    input  logic [31:0] PWDATA,
    input  logic        PWRITE,
    input  logic        PENABLE,
    input  logic        PSEL,
    output logic [31:0] PRDATA,
    output logic        PREADY,
    // internal signals
    input  logic [31:0] msec,
    input  logic [31:0] sec,
    input  logic [31:0] min,
    input  logic [31:0] hour,
    output logic [31:0] set_msec,
    output logic [31:0] set_sec,
    output logic [31:0] set_min,
    output logic [31:0] set_hour,
    output logic        setSig
);
    logic [31:0] slv_reg0, slv_reg1, slv_reg2, slv_reg3;  // ,slv_reg3;
    logic [31:0] slv_reg4, slv_reg5, slv_reg6, slv_reg7;  // ,slv_reg3;

    assign slv_reg0[31:0] = msec;
    assign slv_reg1[31:0] = sec;
    assign slv_reg2[31:0] = min;
    assign slv_reg3[31:0] = hour;
    assign set_msec       = slv_reg4[31:0];
    assign set_sec        = slv_reg5[31:0];
    assign set_min        = slv_reg6[31:0];
    assign set_hour       = slv_reg7[31:0];

    always_ff @(posedge PCLK, posedge PRESET) begin
        if (PRESET) begin
            slv_reg4 <= 0;
            slv_reg5 <= 0;
            slv_reg6 <= 0;
            slv_reg7 <= 0;
        end else begin
            if (PSEL && PENABLE) begin
                PREADY <= 1'b1;
                if (PWRITE) begin
                    setSig <= 1;
                    case (PADDR[4:2])
                        2'd4: slv_reg4 <= PWDATA;
                        2'd5: slv_reg5 <= PWDATA;
                        2'd6: slv_reg6 <= PWDATA;
                        2'd7: slv_reg7 <= PWDATA;
                    endcase
                end else begin
                    PRDATA <= 32'bx;
                    case (PADDR[4:2])
                        2'd0: PRDATA <= slv_reg0;
                        2'd1: PRDATA <= slv_reg1;
                        2'd2: PRDATA <= slv_reg2;
                        2'd3: PRDATA <= slv_reg3;
                    endcase
                end
            end else begin
                PREADY <= 1'b0;
                setSig <= 0;
            end
        end
    end

endmodule
