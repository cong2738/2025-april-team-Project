`timescale 1ns / 1ps
// tb_DHT11_notUVMst.sv
// module DHT11_module (
//     input  logic        clk,
//     input  logic        reset,
//     inout  logic        data,
//     output logic [7:0]  rh,
//     output logic [7:0]  t,
//     output logic        w_finish_tick
// );
//     // 고정된 값으로. reset 후 rh=0xA5, t=0x5A, w_finish_tick=1 (가짜센서)
//     always_ff @(posedge clk or posedge reset) begin
//         if (reset) begin
//             rh            <= 8'h00;
//             t             <= 8'h00;
//             w_finish_tick <= 1'b0;
//         end else begin
//             rh            <= 8'hA5;
//             t             <= 8'h5A;
//             w_finish_tick <= 1'b1;
//         end
//     end
// endmodule

// 센서 프로토콜 전체 구현!!!!!!!!!!!!
module DHT11_module (
    input  logic       clk,
    input  logic       reset,
    inout  tri         data,
    output logic [7:0] rh,
    output logic [7:0] t,
    output logic       w_finish_tick
);

  pullup (data);


  logic drive_low;
  assign data = drive_low ? 1'b0 : 1'bz;


  localparam logic [7:0] RH_BYTE = 8'hA5;
  localparam logic [7:0] T_BYTE = 8'h5A;
  localparam logic [7:0] CHKSUM = RH_BYTE + T_BYTE;


  //   localparam integer START_LOW_TIME = 18_000_000;  // 18ms
  //   localparam integer START_RELEASE = 20_000;  // 20~40us
  //   localparam integer RESP_LOW = 80_000;  // 80us
  //   localparam integer RESP_HIGH = 80_000;  // 80us
  //   localparam integer BIT_START_LOW = 50_000;  // 50us
  //   localparam integer BIT_ONE_HIGH = 70_000;  // “1” -> ~70us high
  //   localparam integer BIT_ZERO_HIGH = 26_000;  // “0” -> ~26us high

  // 시뮬 전용 타이밍 (100× 줄임)
  localparam integer START_LOW_TIME = 200_000;  // 0.2 ms (200 us)
  localparam integer START_RELEASE = 2_000;  // 2 us
  localparam integer RESP_LOW = 8_000;  // 8 us
  localparam integer RESP_HIGH = 8_000;  // 8 us
  localparam integer BIT_START_LOW = 5_000;  // 5 us
  localparam integer BIT_ONE_HIGH = 7_000;  // 7 us
  localparam integer BIT_ZERO_HIGH = 2_600;  // 2.6 us

  logic [39:0] data_bits;
  int i;

  initial begin
    rh            = RH_BYTE;
    t             = T_BYTE;
    w_finish_tick = 1'b0;
    drive_low     = 1'b0;
    // MSB부터: humidity_int, humidity_dec, temp_int, temp_dec, checksum
    data_bits     = {RH_BYTE, 8'h00, T_BYTE, 8'h00, CHKSUM};
  end


  always @(negedge reset) begin

    #100_000;
    forever begin
      #START_LOW_TIME;
      #START_RELEASE;

      drive_low = 1;
      #RESP_LOW;
      drive_low = 0;
      #RESP_HIGH;

      for (i = 39; i >= 0; i = i - 1) begin

        drive_low = 1;
        #BIT_START_LOW;
        drive_low = 0;

        if (data_bits[i]) #BIT_ONE_HIGH;
        else #BIT_ZERO_HIGH;
      end


      w_finish_tick = 1'b1;
      #100_000;  // 잠시 유지
      w_finish_tick = 1'b0;


      //   #1_000_000;
      #10_000;  // 시뮬레이션용

    end
  end

endmodule


module tb_DHT11_notUVMst;

  logic       PCLK;
  logic       PRESET;
  // APB Interface Signals
  logic [3:0] PADDR;

  
  localparam logic [7:0] RH_BYTE = 8'hA5;
  localparam logic [7:0] T_BYTE  = 8'h5A;



  //   localparam integer BIT_START_LOW = 50_000;
  //   localparam integer BIT_ZERO_HIGH = 26_000;  // “0” -> ~26us high
  //   localparam integer BIT_ONE_HIGH = 70_000;  // “1” -> ~70us high

  localparam integer BIT_START_LOW = 5_000;  //  5 us
  localparam integer BIT_ZERO_HIGH = 2_600;  //  2.6 us
  localparam integer BIT_ONE_HIGH = 7_000;  //  7 us

  logic [31:0] PWDATA;
  logic        PWRITE;
  logic        PENABLE;
  logic        PSEL;
  logic [31:0] PRDATA;
  logic        PREADY;

  wire         DATA_IO;

  // 시뮬레이션용
  logic [ 7:0] sim_rh;
  logic [ 7:0] sim_t;
  logic        sim_finish;

  localparam logic [39:0] tb_expected = {8'hA5, 8'h00, 8'h5A, 8'h00, (8'hA5 + 8'h5A)};
  logic [39:0] tb_captured;
  int          tb_bitcnt;


  DHT11_Periph DUT (
      .PCLK      (PCLK),
      .PRESET    (PRESET),
      .PADDR     (PADDR),
      .PWDATA    (PWDATA),
      .PWRITE    (PWRITE),
      .PENABLE   (PENABLE),
      .PSEL      (PSEL),
      .PRDATA    (PRDATA),
      .PREADY    (PREADY),
      .DATA_IO   (DATA_IO),
      .sim_rh    (sim_rh),
      .sim_t     (sim_t),
      .sim_finish(sim_finish)
  );

  initial begin
    PCLK = 0;
    forever #5 PCLK = ~PCLK;
  end

  initial begin
    PRESET = 1;
    #20;
    PRESET = 0;
  end

  // APB Interface Signals 초기화
  initial begin
    PSEL    = 0;
    PENABLE = 0;
    PWRITE  = 0;
    PADDR   = 4'h0;
    PWDATA  = 32'h0;
  end


  int handshake_cnt;

  initial begin
    tb_bitcnt     = 0;
    handshake_cnt = 0;
  end


  always @(posedge DATA_IO) begin
    if (handshake_cnt < 2) begin
      handshake_cnt++;
    end else if (tb_bitcnt < 40) begin
      #((BIT_ZERO_HIGH + BIT_ONE_HIGH) / 2);
      //   tb_captured[tb_bitcnt] = DATA_IO;
      tb_captured[39-tb_bitcnt] = DATA_IO;  // 해결
      tb_bitcnt++;
    end
  end


  // APB read
  task automatic apb_read(input logic [3:0] addr);
    begin
      @(negedge PCLK);
      PADDR   = addr;
      PWRITE  = 1'b0; // read 모드
      PSEL    = 1'b1;
      PENABLE = 1'b0;
      @(negedge PCLK);
      PENABLE = 1'b1;
      wait (PREADY);
      @(negedge PCLK);
      $display("[time=%0t] READ @ 0x%0h -> PRDATA=0x%0h  (rh=0x%0h, t=0x%0h, finish=%b)", $time,
               addr, PRDATA, sim_rh, sim_t, sim_finish);
      // 종료
      PSEL    = 1'b0;
      PENABLE = 1'b0;
      @(negedge PCLK);
    end
  endtask

  // 시나리오
//   initial begin
//     @(negedge PRESET);
//     #20;

//     apb_read(4'h0);  // RH 레지스터 읽기
//     apb_read(4'h4);  // T 레지스터 읽기
//     apb_read(4'h8);  // finish 읽기

//     // 40비트 모두 캡처될 때까지 대기
//     wait (tb_bitcnt == 40);

//     if (tb_captured !== tb_expected) begin
//       $error("DHT11 protocol mismatch! expected=%h, got=%h", tb_expected, tb_captured);
//     end else begin
//       //   $display(">> DHT11 40-bit transfer OK !! (%h)", tb_captured);
//       $display(
//           ">>> DHT11 sensor read complete! Humidity=0x%0h, Temperature=0x%0h, tb_captured=0x%010h, Checksum OK",
//           tb_captured[39:32], tb_captured[23:16], tb_captured);
//     end


//     #50;
//     $finish;
//   end

// 시나리오
    initial begin
        @(negedge PRESET);
        #20;

        // 1. RH read
        apb_read(4'h0);
        if (sim_rh !== RH_BYTE) begin
            $error("RH register mismatch! expected=0x%0h, got=0x%0h", RH_BYTE, sim_rh);
        end else begin
            $display(">> RH register OK: 0x%0h", sim_rh);
        end

        // 2. T read
        apb_read(4'h4);
        if (sim_t !== T_BYTE) begin
            $error("T  register mismatch! expected=0x%0h, got=0x%0h", T_BYTE, sim_t);
        end else begin
            $display(">> T  register OK: 0x%0h", sim_t);
        end

        // 3. 최종
        wait (tb_bitcnt == 40);
        if (tb_captured !== tb_expected) begin
            $error("DHT11 protocol mismatch! expected=0x%010h, got=0x%010h",
                   tb_expected, tb_captured);
        end else begin
            $display(">> DHT11 full read OK!");
            $display("Humidity   = 0x%0h", tb_captured[39:32]);
            $display("Temperature= 0x%0h", tb_captured[23:16]);
            $display("tb_captured= 0x%010h", tb_captured);
        end

        #50;
        $finish;
    end

endmodule
