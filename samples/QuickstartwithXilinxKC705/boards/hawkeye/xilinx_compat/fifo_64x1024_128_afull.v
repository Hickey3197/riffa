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
//    fifo_64x1024_128_afull: Xilinx compatible FIFO based on dcfifo
// ----------------------------------------------------------------------

`default_nettype none
`timescale 1ns/1ps

module fifo_64x1024_128_afull
  ( 
    input wire          clk, srst,
    input wire          rd_en, wr_en,
    output wire [127:0] dout,
    input wire [63:0]   din,
    output wire         empty,
    output wire         full,
    output reg          prog_full,
    output reg          valid
   );

   wire [9:0]          WRUSEDW;

   dcfifo_mixed_widths #
     ( .lpm_width(64),
       .lpm_numwords(1024),
       .lpm_widthu(10),
       .lpm_width_r(128),
       .lpm_widthu_r(9),
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
     ( .data (din),
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
       .q({dout[63:0], dout[127:64]}) );
   
   always @ (posedge clk) begin
      prog_full <= ( WRUSEDW > 800 | (WRUSEDW==0 & ~empty) );
      valid <= ~empty & rd_en;
   end
   
endmodule // fifo_64x1024_128_afull

`ifdef FIFO_COMPAT_TB_EN

module tb();
   parameter real Step = 10;

   reg CLK = 1;
   always # (Step/2) CLK <= ~CLK;

   reg RST, RE;
   
   initial begin
      $shm_open();
      $shm_probe("SA");
      RST <= 1;
      RE <= 0;

      #(10.1*Step)
      RST <= 0;

      #(1500*Step)
      RE <= 1;
      
      
      #(1500*Step)
      $finish;
   end

   wire FULL;
   reg [63:0] D;
   
   always @ (posedge CLK) begin
      if (RST) begin
         D <= 0; 
      end else begin
         if (~FULL) begin D <= D+1; end
      end
   end

   fifo_64x1024_128_afull uut
     ( .clk(CLK), .srst(RST),
       .rd_en(RE), .wr_en(1),
       .dout(), .din(D),
       .full(FULL) );
   
endmodule

`endif


`default_nettype wire
