`timescale 1ns / 1ps
/*
    2025.03.18
*/
module uart #(
    BAUD_RATE = 9600
) (
    input clk,
    input rst,
    input tx_start_triger,
    input [7:0] tx_data,
    input rx,
    output tx,
    output tx_busy,
    output [7:0] rx_data,
    output rx_done
);

    wire tick;
    // rx에쓰려고 16배속 했지만 클럭 동기화 이슈때문에 TX에도 같은곳의 클럭을 써야한다.
    boud_tick_gen #(
        .BAUD_RATE(BAUD_RATE)
    ) U_btn_Debounce (
        .clk(clk),
        .rst(rst),
        .baud_tick(tick)
    );

    uart_rx U_Rx (
        .clk(clk),
        .rst(rst),
        .tick(tick),
        .rx(rx),
        .rx_data(rx_data),
        .rx_done(rx_done)
    );

    uart_tx U_Tx (
        .clk(clk),
        .rst(rst),
        .tick(tick),
        .start_trigger(tx_start_triger),
        .i_data(tx_data),
        .o_tx(tx),
        .tx_busy(tx_busy)
    );

endmodule

module uart_rx (
    input clk,
    input rst,
    input tick,
    input rx,
    output rx_done,
    output [7:0] rx_data
);

    reg [7:0] data, data_next;
    reg [4:0] tick_count, tick_count_next;
    reg [1:0] state, next;
    reg r_rx_done, r_rx_done_next;
    reg [3:0] data_count, data_count_next;
    parameter R_IDLE = 4'h0, START = 4'h1, DATA_STATE = 4'h2, STOP = 4'h3;
    assign rx_data = data;
    assign rx_done = r_rx_done;
    assign rx_data = data;


    always @(posedge clk, posedge rst) begin
        if (rst) begin
            state <= 0;
            data <= 0;
            data_count <= 0;
            tick_count <= 0;
            r_rx_done <= 0;
        end else begin
            state <= next;
            r_rx_done <= r_rx_done_next;
            data_count <= data_count_next;
            tick_count <= tick_count_next;
            data <= data_next;

        end
    end


    always @(*) begin
        next = state;
        r_rx_done_next = 0;
        data_count_next = data_count;
        tick_count_next = tick_count;
        data_next = data;
        case (state)
            R_IDLE: begin
                if (rx == 0) begin
                    next = START;
                end
            end
            START: begin
                if (tick == 1) begin
                    if (tick_count_next == 7) begin
                        next = DATA_STATE;
                        tick_count_next = 0;
                    end else begin
                        tick_count_next = tick_count + 1;
                    end
                end
            end
            DATA_STATE: begin
                if (tick == 1) begin
                    if (tick_count_next == 15) begin
                        data_next[data_count] = rx;
                        tick_count_next = 0;
                        if (data_count_next == 7) begin
                            data_count_next = 0;
                            tick_count_next = 0;
                            next = STOP;
                        end else begin
                            data_count_next = data_count + 1;
                        end
                    end else begin
                        tick_count_next = tick_count + 1;
                    end
                end
            end
            STOP: begin
                if (tick == 1) begin
                    if (tick_count_next == 24) begin
                        next = R_IDLE;
                        tick_count_next = 0;
                        r_rx_done_next = 1;
                    end else begin
                        tick_count_next = tick_count + 1;
                    end
                end
            end

            default: next = R_IDLE;
        endcase

    end
endmodule


module uart_tx (
    input clk,
    input rst,
    input tick,
    input [7:0] i_data,
    input start_trigger,
    output o_tx,
    output tx_busy
);
    parameter R_IDLE = 4'h0, START = 4'h1, DATA_STATE = 4'h2, STOP = 4'h3;

    reg [3:0] data_count, data_count_next;
    reg [3:0] state, next;
    reg [4:0] tick_count, tick_count_next;
    reg [7:0] temp_data_reg, temp_data_next;  // ts data buffer 25-03-21

    reg tx, tx_next;
    reg r_tx_busy, r_tx_busy_next;
    assign tx_busy = r_tx_busy;
    assign o_tx = tx;
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            state <= 0;
            tx <= 1;
            r_tx_busy <= 0;
            data_count <= 0;
            tick_count <= 0;
            temp_data_reg <= 0;
        end else begin
            state <= next;
            tx <= tx_next;
            r_tx_busy <= r_tx_busy_next;
            data_count <= data_count_next;
            tick_count <= tick_count_next;
            temp_data_reg <= temp_data_next;
        end
    end


    always @(*) begin
        next = state;
        tx_next = tx;
        r_tx_busy_next = r_tx_busy;
        data_count_next = data_count;
        tick_count_next = tick_count;
        case (state)
            R_IDLE: begin
                tx_next = 1'b1;
                r_tx_busy_next = 0;
                tick_count_next = 0;
                if (start_trigger == 1) begin
                    next = START;
                    // at start trigger, data buffering
                    temp_data_next = i_data;
                end
            end
            START: begin
                r_tx_busy_next = 1;
                if (tick == 1) begin
                    if (tick_count == 7) begin
                        tx_next = 1'b0;
                        data_count_next = 0;
                        tick_count_next = 0;
                        next = DATA_STATE;
                    end else begin
                        tick_count_next = tick_count + 1;
                    end
                end
            end

            DATA_STATE: begin
                if (tick == 1) begin
                    if (tick_count == 15) begin
                        begin
                            tx_next = temp_data_reg[data_count];
                            // tx_next = i_data[data_count];
                            tick_count_next = 0;
                            if (data_count_next == 7) begin
                                next = STOP;
                            end else begin
                                data_count_next = data_count + 1;
                            end
                        end
                    end else begin
                        tick_count_next = tick_count + 1;
                    end
                end
            end
            STOP: begin
                if (tick == 1) begin
                    if (tick_count == 23) begin
                        data_count_next = 0;
                        tx_next = 1'b1;
                        tick_count_next = 0;
                        next = R_IDLE;
                    end else begin
                        tick_count_next = tick_count + 1;
                    end
                end
            end
        endcase
    end
endmodule

module boud_tick_gen #(
    parameter BAUD_RATE = 9600
) (
    input  clk,
    input  rst,
    output baud_tick
);
    localparam BUAD_COUNT = (100_000_000 / BAUD_RATE) / 16;
    reg [$clog2(BUAD_COUNT)-1:0] count_reg, count_next;
    reg tick_reg, tick_next;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            count_reg <= 0;
            tick_reg  <= 0;
        end else begin
            count_reg <= count_next;
            tick_reg  <= tick_next;
        end
    end

    //next
    always @(*) begin
        count_next = count_reg;
        tick_next  = tick_reg;
        if (count_reg == BUAD_COUNT - 1) begin
            count_next = 0;
            tick_next  = 1;
        end else begin
            count_next = count_reg + 1;
            tick_next  = 0;
        end
    end

    //output
    assign baud_tick = tick_reg;

endmodule


