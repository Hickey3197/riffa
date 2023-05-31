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
//    tb: loopback testbench for KC705 aurora-dual
// ----------------------------------------------------------------------

`timescale 1ns/1ps

module tb();
   reg  CLK125i, CLK156i, CLK200i, CLK250;

   initial CLK125i<=1;  always # (4.0) CLK125i<=~CLK125i;
   initial CLK156i<=1;  always # (3.2) CLK156i<=~CLK156i;
   initial CLK200i<=1;  always # (2.5) CLK200i<=~CLK200i;
   initial CLK250 <=1;  always # (2.0) CLK250 <=~CLK250 ;

   wire CLK50, CLK100, CLK125, CLK200, GTREFCLK156;
   wire DCM_LOCKED;
   
   kc705_clk clkmg
      ( // Clock inputs
        .CLK125P(CLK125i), .CLK125N(~CLK125i),
        .CLK200P(CLK200i), .CLK200N(~CLK200i),
        .CLK156P(CLK156i), .CLK156N(~CLK156i),

        // Output signals
        .CLK50 (CLK50 ), .CLK100(CLK100),
        .CLK125(CLK125), .CLK200(CLK200),
        .GTREFCLK156(GTREFCLK156),
        .DCM_LOCKED (DCM_LOCKED)
       );
   
   reg  RST;
   wire SMA_TXP, SMA_TXN, SFP_TXP, SFP_TXN;
   wire [1:0] CH_UP;
   
   aurora_dual uut
     ( // Clock + reset inputs
       .CLK250 (CLK250),
       .SYS_RST(RST),
       .PE_RST ({RST, RST}), // SMA_PE_RST, SFP_PE_RST
       .CLK50  (CLK50),
       .CLK100 (CLK100),
       .GTREFCLK156(GTREFCLK156),
       .DCM_LOCKED (DCM_LOCKED ),

       .SMA_TXP(SMA_TXP), .SMA_TXN(SMA_TXN),
       .SFP_TXP(SFP_TXP), .SFP_TXN(SFP_TXN),
       .SMA_RXP(SMA_TXP), .SMA_RXN(SMA_TXN),
       .SFP_RXP(SFP_TXP), .SFP_RXN(SFP_TXN),

       .SMA_D      (),  .SFP_D      (),
       .SMA_Q      (),  .SFP_Q      (),
       .SMA_D_VALID(0), .SFP_D_VALID(0),
       .SMA_Q_VALID(),  .SFP_Q_VALID(),
       .SMA_D_BP   (),  .SFP_D_BP   (),
       .SMA_Q_BP   (0), .SFP_Q_BP   (0),

       .CH_UP(CH_UP)
       );
   
/* -----\/----- EXCLUDED -----\/-----
   initial begin
      $shm_open();
      $shm_probe("SA");
   end   
 -----/\----- EXCLUDED -----/\----- */

   // DCM lock detector
   reg        DCM_LOCKED_R = 0;
   always @ (posedge CLK250) begin
      DCM_LOCKED_R <= DCM_LOCKED;
      if (~DCM_LOCKED_R & DCM_LOCKED)
        $display("DCM locked at %f", $time);
   end


   // Channel up detector

   reg [1:0]  CH_UP_R = 0;
   reg [1:0]  CH_OK = 0;
   always @ (posedge CLK250) begin
      CH_UP_R <= CH_UP;
      if (~CH_UP_R[0] & CH_UP[0]) begin
         $display("SMA went UP at %f", $time);
         CH_OK[0] <= 1;
      end
      if (~CH_UP_R[1] & CH_UP[1]) begin
         $display("SFP went UP at %f", $time);
         CH_OK[1] <= 1;
      end
      if (CH_OK == 2'b11) begin
         #1000 $finish;
      end
   end
   
   initial begin
       RST <= 1;

       #(110.1)
       RST <= 0;
       
      #(10000000)
      $finish;
   end
   
endmodule // tb
