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
//    kc705_clk: KC705 clock buffers and DCM
// ----------------------------------------------------------------------

`default_nettype none

module kc705_clk
  ( // Clock inputs
    input wire  CLK125P, CLK125N, CLK200P, CLK200N,
    input wire  CLK156P, CLK156N,

    // Clock outputs
    output wire CLK50, CLK100, CLK200,
    output wire GTREFCLK125, GTREFCLK156,

    output wire DCM_LOCKED
    );    

   // ------------------------------------------------------------
   // GT Reference clock
   IBUFDS clk156_buf ( .I(CLK156P), .IB(CLK156N), .O(GTREFCLK156) );
   IBUFDS clk125_buf ( .I(CLK125P), .IB(CLK125N), .O(GTREFCLK125) );

   // ------------------------------------------------------------
   // Global clocks
   IBUFGDS clk200_buf ( .O(CLK200), .I(CLK200P), .IB(CLK200N) );

   reg [7:0]    DCM_RST_CNT;
   initial DCM_RST_CNT <= 0;
   always @ (posedge CLK200)
        if (DCM_RST_CNT != 8'hff) DCM_RST_CNT <= DCM_RST_CNT + 1;
   
   wire         DCM_RST = DCM_RST_CNT != 8'hff;
   
   clk_200_50_100 dcm1
             ( .clk_in1(CLK200), .clk_out1(CLK50), .clk_out2(CLK100),
               .reset(DCM_RST), .locked(DCM_LOCKED) );

endmodule // kc705_clk

`default_nettype wire
