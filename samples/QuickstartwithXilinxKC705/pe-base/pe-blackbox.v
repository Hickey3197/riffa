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
//    pe(_blackbox): a blackbox PE for PR base design
// ----------------------------------------------------------------------

`default_nettype none

module pe
   (
    input wire         CLK, SYS_RST,
    input wire         PE_RST,

    output wire        D_BP,    D2_BP,
    input wire [63:0]  D,       D2,
    input wire         D_VALID, D2_VALID,

    input wire         Q_BP,    Q2_BP,
    output wire [63:0] Q,       Q2,
    output wire        Q_VALID, Q2_VALID
   );

endmodule // pe

`default_nettype wire
