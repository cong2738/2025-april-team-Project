`timescale 1ns / 1ps

module GP_UART (  //GPIO
    // global signal
    input  logic        PCLK,
    input  logic        PRESET,
    // APB Interface Signals
    input  logic [ 3:0] PADDR,
    input  logic [31:0] PWDATA,
    input  logic        PWRITE,
    input  logic        PENABLE,
    input  logic        PSEL,
    output logic [31:0] PRDATA,
    output logic        PREADY,
    // inout signals
    input  logic        rx,
    output logic        tx
);
    logic [7:0] TXD;
    logic [7:0] RXD;
    logic tx_full, tx_empty;
    logic rx_full, rx_empty;
    logic uart_write;
    logic uart_read;
    logic [7:0] rx_data;
    logic [7:0] tx_data;

    APB_UARTIntf u_APB_UARTIntf (
        .PCLK      (PCLK),
        .PRESET    (PRESET),
        .PADDR     (PADDR),
        .PWDATA    (PWDATA),
        .PWRITE    (PWRITE),
        .PENABLE   (PENABLE),
        .PSEL      (PSEL),
        .PRDATA    (PRDATA),
        .PREADY    (PREADY),
        .tx_full   (tx_full),
        .tx_empty  (tx_empty),
        .rx_full   (rx_full),
        .rx_empty  (rx_empty),
        .uart_write(uart_write),
        .uart_read (uart_read),
        .TXD       (TXD),
        .RXD       (RXD)
    );

    uart u_uart (
        .clk            (PCLK),
        .rst            (PRESET),
        .tx_start_triger(~tx_empty),
        .tx_data        (tx_data),
        .rx             (rx),
        .tx             (tx),
        .tx_done        (tx_done),
        .tx_busy        (tx_busy),
        .rx_data        (rx_data),
        .rx_done        (rx_done),
        .rx_busy        (rx_busy)
    );

    fifo u_outputBuffer (
        .clk  (PCLK),
        .reset(PRESET),
        .wr_en(uart_write),
        .rd_en(tx_done),
        .wData(TXD),
        .rData(tx_data),
        .full (tx_full),
        .empty(tx_empty)
    );
    fifo u_inputBuffer (
        .clk  (PCLK),
        .reset(PRESET),
        .wr_en(rx_done),
        .rd_en(uart_read),
        .wData(rx_data),
        .rData(RXD),
        .full (rx_full),
        .empty(rx_empty)
    );

endmodule

module APB_UARTIntf (
    // global signal
    input  logic        PCLK,
    input  logic        PRESET,
    // APB Interface Signals
    input  logic [ 3:0] PADDR,
    input  logic [31:0] PWDATA,
    input  logic        PWRITE,
    input  logic        PENABLE,
    input  logic        PSEL,
    output logic [31:0] PRDATA,
    output logic        PREADY,
    // internal signals
    input  logic        tx_full,
    input  logic        tx_empty,
    input  logic        rx_full,
    input  logic        rx_empty,
    output logic        uart_write,
    output logic        uart_read,
    output logic [ 7:0] TXD,
    input  logic [ 7:0] RXD
);
    typedef enum logic [1:0] {
        STOP,
        ACCESS,
        READ,
        SEND
    } fifoIntf_state_e;

    fifoIntf_state_e state, next;
    logic wr_reg, wr_next;
    logic rd_reg, rd_next;
    logic [31:0] slv_reg0, slv_next0;
    logic [31:0] slv_reg1, slv_next1;

    assign uart_write = wr_reg;
    assign uart_read  = rd_reg;
    assign TXD        = slv_reg0[7:0];
    assign slv_reg1   = RXD;

    always_ff @(posedge PCLK, posedge PRESET) begin
        if (PRESET) begin
            state    <= STOP;
            rd_reg   <= 0;
            wr_reg   <= 0;
            slv_reg0 <= 0;
        end else begin
            state    <= next;
            wr_reg   <= wr_next;
            rd_reg   <= rd_next;
            slv_reg0 <= slv_next0;
        end
    end
    always_comb begin : next_logic
        next      = state;
        wr_next   = wr_reg;
        rd_next   = rd_reg;
        slv_next0 = slv_reg0;
        slv_next1 = slv_reg1;
        PREADY    = 0;
        case (state)
            STOP: begin
                wr_next = 0;
                rd_next = 0;
                if (PSEL && PENABLE) begin
                    next = ACCESS;
                end
            end
            ACCESS: begin
                if (PWRITE) begin
                    rd_next = 0;
                    case (PADDR[3:2])
                        2'd0: begin
                            wr_next = ~tx_full;
                            slv_next0 <= PWDATA[7:0];
                        end
                        default: ;
                    endcase
                end else begin
                    wr_next = 0;
                    PRDATA  = 32'dx;
                    case (PADDR[3:2])
                        2'd0: PRDATA <= slv_reg0;
                        2'd1: begin
                            rd_next = ~rx_empty;
                            PRDATA <= slv_reg1;
                        end
                    endcase
                end
                next = SEND;
            end
            SEND: begin
                PREADY = 1;
                wr_next = 0;
                rd_next = 0;
                next = STOP;
            end
        endcase
    end
endmodule
