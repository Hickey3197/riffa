// ----------------------------------------------------------------------
// "THE BEER-WARE LICENSE" (Revision 42):
//    <yasu@prosou.nu> and <kaito@lut.eee.u-ryukyu.ac.jp> wrote this
//    file. As long as you retain this notice you can do whatever you
//    want with this stuff. If we meet wsome day, and you think this
//    stuff is worth it, you can buy me a beer in return Yasunori
//    Osana and Kaito Nadoyama at University of the Ryukyus, Japan.
// ----------------------------------------------------------------------
// OpenFC project: an open FPGA accelerated cluster framework
// 
// Modules in this file:
//    pe-icap: Partial reconfiguration controller with router interface,
//             for Intel Cyclone/Arria 10 GX
// ----------------------------------------------------------------------

`timescale 1ns/1ps
`default_nettype none

module pe_icap # ( parameter Device='hc10) // 'hc10 for C10, a10 for A10
  ( input wire CLK, CLK_PR, RST,
    output reg        FREEZE,
    input wire        D_VALID,
    input wire [63:0] D,
    output wire       D_BP,
    output reg [63:0] Q,
    output reg        Q_VALID,
    input wire        Q_BP );

   wire [31:0]       D32;
   wire              FIFO_VALID, FIFO_RE, FIFO_EMPTY;
   
   fwft_64x512_32_async_afull in_fifo
     ( .wr_clk    (CLK), 
       .rd_clk    (CLK_PR), 
       .rst       (RST),
       .wr_en     (D_VALID),
       .rd_en     (FIFO_RE), 
       .din       (D),
       .dout      (D32),
       .empty     (FIFO_EMPTY),
       .full      (),
       .prog_full (D_BP),
       .valid     (FIFO_VALID) );

   reg [3:0]         STAT; // Idle / Run

   reg RST_PR_async, RST_PR;
   reg [31:0] DW_TOGO;
   reg [3:0]  HDR_CNT;
   reg        IGNORE_LASTDW;

   wire PR_START = (STAT==2);
   wire PR_VALID;
   wire PR_READY, PR_READYi;
   wire [2:0] PR_STATUS;

/* -----\/----- EXCLUDED -----\/-----
   // performance counter
   reg [31:0] PERF_CNT    /-* synthesis preserve *-/;
   reg [3:0]  PERF_STAT;
   reg        OWATTA /-* synthesis preserve *-/; 
   always @ (posedge CLK_PR) begin
      OWATTA <= ~PERF_STAT[0] & STAT[0];
      PERF_STAT <= STAT;
      if (RST_PR) begin
         PERF_CNT <= 0;
      end else begin
         PERF_CNT <= STAT[0] ? 0 : PERF_CNT + 1;
      end
   end
 -----/\----- EXCLUDED -----/\----- */
   
   always @ (posedge CLK_PR) begin
      RST_PR <= RST_PR_async; RST_PR_async <= RST;
      if (RST_PR) begin
         STAT <= 'b01;
      end else begin
         case (STAT)
           'b01: begin // idle, OpenFC header [63:32]
              if (FIFO_VALID) begin
                 STAT <= 'b10;
                 HDR_CNT <= 2;
              end
           end
           
           'b10: begin // idle, OpenFC header [31:0] + ICAP header
              if (FIFO_VALID) begin
                 HDR_CNT <= HDR_CNT-1;
                 if (HDR_CNT==1) begin
                    DW_TOGO <= {2'b0, D32[31:2]} + {31'b0, |D32[1:0]};
                    IGNORE_LASTDW <= D32[2];
                    STAT <= 'b100;
                 end
              end
           end

           'b100: begin
              if (FIFO_VALID & PR_READY) begin
                 DW_TOGO <= DW_TOGO-1;
                 if (DW_TOGO==1) begin
                    if (IGNORE_LASTDW) STAT <= 'b1000; else STAT <= 'b01;
                 end
              end
           end

           'b1000: begin
              STAT <= 'b01;
           end

           default: STAT <= 'b01;
         endcase
      end
   end

   wire PR_ERROR = ( ( PR_STATUS==3'b001 ) |  // PR Error
                     ( PR_STATUS==3'b010 ) |  // CRC Error
                     ( PR_STATUS==3'b011 ) ); // Incompatible bitstream
   wire PR_DONE = ( PR_STATUS==3'b101); 

   // Just discard remaining bitsream on error and when it's done
   assign PR_READY = PR_READYi | PR_ERROR | PR_DONE; 
   assign PR_VALID = (STAT[2] & FIFO_VALID);

   assign FIFO_RE = PR_READY | ~STAT[2];

   wire FREEZE_PR;

   // Enable JTAG debug mode, No Avalon-MM interface, 32bit
   generate
      if (Device == 'hc10) begin : c10_pr_gen
         pr_ip u0 
           ( .clk        (CLK_PR),      // I
             .nreset     (~RST),        // I
             .pr_start   (PR_START),    // I
             .double_pr  (1'b0),        // I
             .freeze     (FREEZE_PR),   // O
             .status     (PR_STATUS),   // O [2:0]
             .data       (D32),         // I [31:0]
             .data_valid (PR_VALID),    // I
             .data_ready (PR_READYi) ); // O
      end // block: c10_pr_gen
     
      if (Device == 'ha10) begin : a10_pr_gen // Arria 10
         pr_ip u0 
           ( .clk        (CLK_PR),      // I
             .nreset     (~RST),        // I
             .pr_start   (PR_START),    // I
             .freeze     (FREEZE_PR),   // O
             .status     (PR_STATUS),   // O [2:0]
             .data       (D32),         // I [31:0]
             .data_valid (PR_VALID),    // I
             .data_ready (PR_READYi) ); // O
      end // block: a10_pr_gen
   endgenerate
      
   // ------------------------------------------------------------

   reg  FREEZE_PRi, PR_OKi;
   reg  FREEZE250_async, FREEZE250, FREEZE250r;
   reg  PR_OK250_async, PR_OK250;
   wire FREEZE_DONE = FREEZE250r & ~FREEZE250;
   
   always @ (posedge CLK_PR)  begin
      FREEZE_PRi <= (FREEZE_PR | (DW_TOGO != 0) );
      PR_OKi <= (PR_STATUS ==3'd5);
   end

   // FREEZE generator
   always @ (posedge CLK) begin
      FREEZE250 <= FREEZE250_async; FREEZE250_async <= FREEZE_PRi;
      FREEZE250r <= FREEZE250;
      
      if (RST) begin
         FREEZE <= 0;
      end else begin
         case (FREEZE)
           0: if (D_VALID) FREEZE <= 1;
           1: if (FREEZE_DONE) FREEZE <= 0;
         endcase
      end
   end

   // Reply packet generator
   reg [3:0] REP_STAT;
   always @ (posedge CLK) begin
      PR_OK250 <= PR_OK250_async; PR_OK250_async <= PR_OKi;

      if (RST) begin
         REP_STAT <= 'b1;
         Q_VALID <= 0;
         Q <= 0;
      end else begin
         case (REP_STAT)
           'b1: if (FREEZE_DONE) REP_STAT <= 'b10;

           'b10: begin // Len header
              Q <= 1;
              Q_VALID <= 1;
              REP_STAT <= 'b100; end

           'b100: begin // PR status
              Q <= {63'b0, PR_OK250};
              Q_VALID <= 1; 
              REP_STAT <= 'b1000; end

           'b1000: begin
              Q <= 0;
              Q_VALID <= 0;
              REP_STAT <= 'b1; end

           default: REP_STAT <= 'b1;
         endcase
      end
   end
endmodule

`ifdef PE_ICAP_TB_EN
module tb();
   parameter real Step100 = 10.0;
   parameter real Step = 100.0;

   reg            CLK100 = 1;
   always # (Step100/2) CLK100 <= ~CLK100;

   reg            RST;
   reg [31:0]     PR_ADDR;
   wire [63:0]    PR_DATA;

   assign PR_DATA = PR_ADDR == 32'h0000 ? 64'd4 :  // 4QW payload
                    //PR_ADDR == 32'h0001 ? {32'd21, 32'h1001} : // 21B RBF
                    PR_ADDR == 32'h0001 ? {32'd25, 32'h1001} : // 25B RBF
                    PR_ADDR == 32'h0002 ? 64'h1002 :
                    PR_ADDR == 32'h0003 ? 64'h1003 :
                    //PR_ADDR == 32'h0004 ? {8'hff, 56'h0000} : 64'hz; // 21B
                    PR_ADDR == 32'h0004 ? {40'h12345678_ab, 24'h0000} : 64'hz;
   
   initial begin
      $shm_open();
      $shm_probe("SA");

      RST <= 1;
      #(10.1*Step) RST <=0;
      #(10000*Step) $finish;
   end

   wire D_BP;
   reg [9:0] CNT;
   wire      CNT_FULL = &CNT;
   reg       VALID_TOGGLE;
   
   always @ (posedge CLK100) begin
      VALID_TOGGLE <= (($random() & 8'hff) < 30);
      if (RST) begin
         PR_ADDR <= 0;
         CNT <= 0;
      end else begin
         if (~CNT_FULL) CNT <= CNT+1;
         if ( CNT_FULL & VALID_TOGGLE & ~D_BP) PR_ADDR <= PR_ADDR+1;
      end
   end
   
   pe_icap uut
     ( .CLK    (CLK100),
       .CLK_PR (CLK100),
       .RST    (RST),
       .FREEZE (),
       .D_VALID( CNT_FULL & (PR_ADDR <= 4) & VALID_TOGGLE),
       .D      (PR_DATA),
       .D_BP(D_BP) );

endmodule // tb

`endif

`default_nettype wire
