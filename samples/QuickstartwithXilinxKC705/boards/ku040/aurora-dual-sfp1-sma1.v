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
//                 for Avnet KU040 board in SFP1 + SMA1 configuration
// ----------------------------------------------------------------------

`default_nettype none

module aurora_dual
  ( input wire         CLK250, SYS_RST,
    input wire [1:0]   PE_RST, // = {SFP_PE_RST, SMA1_PE_RST}
    input wire         CLK100, GTREFCLK156,
    input wire         DCM_LOCKED,

    output wire        SFP1_TXP, SFP1_TXN, SMA1_TXP, SMA1_TXN,
    input wire         SFP1_RXP, SFP1_RXN, SMA1_RXP, SMA1_RXN,
    
    input wire [63:0]  SFP1_D, SMA1_D,
    output wire [63:0] SFP1_Q, SMA1_Q,
    input wire         SFP1_D_VALID, SMA1_D_VALID,
    output wire        SFP1_Q_VALID, SMA1_Q_VALID,
    output wire        SFP1_D_BP, SMA1_D_BP,
    input wire         SFP1_Q_BP, SMA1_Q_BP,

    output wire [1:0]  CH_UP
    );

   // ------------------------------
   // Aurora interface signals: [0] for SFP1, [1] for SMA1
   wire [63:0]         TX_TDATA [0:1];
   wire [1:0]          TX_TLAST, TX_TVALID, TX_TREADY;
   wire [63:0]         RX_TDATA [0:1];
   wire [1:0]          RX_TLAST, RX_TVALID;

   wire [15:0]         NFC_TDATA [0:1];
   wire [1:0]          NFC_TREADY, NFC_TVALID;

   wire                AURORA_CLK, AURORA_RST;
   
   // ------------------------------
   // aurora_port_axi x 2

   aurora_port_axi ap_sfp
     ( .CLK            (CLK250),           // I
       .SYS_RST        (SYS_RST),          // I
       .PE_RST         (PE_RST[0]),        // I
       .AURORA_CLK     (AURORA_CLK),       // I
       .AURORA_RST     (AURORA_RST),       // I

       // Router interface
       .D              (SFP1_D),            // I [63:0]
       .D_VALID        (SFP1_D_VALID),      // I
       .D_BP           (SFP1_D_BP),         // O
       
       .Q              (SFP1_Q),            // O [63:0]
       .Q_VALID        (SFP1_Q_VALID),      // O
       .Q_BP           (SFP1_Q_BP),         // I

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

   aurora_port_axi ap_sma
     ( .CLK            (CLK250),           // I
       .SYS_RST        (SYS_RST),          // I
       .PE_RST         (PE_RST[1]),        // I
       .AURORA_CLK     (AURORA_CLK),       // I
       .AURORA_RST     (AURORA_RST),       // I

       // Router interface
       .D              (SMA1_D),            // I [63:0]
       .D_VALID        (SMA1_D_VALID),      // I
       .D_BP           (SMA1_D_BP),         // O
       
       .Q              (SMA1_Q),            // O [63:0]
       .Q_VALID        (SMA1_Q_VALID),      // O
       .Q_BP           (SMA1_Q_BP),         // I

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

   ku_aurora_boot boot
     ( .CLK100(CLK100), .DCM_LOCKED(DCM_LOCKED),
       .PMA_INIT(PMA_INIT), .RESET_PB(RESET_PB) );

   // ------------------------------
   // Aurora Master-Slave signals
   wire                GT_RST, GT_CLK, SYNC_CLK;
   wire                MMCM_NOLOCK;
   
   // SFP1 port (master: built-in clocking)
   ku040_sfp1 aurora_core_sfp1
     ( .rxp           (SFP1_RXP),          // I
       .rxn           (SFP1_RXN),          // I
       .txp           (SFP1_TXP),          // O
       .txn           (SFP1_TXN),          // O
      
       .reset_pb      (RESET_PB),          // I
       .power_down    (1'b0),              // I
       .pma_init      (PMA_INIT),          // I
       .loopback      (3'b000),            // I [2:0]
       .hard_err      (),                  // O
       .soft_err      (),                  // O
       .channel_up    (CH_UP[0]),          // O
       .lane_up       (),                  // O [0:0]
       .tx_out_clk    (),                  // O
       .gt_pll_lock   (),                  // O
      
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

       // DRP disable
       .gt0_drpaddr(0),                    // I [8:0]
       .gt0_drpdi(0),                      // I [15:0]
       .gt0_drprdy(),                      // O
       .gt0_drpwe(1'b0),                   // I
       .gt0_drpen(1'b0),                   // I
       .gt0_drpdo(),                       // O [15:0]

       // Flow control
       .s_axi_nfc_tvalid(NFC_TVALID[0]),   // I
       .s_axi_nfc_tdata (NFC_TDATA [0]),   // I [0:15]
       .s_axi_nfc_tready(NFC_TREADY[0]),   // O

       .mmcm_not_locked_out(MMCM_NOLOCK),  // O
       .init_clk       (CLK100),           // I
       .link_reset_out (),                 // O
       .refclk1_in     (GTREFCLK156),      // I
       .user_clk_out   (AURORA_CLK),       // O
       .sync_clk_out   (SYNC_CLK),         // O
       .gt_rxcdrovrden_in(),               // I
       .sys_reset_out  (AURORA_RST),       // O
       .gt_reset_out   (GT_RST)            // O
       );
   
   // SMA1 port (slave: no built-in clocking)
   ku040_sma1_slave aurora_core_sma1
     ( .rxp            (SMA1_RXP),          // I
       .rxn            (SMA1_RXN),          // I
       .txp            (SMA1_TXP),          // O
       .txn            (SMA1_TXN),          // O

       .reset_pb(AURORA_RST),               // I
       .power_down(1'b0),                   // I
       .pma_init(GT_RST),                   // I
       .loopback(3'b000),                   // I [2:0]
       .hard_err(),                         // O
       .soft_err(),                         // O
       .channel_up(CH_UP[1]),               // O
       .lane_up(),                          // O
       .tx_out_clk(),                       // O
       .bufg_gt_clr_out(),                  // O
       .gt_pll_lock(),                      // O

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

       // DRP disable
       .gt0_drpaddr(0),                     // I [8:0]
       .gt0_drpdi(0),                       // I [15:0]
       .gt0_drprdy(),                       // O
       .gt0_drpwe(1'b0),                    // I
       .gt0_drpen(1'b0),                    // I
       .gt0_drpdo(),                        // O [15:0]

       // Flow control
       .s_axi_nfc_tvalid(NFC_TVALID[1]),    // I
       .s_axi_nfc_tdata (NFC_TDATA [1]),    // I [0:15]
       .s_axi_nfc_tready(NFC_TREADY[1]),    // O
      
       .refclk1_in(GTREFCLK156),            // I
       .user_clk(AURORA_CLK),               // I
       .sync_clk(SYNC_CLK),                 // I

       .mmcm_not_locked(MMCM_NOLOCK),       // I
       .init_clk(CLK100),                   // I
       .link_reset_out(),                   // O
       .gt_rxcdrovrden_in(),                // I
       .sys_reset_out()                     // O
       );

endmodule // aurora_dual

`default_nettype wire
