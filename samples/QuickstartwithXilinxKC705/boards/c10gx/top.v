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
//    top: a top-level module for Intel Cyclone 10 GX Development Board
// ----------------------------------------------------------------------

`default_nettype none

module top
  ( input wire        CLK100,
    input wire        PCIE_RESET_N,
    input wire        PCIE_REFCLK,
     
    input wire [3:0]  PCIE_RX,
    output wire [3:0] PCIE_TX,

    output wire [3:0] LED
   );

   // ------------------------------------------------------------

   wire              CLK, RST;

   wire [1:0]        PCI_D_BP,    PCI_Q_BP;
   wire [1:0]         PCI_D_VALID, PCI_Q_VALID;
   wire [127:0]       PCI_D,       PCI_Q;

   pcie_port # ( .C_NUM_LANES(4)) pci
     ( .PCIE_RESET_N(PCIE_RESET_N),
       .PCIE_REFCLK (PCIE_REFCLK),
     
       .PCIE_RX(PCIE_RX),
       .PCIE_TX(PCIE_TX),

       .CLK_OUT(CLK), .RST_OUT(RST),

       .D(PCI_D), .D_BP(PCI_D_BP), .D_VALID(PCI_D_VALID),   // O
       .Q(PCI_Q), .Q_BP(PCI_Q_BP), .Q_VALID(PCI_Q_VALID) ); // I


   // ------------------------------------------------------------
   // PR IP controller instance

   wire               CLK_ICAP;
   icap_dcm dcm0
     ( .rst (RST),
       .refclk(CLK100),
       .locked(),
       .outclk_0 (CLK_ICAP) ); // 33.3MHz
   
   wire               PR_FREEZE;
   wire [63:0]        ICAP_D, ICAP_Q;
   wire               ICAP_D_VALID, ICAP_D_BP, ICAP_Q_VALID, ICAP_Q_BP;

   pe_icap icap
     ( .CLK     (CLK),          // I
       .CLK_PR  (CLK_ICAP),     // I
       .RST     (RST),          // I
       .FREEZE  (PR_FREEZE),    // O
       .D_VALID (ICAP_D_VALID), // I
       .D       (ICAP_D),       // I [63:0]
       .D_BP    (ICAP_D_BP),
       .Q_VALID (ICAP_Q_VALID), 
       .Q       (ICAP_Q),
       .Q_BP    (ICAP_Q_BP) );
   
   // ------------------------------------------------------------
   // PE instance

   wire               PE_RST;
   wire [127:0]        PE_D, PE_Q;
   wire [1:0]          PE_D_VALID, PE_Q_VALID, PE_D_BP, PE_Q_BP,
                       PE_Q_VALIDi;
   
   pe pe
     ( .CLK(CLK), .SYS_RST(RST), .PE_RST(PE_RST),
       .D (PE_D[ 63: 0]), .D_VALID (PE_D_VALID [0]), .D_BP (PE_D_BP[0]),
       .Q (PE_Q[ 63: 0]), .Q_VALID (PE_Q_VALIDi[0]), .Q_BP (PE_Q_BP[0]),
       .D2(PE_D[127:64]), .D2_VALID(PE_D_VALID [1]), .D2_BP(PE_D_BP[1]),
       .Q2(PE_Q[127:64]), .Q2_VALID(PE_Q_VALIDi[1]), .Q2_BP(PE_Q_BP[1]) );

   assign PE_Q_VALID = PR_FREEZE ? 0 : PE_Q_VALIDi;

   // ------------------------------------------------------------
   // Router instance

   // Port 4, 5 = PCIe
   // Port 3    = ICAP
   // Port 1, 2 = PE

   wire  [4:0] ROUTER_Q_SOF;
   
   defparam ro.NumPorts = 5;
   defparam ro.PassThrough = 5'b00111; // Note: PE_ICAP requires PT!
   router ro
     ( .CLK(CLK), .RST(RST),
       .D      ({PCI_D,       ICAP_Q,       PE_Q      }), // I
       .D_VALID({PCI_D_VALID, ICAP_Q_VALID, PE_Q_VALID}), // I
       .D_BP   ({PCI_D_BP,    ICAP_Q_BP,    PE_Q_BP   }), // O
       
       .Q      ({PCI_Q,       ICAP_D,       PE_D      }), // O
       .Q_VALID({PCI_Q_VALID, ICAP_D_VALID, PE_D_VALID}), // O
       .Q_BP   ({PCI_Q_BP,    ICAP_D_BP,    PE_D_BP   }), // I
       .Q_SOF  (ROUTER_Q_SOF) ); // O: to generate PE_RST

   assign PE_RST      = ROUTER_Q_SOF[0];
   //assign ICAP_PE_RST = ROUTER_Q_SOF[2];

   // ------------------------------------------------------------
   // State LEDs

   // 0: PCIe Clock
   // 1: PCIe 0/1 
   // 2: 
   // 3: 

   wire [3:0] LED_LINK = { 2'b0,        // Not connected
                           2'b11 };     // PCIe is always up

   wire [3:0] LED_ACT  = { 2'b0,    // Not connected
                           PCI_D_VALID[1] | PCI_Q_VALID[1] |
                           PCI_D_VALID[0] | PCI_Q_VALID[0],
                           1'b1 };  // PCIe clock 

   generate
      genvar  i;
      for (i=0; i<4; i=i+1) begin : led_gen
         link_act led ( .CLK(CLK), .RST(RST), .LED(LED[i]), 
                        .LINK(LED_LINK[i]),   .ACT(LED_ACT[i])); 
      end
   endgenerate
   
endmodule // top

`default_nettype wire
  
