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
//    fifo_128x512_64_afull: Xilinx compatible FIFO based on dcfifo
// ----------------------------------------------------------------------

`default_nettype none
`timescale 1ns/1ps

module fifo_128x512_64_afull
  ( 
    input wire         clk, srst,
    input wire         rd_en, wr_en,
    output wire [63:0] dout,
    input wire [127:0]  din,
    output wire        empty,
    output wire        full,
    output reg        prog_full,
    output reg        valid
   );

   wire [8:0]          WRUSEDW;

   dcfifo_mixed_widths #
     ( .lpm_width(128),
       .lpm_numwords(512),
       .lpm_widthu(9),
       .lpm_width_r(64),
       .lpm_widthu_r(10),
       .delay_rdusedw(1),
       .delay_wrusedw(1),
       .rdsync_delaypipe(0),
       .wrsync_delaypipe(0),
       .lpm_showahead("OFF"),
       .underflow_checking("ON"),
       .overflow_checking("ON"),
       .intended_device_family("arria10"),
       .clocks_are_synchronized("TRUE"), // because it's sync FIFO
       .use_eab("ON"),// on BRAM
       .lpm_type("dcfifo_mixed_widths")
       )
   fifo
     ( .data ({din[63:0], din[127:64]}),
       .rdclk(clk),
       .wrclk(clk),
       .aclr(srst),
       .rdreq(rd_en),
       .wrreq(wr_en),
       .eccstatus(),
       .rdfull(),
       .wrfull(full),
       .rdempty(empty),
       .wrempty(),
       .rdusedw(),
       .wrusedw(WRUSEDW),
       .q(dout) );
   
   always @ (posedge clk) begin
      prog_full <= ( WRUSEDW > 400 | (WRUSEDW==0 & ~empty) );
      valid <= ~empty & rd_en;
   end
   
endmodule // fifo_128x512_64_afull

`ifdef FIFO_COMPAT_TB_EN

module tb();
   parameter real Step = 10;

   reg CLK = 1;
   always # (Step/2) CLK <= ~CLK;

   reg RST;
   
   initial begin
      $shm_open();
      $shm_probe("SA");
      RST <= 1;

      #(10.1*Step)
      RST <= 0;

      #(1500*Step)
      $finish;
   end

   wire FULL;
   reg [63:0] D, D1;
   
   always @ (posedge CLK) begin
      if (RST) begin
         D <= 0; D1 <= 1;
      end else begin
         if (~FULL) begin D <= D+2; D1 <= D1+2; end
      end
   end

   fifo_128x512_64_afull uut
     ( .clk(CLK), .srst(RST),
       .rd_en(1), .wr_en(1),
       .dout(), .din({D, D1}),
       .full(FULL) );
   
endmodule

`endif


`default_nettype wire
