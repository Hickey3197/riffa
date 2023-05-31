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
//    top: a top-level module for Xilinx KC705 board
// ----------------------------------------------------------------------

`default_nettype none

module top
  ( // Clock signals
    input wire        CLK125P, CLK125N, CLK200P, CLK200N,
    input wire        CLK156P, CLK156N,

    // PCIe signals
    input wire        PCIE_RESET_N, PCIE_REFCLK_P, PCIE_REFCLK_N,
    input wire [7:0]  PCIE_RXP, PCIE_RXN,
    output wire [7:0] PCIE_TXP, PCIE_TXN,

    // SerDes channels: SMA and SFP
    output wire       SMA_TXP, SMA_TXN,
    input wire        SMA_RXP, SMA_RXN,
    output wire       SFP_TXP, SFP_TXN,
    input wire        SFP_RXP, SFP_RXN,

    // State LEDs
    output wire [7:0] LED
    );

   // ------------------------------------------------------------
   // Clock managers

   wire               CLK50, CLK100, CLK200, GTREFCLK156;
   wire               DCM_LOCKED;

   kc705_clk cm
     ( .CLK200P(CLK200P), .CLK200N(CLK200N), // I 
       .CLK156P(CLK156P), .CLK156N(CLK156N), // I

       .CLK50(CLK50),     .CLK100(CLK100),  .CLK200(CLK200), // O
       .GTREFCLK156(GTREFCLK156), // O
       .DCM_LOCKED(DCM_LOCKED) // O
    );    

   // ------------------------------------------------------------
   // PCIe interface 
   
   wire               CLK, RST;
   
   wire [1:0]         PCI_D_BP,    PCI_Q_BP;
   wire [1:0]         PCI_D_VALID, PCI_Q_VALID;
   wire [127:0]       PCI_D,       PCI_Q;
   
   pcie_port pci
     ( .PCIE_RESET_N(PCIE_RESET_N),
       .PCIE_REFCLK_P(PCIE_REFCLK_P),
       .PCIE_REFCLK_N(PCIE_REFCLK_N),

       .PCIE_RXP(PCIE_RXP), .PCIE_RXN(PCIE_RXN),
       .PCIE_TXP(PCIE_TXP), .PCIE_TXN(PCIE_TXN),

       .CLK_OUT(CLK), .RST_OUT(RST),
       
       .D(PCI_D), .D_BP(PCI_D_BP), .D_VALID(PCI_D_VALID),   // O
       .Q(PCI_Q), .Q_BP(PCI_Q_BP), .Q_VALID(PCI_Q_VALID) ); // I
   
   // ------------------------------------------------------------
   // Aurora interface

   wire               SMA_PE_RST, SFP_PE_RST;              
   wire [1:0]         CH_UP;

   wire [127:0]       GT_D, GT_Q;
   wire [1:0]         GT_D_VALID, GT_Q_VALID, GT_D_BP, GT_Q_BP;
   
   aurora_dual au
     ( .CLK250(CLK),  .SYS_RST(RST), .PE_RST({SMA_PE_RST, SFP_PE_RST}),
       .CLK50(CLK50), .CLK100(CLK100),
       .GTREFCLK156(GTREFCLK156),
       .DCM_LOCKED (DCM_LOCKED),

       .SMA_TXP(SMA_TXP), .SMA_TXN(SMA_TXN),
       .SMA_RXP(SMA_RXP), .SMA_RXN(SMA_RXN),
       .SFP_TXP(SFP_TXP), .SFP_TXN(SFP_TXN),
       .SFP_RXP(SFP_RXP), .SFP_RXN(SFP_RXN),

       .SMA_D      (GT_D[63:0]),    .SMA_Q(GT_Q[63:0]),
       .SMA_D_VALID(GT_D_VALID[0]), .SMA_D_BP(GT_D_BP[0]),
       .SMA_Q_VALID(GT_Q_VALID[0]), .SMA_Q_BP(GT_Q_BP[0]),
       .SFP_D      (GT_D[127:64]),  .SFP_Q(GT_Q[127:64]), 
       .SFP_D_VALID(GT_D_VALID[1]), .SFP_D_BP(GT_D_BP[1]),
       .SFP_Q_VALID(GT_Q_VALID[1]), .SFP_Q_BP(GT_Q_BP[1]),

       .CH_UP(CH_UP) );

   // ------------------------------------------------------------
   // ICAP instance
   wire               ICAP_PE_RST;
   wire [63:0]        ICAP_D, ICAP_Q;
   wire               ICAP_D_VALID, ICAP_Q_VALID, ICAP_D_BP, ICAP_Q_BP;
   wire               ICAP_BUSY;
   
   pe_icap icap
     ( .CLK250(CLK), .CLK100(CLK100), .SYS_RST(RST), .PE_RST(ICAP_PE_RST),
       .D(ICAP_D), .D_VALID(ICAP_D_VALID), .D_BP(ICAP_D_BP),
       .Q(ICAP_Q), .Q_VALID(ICAP_Q_VALID), .Q_BP(ICAP_Q_BP),
       .BUSY(ICAP_BUSY) );

   // ------------------------------------------------------------
   // PE instance

   wire               PE_RST;
   wire [127:0]        PE_D, PE_Q;
   wire [1:0]          PE_D_VALID, PE_Q_VALID, PE_D_BP, PE_Q_BP,
                       PE_Q_VALIDi;
   
   pe pe
     ( .CLK(CLK), .SYS_RST(RST),.PE_RST (PE_RST),
       .D (PE_D[ 63: 0]), .D_VALID (PE_D_VALID [0]), .D_BP (PE_D_BP[0]),
       .Q (PE_Q[ 63: 0]), .Q_VALID (PE_Q_VALIDi[0]), .Q_BP (PE_Q_BP[0]),
       .D2(PE_D[127:64]), .D2_VALID(PE_D_VALID [1]), .D2_BP(PE_D_BP[1]),
       .Q2(PE_Q[127:64]), .Q2_VALID(PE_Q_VALIDi[1]), .Q2_BP(PE_Q_BP[1]) );

   assign PE_Q_VALID = ICAP_BUSY ? 0 : PE_Q_VALIDi;
   
   // ------------------------------------------------------------
   // Router instance

   // Port 6, 7 = PCIe
   // Port 4, 5 = SMA, SFP
   // Port    3 = ICAP
   // Port 1, 2 = PE

   wire  [6:0] ROUTER_Q_SOF;
   
   defparam ro.NumPorts = 7;
   defparam ro.PassThrough = 7'b0000111; // Note: PE_ICAP requires PT!
   router ro
     ( .CLK(CLK), .RST(RST),
       .D      ({PCI_D,       GT_Q,       ICAP_Q,       PE_Q      }), // I
       .D_VALID({PCI_D_VALID, GT_Q_VALID, ICAP_Q_VALID, PE_Q_VALID}), // I
       .D_BP   ({PCI_D_BP,    GT_Q_BP,    ICAP_Q_BP,    PE_Q_BP   }), // O
       
       .Q      ({PCI_Q,       GT_D,       ICAP_D,       PE_D      }), // O
       .Q_VALID({PCI_Q_VALID, GT_D_VALID, ICAP_D_VALID, PE_D_VALID}), // O
       .Q_BP   ({PCI_Q_BP,    GT_D_BP,    ICAP_D_BP,    PE_D_BP   }), // I
       .Q_SOF  (ROUTER_Q_SOF) ); // O: to generate PE_RST

   assign PE_RST      = ROUTER_Q_SOF[0];
   assign ICAP_PE_RST = ROUTER_Q_SOF[2];
   assign SMA_PE_RST  = 0;
   assign SFP_PE_RST  = 0;

   // ------------------------------------------------------------
   // State LEDs

   // 0: PCIe Clock    4: 
   // 1: PCIe 0        5:
   // 2: PCIe 1        6: Aurora SMA
   // 3:               7: Aurora SFP

   wire [7:0] LED_LINK = { CH_UP[1:0],  // Aurora 
                           3'b0,        // Not connected
                           3'b111 };    // PCIe is always up

   wire [7:0] LED_ACT  = { GT_D_VALID[1] | GT_Q_VALID[1],
                           GT_D_VALID[0] | GT_Q_VALID[0],
                           3'b0,    // Not connected
                           PCI_D_VALID[1] | PCI_Q_VALID[1],
                           PCI_D_VALID[0] | PCI_Q_VALID[0],
                           1'b1 };  // PCIe clock 

   generate
      genvar  i;
      for (i=0; i<8; i=i+1) begin : led_gen
         link_act led ( .CLK(CLK), .RST(RST), .LED(LED[i]), 
                        .LINK(LED_LINK[i]),   .ACT(LED_ACT[i])); 
      end
   endgenerate
   
endmodule // top

`default_nettype wire