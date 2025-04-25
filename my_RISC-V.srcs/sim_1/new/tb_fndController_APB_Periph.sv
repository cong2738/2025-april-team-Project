`timescale 1ns / 1ps

class transaction;
    // APB Interface Signals
    rand logic [ 3:0] PADDR;
    rand logic [31:0] PWDATA;
    rand logic        PWRITE;
    rand logic        PENABLE;
    rand logic        PSEL;
    logic      [31:0] PRDATA;  // dut out data
    logic             PREADY;  // dut out data
    // outport signals
    logic      [ 3:0] fndCom;  // dut out data
    logic      [ 7:0] fndFont;  // dut out data
    logic      [ 3:0] sim_dp;  // dut out data
    logic      [13:0] sim_bcd;  // dut out data
    // en / com / data
    constraint c_paddr {
        PADDR dist {
            4'h0 := 10,
            4'h4 := 50,
            4'h8 := 50
        };
    }  // 이 중에 하나 쓸거임
    // constraint c_wdata {PWDATA < 10;}
    constraint c_paddr_0 {
        if (PADDR == 0)
        PWDATA inside {1'b0, 1'b1};
        else
        if (PADDR == 4)
        PWDATA < 14'd10000;
        else
        if (PADDR == 8) PWDATA < 4'b1111;
    }

    task display(string name);
        $display(
            "[%s] PADDR=%h, PWDATA=%h, PWRITE=%h, PENABLE=%h, PSEL=%h, PRDATA=%h, PREADY=%h, fndCom=%h, fndFont=%h, dp=%b, bcd=%d",
            name, PADDR, PWDATA, PWRITE, PENABLE, PSEL, PRDATA, PREADY, fndCom,
            fndFont, sim_dp, sim_bcd);
    endtask

endclass  //transaction

interface APB_Slave_Interface;
    logic        PCLK;
    logic        PRESET;
    // APB Interface Signals
    logic [ 3:0] PADDR;
    logic [31:0] PWDATA;
    logic        PWRITE;
    logic        PENABLE;
    logic        PSEL;
    logic [31:0] PRDATA;  // dut out data
    logic        PREADY;  // dut out data
    // outport signals
    logic [ 3:0] fndCom;  // dut out data
    logic [ 7:0] fndFont;  // dut out data


    logic [ 3:0] sim_dp;  // dut out data
    logic [13:0] sim_bcd;  // dut out data
endinterface  //APB_Slave_Interface

class generator;
    mailbox #(transaction) Gen2Drv_mbox;
    event gen_next_event;

    function new(mailbox#(transaction) Gen2Drv_mbox, event gen_next_event);
        this.Gen2Drv_mbox   = Gen2Drv_mbox;
        this.gen_next_event = gen_next_event;
    endfunction  //new()

    task run(int repeat_counter);
        transaction fnd_tr;
        repeat (repeat_counter) begin
            fnd_tr = new();  // make instance
            if (!fnd_tr.randomize()) $error("Randomization fail!");
            fnd_tr.display("GEN");
            Gen2Drv_mbox.put(fnd_tr);
            @(gen_next_event);  // wait a event from driver
        end
    endtask
endclass  //generator


class driver;
    virtual APB_Slave_Interface fnd_intf;
    mailbox #(transaction) Gen2Drv_mbox;
    transaction fnd_tr;

    function new(virtual APB_Slave_Interface fnd_intf,
                 mailbox#(transaction) Gen2Drv_mbox);
        this.fnd_intf = fnd_intf;
        this.Gen2Drv_mbox = Gen2Drv_mbox;
    endfunction  //new()

    task run();
        forever begin
            Gen2Drv_mbox.get(fnd_tr);
            fnd_tr.display("DRV");
            @(posedge fnd_intf.PCLK);
            fnd_intf.PADDR   <= fnd_tr.PADDR;
            fnd_intf.PWDATA  <= fnd_tr.PWDATA;
            fnd_intf.PWRITE  <= 1'b1;
            fnd_intf.PENABLE <= 1'b0;
            fnd_intf.PSEL    <= 1'b1;
            @(posedge fnd_intf.PCLK);
            fnd_intf.PADDR   <= fnd_tr.PADDR;
            fnd_intf.PWDATA  <= fnd_tr.PWDATA;
            fnd_intf.PWRITE  <= 1'b1;
            fnd_intf.PENABLE <= 1'b1;
            fnd_intf.PSEL    <= 1'b1;
            wait (fnd_intf.PREADY == 1'b1);
        end
    endtask  //run

endclass  // driver


class monitor;
    mailbox #(transaction) Mon2SCB_mbox;
    virtual APB_Slave_Interface fnd_intf;
    transaction fnd_tr;

    function new(virtual APB_Slave_Interface fnd_intf,
                 mailbox#(transaction) Mon2SCB_mbox);
        this.fnd_intf = fnd_intf;
        this.Mon2SCB_mbox = Mon2SCB_mbox;
    endfunction  //new()

    task run();
        forever begin
            fnd_tr = new();
            // wait (fnd_intf.PREADY == 1'b1);
            @(posedge fnd_intf.PREADY);
            #1;
            fnd_tr.PADDR   = fnd_intf.PADDR;
            fnd_tr.PWDATA  = fnd_intf.PWDATA;
            fnd_tr.PWRITE  = fnd_intf.PWRITE;
            fnd_tr.PENABLE = fnd_intf.PENABLE;
            fnd_tr.PSEL    = fnd_intf.PSEL;
            fnd_tr.PRDATA  = fnd_intf.PRDATA;
            fnd_tr.PREADY  = fnd_intf.PREADY;
            fnd_tr.fndCom  = fnd_intf.fndCom;
            fnd_tr.fndFont = fnd_intf.fndFont;
            fnd_tr.sim_dp  = fnd_intf.sim_dp;
            fnd_tr.sim_bcd = fnd_intf.sim_bcd;
            Mon2SCB_mbox.put(fnd_tr);
            fnd_tr.display("MON");
            @(posedge fnd_intf.PCLK);
        end
    endtask
endclass  //monitor


class scoreboard;
    mailbox #(transaction) Mon2SCB_mbox;
    transaction fnd_tr;
    event gen_next_event;

    // reference model
    logic [31:0] refFndReg[0:2];  // = slv_reg0, slv_reg1, slv_reg2

    int write_cnt;
    int read_cnt;
    int bcd_pass_cnt;
    int dp_pass_cnt;
    int en_pass_cnt;
    int bcd_fail_cnt;
    int dp_fail_cnt;
    int en_fail_cnt;
    int total_cnt;

    function new(mailbox#(transaction) Mon2SCB_mbox, event gen_next_event);
        this.Mon2SCB_mbox = Mon2SCB_mbox;
        this.gen_next_event = gen_next_event;

        write_cnt = 0;
        read_cnt = 0;
        bcd_pass_cnt = 0;
        dp_pass_cnt = 0;
        en_pass_cnt = 0;
        bcd_fail_cnt = 0;
        dp_fail_cnt = 0;
        en_fail_cnt = 0;
        total_cnt = 0;

        for (int i = 0; i < 3; i++) begin
            refFndReg[i] = 0;
        end
    endfunction  //new()

    task run();
        forever begin
            Mon2SCB_mbox.get(fnd_tr);
            fnd_tr.display("SCB");

            if (fnd_tr.PWRITE) begin  // write mode
                write_cnt++;
                total_cnt++;
                refFndReg[fnd_tr.PADDR[3:2]] = fnd_tr.PWDATA;
                if (refFndReg[1] == fnd_tr.sim_bcd) begin  // PASS!
                    bcd_pass_cnt++;
                    $display("FND BCD PASS!, %d, %d", refFndReg[1],
                             fnd_tr.sim_bcd);
                end else begin
                    bcd_fail_cnt++;
                    $display("FND BCD FAIL!, %d, %d", refFndReg[1],
                             fnd_tr.sim_bcd);
                end
                if (refFndReg[0] == 0) begin  // en == 0: fndCom == 4'b1111;
                    if (4'hf == fnd_tr.fndCom) begin
                        dp_pass_cnt++;
                        $display("FND Enable PASS!");
                    end else begin
                        dp_fail_cnt++;
                        $display("FND Enable FAIL!");
                    end
                end else begin  // en == 1;
                    if (refFndReg[2][3:0] == fnd_tr.sim_dp) begin
                        en_pass_cnt++;
                        $display("FND DP PASS!, %h, %h", refFndReg[2][3:0],
                                 fnd_tr.sim_dp);
                    end else en_fail_cnt++;
                    $display("FND DP FAIL!, %h, %h", refFndReg[2][3:0],
                             fnd_tr.sim_dp);
                end
            end else begin  // read mode 나중에 할게
            end
            ->gen_next_event;
        end
    endtask


endclass  //scoreboard


class envirnment;
    mailbox #(transaction) Gen2Drv_mbox;
    mailbox #(transaction) Mon2SCB_mbox;

    generator              fnd_gen;
    driver                 fnd_drv;
    monitor                fnd_mon;
    scoreboard             fnd_scb;

    task show_report();
        $display("==================================");
        $display("==        Final Report          ==");
        $display("==================================");
        $display("Write_cnt Test  : %0d", this.fnd_scb.write_cnt);
        $display("Read_cnt  Test  : %0d", this.fnd_scb.read_cnt);
        $display("Bcd_pass_cnt  Test  : %0d", this.fnd_scb.bcd_pass_cnt);
        $display("Dp_pass_cnt  Test  : %0d", this.fnd_scb.dp_pass_cnt);
        $display("En_pass_cnt  Test  : %0d", this.fnd_scb.en_pass_cnt);
        $display("Bcd_fail_cnt  Test  : %0d", this.fnd_scb.bcd_fail_cnt);
        $display("Dp_fail_cnt  Test  : %0d", this.fnd_scb.dp_fail_cnt);
        $display("En_fail_cnt  Test  : %0d", this.fnd_scb.en_fail_cnt);
        $display("Total Test  : %0d", this.fnd_scb.total_cnt);
        $display("==================================");
        $display("==    test bench is finished!   ==");
    endtask

    event gen_next_event;

    function new(virtual APB_Slave_Interface fnd_intf);
        this.Gen2Drv_mbox = new();
        this.Mon2SCB_mbox = new();
        this.fnd_gen = new(Gen2Drv_mbox, gen_next_event);
        this.fnd_drv = new(fnd_intf, Gen2Drv_mbox);
        this.fnd_mon = new(fnd_intf, Mon2SCB_mbox);
        this.fnd_scb = new(Mon2SCB_mbox, gen_next_event);
    endfunction  //new()

    task run(int count);
        fork
            fnd_gen.run(count);
            fnd_drv.run();
            fnd_mon.run();
            fnd_scb.run();
        join_any
    endtask  //

endclass  // envirnment

module tb_fndController_APB_Periph ();

    envirnment fnd_env;
    APB_Slave_Interface fnd_intf ();

    always #5 fnd_intf.PCLK = ~fnd_intf.PCLK;

    fnd_Periph dut (
        // global signal
        .PCLK(fnd_intf.PCLK),
        .PRESET(fnd_intf.PRESET),
        // APB Interface Signals
        .PADDR(fnd_intf.PADDR),
        .PWDATA(fnd_intf.PWDATA),
        .PWRITE(fnd_intf.PWRITE),
        .PENABLE(fnd_intf.PENABLE),
        .PSEL(fnd_intf.PSEL),
        .PRDATA(fnd_intf.PRDATA),
        .PREADY(fnd_intf.PREADY),
        // outport signals
        .fndCom(fnd_intf.fndCom),
        .fndFont(fnd_intf.fndFont),
        .sim_dp(fnd_intf.sim_dp),
        .sim_bcd(fnd_intf.sim_bcd)
    );



    initial begin
        fnd_intf.PCLK   = 0;
        fnd_intf.PRESET = 1;
        #10 fnd_intf.PRESET = 0;
        fnd_env = new(fnd_intf);
        fnd_env.run(100);
        #30;
        fnd_env.show_report();
        $finish;
    end
endmodule
