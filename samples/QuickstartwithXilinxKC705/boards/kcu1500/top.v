// ----------------------------------------------------------------------
// "THE BEER-WARE LICENSE" (Revision 42):
//    <yasu@prosou.nu> wrote this file. As long as you retain this
//    notice you can do whatever you want with this stuff. If we meet
//    some day, and you think this stuff is worth it, you can buy me a
//    beer in return Yasunori Osana at University of the Ryukyus,
//    Japan.
// ----------------------------------------------------------------------
// OpenFC project: an open FPGA accelerated cluster toolkit
// 
// Modules in this file:
//    top: a top-level module for Xilinx KCU1500 board
// ----------------------------------------------------------------------

`default_nettype none

module top
  ( // Clock signals
    input wire        SYSCLK0_300_P, SYSCLK0_300_N,
    
    // PCIe signals
    input wire        PCIE_REFCLK_P, PCIE_REFCLK_N,
    input wire        PCIE_RESET_N, 
    input wire [7:0]  PCIE_RXP, PCIE_RXN,
    output wire [7:0] PCIE_TXP, PCIE_TXN,

    // QSFP signals
    input wire [3:0]  QSFP0_RXN, QSFP0_RXP,
    output wire [3:0] QSFP0_TXN, QSFP0_TXP,
    input wire        QSFP0_REFCLKN, QSFP0_REFCLKP,

`ifdef ENABLE_QSFP1    
    input wire [3:0]  QSFP1_RXN, QSFP1_RXP,
    output wire [3:0] QSFP1_TXN, QSFP1_TXP,
    input wire        QSFP1_REFCLKN, QSFP1_REFCLKP,
`endif
    
    // State LEDs
    output wire [7:0] LED
    );

   // ------------------------------------------------------------
   // Clock managers

   wire               CLK100;
   wire               DCM_LOCKED;

   kcu1500_clk cm
     ( .CLK300P(SYSCLK0_300_P), .CLK300N(SYSCLK0_300_N),
       .CLK100 (CLK100),
       .DCM_LOCKED(DCM_LOCKED) );
     

   // ------------------------------------------------------------
   // PCIe interface (4 router ports)

   wire               CLK, RST;
   
   wire [3:0]         PCI_D_BP,    PCI_Q_BP;
   wire [3:0]         PCI_D_VALID, PCI_Q_VALID;
   wire [255:0]       PCI_D,       PCI_Q;
   
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

   wire [7:0]         AURORA_PE_RST = 0;
   wire               QSFP0_REFCLK;
   IBUFDS_GTE3 qsfp0_clkb( .I(QSFP0_REFCLKP), .IB(QSFP0_REFCLKN), .CEB(0),
                           .O(QSFP0_REFCLK) );

`ifndef ENABLE_QSFP1   
   wire [255:0]       GT_D, GT_Q;
   wire [3:0]         GT_D_VALID, GT_Q_VALID, GT_D_BP, GT_Q_BP;
   wire [3:0]         GT_UP;
`else
   wire [511:0]       GT_D, GT_Q;
   wire [7:0]         GT_D_VALID, GT_Q_VALID, GT_D_BP, GT_Q_BP;
   wire [7:0]         GT_UP;
`endif
   
   aurora_quad au_qsfp0
     ( .CLK250      (CLK), 
       .SYS_RST     (RST),
       .PE_RST      (AURORA_PE_RST[3:0]),
       .CLK100      (CLK100),
       .GTREFCLK    (QSFP0_REFCLK),
       .DCM_LOCKED  (DCM_LOCKED),
 
       .TXP(QSFP0_TXP), .TXN(QSFP0_TXN),
       .RXP(QSFP0_RXP), .RXN(QSFP0_RXP),

       .D       (GT_D       [255:0]), .Q       (GT_Q       [255:0]),
       .D_VALID (GT_D_VALID [  3:0]), .Q_VALID (GT_Q_VALID [  3:0]),
       .D_BP    (GT_D_BP    [  3:0]), .Q_BP    (GT_Q_BP    [  3:0]),

       .CH_UP(GT_UP[3:0]) );

`ifdef ENABLE_QSFP1   
   wire               QSFP1_REFCLK; 
   IBUFDS_GTE3 qsfp1_clkb( .I(QSFP1_REFCLKP), .IB(QSFP1_REFCLKN), .CEB(0),
                           .O(QSFP1_REFCLK) );

   aurora_quad au_qsfp1
     ( .CLK250      (CLK), 
       .SYS_RST     (RST),
       .PE_RST      (AURORA_PE_RST[7:4]),
       .CLK100      (CLK100),
       .GTREFCLK    (QSFP1_REFCLK),
       .DCM_LOCKED  (DCM_LOCKED),
 
       .TXP(QSFP1_TXP), .TXN(QSFP1_TXN),
       .RXP(QSFP1_RXP), .RXN(QSFP1_RXP),

       .D       (GT_D       [511:256]), .Q       (GT_Q       [511:256]),
       .D_VALID (GT_D_VALID [  7:  4]), .Q_VALID (GT_Q_VALID [  7:  4]),
       .D_BP    (GT_D_BP    [  7:  4]), .Q_BP    (GT_Q_BP    [  7:  4]),

       .CH_UP(GT_UP[7:4]) );
`endif //  `ifdef ENABLE_QSFP1

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

   // Port 12-15 = QSFP1 (if enabled)
   // Port  8-11 = QSFP0
   // Port  4- 7 = PCIe
   // Port     3 = ICAP
   // Port  1, 2 = PE

   wire  [14:0] ROUTER_Q_SOF;

`ifndef ENABLE_QSFP1
   defparam ro.NumPorts = 11;
`else
   defparam ro.NumPorts = 15;
`endif
   
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
   // State LEDs

   // 0: PCIe Clock    4: 
   // 1: PCIe 0        5:
   // 2: PCIe 1        6: 
   // 3:               7: 

   wire [1:0]   QSFP_LINK, QSFP_ACT;

`ifdef ENABLE_QSFP1
   assign QSFP_LINK[1] =  &GT_UP     [7:4];
   assign QSFP_ACT [1] = |(GT_D_VALID[7:4] | GT_Q_VALID[7:4]);
`else
   assign QSFP_LINK[1] = 0;
   assign QSFP_ACT [1] = 0;
`endif

   assign QSFP_LINK[0] =  &GT_UP     [3:0];
   assign QSFP_ACT [0] = |(GT_D_VALID[3:0] | GT_Q_VALID[3:0]);
   
   wire [7:0] LED_LINK = { QSFP_LINK,   // [1:0]
                           3'b0,        // Not connected
                           3'b111 };    // PCIe is always up

   wire [7:0] LED_ACT  = { QSFP_ACT,    // [1:0]
                           3'b0,        // Not connected
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
