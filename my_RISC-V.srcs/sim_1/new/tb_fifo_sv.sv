`timescale 1ns / 1ps

interface fifo_intf (
    input bit clk,
    input bit reset
);
    logic wr_en;
    logic rd_en;
    logic [7:0] wData;
    logic [7:0] rData;
    logic full;
    logic empty;


    //클래스 입출력 타이밍을 미뤄주기 위한 기능
    clocking drv_cb @(posedge clk);
        default input #1 output #1; // 인풋은 1단위시간, 아웃풋은 1단위시간 뒤에 캡쳐한다.
        output wr_en, rd_en, wData;
        input rData, full, empty;
    endclocking

    clocking mon_cb @(posedge clk);
        default input #1 output #1;
        input wr_en, rd_en, wData;
        output rData, full, empty;
    endclocking

    //포트의 방향성을  기능.
    modport drv_mport(clocking drv_cb, input reset);
    modport mon_mport(clocking mon_cb, input reset);

endinterface  //fifo_intf

class transaction;
    rand logic       oper;  // read/write flag operator
    rand logic       wr_en;
    rand logic       rd_en;
    rand logic [7:0] wData;
    logic      [7:0] rData;
    logic            full;
    logic            empty;

    constraint c_wren {wr_en inside {1'b0, 1'b1};}
    constraint c_rden {rd_en inside {1'b0, 1'b1};}
    constraint c_wdata {wData < 10;}

    task display(string name);
        $display(
            "[%S](oper= %h): wr_en = %h, rd_en = %h, wData = %h, rData = %h,full = %h, empty = %h,",
            name, oper, wr_en, rd_en, wData, rData, full, empty);
    endtask  //
endclass  //transaction

class generator;
    mailbox #(transaction) GenToDrv_mbox;
    event next_gen_event;

    transaction fifo_tr;

    function new(mailbox#(transaction) GenToDrv_mbox, event next_gen_event);
        this.GenToDrv_mbox  = GenToDrv_mbox;
        this.next_gen_event = next_gen_event;
    endfunction  //new()

    task run(int repeat_counter);
        repeat (repeat_counter) begin
            fifo_tr = new();
            if (!fifo_tr.randomize()) $error("Randomization failed!!!");
            fifo_tr.display("GEN");
            GenToDrv_mbox.put(fifo_tr);
            @(next_gen_event);
        end
    endtask  //
endclass  //generator

class driver;
    mailbox #(transaction) GenToDrv_mbox;
    virtual fifo_intf.drv_mport fifo_if;

    transaction fifo_tr;

    function new(mailbox#(transaction) GenToDrv_mbox,
                 virtual fifo_intf.drv_mport fifo_if);
        this.GenToDrv_mbox = GenToDrv_mbox;
        this.fifo_if = fifo_if;
    endfunction  //new()

    task write();
        @(fifo_if.drv_cb);
        fifo_if.wr_en <= 1'b1;
        fifo_if.rd_en <= 1'b0;
        fifo_if.wData <= fifo_tr.wData;
        @(fifo_if.drv_cb);
        fifo_if.wr_en <= 1'b0;
    endtask  //

    task read();
        @(fifo_if.drv_cb);
        fifo_if.wr_en <= 1'b0;
        fifo_if.rd_en <= 1'b1;
        @(fifo_if.drv_cb);
        fifo_if.rd_en <= 1'b0;
    endtask  //

    task run();
        forever begin
            GenToDrv_mbox.get(fifo_tr);
            if (fifo_tr.oper) write();
            else read();
            fifo_tr.display("DRV");
        end
    endtask  //

endclass  //driver

class monitor;
    mailbox #(transaction) MonToSCB_mbox;
    virtual fifo_intf.mon_cb fifo_if;

    transaction fifo_tr;

    function new(mailbox#(transaction) MonToSCB_mbox,
                 virtual fifo_intf.mon_cb fifo_if);
        this.MonToSCB_mbox = MonToSCB_mbox;
        this.fifo_if = fifo_if;
    endfunction  //new()

    task mon_sinc_to_drv();
        // drv가 총 클락 두번 걸리기에 모니터에서는 클락 두번뒤 캡쳐한다
        @(fifo_if.mon_cb);
        @(fifo_if.mon_cb);
    endtask  //

    task run();
        forever begin
            mon_sinc_to_drv();

            fifo_tr       = new();
            fifo_tr.wr_en = fifo_if.wr_en;
            fifo_tr.rd_en = fifo_if.rd_en;
            fifo_tr.wData = fifo_if.wData;
            fifo_tr.rData = fifo_if.rData;
            fifo_tr.empty = fifo_if.empty;
            fifo_tr.full  = fifo_if.full;
            fifo_tr.display("MON");
            MonToSCB_mbox.put(fifo_tr);
        end
    endtask  //

endclass  //monitor

class scoreboard;
    mailbox #(transaction) MonToSCB_mbox;
    event next_gen_event;

    transaction fifo_tr;
    logic [7:0] ref_model[0:2**5-1];
    logic [7:0] scb_fifo[$:3];  // queue
    auto pop_data;

    function new(mailbox#(transaction) MonToSCB_mbox, event next_gen_event);
        this.MonToSCB_mbox = MonToSCB_mbox;
        foreach (ref_model[i]) ref_model[i] = 0;
        this.next_gen_event = next_gen_event;
    endfunction  //new()


    task run();
        forever begin
            MonToSCB_mbox.get(fifo_tr);
            fifo_tr.display("SCB");
            if (fifo_tr.wr_en) begin
                if (!fifo_tr.full) begin
                    scb_fifo.push_back(fifo_tr.wData);
                    // 시스템베릴로그 시뮬레이션에서 queue 출력에는 %p가 사용된다
                    $display("[SCB] : Data Stored in Queue - %h, %p",
                             fifo_tr.wData, scb_fifo);
                end else begin
                    $display("[SCB] : FIFO is Full!!! - %p", scb_fifo);
                end
            end
            if (fifo_tr.rd_en) begin
                if (!fifo_tr.empty) begin
                    pop_data = scb_fifo.pop_front();
                    if (fifo_tr.rData == pop_data) begin
                        $display("[SCB] : Data Matched %h==%h", fifo_tr.rData,
                                 pop_data);
                    end else begin
                        $display("[SCB] : Data MisMatched %h!=%h",
                                 fifo_tr.rData, pop_data);
                    end
                end else begin
                    $display("[SCB] : FIFO is Empty!!!");
                end
            end
        end
    endtask  //
endclass  //scoreboard

class envirnment;
    mailbox #(transaction) GenToDrv_mbox;
    mailbox #(transaction) MonToSCB_mbox;
    eveng                  next_gen_event;
    generator              fifo_gen;
    driver                 fifo_drv;
    monitor                fifo_mon;
    scoreboard             fifo_scb;

    function new(virtual fifo_intf fifo_if);
        GenToDrv_mbox = new();
        MonToSCB_mbox = new();
        fifo_gen = new(GenToDrv_mbox, next_gen_event);
        fifo_drv = new(GenToDrv_mbox, fifo_if);
        fifo_mon = new(MonToSCB_mbox, fifo_if);
        fifo_scb = new(MonToSCB_mbox, next_gen_event);
    endfunction  //new()

    task run(int count);
        fork
            fifo_gen.run(count);
            fifo_drv.run();
            fifo_mon.run();
            fifo_scb.run();
        join_any
    endtask  //
endclass  //envirnment

module tb_fifo_sv ();
    fifo_interface fifo_intf ();
    fifo dut (
        .clk  (fifo_intf.clk),
        .reset(fifo_intf.reset),
        .wr_en(fifo_intf.wr_en),
        .rd_en(fifo_intf.rd_en),
        .wData(fifo_intf.wData),
        .rData(fifo_intf.rData),
        .full (fifo_intf.full),
        .empty(fifo_intf.empty)
    );

    always #5 fifo_intf.clk = ~fifo_intf.clk;

    initial begin
        fifo_intf.clk   = 0;
        fifo_intf.reset = 1;
        #10 fifo_intf.reset = 0;
    end
endmodule
