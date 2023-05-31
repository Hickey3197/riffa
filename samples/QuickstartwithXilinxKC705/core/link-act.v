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
//    link_act:    LINK/ACT-like LED indicator
//    link_act_tb: Simple testbench
// ----------------------------------------------------------------------

`default_nettype none
module link_act
  ( input wire CLK, RST,
    input wire  LINK, ACT,
    output wire LED
   );

   parameter BlinkBits = 26;
   reg [BlinkBits-1:0]   BLINK_TIMER;
   reg [BlinkBits  :0]   ACT_TIMER;
   
   always @ (posedge CLK) begin
      if (RST) begin
         BLINK_TIMER <= 0;
         ACT_TIMER <= 0;
      end else begin

         // ACT state machine
         if (ACT_TIMER==0) begin
            if (ACT) ACT_TIMER <= 1;
         end else begin
            ACT_TIMER <= ACT ? 1 : ACT_TIMER+1;
         end

         // Blink timer control
         if (ACT_TIMER==0) 
           BLINK_TIMER <= 0;
         else
           BLINK_TIMER <= BLINK_TIMER+1;
      end
   end
   
   assign LED = (ACT_TIMER==0) ? LINK : BLINK_TIMER[BlinkBits-1];
endmodule // link_act

`ifdef USE_LINK_ACT_TB
module link_act_tb();
   parameter real Step=10;
   
   reg CLK, RST, LINK, ACT;

   initial CLK <= 1;
   always #(Step/2) CLK <= ~CLK;

   defparam uut.BlinkBits = 3;
   link_act uut (.CLK(CLK), .RST(RST), .LINK(LINK), .ACT(ACT), .LED());

   initial begin
      $shm_open();
      $shm_probe("SA");
      RST <= 1;
      ACT <= 0;
      LINK <= 0;

      #(10.1*Step)
      RST <= 0;

      #(500*Step) LINK <= 1;
      #(100*Step) LINK <= 0;
      #(  1*Step) LINK <= 1;
      
      #(500*Step) ACT <= 1;
      #(  1*Step) ACT <= 0;
      
      #(500*Step) ACT <= 1;
      #(  1*Step) ACT <= 0;
      #( 10*Step) ACT <= 1;
      #(  1*Step) ACT <= 0;

      #(500*Step) $finish;
   end
   
endmodule // link_act_tb
`endif

`default_nettype wire
