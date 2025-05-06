`timescale 1ns / 1ps

module APB_Master (
    // global signal
    input  logic        PCLK,
    input  logic        PRESET,
    // APB Interface Signals
    output logic [31:0] PADDR,
    output logic [31:0] PWDATA,
    output logic        PWRITE,
    output logic        PENABLE,
    output logic [15:0] PSEL,
    input  logic [31:0] PRDATA  [0:15],
    input  logic [15:0] PREADY,
    // Internal Interface Signals
    input  logic        transfer,        // trigger signal
    output logic        ready,
    input  logic [31:0] addr,
    input  logic [31:0] wdata,
    output logic [31:0] rdata,
    input  logic        write            // 1:write, 0:read
);
    logic [31:0] master_addr;
    logic        decoder_en;

    APB_Master_CU u_APB_Master_CU(.*);
    
    APB_Decoder U_APB_Decoder (
        .en (decoder_en),
        .sel(master_addr),
        .y  (PSEL)
    );

    APB_Mux U_APB_Mux (
        .sel  (master_addr),
        .d   (PRDATA),
        .r   (PREADY),
        .rdata(rdata),
        .ready(ready)
    );
endmodule

module APB_Master_CU (
    // global signal
    input  logic        PCLK,
    input  logic        PRESET,
    // APB Interface Signals
    output logic [31:0] PADDR,
    output logic [31:0] PWDATA,
    output logic        PWRITE,
    output logic        PENABLE,
    input  logic [31:0] PRDATA  [0:15],
    input  logic [15:0] PREADY,
    // Internal Interface Signals
    input  logic        transfer,        // trigger signal
    input  logic        ready,
    input  logic [31:0] addr,
    input  logic [31:0] wdata,
    input  logic        write,           // 1:write, 0:read

    output logic [31:0] master_addr,
    output logic        decoder_en
);
    logic [31:0] temp_addr_next, temp_addr_reg;
    logic [31:0] temp_wdata_next, temp_wdata_reg;
    logic temp_write_next, temp_write_reg;

    assign master_addr = temp_addr_reg;

    typedef enum bit [1:0] {
        IDLE,
        SETUP,
        ACCESS
    } apb_state_e;

    apb_state_e state, state_next;

    always_ff @(posedge PCLK, posedge PRESET) begin
        if (PRESET) begin
            state          <= IDLE;
            temp_addr_reg  <= 0;
            temp_wdata_reg <= 0;
            temp_write_reg <= 0;
        end else begin
            state          <= state_next;
            temp_addr_reg  <= temp_addr_next;
            temp_wdata_reg <= temp_wdata_next;
            temp_write_reg <= temp_write_next;
        end
    end

    always_comb begin
        state_next      = state;
        temp_addr_next  = temp_addr_reg;
        temp_wdata_next = temp_wdata_reg;
        temp_write_next = temp_write_reg;
        PADDR           = temp_addr_reg;
        PWDATA          = temp_wdata_reg;
        PWRITE          = 1'b0;
        PENABLE         = 1'b0;
        decoder_en      = 1'b0;
        case (state)
            IDLE: begin
                decoder_en = 1'b0;
                if (transfer) begin
                    state_next      = SETUP;
                    temp_addr_next  = addr;  
                    temp_wdata_next = wdata;
                    temp_write_next = write;
                end
            end
            SETUP: begin
                decoder_en = 1'b1;
                PENABLE    = 1'b0;
                PADDR      = temp_addr_reg;
                if (temp_write_reg) begin
                    PWRITE = 1'b1;
                    PWDATA = temp_wdata_reg;
                end else begin
                    PWRITE = 1'b0;
                end
                state_next = ACCESS;
            end
            ACCESS: begin
                decoder_en = 1'b1;
                PENABLE    = 1'b1;
                PADDR      = temp_addr_reg;
                if (temp_write_reg) begin
                    PWRITE = 1'b1;
                    PWDATA = temp_wdata_reg;
                end else begin
                    PWRITE = 1'b0;
                end
                if (ready) begin
                    state_next = IDLE;
                end
            end
        endcase
    end
endmodule

module APB_Decoder (
    input  logic        en,
    input  logic [31:0] sel,
    output logic [15:0] y
);
    always_comb begin
        y = 16'b0;
        if (en) begin
            casex (sel)
                32'h1000_0xxx: y[0]  = 1;
                32'h1000_1xxx: y[1]  = 1;
                32'h1000_2xxx: y[2]  = 1;
                32'h1000_3xxx: y[3]  = 1;
                32'h1000_4xxx: y[4]  = 1;
                32'h1000_5xxx: y[5]  = 1;
                32'h1000_6xxx: y[6]  = 1;
                32'h1000_7xxx: y[7]  = 1;
                32'h1000_8xxx: y[8]  = 1;
                32'h1000_9xxx: y[9]  = 1;
                32'h1000_axxx: y[10] = 1;
                32'h1000_bxxx: y[11] = 1;
                32'h1000_cxxx: y[12] = 1;
                32'h1000_dxxx: y[13] = 1;
                32'h1000_exxx: y[14] = 1;
                32'h1000_fxxx: y[15] = 1;
            endcase
        end
    end
endmodule

module APB_Mux (
    input  logic [31:0] sel,
    input  logic [31:0] d    [0:15],
    input  logic [15:0] r,
    output logic [31:0] rdata,
    output logic        ready
);

    always_comb begin
        rdata = 32'bx;
        casex (sel)
            32'h1000_0xxx: rdata = d[0];
            32'h1000_1xxx: rdata = d[1];
            32'h1000_2xxx: rdata = d[2];
            32'h1000_3xxx: rdata = d[3];
            32'h1000_4xxx: rdata = d[4];
            32'h1000_5xxx: rdata = d[5];
            32'h1000_6xxx: rdata = d[6];
            32'h1000_7xxx: rdata = d[7];
            32'h1000_8xxx: rdata = d[8];
            32'h1000_9xxx: rdata = d[9];
            32'h1000_axxx: rdata = d[10];
            32'h1000_bxxx: rdata = d[11];
            32'h1000_cxxx: rdata = d[12];
            32'h1000_dxxx: rdata = d[13];
            32'h1000_exxx: rdata = d[14];
            32'h1000_fxxx: rdata = d[15];
        endcase
    end

    always_comb begin
        ready = 1'b0;
        casex (sel)
            32'h1000_0xxx: ready = r[0];
            32'h1000_1xxx: ready = r[1];
            32'h1000_2xxx: ready = r[2];
            32'h1000_3xxx: ready = r[3];
            32'h1000_4xxx: ready = r[4];
            32'h1000_5xxx: ready = r[5];
            32'h1000_6xxx: ready = r[6];
            32'h1000_7xxx: ready = r[7];
            32'h1000_8xxx: ready = r[8];
            32'h1000_9xxx: ready = r[9];
            32'h1000_axxx: ready = r[10];
            32'h1000_bxxx: ready = r[11];
            32'h1000_cxxx: ready = r[12];
            32'h1000_dxxx: ready = r[13];
            32'h1000_exxx: ready = r[14];
            32'h1000_fxxx: ready = r[15];
        endcase
    end
endmodule
