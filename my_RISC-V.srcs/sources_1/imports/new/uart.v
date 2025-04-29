`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/03/26 21:51:20
// Design Name: 
// Module Name: uart
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/03/25 15:38:54
// Design Name: 
// Module Name: uart
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////



    module uart_clock (
    input reset,
    input clk,
    input finish_tick,
    input start_trigger,
    output tx,
    input [15:0] sensor_data,
    input rx
);


    wire [7:0] w_o_data;
    wire [7:0] w_o_data10;
    wire [7:0] w_o_data100;
    wire [7:0] w_o_data1000;
    wire [7:0] w_data, w_data2, w_data3;


    fifo utx2 (
        .clk(clk),
        .reset(reset),
        .wdata(w_data),
        .wr(w_tx_start),
        .rd(~tx_done & ~w_empty2),
        .rdata(w_data2),
        .empty(w_empty2),
        .full(w_full)
    );
    tick_9600hz utick9600hz2 (
        .clk  (clk),
        .reset(reset),
        .tick (w_tick)
    );
    uart_tx u_uart_tx2 (
        .clk(clk),
        .reset(reset),
        .tick(w_tick),
        .data_in(w_data3),
        .start_trigger(~w_empty2 & ~tx_done),
        .o_tx(tx),
        .tx_done(tx_done)
    );

    clock_tx_control uclock_Tx (
        .o_data(w_o_data),
        .o_data10(w_o_data10),
        .o_data100(w_o_data100),
        .o_data1000(w_o_data1000),
        .clk(clk),
        .reset(reset),
        .tx_start(w_tx_start),
        .finish_tick(finish_tick),
        .start_trigger(start_trigger),
        .data(w_data),
        .w_empty2(w_empty2)
    );
    data_save d_save2 (
        .clk(clk),
        .reset(reset),
        .rd(~tx_done & ~w_empty2),
        .data_in(w_data2),
        .data_out(w_data3)
    );
    bit_asci u_bit (
        .data(sensor_data),
        .o_data(w_o_data),
        .o_data10(w_o_data10),
        .o_data100(w_o_data100),
        .o_data1000(w_o_data1000)
    );



endmodule



module transasci (
    input [7:0] rx_data,
    input clk,
    input rx_done,
    input reset,
    output btn
);

    reg btn_reg, btn_next;
    assign btn = btn_reg;


    always @(posedge clk, posedge reset) begin
        if (reset) begin
            btn_reg <= 0;
        end else begin
            btn_reg <= btn_next;
        end
    end
    always @(*) begin
        btn_next = 1'b0;

        if (rx_done == 1) begin
            case (rx_data)
                "m": btn_next = 1'b1;
            endcase
        end
    end





endmodule







module clock_tx_control (
    input [7:0] o_data,
    input [7:0] o_data10,
    input [7:0] o_data100,
    input [7:0] o_data1000,
    input finish_tick,
    input start_trigger,
    input w_empty2,
    input clk,
    input reset,
    output tx_start,
    output [7:0] data
);
    parameter
    IDLE   = 5'b00000,
    DATA   = 5'b00001,
    DATA2  = 5'b00010,
    DATA3  = 5'b00011,
    DATA4  = 5'b00100,
    DATA5  = 5'b00101,
    DATA6  = 5'b00110,
    DATA7  = 5'b00111,
    DATA8  = 5'b01000,
    DATA9  = 5'b01001,
    DATA10 = 5'b01010,
    DATA11 = 5'b01011,
    DATA12 = 5'b01100,
    DATA13 = 5'b01101,
    DATA14 = 5'b01110,
    DATA15 = 5'b01111,
    DATA16 = 5'b10000,
    DATA17 = 5'b10001,
    DATA18 = 5'b10010,
    DATA19 = 5'b10011,
    DATA20 = 5'b10100,
    DATA21 = 5'b10101,
    DATA22 = 5'b10110,
    DATA23 = 5'b10111,
    DATA24 = 5'b11000,
    DATA25 = 5'b11001,
    SPACE  = 5'b11010,
    WAIT   = 5'b11011;
    reg start, start_next;
    reg [3:0] data_count, data_count_next;
    reg [3:0] state, next;
    reg [7:0] data_reg, data_next;
    assign tx_start = start;
    assign data = data_reg;
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            state <= 0;
            start <= 0;
            data_reg <= 0;
            data_count <= 0;
        end else begin
            start <= start_next;
            state <= next;
            data_count <= data_count_next;
            data_reg <= data_next;
        end
    end
    always @(*) begin
        start_next = 0;
        next = state;
        data_next = data_reg;
        data_count_next = data_count;
        case (state)
            IDLE:
            if (finish_tick == 1) begin
                next = DATA;
            end
            DATA: begin
                start_next = 1;
                data_next = "t";
                next = DATA2;
            end
            DATA2: begin
                start_next = 1;
                data_next = "e";
                next = DATA3;
            end
            DATA3: begin
                start_next = 1;
                data_next = "m";
                next = DATA4;
            end
            DATA4: begin
                start_next = 1;
                data_next = "p";
                next = DATA5;
            end
            DATA5: begin
                start_next = 1;
                data_next = ":";
                next = DATA6;
            end
            DATA6: begin
                start_next = 1;
                data_next = o_data1000;
                next = DATA7;
            end
            DATA7: begin
                start_next = 1;
                data_next = o_data100;
                next = DATA8;
            end
            DATA8: begin
                start_next = 1;
                data_next = "h";
                next = DATA9;
            end
            DATA9: begin
                start_next = 1;
                data_next = "u";
                next = DATA10;
            end
            DATA10: begin
                start_next = 1;
                data_next = "m";
                next = DATA11;
            end
             DATA11: begin
                start_next = 1;
                data_next = ":";
                next = DATA12;
            end
            DATA12: begin
                start_next = 1;
                data_next = o_data10;
                next = DATA13;
            end
            DATA13: begin
                start_next = 1;
                data_next = o_data;
                next = SPACE;
            end
            SPACE: begin
                start_next = 1;
                data_next = "\n";
                next = WAIT;
            end

            WAIT: begin
                if (start_trigger == 1) begin
                    next = IDLE;
                end
            end

        endcase
    end


endmodule

module bit_asci (
    input [15:0] data,
    output reg [7:0] o_data,
    o_data10,
    o_data100,
    o_data1000
);
    reg [7:0] data0, data10, data100, data1000;
    always @(*) begin
        data0 = data % 10;
        data10 = data / 10 % 10;
        data100 = data / 100 % 10;
        data1000 = data / 1000 % 10;
        case (data0)
            0: o_data = "0";
            1: o_data = "1";
            2: o_data = "2";
            3: o_data = "3";
            4: o_data = "4";
            5: o_data = "5";
            6: o_data = "6";
            7: o_data = "7";
            8: o_data = "8";
            9: o_data = "9";

            default: o_data = "0";
        endcase
        case (data10)
            0: o_data10 = "0";
            1: o_data10 = "1";
            2: o_data10 = "2";
            3: o_data10 = "3";
            4: o_data10 = "4";
            5: o_data10 = "5";
            6: o_data10 = "6";
            7: o_data10 = "7";
            8: o_data10 = "8";
            9: o_data10 = "9";
            default: o_data10 = "0";
        endcase
        case (data100)
            0: o_data100 = "0";
            1: o_data100 = "1";
            2: o_data100 = "2";
            3: o_data100 = "3";
            4: o_data100 = "4";
            5: o_data100 = "5";
            6: o_data100 = "6";
            7: o_data100 = "7";
            8: o_data100 = "8";
            9: o_data100 = "9";
            default: o_data100 = "0";
        endcase
        case (data1000)
            0: o_data1000 = "0";
            1: o_data1000 = "1";
            2: o_data1000 = "2";
            3: o_data1000 = "3";
            4: o_data1000 = "4";
            5: o_data1000 = "5";
            6: o_data1000 = "6";
            7: o_data1000 = "7";
            8: o_data1000 = "8";
            9: o_data1000 = "9";
            default: o_data1000 = "0";
        endcase
    end



endmodule


module tick_9600hz (
    input  clk,
    input  reset,
    output tick
);

    parameter BAUD_RATE = 9600;
    localparam BAUD_COUNT = (100_000_000 / BAUD_RATE) / 16;
    reg [$clog2(BAUD_COUNT)-1:0] count_reg, count_next;

    reg tick_reg, tick_next;
    assign tick = tick_reg;

    always @(posedge clk, posedge reset) begin
        if (reset == 1) begin
            count_reg <= 0;
            tick_reg  <= 0;
        end else begin
            count_reg <= count_next;
            tick_reg  <= tick_next;
        end
    end


    always @(*) begin
        count_next = count_reg;
        tick_next  = tick_reg;
        if (count_reg == BAUD_COUNT - 1) begin
            count_next = 0;
            tick_next  = 1'b1;
        end else begin
            count_next = count_reg + 1;
            tick_next  = 1'b0;
        end
    end

endmodule





module fifo (
    input clk,
    input reset,
    // write
    input [7:0] wdata,
    input wr,
    // read
    input rd,
    output [7:0] rdata,
    output empty,
    output full
);

    wire [3:0] w_waddr, w_raddr;


    register_file uregister (
        .clk(clk),
        .waddr(w_waddr),
        .wdata(wdata),
        .raddr(w_raddr),
        .wr({~full & wr}),
        .rdata(rdata)
    );


    fifo_cu ufifo_cu (
        .clk(clk),
        .reset(reset),
        .wr(wr),
        .rd(rd),
        .waddr(w_waddr),
        .raddr(w_raddr),
        .full(full),
        .empty(empty)
    );

endmodule


module register_file (
    input clk,
    input [3:0] waddr,
    input [7:0] wdata,
    input [3:0] raddr,
    input wr,
    output [7:0] rdata
);

    reg [7:0] ram[0:2**4-1];

    assign rdata = ram[raddr];  // 0 0 일떄 우선순위?

    always @(posedge clk) begin
        if (wr) begin
            ram[waddr] = wdata;
        end
    end

endmodule


module fifo_cu (
    input clk,
    input reset,
    input wr,
    input rd,
    output [3:0] waddr,
    output [3:0] raddr,
    output full,
    output empty
);

    reg full_reg, full_next, empty_reg, empty_next;
    reg [3:0] w_ptr, w_ptr_next, r_ptr, r_ptr_next;
    assign empty = empty_reg;
    assign full  = full_reg;
    assign waddr = w_ptr;
    assign raddr = r_ptr;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
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


module data_save (
    input clk,
    input reset,
    input rd,
    input [7:0] data_in,
    output [7:0] data_out
);
    reg [7:0] data_reg, data_next;
    assign data_out = data_reg;
    always @(posedge clk) begin
        if (reset) begin
            data_reg <= 0;
        end else begin
            data_reg <= data_next;
        end
    end
    always @(*) begin
        data_next = data_reg;
        if (rd) begin
            data_next = data_in;
        end


    end

endmodule


module uart_tx (
    input clk,
    input reset,
    input tick,
    input [7:0] data_in,
    input start_trigger,
    output o_tx,
    output tx_done
);
    parameter R_IDLE = 4'h0, START = 4'h1, DATA_STATE = 4'h2, STOP = 4'h3;

    reg [3:0] data_count, data_count_next;
    reg [3:0] state, next;
    reg [3:0] tick_count, tick_count_next;
    reg [7:0] temp_data_reg, temp_data_next;

    reg tx, tx_next;
    reg r_tx_done, r_tx_done_next;
    assign tx_done = r_tx_done;
    assign o_tx = tx;
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            state <= 0;
            tx <= 1;
            r_tx_done <= 0;
            data_count <= 0;
            tick_count <= 0;
        end else begin
            state <= next;
            tx <= tx_next;
            r_tx_done <= r_tx_done_next;
            data_count <= data_count_next;
            tick_count <= tick_count_next;
        end
    end


    always @(*) begin
        next = state;
        tx_next = tx;
        r_tx_done_next = r_tx_done;
        data_count_next = data_count;
        tick_count_next = tick_count;
        case (state)
            R_IDLE: begin
                tx_next = 1'b1;
                r_tx_done_next = 0;
                tick_count_next = 0;
                if (start_trigger == 1) begin
                    next = START;
                    r_tx_done_next = 1;
                end
            end
            START: begin
                if (tick == 1) begin
                    if (tick_count == 15) begin
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
                            tx_next = data_in[data_count];
                            data_count_next = data_count + 1;
                            tick_count_next = 0;
                            if (data_count_next == 8) begin
                                next = STOP;
                            end
                        end
                    end else begin
                        tick_count_next = tick_count + 1;
                    end
                end
            end
            STOP: begin
                if (tick == 1) begin
                    if (tick_count == 15) begin
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


// module uart_fsm (
//     input reset,
//     input clk,
//     output tx,
//     inout w_empty,
//     output [7:0] w_o_data2,
//     input rx
// );
//     wire w_tick, w_btn_start;
//     wire w_tx_done, w_rx_done;
//     wire [7:0] w_o_data, w_o_data3, w_o_data4;


//     uart_tx u_uart_tx (
//         .clk(clk),
//         .reset(reset),
//         .tick(w_tick),
//         .data_in(w_o_data4),
//         .start_trigger(~w_empty2 & ~tx_done),
//         .o_tx(tx),
//         .tx_done(tx_done)
//     );

//     uart_rx urx (
//         .clk(clk),
//         .reset(reset),
//         .tick(w_tick),
//         .rx(rx),
//         .rx_done(w_rx_done),
//         .o_data(w_o_data)
//     );

//     tick_9600hz utick9600hz (
//         .clk  (clk),
//         .reset(reset),
//         .tick (w_tick)
//     );

//     fifo urxa (
//         .clk(clk),
//         .reset(reset),
//         .wdata(w_o_data),
//         .wr(w_rx_done),
//         .rd(~w_full),
//         .rdata(w_o_data2),
//         .empty(w_empty),
//         .full()
//     );
//     fifo utx (
//         .clk(clk),
//         .reset(reset),
//         .wdata(w_o_data2),
//         .wr(~w_empty),
//         .rd(~w_empty2 & ~tx_done),
//         .rdata(w_o_data3),
//         .empty(w_empty2),
//         .full(w_full)
//     );
//     data_save d_save (
//         .clk(clk),
//         .reset(reset),
//         .rd(~w_empty2),
//         .data_in(w_o_data3),
//         .data_out(w_o_data4)
//     );


// endmodule





module uart_rx (
    input clk,
    input reset,
    input tick,
    input rx,
    output rx_done,
    output [7:0] o_data
);


    reg [7:0] data, data_next;
    reg [4:0] tick_count, tick_count_next;
    reg [1:0] state, next;
    reg r_rx_done, r_rx_done_next;
    reg [3:0] data_count, data_count_next;
    parameter R_IDLE = 4'h0, START = 4'h1, DATA_STATE = 4'h2, STOP = 4'h3;
    assign o_data  = data;
    assign rx_done = r_rx_done;
    assign o_data  = data;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
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
                    tick_count_next = tick_count + 1;
                    if (tick_count_next == 8) begin
                        next = DATA_STATE;
                        tick_count_next = 0;
                    end
                end
            end
            DATA_STATE: begin
                if (tick == 1) begin
                    tick_count_next = tick_count + 1;
                    if (tick_count_next == 16) begin
                        data_next[data_count] = rx;
                        tick_count_next = 0;
                        data_count_next = data_count + 1;
                        if (data_count_next == 8) begin
                            data_count_next = 0;
                            tick_count_next = 0;
                            next = STOP;
                        end
                    end
                end
            end

            STOP: begin
                if (tick == 1) begin
                    tick_count_next = tick_count + 1;
                    if (tick_count_next == 24) begin
                        next = R_IDLE;
                        tick_count_next = 0;
                        r_rx_done_next = 1;
                    end
                end
            end


        endcase

    end
endmodule
