`timescale 1ns / 1ps

module GP_UART #(parameter BAUD_RATE = 9600) (  //GPIO
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
    output logic        tx,
    output logic tx_full, tx_empty,
    output logic rx_full, rx_empty
);
    logic [7:0] TXD;
    logic [7:0] RXD;
    
    logic uart_write;
    logic uart_read;
    logic [7:0] rx_data;
    logic [7:0] tx_data;

    APB_UARTIntf u_APB_UARTIntf(.*);

    uart #(.BAUD_RATE(BAUD_RATE)) u_uart (
        .clk            (PCLK),
        .rst            (PRESET),
        .tx_start_triger(~tx_empty & ~tx_busy),
        .tx_data        (tx_data),
        .rx             (rx),
        .tx             (tx),
        .tx_done        (tx_done),
        .tx_busy        (tx_busy),
        .rx_data        (rx_data),
        .rx_done        (rx_done),
        .rx_busy        (rx_busy)
    );

    fifo #(
        .FIFO_UNIT(8),
        .FIFO_CAP(2**8)
    ) u_outputBuffer (
        .clk  (PCLK),
        .reset(PRESET),
        .wr_en(uart_write),
        .rd_en(tx_done),
        .wData(TXD),
        .rData(tx_data),
        .full (tx_full),
        .empty(tx_empty)
    );
    fifo #(
        .FIFO_UNIT(8),
        .FIFO_CAP(2**8)
    ) u_inputBuffer (
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
    input  logic        tx_busy,
    input  logic        tx_done,
    input  logic        tx_full,
    input  logic        tx_empty,
    input  logic        rx_busy,
    input  logic        rx_done,
    input  logic        rx_full,
    input  logic        rx_empty,
    output logic        uart_write,
    output logic        uart_read,
    output logic [ 7:0] TXD,
    input  logic [ 7:0] RXD
);
    typedef enum logic [1:0] {
        STOP,
        READ,
        SEND
    } fifoIntf_state_e;

    fifoIntf_state_e state, next;
    logic wr_reg, wr_next;
    logic rd_reg, rd_next;
    logic [31:0] slv_reg0, slv_next0;
    logic [31:0] slv_reg1;
    logic [31:0] slv_reg2;
    logic [31:0] slv_reg3;
    logic [31:0] PRDATA_next;

    assign uart_write = wr_reg;
    assign uart_read  = rd_reg;
    assign TXD        = slv_reg0[7:0];
    assign slv_reg1   = RXD;
    assign slv_reg2   = tx_full;
    assign slv_reg3   = rx_empty;

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
            PRDATA <= PRDATA_next;
        end
    end
    always_comb begin : next_logic
        next      = state;
        wr_next   = wr_reg;
        rd_next   = rd_reg;
        slv_next0 = slv_reg0;
        PREADY    = 0;
        PRDATA_next = PRDATA;
        case (state)
            STOP: begin
                wr_next = 0;
                rd_next = 0;
                if (PSEL && PENABLE) begin
                    next = READ;
                end
            end
            READ: begin
                if (PWRITE) begin
                    rd_next = 0;
                    wr_next = 0;
                    case (PADDR[3:2])
                        2'd0: begin
                            if(~tx_full) begin
                                wr_next = 1;
                                slv_next0 <= PWDATA[7:0];
                            end
                        end
                        default: ;
                    endcase
                end else begin
                    rd_next = 0;
                    wr_next = 0;
                    PRDATA_next  = 32'dx;
                    case (PADDR[3:2])
                        2'd0: PRDATA_next <= slv_reg0;
                        2'd1: begin
                            if(~rx_empty) begin
                                rd_next = 1;
                                PRDATA_next <= slv_reg1;
                            end
                        end
                        2'd2: PRDATA_next <= slv_reg2;
                        2'd3: PRDATA_next <= slv_reg3;
                    endcase
                end
                next = SEND;
            end
            SEND: begin
                wr_next = 0;
                rd_next = 0;
                PREADY = 1;
                next = STOP;
            end
        endcase
    end
endmodule
