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
//    aurora_dual: 2x ( Aurora 64b66b core + aurora_port_axi)
//                 for SFP1 + SMA1 port on Avnet KU040 DB
// ----------------------------------------------------------------------

`default_nettype none

module aurora_dual
  ( input wire         CLK250, SYS_RST,
    input wire [1:0]   PE_RST, // {DP0_PE_RST, DP1_PE_RST}
    input wire         CLK50, CLK100, GTREFCLK156,
    input wire         DCM_LOCKED,

    output wire        DP0_TXP, DP0_TXN, DP1_TXP, DP1_TXN,
    input wire         DP0_RXP, DP0_RXN, DP1_RXP, DP1_RXN,
    
    input wire [63:0]  DP0_D, DP1_D,
    output wire [63:0] DP0_Q, DP1_Q,
    input wire         DP0_D_VALID, DP1_D_VALID,
    output wire        DP0_Q_VALID, DP1_Q_VALID,
    output wire        DP0_D_BP, DP1_D_BP,
    input wire         DP0_Q_BP, DP1_Q_BP,

    output wire [1:0]  CH_UP
    );

   // ------------------------------
   // Aurora interface signals: [0] for DP0, [1] for DP1
   wire [63:0]         TX_TDATA [0:1];
   wire [1:0]          TX_TLAST, TX_TVALID, TX_TREADY;
   wire [63:0]         RX_TDATA [0:1];
   wire [1:0]          RX_TLAST, RX_TVALID;

   wire [15:0]         NFC_TDATA [0:1];
   wire [1:0]          NFC_TREADY, NFC_TVALID;

   wire                AURORA_CLK, AURORA_RST;
   
   // ------------------------------
   // aurora_port_axi x 2

   aurora_port_axi ap_dp0
     ( .CLK            (CLK250),           // I
       .SYS_RST        (SYS_RST),          // I
       .PE_RST         (PE_RST[0]),        // I
       .AURORA_CLK     (AURORA_CLK),       // I
       .AURORA_RST     (AURORA_RST),       // I

       // Router interface
       .D              (DP0_D),            // I [63:0]
       .D_VALID        (DP0_D_VALID),      // I
       .D_BP           (DP0_D_BP),         // O
       
       .Q              (DP0_Q),            // O [63:0]
       .Q_VALID        (DP0_Q_VALID),      // O
       .Q_BP           (DP0_Q_BP),         // I

       // Aurora interface
       .TX_TDATA       (TX_TDATA [0]),     // O [63:0]
       .TX_TVALID      (TX_TVALID[0]),     // O
       .TX_TLAST       (TX_TLAST [0]),     // O
       .TX_TREADY      (TX_TREADY[0]),     // I

       .RX_TDATA       (RX_TDATA [0]),     // I [63:0]
       .RX_TVALID      (RX_TVALID[0]),     // I
       .RX_TLAST       (RX_TLAST [0]),     // I

       // Aurora NFC interface 
       .NFC_TVALID     (NFC_TVALID[0]),    // O
       .NFC_TDATA      (NFC_TDATA [0]),    // O [15:0]
       .NFC_TREADY     (NFC_TREADY[0])     // I
       );

   aurora_port_axi ap_sfp
     ( .CLK            (CLK250),           // I
       .SYS_RST        (SYS_RST),          // I
       .PE_RST         (PE_RST[1]),        // I
       .AURORA_CLK     (AURORA_CLK),       // I
       .AURORA_RST     (AURORA_RST),       // I

       // Router interface
       .D              (DP1_D),            // I [63:0]
       .D_VALID        (DP1_D_VALID),      // I
       .D_BP           (DP1_D_BP),         // O
       
       .Q              (DP1_Q),            // O [63:0]
       .Q_VALID        (DP1_Q_VALID),      // O
       .Q_BP           (DP1_Q_BP),         // I

       // Aurora interface
       .TX_TDATA       (TX_TDATA  [1]),    // O [63:0]
       .TX_TVALID      (TX_TVALID [1]),    // O
       .TX_TLAST       (TX_TLAST  [1]),    // O
       .TX_TREADY      (TX_TREADY [1]),    // I

       .RX_TDATA       (RX_TDATA  [1]),    // I [63:0]
       .RX_TVALID      (RX_TVALID [1]),    // I
       .RX_TLAST       (RX_TLAST  [1]),    // I

       // Aurora NFC interface 
       .NFC_TVALID     (NFC_TVALID[1]),    // O
       .NFC_TDATA      (NFC_TDATA [1]),    // O [15:0]
       .NFC_TREADY     (NFC_TREADY[1])     // I
       );
      
   // ------------------------------
   // Aurora Bootup controller
   wire                PMA_INIT, RESET_PB;

   k7_aurora_boot boot
     ( .CLK50(CLK50), .CLK100(CLK100), .DCM_LOCKED(DCM_LOCKED),
       .PMA_INIT(PMA_INIT), .RESET_PB(RESET_PB) );

   // ------------------------------
   // Aurora Master-Slave signals
   wire                SYNC_CLK, MMCM_NOLOCK;
   wire                QPLL_CLK, QPLL_RCLK, QPLL_LOCK, QPLL_LOST;
   wire                GT_RST;
   
   // DP0 port (master: built-in clocking)
   netfpga_fmc_dp0_6g_frame aurora_core_dp0
     ( .rxp            (DP0_RXP),          // I[0:0]
       .rxn            (DP0_RXN),          // I[0:0]
       .txp            (DP0_TXP),          // O[0:0]
       .txn            (DP0_TXN),          // O[0:0]
      
       .reset_pb       (RESET_PB),         // I
       .power_down     (1'b0),             // I
       .pma_init       (PMA_INIT),         // I
       .loopback       (3'b000),           // I[2:0]
       .hard_err       (),                 // O
       .soft_err       (),                 // O
       .channel_up     (CH_UP[0]),         // O
       .lane_up        (),                 // O[0:0]
       .tx_out_clk     (),                 // O
       .gt_pll_lock    (),                 // O
      
       // AXI TX / RX
       .s_axi_tx_tdata (TX_TDATA [0]),     // I[0:63]
       .s_axi_tx_tkeep (8'hff),            // I[0:7]
       .s_axi_tx_tlast (TX_TLAST [0]),     // I
       .s_axi_tx_tvalid(TX_TVALID[0]),     // I
       .s_axi_tx_tready(TX_TREADY[0]),     // O
       .m_axi_rx_tdata (RX_TDATA [0]),     // O[0:63]
       .m_axi_rx_tkeep (),                 // O[0:7]
       .m_axi_rx_tlast (RX_TLAST [0]),     // O
       .m_axi_rx_tvalid(RX_TVALID[0]),     // O
      
       .mmcm_not_locked_out(MMCM_NOLOCK),  // O
      
       // DRP disable
       .drp_clk_in     (CLK100),           // I
       .drpaddr_in     (),                 // I[8:0]
       .drpdi_in       (),                 // I[15:0]
       .drprdy_out     (),                 // O
       .drpen_in       (1'b0),             // I
       .drpwe_in       (1'b0),             // I
       .drpdo_out      (),                 // O[15:0]
      
       // Flow control
       .s_axi_nfc_tvalid(NFC_TVALID[0]),   // I
       .s_axi_nfc_tdata (NFC_TDATA [0]),   // I [0:15]
       .s_axi_nfc_tready(NFC_TREADY[0]),   // O

       // QPLL DRP disable
       .qpll_drpaddr_in(),                  // I [7:0]
       .qpll_drpdi_in  (),                  // I [15:0]
       .qpll_drprdy_out(),                  // O
       .qpll_drpen_in  (1'b0),              // I
       .qpll_drpwe_in  (1'b0),              // I
       .qpll_drpdo_out (),                  // O [15:0]
     
       .init_clk       (CLK50),             // I
       .link_reset_out (),                  // O
       .refclk1_in     (GTREFCLK156),       // I
       .user_clk_out   (AURORA_CLK),        // O
       .sync_clk_out   (SYNC_CLK),          // O

       .gt_qpllclk_quad2_out   (QPLL_CLK),  // O
       .gt_qpllrefclk_quad2_out(QPLL_RCLK), // O
       .gt_rxcdrovrden_in      (),         // I
       .gt_qplllock_out        (QPLL_LOCK), // O
       .gt_qpllrefclklost_out  (QPLL_LOST), // O

       .sys_reset_out (AURORA_RST),         // O
       .gt_reset_out  (GT_RST)//,           // O
       //      .gt_refclk1_out()            // O
       );
   
   // DP1 port (slave: no built-in clocking)
   netfpga_fmc_dp1_slave aurora_core_sfp
     ( .rxp            (DP1_RXP),           // I
       .rxn            (DP1_RXN),           // I
       .txp            (DP1_TXP),           // O
       .txn            (DP1_TXN),           // O
       
       .reset_pb       (AURORA_RST),        // I
       .power_down     (1'b0),              // I
       .pma_init       (GT_RST),            // I
       .loopback       (3'b000),            // I [2:0]
       .hard_err       (),                  // O
       .soft_err       (),                  // O 
       .channel_up     (CH_UP[1]),          // O
       .lane_up        (),                  // O
       .tx_out_clk     (),                  // O
       .gt_pll_lock    (),                  // O
       
       // AXI TX / RX
       .s_axi_tx_tdata (TX_TDATA [1]),      // I [0:63]
       .s_axi_tx_tkeep (8'hff),             // I [0:7]
       .s_axi_tx_tlast (TX_TLAST [1]),      // I
       .s_axi_tx_tvalid(TX_TVALID[1]),      // I
       .s_axi_tx_tready(TX_TREADY[1]),      // O
       .m_axi_rx_tdata (RX_TDATA [1]),      // O [0:63]
       .m_axi_rx_tkeep (),                  // O [0:7]
       .m_axi_rx_tlast (RX_TLAST [1]),      // O
       .m_axi_rx_tvalid(RX_TVALID[1]),      // O
       
       .mmcm_not_locked(MMCM_NOLOCK),       // I
       
       // DRP disable
       .drp_clk_in     (CLK100),            // I
       .drpaddr_in     (),                  // I [8:0]
       .drpdi_in       (),                  // I [15:0]
       .drprdy_out     (),                  // O
       .drpen_in       (1'b0),              // I
       .drpwe_in       (1'b0),              // I
       .drpdo_out      (),                  // O [15:0]
     
       // Flow control
       .s_axi_nfc_tvalid(NFC_TVALID[1]),    // I
       .s_axi_nfc_tdata (NFC_TDATA [1]),    // I [0:15]
       .s_axi_nfc_tready(NFC_TREADY[1]),    // O
     
       // QPLL DRP disable
       .qpll_drpaddr_in(),                  // I [7:0]
       .qpll_drpdi_in  (),                  // I [15:0]
       .qpll_drprdy_out(),                  // O
       .qpll_drpen_in  (1'b0),              // I
       .qpll_drpwe_in  (1'b0),              // I
       .qpll_drpdo_out (),                  // O [15:0]
     
       .init_clk       (CLK50),             // I
       .link_reset_out (),                  // O
       .refclk1_in     (GTREFCLK156),       // I
       .user_clk       (AURORA_CLK),        // I
       .sync_clk       (SYNC_CLK),          // I
     
       .gt_qpllclk_quad2_in   (QPLL_CLK),   // I
       .gt_qpllrefclk_quad2_in(QPLL_RCLK),  // I
     
       .gt_to_common_qpllreset_out(),       // O
       .gt_qplllock_in      (QPLL_LOCK),    // I
       .gt_qpllrefclklost_in(QPLL_LOST),    // I

       .gt_rxcdrovrden_in(),                    // I
       .sys_reset_out()                         // O
       );

endmodule // aurora_dual

`default_nettype wire
