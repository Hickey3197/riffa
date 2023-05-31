// ----------------------------------------------------------------------
// "THE BEER-WARE LICENSE" (Revision 42):
//    <yasu@prosou.nu> wrote this file. As long as you retain this
//    notice you can do whatever you want with this stuff. If we meet
//    some day, and you think this stuff is worth it, you can buy me a
//    beer in return Yasunori Osana at University of the Ryukyus,
//    Japan.
// ----------------------------------------------------------------------
// OpenFC project: an open FPGA accelerated cluster framework
// 
// Modules in this file:
//    fwft_64x512_32_async_afull: Xilinx compatible FIFO based on dcfifo
// ----------------------------------------------------------------------

`default_nettype none
`timescale 1ns/1ps

module fwft_64x512_32_async_afull
  ( 
    input wire         wr_clk, rd_clk, rst,
    input wire         rd_en, wr_en,
    output wire [31:0] dout,
    input wire [63:0]  din,
    output wire        empty,
    output wire        full,
    output reg         prog_full,
    output wire        valid
   );

   wire [8:0]          WRUSEDW;
   wire                WREMPTY;

   dcfifo_mixed_widths #
     ( .lpm_width   (64),  // same to data (input)
       .lpm_width_r (32),  // same to q (output)
       .lpm_numwords(512), // FIFO depth = 2^lpm_widthu
       .lpm_widthu  (9),   // width of wrusedw
       .lpm_widthu_r(10),  // width of rdusedw
       .delay_rdusedw(1),
       .delay_wrusedw(1),
       .rdsync_delaypipe(0),
       .wrsync_delaypipe(0),
       .lpm_showahead("ON"),
       .underflow_checking("ON"),
       .overflow_checking("ON"),
       .intended_device_family("arria10"),
       .clocks_are_synchronized("FALSE"), // because it's sync FIFO
       .use_eab("ON"),// on BRAM
       .lpm_type("dcfifo_mixed_widths")
       )
   fifo
     ( .data   ({din[31:0], din[63:32]}),
       .rdclk  (rd_clk),
       .wrclk  (wr_clk),
       .aclr   (rst),
       .rdreq  (rd_en),
       .wrreq  (wr_en),
       .eccstatus(),
       .rdfull (),
       .wrfull (full),
       .rdempty(empty),
       .wrempty(WREMPTY),
       .rdusedw(),
       .wrusedw(WRUSEDW),
       .q      (dout) );
   
   always @ (posedge wr_clk) begin
      prog_full <= ( WRUSEDW > 400 | (WRUSEDW==0 & ~WREMPTY) );
   end

   assign valid = ~empty; //  & rd_en;
endmodule // fifo_64x512_32_async_afull

`ifdef FIFO_COMPAT_TB_EN

module tb();
   parameter real Step = 10;
   parameter real RStep = 4;

   reg CLK = 1;
   always # (Step/2) CLK <= ~CLK;

   reg RCLK = 1;
   always # (RStep/2) RCLK <= ~RCLK;

   
   reg RST;
   
   initial begin
      $shm_open();
      $shm_probe("SA");
      RST <= 1;

      #(10.1*Step)
      RST <= 0;

      #(8000*Step)
      $finish;
   end

   // ------------------------------------------------------------
   // write control

   reg [31:0] WCNT;
   reg        WR_EN;

   always @ (posedge CLK) begin
      if (RST) begin
         WR_EN <= 0;
         WCNT <= 0;
      end else begin
         WCNT <= WCNT + 1;
         if (WCNT == 2000) WR_EN <= 1;
      end
   end
   
   // ------------------------------------------------------------
   // readout control
   
   reg [31:0] RCNT;
   reg        RD_EN;
   
   always @ (posedge RCLK) begin
     if (RST) begin
        RCNT <= 0;
        RD_EN <= 0;
     end else begin 
        RCNT <= RCNT+1;
        RD_EN <= (RCNT > 1000 & RCNT[3:0] ==0) ;
     end
   end

   
   wire FULL;
   reg [31:0] D, D1;
   
   always @ (posedge CLK) begin
      if (RST) begin
         D <= 0; D1 <= 1;
      end else begin
         if (~FULL) begin D <= D+2; D1 <= D1+2; end
      end
   end

   fwft_64x512_32_async_afull uut
     ( .wr_clk(CLK), .rst(RST), .rd_clk(RCLK),
       .rd_en(RD_EN), .wr_en(WR_EN),
       .dout(), .din({D, D1}),
       .full(FULL) );
   
endmodule

`endif


`default_nettype wire
