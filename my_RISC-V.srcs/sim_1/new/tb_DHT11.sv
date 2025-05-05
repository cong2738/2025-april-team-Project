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
      4'h0 := 45,
      4'h4 := 45,
      4'h8 := 10
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
  
  tri1 DATA_IO;
  // pullup pul1 (DATA_IO);
  // wire         DATA_IO = drive_en ? drive_data : 1'bz;
  assign DATA_IO = drive_en ? drive_data : 1'bz;
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
  mailbox #(transaction) gen_mb; // from generator
  // mailbox #(transaction) mon_mb; // to monitor
  event                  done_evt;

  // DHT11 timing parameters (data sheet)
  localparam integer START_LOW = 18_000_000; // 18 ms
  localparam integer START_REL = 20_000;     // 20 us // 대기
  localparam integer RESP_LOW  = 80_000;     // 80 us
  localparam integer RESP_HIGH = 80_000;     // 80 us
  localparam integer BIT_START  = 50_000;    // 50 us
  localparam integer BIT_ONE_H  = 70_000;    // 70 us
  localparam integer BIT_ZERO_H = 26_000;    // 26 us

  function new(virtual DHT11_if ifc_i, mailbox#(transaction) mb_i, event done_evt_i);
    ifc      = ifc_i;
    gen_mb       = mb_i;
    // mon_mb   = mon_mb_i;
    done_evt = done_evt_i;
  endfunction

  task sensor_behave(logic [7:0] H, logic [7:0] T);
    bit [39:0] bits = {H, 8'h00, T, 8'h00, H + T};

    wait (ifc.DATA_IO === 1'b0);
    #START_LOW;
    
    ifc.drive_en = 0;        
    #START_REL;              

    ifc.drive_en   = 1;      
    ifc.drive_data = 0;
    #RESP_LOW;
    ifc.drive_data = 1;
    #RESP_HIGH;

    // 40bit
    for (int i = 39; i >= 0; i--) begin
      ifc.drive_data = 0;
      #BIT_START;
      ifc.drive_data = bits[i];
      if (bits[i])
        #BIT_ONE_H;
      else
        #BIT_ZERO_H;
    end

    ifc.drive_en = 0;
  endtask



  task run();
    transaction tr;
    forever begin
      gen_mb.get(tr);
      
      // ifc.drive_en   = 1;
      // ifc.drive_data = 0;
      // sensor_behave(tr.humidity, tr.temperature);
      fork
        sensor_behave(tr.humidity, tr.temperature);
      join_none
      
      // ifc.drive_en = 0;
      $display("[DRV] Sensor done, issuing APB read for PADDR=%0h @%0t", tr.PADDR, $realtime);
      @(posedge ifc.PCLK);
      ifc.PSEL    <= 1;
      ifc.PWRITE  <= 0;
      ifc.PADDR   <= tr.PADDR;
      ifc.PENABLE <= 0;
      $display("[DRV] APB Address phase: PADDR=%0h @%0t", tr.PADDR, $realtime);
      @(posedge ifc.PCLK);
      ifc.PENABLE <= 1;
      $display("[DRV] APB Enable phase @%0t", $realtime);
      @(posedge ifc.PREADY);
      
      tr.PRDATA = ifc.PRDATA;
      tr.PREADY = ifc.PREADY;
      $display("[DRV] APB Read complete: PRDATA=%0h PREADY=%0b @%0t", 
               tr.PRDATA, tr.PREADY, $realtime);
      mon_mb.put(tr);
      #1 ->done_evt;

      ifc.PSEL    <= 0;
      ifc.PENABLE <= 0;
    end
  endtask
endclass


class monitor;
  mailbox #(transaction) in_mb, out_mb;
  virtual DHT11_if       ifc;
  // event                  done_evt;
  event                  drv_done_evt;
  event                  mon_done_evt;

  function new(mailbox#(transaction) in_mb_i, mailbox#(transaction) out_mb_i, event drv_done_evt_i, event mon_done_evt_i, virtual DHT11_if ifc_i);
    ifc      = ifc_i;
    in_mb       = in_mb_i;
    out_mb       = out_mb_i;
    drv_done_evt = drv_done_evt_i;
    mon_done_evt = mon_done_evt_i;
  endfunction

  task run();
    transaction tr;
    forever begin
      @(drv_done_evt);
      in_mb.get(tr);
      if (ifc.PSEL && ifc.PENABLE && ifc.PREADY) begin
        tr.PRDATA = ifc.PRDATA;
        tr.PREADY = ifc.PREADY;
      end
      $display("[MON] Captured PRDATA=%0h PREADY=%0b @%0t", 
               tr.PRDATA, tr.PREADY, $realtime);
      out_mb.put(tr);
      #1 ->mon_done_evt;
    end
  endtask
endclass


class scoreboard;
  mailbox #(transaction) mb;
  event                  mon_done_evt;
  event                  gen_done_evt;
  int                    pass = 0, fail = 0;

  function new(mailbox#(transaction) mb_i, event mon_done_evt_i, event gen_done_evt_i);
    mb       = mb_i;
    mon_done_evt = mon_done_evt_i;
    gen_done_evt = gen_done_evt_i;
  endfunction

  task run(int total);
    transaction tr;
    repeat (total) begin
      @(mon_done_evt);
      mb.get(tr);
      case (tr.PADDR)
        4'h0: if (tr.PRDATA[7:0] == tr.humidity) pass++; else fail++;
        4'h4: if (tr.PRDATA[7:0] == tr.temperature) pass++; else fail++;
        // 4'h8: if (tr.PRDATA[0] == (tr.humidity + tr.temperature)) pass++; else fail++;
        4'h8: if (tr.PRDATA[0] == 1) pass++; else fail++;
      endcase
      $display("[SCB] PADDR=%0h PRDATA=%0h HUM=%0d TEMP=%0d PASS=%0d FAIL=%0d @%0t",
               tr.PADDR, tr.PRDATA, tr.humidity, tr.temperature, pass, fail, $realtime);
      #1 ->gen_done_evt;
    end
    $display("=== Result: PASS=%0d, FAIL=%0d ===", pass, fail);
  endtask
endclass


class env;
  virtual DHT11_if       ifc;
  mailbox #(transaction) gen2drv, drv2mon, mon2scb;
  event evt_drv_done, evt_mon_done, evt_gen_done;
  generator              gen;
  driver                 drv;
  monitor                mon;
  scoreboard             sb;
  int                    N;


  function new(virtual DHT11_if ifc_i, int N_i);
    ifc     = ifc_i;
    N       = N_i;
    gen2drv = new();
    drv2mon = new();
    mon2scb = new();

    gen = new(gen2drv,   evt_gen_done);
    drv = new(ifc, gen2drv, drv2mon, evt_drv_done);
    mon = new(drv2mon, mon2scb, evt_drv_done, evt_mon_done);
    sb  = new(mon2scb,   evt_mon_done, evt_gen_done);
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
  pullup pul1 (ifc.DATA_IO);
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
    $display("finished!");
    $finish;
  end
endmodule
