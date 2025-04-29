`timescale 1ns / 1ps

module send_tx_btn #(
    parameter BAUD_RATE = 9600
) (
    input  clk,
    input  rst,
    input  btn_start,
    output tx
);
    wire d_start;
    btn_debounce U_btn_Debounce (
        .clk  (clk),
        .reset(rst),
        .i_btn(btn_start),
        .o_btn(d_start)
    );

    // wire w_tx_busy;
    // shot_15tic U_Shot (
    //     .start_shot(d_start),
    //     .tx_busy(w_tx_busy),
    //     .clk(clk),
    //     .rst(rst),
    //     .tx_tirgger(uart_start)
    // );

    wire uart_start;
    wire [7:0] i_uart_data;
    shot_15tic U_CU (
        .clk(clk),
        .rst(rst),
        .d_start(d_start),
        .tx_busy(w_tx_busy),
        .uart_start(uart_start),
        .data(i_uart_data)
    );

    // uart #(
    //     .BAUD_RATE(BAUD_RATE)
    // ) U_Uart (
    //     .clk(clk),
    //     .rst(rst),
    //     .start_triger(uart_start),
    //     .i_data(i_uart_data),
    //     .tx(tx),
    //     .tx_busy(w_tx_busy)
    // );

endmodule

module shot_15tic (
    input clk,
    input rst,
    input d_start,
    input tx_busy,
    output uart_start,
    output [7:0] data
);
    //send tx ascii to PC
    reg [7:0] data_curr, data_next;
    reg [1:0] state, next;  //send char fsm state
    reg send_reg, send_next;  //start trigger state
    reg [3:0] send_count_reg, send_count_next;

    assign data = data_curr;
    assign uart_start = send_reg;

    localparam IDLE = 0, START = 1, SEND = 2;
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            data_curr <= "0";
            state = IDLE;
            send_reg = 0;
            send_count_reg = 0;
        end else begin
            data_curr <= data_next;
            state = next;
            send_reg = send_next;
            send_count_reg = send_count_next;
        end
    end

    always @(*) begin
        data_next = data_curr;
        next = state;
        send_next = 0;
        send_count_next = send_count_reg;
        case (state)
            IDLE: begin
                send_next = 0;
                send_count_next = 0;
                if (d_start) begin
                    next = START;
                    send_next = 1;
                end
            end
            START: begin
                send_next = 0;
                if (tx_busy) begin
                    next = SEND;
                end
            end
            SEND: begin
                if (!tx_busy) begin
                    send_next = 1;
                    send_count_next = send_count_reg + 1;
                    if (send_count_reg == 15) begin
                        next = IDLE;
                        send_count_next = 0;
                    end else begin
                        if (data_next == "z") begin
                            data_next = "0";
                        end else begin
                            data_next = data_curr + 1;  // increase 1 for ASCII
                        end
                        next = START;
                    end
                end
            end
            default: next = IDLE;
        endcase
    end
endmodule
