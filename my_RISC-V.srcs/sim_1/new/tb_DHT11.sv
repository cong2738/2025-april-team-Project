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
    $display("[%s] PADDR=%h HUM=%0d TEMP=%0d PRDATA=%h", name, PADDR, humidity, temperature,
             PRDATA);
  endtask
endclass


interface DHT11_if;
  logic        PCLK;
  logic        PRESET;
  logic [ 3:0] PADDR;
  logic        PWRITE;
  logic        PENABLE;
  logic        PSEL;
  logic [31:0] PRDATA;
  logic        PREADY;

  // Drive signals for inout DATA_IO // tri로 하면 오류가 뜸 
  logic        drive_en;
  logic        drive_data;
  wire         DATA_IO = drive_en ? drive_data : 1'bz;
endinterface


class generator;
  mailbox #(transaction) mb;
  event                  done_evt;

  function new(mailbox#(transaction) mb_i, event done_evt_i);
    mb       = mb_i;
    done_evt = done_evt_i;
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


class driver;
  virtual DHT11_if       ifc;
  mailbox #(transaction) mb;
  event                  done_evt;

  function new(virtual DHT11_if ifc_i, mailbox#(transaction) mb_i, event done_evt_i);
    ifc      = ifc_i;
    mb       = mb_i;
    done_evt = done_evt_i;
  endfunction

  // task sensor_behave(logic [7:0] H, logic [7:0] T);
  //   bit [39:0] bits = {H, 8'h00, T, 8'h00, H + T};
  //   wait (ifc.DATA_IO === 1'b0);
  //   #200_000;
  //   wait (ifc.DATA_IO === 1'bz);
  //   ifc.drive_en   = 1;
  //   ifc.drive_data = 0;
  //   #80_000;
  //   ifc.drive_en = 0;
  //   #80_000;
  //   for (int i = 39; i >= 0; i = i - 1) begin
  //     ifc.drive_en   = 1;
  //     ifc.drive_data = 0;
  //     #50_000;
  //     ifc.drive_en = bits[i];
  //     #((bits[i]) ? 70_000 : 0);
  //     ifc.drive_en = 0;
  //     #26_000;
  //   end
  //   ifc.drive_en = 0;
  // endtask

  localparam integer START_LOW = 200_000;  // 200 µs
  localparam integer START_REL = 2_000;  //   2 µs
  localparam integer RESP_LOW = 8_000;  //   8 µs
  localparam integer RESP_HIGH = 8_000;  //   8 µs
  localparam integer BIT_START = 5_000;  //   5 µs
  localparam integer BIT_ONE_H = 7_000;  //   7 µs
  localparam integer BIT_ZERO_H = 2_600;  // 2.6 µs
  localparam integer BIT_POST = 2_600;  // 2.6 µs

  // 센서 구현
  task sensor_behave(logic [7:0] H, logic [7:0] T);
    bit [39:0] bits = {H, 8'h00, T, 8'h00, H + T};

    wait (ifc.DATA_IO === 0);
    #START_LOW;
    wait (ifc.DATA_IO === 1'bz);

    ifc.drive_en = 1;
    #RESP_LOW;
    ifc.drive_en = 0;
    #RESP_HIGH;

    // 40비트
    for (int i = 39; i >= 0; i = i - 1) begin
      ifc.drive_en = 1;
      #BIT_START;
      ifc.drive_en = bits[i];
      #(bits[i] ? BIT_ONE_H : BIT_ZERO_H);
      ifc.drive_en = 0;
      #BIT_POST;
    end

    ifc.drive_en = 0;
  endtask

  task run();
    transaction tr;
    forever begin
      mb.get(tr);
      // @(posedge ifc.PCLK);
      // ifc.PSEL    <= 1;
      // ifc.PWRITE  <= 0;
      // ifc.PADDR   <= tr.PADDR;
      // ifc.PENABLE <= 0;
      // ifc.drive_en   = 1;
      // ifc.drive_data = 0;
      // fork
      //   sensor_behave(tr.humidity, tr.temperature);
      // join_none
      // @(posedge ifc.PCLK);
      // ifc.PENABLE <= 1;
      // @(posedge ifc.PREADY);
      // tr.PRDATA = ifc.PRDATA;
      // tr.PREADY = ifc.PREADY;
      // ->done_evt;
      // ifc.PSEL    <= 0;
      // ifc.PENABLE <= 0;
      // ifc.drive_en = 0;
      ifc.drive_en   = 1;
      ifc.drive_data = 0;
      sensor_behave(tr.humidity, tr.temperature);
      ifc.drive_en = 0;

      @(posedge ifc.PCLK);
      ifc.PSEL    <= 1;
      ifc.PWRITE  <= 0;
      ifc.PADDR   <= tr.PADDR;
      ifc.PENABLE <= 0;

      @(posedge ifc.PCLK);
      ifc.PENABLE <= 1;

      @(posedge ifc.PREADY);
      tr.PRDATA = ifc.PRDATA;
      tr.PREADY = ifc.PREADY;
      ->done_evt;

      ifc.PSEL    <= 0;
      ifc.PENABLE <= 0;
    end
  endtask
endclass


class monitor;
  mailbox #(transaction) mb;
  virtual DHT11_if       ifc;
  event                  done_evt;

  function new(virtual DHT11_if ifc_i, mailbox#(transaction) mb_i, event done_evt_i);
    ifc      = ifc_i;
    mb       = mb_i;
    done_evt = done_evt_i;
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

  function new(mailbox#(transaction) mb_i, event done_evt_i);
    mb       = mb_i;
    done_evt = done_evt_i;
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


class env;
  virtual DHT11_if       ifc;
  mailbox #(transaction) gen2drv,      mon2scb;
  event                  evt_gen_done, evt_drv_done;
  generator              gen;
  driver                 drv;
  monitor                mon;
  scoreboard             sb;
  int                    N;


  function new(virtual DHT11_if ifc_i, int N_i);
    ifc     = ifc_i;
    N       = N_i;
    gen2drv = new();
    mon2scb = new();
    gen     = new(gen2drv, evt_gen_done);
    drv     = new(ifc, gen2drv, evt_drv_done);
    mon     = new(ifc, mon2scb, evt_drv_done);
    sb      = new(mon2scb, evt_gen_done);
  endfunction


  task run();
    fork
      gen.run(N);
      drv.run();
      mon.run();
      sb.run(N);
    join
    ;
  endtask
endclass


module tb_DHT11 ();
  // parameter N = 50;
  parameter N = 10;  // 줄여봄
  DHT11_if ifc ();
  env environment;

  DHT11_Periph dut (
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
    ifc.PADDR      = 4'h0;
    ifc.PWRITE     = 1'b0;
    ifc.PENABLE    = 1'b0;
    ifc.PSEL       = 1'b0;
    ifc.drive_en   = 1'b0;
    ifc.drive_data = 1'b0;
  end

  initial begin
    environment = new(ifc, N);
    environment.run();
    #100;
    $finish;
  end
endmodule
