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
//    ku_aurora_boot: Kintex Ultrascale Aurora 64b66b bootup controller
// ----------------------------------------------------------------------

`default_nettype none

module ku_aurora_boot
  ( input wire CLK100,
    input wire DCM_LOCKED,
    output reg PMA_INIT, RESET_PB
    );
   
   // ------------------------------
   // DCM_RST -> PMA_INIT

   reg [7:0]        PMA_INIT_CNT;

   initial PMA_INIT <= 1;
   initial RESET_PB <= 1;
   
   always @ (posedge CLK100) begin
      if (~DCM_LOCKED) PMA_INIT_CNT <= 0;
      else PMA_INIT_CNT <= PMA_INIT_CNT + ((~&PMA_INIT_CNT) ? 1 : 0);
      
      case (PMA_INIT_CNT)
        //        500:  RESET_PB <= 1;
        //        1000: PMA_INIT <= 1;
        100: PMA_INIT <= 0;
        200: RESET_PB <= 0;
      endcase // case (PMA_INIT_CNT)
   end // always @ (posedge CLK50)
   
endmodule // ku_aurora_boot

`default_nettype wire
