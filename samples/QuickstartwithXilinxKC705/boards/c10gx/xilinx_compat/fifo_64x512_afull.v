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
//    fifo_64x512_afull: Xilinx compatible FIFO based on scfifo
// ----------------------------------------------------------------------

`default_nettype none

module fifo_64x512_afull
  ( 
    input wire         clk, srst,
    input wire         rd_en, wr_en,
    output wire [63:0] dout,
    input wire [63:0]  din,
    output wire        empty,
    output wire        full,
    output wire        prog_full,
    output wire        valid
   );

   scfifo #
     ( .lpm_width(64),
       .lpm_numwords(512),
       .lpm_widthu(9),
       .almost_full_value(400),
//       .almost_full_value(4),
       .lpm_showahead("OFF"),
       .lpm_type("scfifo"),
       .overflow_checking("ON"),
       .underflow_checking("ON"),
       .use_eab("ON"), // on BRAM
       .add_ram_output_register("OFF")
      ) 
   fifo
     (
      .clock (clk),
      .data  (din),
      .rdreq (rd_en),
      .sclr  (srst),
      .aclr  (srst),
      .wrreq (wr_en),
      .empty (empty),
      .full  (full),
      .q     (dout),
      .almost_empty  (),
      .almost_full (prog_full)
      );

   reg                 VALIDi;
   always @ (posedge clk) VALIDi <= ~empty & rd_en;
   assign valid = VALIDi;
   
endmodule // fifo_64x512_afull

`default_nettype wire
