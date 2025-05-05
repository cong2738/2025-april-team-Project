`timescale 1ns / 1ps

interface dht_interface;
  logic clk;
  logic reset;
  logic start_trigger;

  // DHT IO lines
  wire dht_io;
  logic io_oe;      // 1: drive output, 0: input
  logic dht_data;   // data to drive
  int rand_width;   // random width for sensor bits

  // APB bus signals
  logic [3:0]  PADDR;
  logic [31:0] PWDATA;
  logic        PWRITE;
  logic        PENABLE;
  logic        PSEL;
  logic [31:0] PRDATA;
  logic        PREADY;

  assign dht_io = io_oe ? 1'bz : dht_data;

  // Modports for components
  modport drv_mport (
    output PADDR, PWDATA, PWRITE, PENABLE, PSEL,
    input  PRDATA, PREADY,
    inout dht_io
  );

  modport mon_mport (
    output PADDR, PWDATA, PWRITE, PENABLE, PSEL,
    input  PRDATA, PREADY, dht_io, rand_width
  );

  modport dut_mport (
    input  PADDR, PWDATA, PWRITE, PENABLE, PSEL, start_trigger,
    output PRDATA, PREADY,
    inout  dht_io
  );
endinterface 

class transaction;
  rand int rand_width;
  logic [3:0]  PADDR;
  logic        PWRITE;
  logic        PENABLE;
  logic        PSEL;
  logic [31:0] PRDATA;
  logic        PREADY;
  logic [31:0] data_out;
  logic [31:0] checksum;

  constraint odata { rand_width dist { 70 := 40, 30 := 60 }; }

  task display(string name);
    $display("[%s] rand_width=%0d PRDATA=0x%0h checksum=0x%0h",
      name, rand_width, data_out, checksum);
  endtask
endclass

class generator;
  mailbox #(transaction) GenToDrvMon_mbox;
  event               rand_width_require, rand_width_accept, scb_end;

  function new(
    mailbox#(transaction) m,
    event           wr_req, wr_acc, scb_ev
  );
    this.GenToDrvMon_mbox   = m;
    this.rand_width_require = wr_req;
    this.rand_width_accept  = wr_acc;
    this.scb_end            = scb_ev;
  endfunction

  task run(int repeat_count, int total_count);
    transaction tr = new();
    repeat (total_count) begin
      repeat (repeat_count) begin
        -> rand_width_require;
        if (!tr.randomize()) $error("Randomize failed");
        tr.display("GEN");
        GenToDrvMon_mbox.put(tr);
        -> rand_width_accept;
        #10;
      end
      @(scb_end);
    end
  endtask
endclass

class driver;
  virtual dht_interface.drv_mport intf;
  mailbox #(transaction)    GenToDrvMon_mbox;
  event                     rand_width_require, rand_width_accept, drv_end, scb_end;

  function new(
    mailbox#(transaction) m,
    virtual dht_interface.drv_mport f,
    event wr_req, wr_acc, drv_ev, scb_ev
  );
    this.GenToDrvMon_mbox   = m;
    this.intf                = f;
    this.rand_width_require = wr_req;
    this.rand_width_accept  = wr_acc;
    this.drv_end            = drv_ev;
    this.scb_end            = scb_ev;
  endfunction

  task start_trigger_pulse();
    intf.start_trigger = 1;
    @(posedge intf.clk);
    intf.start_trigger = 0;
  endtask

  task run(int repeat_count);
    transaction tr;
    forever begin
      start_trigger_pulse();
      @(intf.dht_io === 0);
      @(intf.dht_io === 1);
      #1000;
      intf.io_oe   = 0; 
      #35000;
      intf.io_oe   = 1;
      for (int i = 0; i < repeat_count; i++) begin
        -> rand_width_require;
        GenToDrvMon_mbox.get(tr);
        intf.rand_width = tr.rand_width;
        intf.dht_data = 1;
        repeat (tr.rand_width) @(posedge intf.clk);
        intf.dht_data = 0;
        -> rand_width_accept;
      end
      #100;
      -> drv_end;
      @(scb_end);
    end
  endtask
endclass

class monitor;
  virtual dht_interface.mon_mport intf;
  mailbox #(transaction)     MonToSCB_mbox;
  event                      drv_end, mon_end, rand_width_accept;

  function new(
    mailbox#(transaction) m,
    virtual dht_interface.mon_mport f,
    event drv_ev, mon_ev, wr_acc
  );
    this.MonToSCB_mbox     = m;
    this.intf               = f;
    this.drv_end           = drv_ev;
    this.mon_end           = mon_ev;
    this.rand_width_accept = wr_acc;
  endfunction

  task run(int repeat_count);
    transaction tr = new();
    forever begin
      repeat (repeat_count) begin
        @(rand_width_accept);
        tr.rand_width = intf.rand_width;
        MonToSCB_mbox.put(tr);
      end
      
      @(drv_end);
      // read humidity/temp
      intf.mon_mport.PADDR   = 4'h4;          
      intf.mon_mport.PWRITE  = 0;             
      intf.mon_mport.PSEL    = 1;            
      @(posedge intf.clk);          
      intf.mon_mport.PENABLE = 1;             
      @(posedge intf.clk);
      intf.mon_mport.PSEL    = 0;
      intf.mon_mport.PENABLE = 0;
      tr.data_out  = intf.mon_mport.PRDATA;   

      // read checksum
      intf.mon_mport.PADDR   = 4'h8;
      intf.mon_mport.PWRITE  = 0;
      intf.mon_mport.PSEL    = 1;
      @(posedge intf.clk);
      intf.mon_mport.PENABLE = 1;
      @(posedge intf.clk);
      intf.mon_mport.PSEL    = 0;
      intf.mon_mport.PENABLE = 0;
      tr.checksum  = intf.mon_mport.PRDATA;   
      MonToSCB_mbox.put(tr);
      -> mon_end;
    end
  endtask
endclass

class scoreboard;
  mailbox #(transaction)      MonToSCB_mbox;
  event                       rand_width_accept, mon_end, scb_end;
  int                         pass = 0, fail = 0;
  logic [39:0]                ref_data;
  logic                       ref_chk;

  function new(
    mailbox#(transaction) m,
    event wr_acc, mon_ev, scb_ev
  );
    this.MonToSCB_mbox     = m;
    this.rand_width_accept = wr_acc;
    this.mon_end           = mon_ev;
    this.scb_end           = scb_ev;
  endfunction

  task report();
  begin
    $display("=== TEST SUMMARY ===");
    $display("PASS : %0d", pass);
    $display("FAIL : %0d", fail);
    $display("====================");
  end
  endtask

  task run(int repeat_count);
    transaction tr;
    forever begin
      int idx = 0;
      // build reference bits
      repeat (repeat_count) begin
        @(rand_width_accept);
        MonToSCB_mbox.get(tr);
        ref_data[39-idx] = (tr.rand_width > 50);
        idx++;
      end
      ref_chk = ((ref_data[39:32] + ref_data[31:24] + ref_data[23:16] + ref_data[15:8]) == ref_data[7:0]);
      // wait monitor
      @(mon_end);
      MonToSCB_mbox.get(tr);
      if (tr.data_out != ref_data[39:8]) fail++; else pass++;
      MonToSCB_mbox.get(tr);
      if (tr.checksum[0] != ref_chk) fail++; else pass++;
      -> scb_end;
    end
  endtask
endclass

class environment;
  mailbox #(transaction) GenToDrvMon_mbox;
  mailbox #(transaction) MonToSCB_mbox;
  generator     gen;
  driver        drv;
  monitor       mon;
  scoreboard    scb;
  event         wr_req, wr_acc, drv_end, mon_end, scb_end;

  function new(virtual dht_interface intf);
    GenToDrvMon_mbox = new();
    MonToSCB_mbox    = new();
    gen = new(GenToDrvMon_mbox, wr_req, wr_acc, scb_end);
    drv = new(GenToDrvMon_mbox, intf.drv_mport, wr_req, wr_acc, drv_end, scb_end);
    mon = new(MonToSCB_mbox, intf.mon_mport, drv_end, mon_end, wr_acc);
    scb = new(MonToSCB_mbox, wr_acc, mon_end, scb_end);
  endfunction

  task run(int repeat_count, int total_count);
    fork
      gen.run(repeat_count, total_count);
      drv.run(repeat_count);
      mon.run(repeat_count);
      scb.run(repeat_count);
    join_any
    scb.report();
  endtask
endclass

module tb_DHT11;
  dht_interface intf();
  environment   env;

  // Instantiate DUT
  DHT11_Periph dut (
    .PCLK         (intf.clk),
    .PRESET       (intf.reset),
    .PADDR        (intf.dut_mport.PADDR),
    .PWDATA       (intf.dut_mport.PWDATA),
    .PWRITE       (intf.dut_mport.PWRITE),
    .PENABLE      (intf.dut_mport.PENABLE),
    .PSEL         (intf.dut_mport.PSEL),
    .PRDATA       (intf.dut_mport.PRDATA),
    .PREADY       (intf.dut_mport.PREADY),
    .DATA_IO      (intf.dut_mport.dht_io),
    .start_trigger(intf.dut_mport.start_trigger)
  );

  always #5 intf.clk = ~intf.clk;

  initial begin
    intf.clk   = 0;
    intf.reset = 1;
    intf.io_oe = 1;
    intf.dht_data = 1;
    #20 intf.reset = 0;

    env = new(intf);
    env.run(40, 20);
    #50 $finish;
  end
endmodule
