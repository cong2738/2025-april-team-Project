`timescale 1ns / 1ps

class transaction;

  rand logic [ 3:0] PADDR;
  logic             PWRITE       = 1'b0;
  logic             PENABLE;
  logic             PSEL;
  logic      [31:0] PRDATA;
  logic             PREADY;


  rand logic [ 7:0] humidity;
  rand logic [ 7:0] temperature;


  constraint c_addr {
    PADDR dist {
      4'h0 := 33,
      4'h4 := 33,
      4'h8 := 34
    };
  }

  constraint c_h {humidity inside {[20 : 90]};}
  constraint c_t {temperature inside {[0 : 50]};}

  task display(string name);
    $display("[%s] PADDR=%0h, HUM=%0d, TEMP=%0d, PRDATA=%0h", name, PADDR, humidity,
             temperature, PRDATA);
  endtask
endclass


interface DHT11_if;
  logic PCLK, PRESET;
  logic [3:0] PADDR;
  logic PWRITE, PENABLE, PSEL;
  logic [31:0] PRDATA;
  logic        PREADY;
  tri          DATA_IO;

endinterface


class generator;
  mailbox #(transaction) mb;
  event                  done_evt;

  function new(mailbox#(transaction) mb, event done_evt);
    this.mb       = mb;
    this.done_evt = done_evt;
  endfunction

  task run(int N);
    transaction tr;
    repeat (N) begin
      tr = new();
      if (!tr.randomize()) begin
        $error("Randomize failed");
        $finish;
      end

      tr.display("GEN");
      mb.put(tr);
      @(done_evt);
    end
  endtask
endclass

// 원인? 지피티 검색 
// 이렇게 인터페이스 안의 tri 넷을 procedural 영역(클래스 태스크)에서 강제구조(force)로 제어하면, 
// Vivado XSIM에서는 종종 내부 상태가 꼬여서 복구 불가능한 예외가 발생합니다.


class driver;
  virtual DHT11_if       ifc;
  mailbox #(transaction) mb;
  event                  done_evt;

  function new(virtual DHT11_if ifc, mailbox#(transaction) mb, event done_evt);
    this.ifc      = ifc;
    this.mb       = mb;
    this.done_evt = done_evt;
  endfunction


  task sensor_behave(logic [7:0] H, logic [7:0] T);
    bit [39:0] bits = {H, 8'h00, T, 8'h00, H + T};


    wait (ifc.DATA_IO === 1'b0);
    #200_000;
    wait (ifc.DATA_IO === 1'bz);


    force ifc.DATA_IO = 1'b0;
    #80_000;
    release ifc.DATA_IO;
    #80_000;


    for (int i = 39; i >= 0; --i) begin

      force ifc.DATA_IO = 1'b0;
      #50_000;
      if (bits[i]) begin

        release ifc.DATA_IO;
        #70_000;
      end else release ifc.DATA_IO;
      #26_000;
    end


    release ifc.DATA_IO;
  endtask

  task run();
    transaction tr;
    forever begin
      mb.get(tr);


      @(posedge ifc.PCLK);
      ifc.PSEL    <= 1;
      ifc.PWRITE  <= 0;
      ifc.PADDR   <= tr.PADDR;
      ifc.PENABLE <= 0;

      force ifc.DATA_IO = 1'b0;


      fork
        sensor_behave(tr.humidity, tr.temperature);
      join_none


      @(posedge ifc.PCLK);
      ifc.PENABLE <= 1;


      ifc.PREADY  <= 1;
      @(posedge ifc.PCLK);
      tr.PRDATA = ifc.PRDATA;
      tr.PREADY = ifc.PREADY;

      ->done_evt;


      ifc.PSEL    <= 0;
      ifc.PENABLE <= 0;
      ifc.PREADY  <= 0;

      release ifc.DATA_IO;
    end
  endtask
endclass


class monitor;
  mailbox #(transaction) mb;
  virtual DHT11_if       ifc;
  event                  done_evt;

  function new(virtual DHT11_if ifc, mailbox#(transaction) mb, event done_evt);
    this.ifc      = ifc;
    this.mb       = mb;
    this.done_evt = done_evt;
  endfunction

  task run();
    transaction tr;
    forever begin
      @(done_evt);
      tr = new();
      tr.PRDATA = ifc.PRDATA;
      tr.PREADY = ifc.PREADY;
      mb.put(tr);
    end
  endtask
endclass


class scoreboard;
  mailbox #(transaction) mb;
  event                  done_evt;
  int                    pass      = 0, fail = 0;

  function new(mailbox#(transaction) mb, event done_evt);
    this.mb       = mb;
    this.done_evt = done_evt;
  endfunction

  task run(int total);
    transaction tr;
    repeat (total) begin
      mb.get(tr);
      case (tr.PADDR)
        4'h0: if (tr.PRDATA[7:0] == tr.humidity) pass++;
 else fail++;
        4'h4: if (tr.PRDATA[7:0] == tr.temperature) pass++;
 else fail++;
        4'h8: if (tr.PRDATA[0] == (tr.humidity + tr.temperature)) pass++;
 else fail++;
      endcase
      ->done_evt;
    end
    $display("=== Result: PASS=%0d, FAIL=%0d ===", pass, fail);
  endtask
endclass


module tb_DHT11;
  parameter N = 50;


  DHT11_if ifc ();


  mailbox #(transaction) gen2drv = new();
  mailbox #(transaction) mon2scb = new();
  event evt_gen_done, evt_drv_done;


  generator  gen;
  driver     drv;
  monitor    mon;
  scoreboard sb;


  DHT11_Periph DUT (
      .PCLK   (ifc.PCLK),
      .PRESET (ifc.PRESET),
      .PADDR  (ifc.PADDR),
      .PWDATA (),
      .PWRITE (ifc.PWRITE),
      .PENABLE(ifc.PENABLE),
      .PSEL   (ifc.PSEL),
      .PRDATA (ifc.PRDATA),
      .PREADY (ifc.PREADY),
      .DATA_IO(ifc.DATA_IO)
  );


  initial begin
    ifc.PCLK = 0;
    forever #5 ifc.PCLK = ~ifc.PCLK;
  end
  initial begin
    ifc.PRESET = 1;
    #20;
    ifc.PRESET = 0;
  end


  initial begin
    ifc.PADDR   = 4'h0;
    ifc.PWRITE  = 1'b0;
    ifc.PENABLE = 1'b0;
    ifc.PSEL    = 1'b0;
  end


  initial begin

    gen = new(gen2drv, evt_gen_done);
    drv = new(ifc, gen2drv, evt_drv_done);
    mon = new(ifc, mon2scb, evt_drv_done);
    sb  = new(mon2scb, evt_gen_done);


    fork
      gen.run(N);
      drv.run();
      mon.run();
      sb.run(N);
    join_any

    #100;
    $finish;
  end
endmodule

