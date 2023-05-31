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
//    ICAPE2: ICAPE3 wrapper for Xilinx Ultrascale FPGAs
// ----------------------------------------------------------------------

`default_nettype none

module ICAPE2 #
  (parameter DEVICE_ID=123, ICAP_WIDTH=32 )
  (
   output wire [31:0] O,
   input wire         CLK,
   input wire         CSIB,
   input wire [31:0]  I,
   input wire         RDWRB
   );

   wire               AVAIL, PRDONE, PRERROR;

  ICAPE3 #
    ( .DEVICE_ID(32'h03628093),     // for simulation
      .ICAP_AUTO_SWITCH("DISABLE"), // Enable switch ICAP using sync word
      .SIM_CFG_FILE_NAME("NONE")    // for simulation
      )
   ICAPE3_inst 
     ( .AVAIL  (AVAIL),   // O      : Availability status of ICAP
       .O      (O),       // O[31:0]: Configuration data output bus
       .PRDONE (PRDONE),  // O      : Indicates completion of PR
       .PRERROR(PRERROR), // O      : Indicates Error during PR
       .CLK    (CLK),     // I      : Clock input
       .CSIB   (CSIB),    // I      : Active-Low ICAP enable
       .I      (I),       // I[31:0]: Configuration data input bus
       .RDWRB  (RDWRB)    // I      : Read/Write Select input
       );

endmodule // ICAPE2

`default_nettype wire
