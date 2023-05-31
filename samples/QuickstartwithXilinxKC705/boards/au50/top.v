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
//    top: a top-level module for Xilinx Alveo U50 board
// ----------------------------------------------------------------------

`default_nettype none

module top
  ( // Clock signals
    input wire        CMC_CLKP, CMC_CLKN,
    input wire        HBM_CLKP, HBM_CLKN,
  
    // PCIe signals
    input wire        PCIE_RESET_N, PCIE_REFCLK_P, PCIE_REFCLK_N,
    input wire [ 7:0] PCIE_RXP, PCIE_RXN,
    output wire [7:0] PCIE_TXP, PCIE_TXN,

    // QSFP signals: refclk is MGTREFCLK0_131 @ 161.1328125MHz
    input wire [3:0]  QSFP_RXN, QSFP_RXP,
    output wire [3:0] QSFP_TXN, QSFP_TXP,
    input wire        QSFP_REFCLKN, QSFP_REFCLKP,

    // Status / Activity LED
    output wire       LED_STA_G, LED_STA_Y,
    output wire       LED_ACT
    );

   // ------------------------------------------------------------
   // Clock buffers (no managers!)

   wire                CLK100;
   IBUFGDS clk100_buf ( .O(CLK100), .I(CMC_CLKP), .IB(CMC_CLKN) );

   // No clock managers
   wire                DCM_LOCKED = 1'b1;
   
   // ------------------------------------------------------------
   // PCIe interface (4 router ports)
   
   wire                CLK, RST;

   wire [3:0]          PCI_D_BP,    PCI_Q_BP;
   wire [3:0]          PCI_D_VALID, PCI_Q_VALID;
   wire [255:0]        PCI_D,       PCI_Q;

   defparam pci.IBUFDS_GTE = 4;
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
   
   wire [3:0]          AURORA_PE_RST = 0;
   wire                QSFP_REFCLK;
   IBUFDS_GTE4 qsfp_clkb( .I(QSFP_REFCLKP), .IB(QSFP_REFCLKN), .CEB(0),
                          .O(QSFP_REFCLK) );
   
   wire [255:0]        GT_D, GT_Q;
   wire [3:0]          GT_D_VALID, GT_Q_VALID, GT_D_BP, GT_Q_BP;
   wire [3:0]          GT_UP;

   aurora_quad au_qsfp
     ( .CLK250      (CLK),
       .SYS_RST     (RST),
       .PE_RST      (AURORA_PE_RST[3:0]),
       .CLK100      (CLK100),
       .GTREFCLK    (QSFP_REFCLK),
       .DCM_LOCKED  (DCM_LOCKED),
      
       .TXP(QSFP_TXP), .TXN(QSFP_TXN),
       .RXP(QSFP_RXP), .RXN(QSFP_RXP),
      
       .D       (GT_D       [255:0]), .Q       (GT_Q       [255:0]),
       .D_VALID (GT_D_VALID [  3:0]), .Q_VALID (GT_Q_VALID [  3:0]),
       .D_BP    (GT_D_BP    [  3:0]), .Q_BP    (GT_Q_BP    [  3:0]),
      
       .CH_UP(GT_UP[3:0]) );

   // ------------------------------------------------------------
   // ICAP instance

   wire                ICAP_PE_RST;
   wire [63:0]         ICAP_D, ICAP_Q;
   wire                ICAP_D_VALID, ICAP_Q_VALID, ICAP_D_BP, ICAP_Q_BP;
   wire                ICAP_BUSY;

   pe_icap icap
     ( .CLK250(CLK), .CLK100(CLK100), .SYS_RST(RST), .PE_RST(ICAP_PE_RST),
       .D(ICAP_D), .D_VALID(ICAP_D_VALID), .D_BP(ICAP_D_BP),
       .Q(ICAP_Q), .Q_VALID(ICAP_Q_VALID), .Q_BP(ICAP_Q_BP),
       .BUSY(ICAP_BUSY) );

   // ------------------------------------------------------------
   // PE instance

   wire                PE_RST;
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

   // Port  8-11 = QSFP
   // Port  4- 7 = PCIe
   // Port     3 = ICAP
   // Port  1, 2 = PE

   wire [10:0]         ROUTER_Q_SOF;

   defparam ro.NumPorts = 11;
   defparam ro.PassThrough = 'b000_111; // Note: PE_ICAP requires PT!

   router ro
     ( .CLK(CLK), .RST(RST),
       .D      ({GT_Q,       PCI_D,       ICAP_Q,       PE_Q      }), // I
       .D_VALID({GT_Q_VALID, PCI_D_VALID, ICAP_Q_VALID, PE_Q_VALID}), // I
       .D_BP   ({GT_Q_BP,    PCI_D_BP,    ICAP_Q_BP,    PE_Q_BP   }), // O

       .Q      ({GT_D,       PCI_Q,       ICAP_D,       PE_D      }), // O
       .Q_VALID({GT_D_VALID, PCI_Q_VALID, ICAP_D_VALID, PE_D_VALID}), // O
       .Q_BP   ({GT_D_BP,    PCI_Q_BP,    ICAP_D_BP,    PE_D_BP   }), // I
       .Q_SOF  (ROUTER_Q_SOF) ); // O: to generate PE_RST

   assign PE_RST      = ROUTER_Q_SOF[0];
   assign ICAP_PE_RST = ROUTER_Q_SOF[2];

   // ------------------------------------------------------------
   // Status / Activity LEDs

   assign LED_STA_G = 0;
   assign LED_STA_Y = &GT_UP;

   link_act led_pcie ( .CLK(CLK), .RST(RST), .LED(LED_ACT), 
                       .LINK(1),   .ACT(1)); 

   
endmodule // top

`default_nettype wire

