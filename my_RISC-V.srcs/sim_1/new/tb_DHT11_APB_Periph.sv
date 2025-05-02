`timescale 1ns / 1ps
// tb_DHT11_APB_Periph.sv

class transaction;
  // APB Interface Signals
  rand logic [ 3:0] PADDR;
  rand logic [31:0] PWDATA;
  rand logic        PWRITE;
  rand logic        PENABLE;
  rand logic        PSEL;
  logic      [31:0] PRDATA;
  logic             PREADY;
  logic             DATA_IO;

  logic      [ 7:0] sim_rh;
  logic      [ 7:0] sim_t;
  logic             sim_finish;


  constraint c_read_addr {PADDR inside {4'h0, 4'h4, 4'h8};}
  constraint c_read_only {PWRITE == 1'b0;}
  constraint c_dummy_data {PWDATA inside {32'h0};}

  task display(string name);
    $display("[%s] PADDR=%h, PRDATA=%h, PREADY=%h, sim_rh=%0d, sim_t=%0d, sim_finish=%b", name,
             PADDR, PRDATA, PREADY, sim_rh, sim_t, sim_finish);
  endtask
endclass

interface APB_Slave_Interface;
  logic        PCLK;
  logic        PRESET;
  logic [ 3:0] PADDR;
  logic [31:0] PWDATA;
  logic        PWRITE;
  logic        PENABLE;
  logic        PSEL;
  logic [31:0] PRDATA;
  logic        PREADY;
  //   logic        DATA_IO;
  wire         DATA_IO;
  logic [ 7:0] sim_rh;
  logic [ 7:0] sim_t;
  logic        sim_finish;
endinterface

class generator;
  virtual APB_Slave_Interface vif;
  mailbox #(transaction) Gen2Drv_mbox;
  event gen_next_event;

  function new(
    virtual APB_Slave_Interface vif,
    mailbox #(transaction) mb,
    event                 ev
  );
    this.vif            = vif;
    this.Gen2Drv_mbox   = mb;
    this.gen_next_event = ev;
  endfunction

  task run(int repeat_counter);
    transaction tr;
    repeat (repeat_counter) begin

      // START
      tr = new();
      tr.PADDR   = 4'h0;    
      tr.PWDATA  = 32'h1;   
      tr.PWRITE  = 1'b1;
      tr.PSEL    = 1'b1;
      tr.PENABLE = 1'b0;
      Gen2Drv_mbox.put(tr);
      @(gen_next_event);


      // RH 읽기
      tr = new();
      tr.PADDR   = 4'h0;   
      tr.PWRITE  = 1'b0;
      tr.PSEL    = 1'b1;
      tr.PENABLE = 1'b0;
      Gen2Drv_mbox.put(tr);
      @(gen_next_event);

      // T 읽기 트랜잭션
      tr = new();
      tr.PADDR   = 4'h4;    
      tr.PWRITE  = 1'b0;
      tr.PSEL    = 1'b1;
      tr.PENABLE = 1'b0;
      Gen2Drv_mbox.put(tr);
      @(gen_next_event);

      // Finish 읽기 트랜잭션
      tr = new();
      tr.PADDR   = 4'h8;   
      tr.PWRITE  = 1'b0;
      tr.PSEL    = 1'b1;
      tr.PENABLE = 1'b0;
      Gen2Drv_mbox.put(tr);
      @(gen_next_event);
    end
  endtask
endclass

class driver;
  virtual APB_Slave_Interface vif;
  mailbox #(transaction) Gen2Drv_mbox;
  transaction tr;
  event gen_next_event;
  function new(virtual APB_Slave_Interface vif, mailbox#(transaction) mb, event ev);
    this.vif = vif;
    this.Gen2Drv_mbox = mb;
    this.gen_next_event = ev;
  endfunction
  task run();
    forever begin
      Gen2Drv_mbox.get(tr);
      
      @(posedge vif.PCLK);
      vif.PADDR   <= tr.PADDR;
      vif.PWDATA  <= tr.PWDATA; 
      vif.PWRITE  <= tr.PWRITE;
      vif.PSEL    <= tr.PSEL;
      vif.PENABLE <= 1'b0;
     
      @(posedge vif.PCLK);
      vif.PENABLE <= 1'b1;
      wait (vif.PREADY == 1'b1);
      
      @(posedge vif.PCLK);
      vif.PSEL    <= 1'b0;
      vif.PENABLE <= 1'b0;
      ->gen_next_event;
    end
  endtask
endclass

class monitor;
  mailbox #(transaction) Mon2SCB_mbox;
  virtual APB_Slave_Interface vif;
  transaction tr;
  function new(virtual APB_Slave_Interface vif, mailbox#(transaction) mb);
    this.vif = vif;
    this.Mon2SCB_mbox = mb;
  endfunction
  task run();
    forever begin
      @(posedge vif.PREADY);
      #1;
      tr            = new();
      tr.PADDR      = vif.PADDR;
      tr.PRDATA     = vif.PRDATA;
      tr.PREADY     = vif.PREADY;
      tr.sim_rh     = vif.sim_rh;
      tr.sim_t      = vif.sim_t;
      tr.sim_finish = vif.sim_finish;
      tr.display("MON");
      Mon2SCB_mbox.put(tr);
    end
  endtask
endclass

class scoreboard;
  mailbox #(transaction) Mon2SCB_mbox;
  transaction tr;
  event gen_next_event;
  // reference model
  logic [31:0] refReg[0:2];  // [0]=RH, [1]=T, [2]=finish
  
  int total_cnt;
  int read_cnt;
  int rh_pass_cnt;
  int rh_fail_cnt;
  int t_pass_cnt;
  int t_fail_cnt;
  int finish_pass_cnt;
  int finish_fail_cnt;
  
  function new(mailbox#(transaction) mb, event ev);
    this.Mon2SCB_mbox   = mb;
    this.gen_next_event = ev;
    total_cnt           = 0;
    read_cnt            = 0;
    rh_pass_cnt         = 0;
    rh_fail_cnt         = 0;
    t_pass_cnt          = 0;
    t_fail_cnt          = 0;
    finish_pass_cnt     = 0;
    finish_fail_cnt     = 0;
    for (int i = 0; i < 3; i++) refReg[i] = 0;
  endfunction
  
   task run();
    forever begin
      Mon2SCB_mbox.get(tr);
      // 쓰기 스킵킵
      if (tr.PWRITE) begin
        ->gen_next_event;
        continue;
      end

      tr.display("SCB");
      total_cnt++;
      read_cnt++;

      case (tr.PADDR)
        4'h0: begin  // RH 읽기
          refReg[0] = tr.sim_rh;
          if (tr.PRDATA[7:0] === tr.sim_rh) rh_pass_cnt++;
          else                                rh_fail_cnt++;
        end
        4'h4: begin  // T  읽기
          refReg[1] = tr.sim_t;
          if (tr.PRDATA[7:0] === tr.sim_t)  t_pass_cnt++;
          else                                t_fail_cnt++;
        end
        4'h8: begin  // Finish 읽기
          refReg[2] = tr.sim_finish;
          if (tr.PRDATA[0]   === tr.sim_finish) finish_pass_cnt++;
          else                                    finish_fail_cnt++;
        end
      endcase

      ->gen_next_event;
    end
  endtask
endclass

class envirnment;
  mailbox #(transaction) genMb;
  mailbox #(transaction) monMb;

  generator              gen;
  driver                 drv;
  monitor                mon;
  scoreboard             sb;
  event                  gen_next_event;


  function new(virtual APB_Slave_Interface vif);
    this.genMb = new();
    this.monMb = new();
    this.gen = new(vif, genMb, gen_next_event);
    this.drv = new(vif, genMb, gen_next_event);
    this.mon = new(vif, monMb);
    this.sb = new(monMb, gen_next_event);
  endfunction
  task run(int count);
    fork
      gen.run(count);
      drv.run();
      mon.run();
      sb.run();
    join_any
  endtask

  task show_report();
    $display("=== Final Report ===");
    $display("Total Reads     : %0d", sb.read_cnt);
    $display("RH Passed       : %0d", sb.rh_pass_cnt);
    $display("RH Failed       : %0d", sb.rh_fail_cnt);
    $display("T  Passed       : %0d", sb.t_pass_cnt);
    $display("T  Failed       : %0d", sb.t_fail_cnt);
    $display("Finish Passed   : %0d", sb.finish_pass_cnt);
    $display("Finish Failed   : %0d", sb.finish_fail_cnt);
    $display("====================");
  endtask

endclass

module tb_DHT11_APB_Periph;
  APB_Slave_Interface vif ();
  envirnment env;

  reg sensor_drive;
  assign vif.DATA_IO = sensor_drive ? 1'b0 : 1'bz;

  reg [7:0] RH_var, T_var, chk_var;
  reg [39:0] bits_var;
  integer    i;

  DHT11_Periph dut (
      .PCLK      (vif.PCLK),
      .PRESET    (vif.PRESET),
      .PADDR     (vif.PADDR),
      .PWDATA    (vif.PWDATA),
      .PWRITE    (vif.PWRITE),
      .PENABLE   (vif.PENABLE),
      .PSEL      (vif.PSEL),
      .PRDATA    (vif.PRDATA),
      .PREADY    (vif.PREADY),
      .DATA_IO   (vif.DATA_IO),
      .sim_rh    (vif.sim_rh),
      .sim_t     (vif.sim_t),
      .sim_finish(vif.sim_finish)
  );

  // DHT11 START 펄스 감지 -> 응답 -> 40비트 전송
  initial begin
    sensor_drive = 0;
    forever begin
      // DUT가 스타트 펄스(약 18ms LOW) 시작
      wait (vif.DATA_IO === 1'b0);

      // 센서 응답: 80us LOW
      #80_000;  // 80us 이후
      sensor_drive = 1;  // LOW 드라이브
      #80_000;  // 80us 유지
      sensor_drive = 0;  // release

      // 80us HIGH
      #80_000;

      // 40비트 전송
      RH_var = $urandom_range(20, 90);
      T_var = $urandom_range(15, 35);
      chk_var = (RH_var + T_var) & 8'hFF;
      bits_var = {RH_var, 8'h00, T_var, 8'h00, chk_var};
      for (i = 39; i >= 0; i = i - 1) begin
        // 50us LOW
        sensor_drive = 1;
        #50_000;
        // HIGH 펄스: 0 -> 26us, 1 -> 70us
        sensor_drive = 0;
        if (bits_var[i]) #70_000;
        else #26_000;
      end

      sensor_drive = 0;
      #100_000;
    end
  end

  initial begin
    vif.PCLK = 0;
    forever #5 vif.PCLK = ~vif.PCLK;
  end
  initial begin
    vif.PRESET = 1;
    #20 vif.PRESET = 0;
  end

  initial begin
    env = new(vif);
    env.run(3);
    #50;
    env.show_report();
    $finish;
  end
endmodule
