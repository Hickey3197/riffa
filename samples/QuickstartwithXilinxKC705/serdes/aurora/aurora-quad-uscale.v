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
//    aurora_quad: 4x (Aurora 64b66b core + aurora_port_axi)
//                 for Ultrascale/Ultrascale+ FPGAs
// ----------------------------------------------------------------------

`default_nettype none

module aurora_quad
  ( input wire CLK250, SYS_RST,
    input wire [3:0]    PE_RST,
    input wire          CLK100, GTREFCLK,
    input wire          DCM_LOCKED,

    output wire [3:0]   TXP, TXN,
    input wire [3:0]    RXP, RXN,

    input wire [255:0]  D,
    output wire [255:0] Q,
    input wire [3:0]    D_VALID,
    output wire [3:0]   D_BP,
    output wire [3:0]   Q_VALID,
    input wire [3:0]    Q_BP,

    output wire [3:0]   CH_UP );

   genvar               ch;
   
  // ------------------------------
   // Aurora interface signals
   wire [63:0]         TX_TDATA [3:0];
   wire [3:0]          TX_TLAST, TX_TVALID, TX_TREADY;
   wire [63:0]         RX_TDATA [3:0];
   wire [3:0]          RX_TLAST, RX_TVALID;

   wire [15:0]         NFC_TDATA [3:0];
   wire [3:0]          NFC_TREADY, NFC_TVALID;

   wire                AURORA_CLK, AURORA_RST;

   // ------------------------------
   // Aurora-port AXI 
   
   generate
      for (ch=0; ch<4; ch=ch+1) begin : ap_gen
         aurora_port_axi ap_sfp
              ( .CLK            (CLK250),           // I
                .SYS_RST        (SYS_RST),          // I
                .PE_RST         (PE_RST[ch]),       // I
                .AURORA_CLK     (AURORA_CLK),       // I
                .AURORA_RST     (AURORA_RST),       // I
                
                // Router interface
                .D              (D      [ch]),      // I [63:0]
                .D_VALID        (D_VALID[ch]),      // I
                .D_BP           (D_BP   [ch]),      // O

                .Q              (Q      [ch]),      // O [63:0]
                .Q_VALID        (Q_VALID[ch]),      // O
                .Q_BP           (Q_BP   [ch]),      // I

                // Aurora interface
                .TX_TDATA       (TX_TDATA [ch]),     // O [63:0]
                .TX_TVALID      (TX_TVALID[ch]),     // O
                .TX_TLAST       (TX_TLAST [ch]),     // O
                .TX_TREADY      (TX_TREADY[ch]),     // I

                .RX_TDATA       (RX_TDATA [ch]),     // I [63:0]
                .RX_TVALID      (RX_TVALID[ch]),     // I
                .RX_TLAST       (RX_TLAST [ch]),     // I

                // Aurora NFC interface
                .NFC_TVALID     (NFC_TVALID[ch]),    // O
                .NFC_TDATA      (NFC_TDATA [ch]),    // O [15:0]
                .NFC_TREADY     (NFC_TREADY[ch])     // I
                );
      end // block: ap_gen
   endgenerate

   // ------------------------------
   // Aurora Bootup controller

   wire                PMA_INIT, RESET_PB;

   ku_aurora_boot boot
     ( .CLK100(CLK100), .DCM_LOCKED(DCM_LOCKED),
       .PMA_INIT(PMA_INIT), .RESET_PB(RESET_PB) );


   // ------------------------------
   // Aurora shared-logic signals + cores

   wire                QPLL_CLK, QPLL_REFCLK, QPLL_LOST, QPLL_LOCK;
   wire                GT_RST, GT_CLK, SYNC_CLK;
   wire                MMCM_NOLOCK;

   // Core with QPLL 
  aurora_w_qpll ac0 
     ( .rxp           (RXP[0]),          // I
       .rxn           (RXN[0]),          // I
       .txp           (TXP[0]),          // O
       .txn           (TXN[0]),          // O

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
       .refclk1_in     (GTREFCLK),         // I
       .user_clk_out   (AURORA_CLK),       // O
       .sync_clk_out   (SYNC_CLK),         // O

       // --- QPLL specific signals: remove with CPLL Aurora cores ---
       .gt_qpllclk_quad1_out        (QPLL_CLK),     // O
       .gt_qpllrefclk_quad1_out     (QPLL_REFCLK),  // O
       .gt_qpllrefclklost_quad1_out (QPLL_LOST),    // O
       .gt_qplllock_quad1_out       (QPLL_LOCK),    // O
       // ----------------- end QPLL specific signals ----------------
       
       .gt_rxcdrovrden_in(),               // I
       .sys_reset_out  (AURORA_RST),       // O
       .gt_reset_out   (GT_RST)            // O
       );


   generate
      for (ch=1; ch<4; ch=ch+1) begin : aurora_gen
         aurora_wo_qpll acX
              ( .rxp            (RXP[ch]),          // I
                .rxn            (RXN[ch]),          // I
                .txp            (TXP[ch]),          // O
                .txn            (TXN[ch]),          // O

                .reset_pb(AURORA_RST),               // I
                .power_down(1'b0),                   // I
                .pma_init(GT_RST),                   // I
                .loopback(3'b000),                   // I [2:0]
                .hard_err(),                         // O
                .soft_err(),                         // O
                .channel_up(CH_UP[ch]),               // O
                .lane_up(),                          // O
                .tx_out_clk(),                       // O
                .bufg_gt_clr_out(),                  // O
                .gt_pll_lock(),                      // O

                // AXI TX / RX
                .s_axi_tx_tdata (TX_TDATA [ch]),      // I [0:63]
                .s_axi_tx_tkeep (8'hff),             // I [0:7]
                .s_axi_tx_tlast (TX_TLAST [ch]),      // I
                .s_axi_tx_tvalid(TX_TVALID[ch]),      // I
                .s_axi_tx_tready(TX_TREADY[ch]),      // O
                .m_axi_rx_tdata (RX_TDATA [ch]),      // O [0:63]
                .m_axi_rx_tkeep (),                  // O [0:7]
                .m_axi_rx_tlast (RX_TLAST [ch]),      // O
                .m_axi_rx_tvalid(RX_TVALID[ch]),      // O

                // DRP disable
                .gt0_drpaddr(0),                     // I [8:0]
                .gt0_drpdi(0),                       // I [15:0]
                .gt0_drprdy(),                       // O
                .gt0_drpwe(1'b0),                    // I
                .gt0_drpen(1'b0),                    // I
                .gt0_drpdo(),                        // O [15:0]

                // Flow control
                .s_axi_nfc_tvalid(NFC_TVALID[ch]),    // I
                .s_axi_nfc_tdata (NFC_TDATA [ch]),    // I [0:15]
                .s_axi_nfc_tready(NFC_TREADY[ch]),    // O

                .refclk1_in(GTREFCLK),               // I
                .user_clk(AURORA_CLK),               // I
                .sync_clk(SYNC_CLK),                 // I

                .mmcm_not_locked(MMCM_NOLOCK),       // I
                .init_clk(CLK100),                   // I

                // -- QPLL specific signals: remove with CPLL Aurora cores --
                .gt_qpllclk_quad1_in        (QPLL_CLK),    // I
                .gt_qpllrefclk_quad1_in     (QPLL_REFCLK), // I
                .gt_to_common_qpllreset_out (),            // O
                .gt_qplllock_quad1_in       (QPLL_LOCK),   // I
                .gt_qpllrefclklost_quad1    (QPLL_LOST),   // I
                // ---------------- end QPLL specific signals ---------------

                .link_reset_out(),                   // O
                .gt_rxcdrovrden_in(),                // I
                .sys_reset_out()                     // O
                );
      end // block: aurora_gen
   endgenerate
   
endmodule // aurora_quad

`default_nettype wire
