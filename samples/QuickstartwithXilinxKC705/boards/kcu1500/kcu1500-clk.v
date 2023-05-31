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
//    kcu1500_clk: KCU1500 clock buffers and DCM
// ----------------------------------------------------------------------

`default_nettype none

module kcu1500_clk
  ( // Clock inputs
    input wire  CLK300P, CLK300N,

    // Clock outputs
    output wire CLK100,

    output wire DCM_LOCKED
    );

   // ------------------------------------------------------------
   // Global clocks

   wire         CLK300;
   IBUFGDS clk300_buf ( .O(CLK300), .I(CLK300P), .IB(CLK300N) );

   reg [7:0]    DCM_RST_CNT;
   initial DCM_RST_CNT <= 0;
   always @ (posedge CLK300)
        if (DCM_RST_CNT != 8'hff) DCM_RST_CNT <= DCM_RST_CNT + 1;

   wire         DCM_RST = DCM_RST_CNT != 8'hff;

   clk_300_100 dcm1
             ( .clk_in1  (CLK300),
               .clk_out1 (CLK100),
               .reset    (DCM_RST), .locked(DCM_LOCKED) );

endmodule // kcu1500_clk

`default_nettype wire
