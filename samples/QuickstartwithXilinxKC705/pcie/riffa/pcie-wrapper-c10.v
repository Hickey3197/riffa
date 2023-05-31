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
//    pcie_wrapper_c10: Cyclone 10 / Arria 10 PCIe block adapter for
//        RIFFA, which is designed for Stratix V PCIe block.
// ----------------------------------------------------------------------
              
module pcie_wrapper_c10
  (
   output wire [3:0]  tl_cfg_add,
   output wire [31:0] tl_cfg_ctl,
   output wire [52:0] tl_cfg_sts,
   output wire        coreclkout_hip,
   input wire         pld_core_ready,
   output wire        serdes_pll_locked,
   output wire        reset_status,
   input wire [3:0]   PCIE_RX_IN, 
   output wire [3:0]  PCIE_TX_OUT,
   output wire        derr_cor_ext_rcv,
   output wire        derr_cor_ext_rpl,
   output wire        derr_rpl,
   output wire        dlup,
   output wire        dlup_exit,
   output wire        ev128ns,
   output wire        ev1us,
   output wire        hotrst_exit,
   output wire [3:0]  int_status,
   output wire        l2_exit,
   output wire [3:0]  lane_act,
   output wire [4:0]  ltssmstate,
   output wire        rx_par_err,
   output wire [1:0]  tx_par_err,
   output wire        cfg_par_err,
   output wire [7:0]  ko_cpl_spc_header,
   output wire [11:0] ko_cpl_spc_data,
   output wire        app_int_ack,
   input wire         app_msi_req,
   output wire        app_msi_ack,
   input wire         npor,
   input wire         pin_perst,
   input wire         pld_clk,
   input wire         refclk,
   output wire        rx_st_sop,
   output wire        rx_st_eop,
   output wire        rx_st_valid,
   input wire         rx_st_ready, 
   output wire [63:0] rx_st_data,
   input wire         tx_st_sop, 
   input wire         tx_st_eop, 
   input wire         tx_st_valid, 
   output wire        tx_st_ready,
   input wire [63:0]  tx_st_data
   );

   c10pcie_gen2x4 u0 
     (
      .clr_st              (), //  O 1
      .hpg_ctrler          (), //  I 5
      .tl_cfg_add          (tl_cfg_add), //  O 4
      .tl_cfg_ctl          (tl_cfg_ctl), //  O 32
      .tl_cfg_sts          (tl_cfg_sts), //  O 53
      .cpl_err             (), //  I 7
      .cpl_pending         (), //  I 1
      .coreclkout_hip      (coreclkout_hip), //  O 1
      .currentspeed        (), //  O 2
      .test_in             (), //  I 32
      .simu_mode_pipe      (), //  I 1
      .sim_pipe_pclk_in    (), //  I 1
      .sim_pipe_rate       (), //  O 2
      .sim_ltssmstate      (), //  O 5
      .eidleinfersel0      (), //  O 3
      .eidleinfersel1      (), //  O 3
      .eidleinfersel2      (), //  O 3
      .eidleinfersel3      (), //  O 3
      .powerdown0          (), //  O 2
      .powerdown1          (), //  O 2
      .powerdown2          (), //  O 2
      .powerdown3          (), //  O 2
      .rxpolarity0         (), //  O 1
      .rxpolarity1         (), //  O 1
      .rxpolarity2         (), //  O 1
      .rxpolarity3         (), //  O 1
      .txcompl0            (), //  O 1
      .txcompl1            (), //  O 1
      .txcompl2            (), //  O 1
      .txcompl3            (), //  O 1
      .txdata0             (), //  O 32
      .txdata1             (), //  O 32
      .txdata2             (), //  O 32
      .txdata3             (), //  O 32
      .txdatak0            (), //  O 4
      .txdatak1            (), //  O 4
      .txdatak2            (), //  O 4
      .txdatak3            (), //  O 4
      .txdetectrx0         (), //  O 1
      .txdetectrx1         (), //  O 1
      .txdetectrx2         (), //  O 1
      .txdetectrx3         (), //  O 1
      .txelecidle0         (), //  O 1
      .txelecidle1         (), //  O 1
      .txelecidle2         (), //  O 1
      .txelecidle3         (), //  O 1
      .txdeemph0           (), //  O 1
      .txdeemph1           (), //  O 1
      .txdeemph2           (), //  O 1
      .txdeemph3           (), //  O 1
      .txmargin0           (), //  O 3
      .txmargin1           (), //  O 3
      .txmargin2           (), //  O 3
      .txmargin3           (), //  O 3
      .txswing0            (), //  O 1
      .txswing1            (), //  O 1
      .txswing2            (), //  O 1
      .txswing3            (), //  O 1
      .phystatus0          (), //  I 1
      .phystatus1          (), //  I 1
      .phystatus2          (), //  I 1
      .phystatus3          (), //  I 1
      .rxdata0             (), //  I 32
      .rxdata1             (), //  I 32
      .rxdata2             (), //  I 32
      .rxdata3             (), //  I 32
      .rxdatak0            (), //  I 4
      .rxdatak1            (), //  I 4
      .rxdatak2            (), //  I 4
      .rxdatak3            (), //  I 4
      .rxelecidle0         (), //  I 1
      .rxelecidle1         (), //  I 1
      .rxelecidle2         (), //  I 1
      .rxelecidle3         (), //  I 1
      .rxstatus0           (), //  I 3
      .rxstatus1           (), //  I 3
      .rxstatus2           (), //  I 3
      .rxstatus3           (), //  I 3
      .rxvalid0            (), //  I 1
      .rxvalid1            (), //  I 1
      .rxvalid2            (), //  I 1
      .rxvalid3            (), //  I 1
      .rxdataskip0         (), //  I 1
      .rxdataskip1         (), //  I 1
      .rxdataskip2         (), //  I 1
      .rxdataskip3         (), //  I 1
      .rxblkst0            (), //  I 1
      .rxblkst1            (), //  I 1
      .rxblkst2            (), //  I 1
      .rxblkst3            (), //  I 1
      .rxsynchd0           (), //  I 2
      .rxsynchd1           (), //  I 2
      .rxsynchd2           (), //  I 2
      .rxsynchd3           (), //  I 2
      .currentcoeff0       (), //  O 18
      .currentcoeff1       (), //  O 18
      .currentcoeff2       (), //  O 18
      .currentcoeff3       (), //  O 18
      .currentrxpreset0    (), //  O 3
      .currentrxpreset1    (), //  O 3
      .currentrxpreset2    (), //  O 3
      .currentrxpreset3    (), //  O 3
      .txsynchd0           (), //  O 2
      .txsynchd1           (), //  O 2
      .txsynchd2           (), //  O 2
      .txsynchd3           (), //  O 2
      .txblkst0            (), //  O 1
      .txblkst1            (), //  O 1
      .txblkst2            (), //  O 1
      .txblkst3            (), //  O 1
      .txdataskip0         (), //  O 1
      .txdataskip1         (), //  O 1
      .txdataskip2         (), //  O 1
      .txdataskip3         (), //  O 1
      .rate0               (), //  O 2
      .rate1               (), //  O 2
      .rate2               (), //  O 2
      .rate3               (), //  O 2
      .pld_core_ready      (pld_core_ready), //  I 1
      .pld_clk_inuse       (), //  O 1
      .serdes_pll_locked   (serdes_pll_locked), //  O 1
      .reset_status        (reset_status), //  O 1
      .testin_zero         (), //  O 1
      .rx_in0              (PCIE_RX_IN[0]), //  I 1
      .rx_in1              (PCIE_RX_IN[1]), //  I 1
      .rx_in2              (PCIE_RX_IN[2]), //  I 1
      .rx_in3              (PCIE_RX_IN[3]), //  I 1
      .tx_out0             (PCIE_TX_OUT[0]), //  O 1
      .tx_out1             (PCIE_TX_OUT[1]), //  O 1
      .tx_out2             (PCIE_TX_OUT[2]), //  O 1
      .tx_out3             (PCIE_TX_OUT[3]), //  O 1
      .derr_cor_ext_rcv    (derr_cor_ext_rcv), //  O 1
      .derr_cor_ext_rpl    (derr_cor_ext_rpl), //  O 1
      .derr_rpl            (derr_rpl), //  O 1
      .dlup                (dlup), //  O 1
      .dlup_exit           (dlup_exit), //  O 1
      .ev128ns             (ev128ns), //  O 1
      .ev1us               (ev1us), //  O 1
      .hotrst_exit         (hotrst_exit), //  O 1
      .int_status          (int_status), //  O 4
      .l2_exit             (l2_exit), //  O 1
      .lane_act            (lane_act), //  O 4
      .ltssmstate          (ltssmstate), //  O 5
      .rx_par_err          (rx_par_err), //  O 1
      .tx_par_err          (tx_par_err), //  O 2
      .cfg_par_err         (cfg_par_err), //  O 1
      .ko_cpl_spc_header   (ko_cpl_spc_header), //  O 8
      .ko_cpl_spc_data     (ko_cpl_spc_data), //  O 12
      .app_int_sts         (), //  I 1
      .app_int_ack         (app_int_ack), //  O 1
      .app_msi_num         (), //  I 5
      .app_msi_req         (app_msi_req), //  I 1
      .app_msi_tc          (), //  I 3
      .app_msi_ack         (app_msi_ack), //  O 1
      .npor                (npor), //  I 1
      .pin_perst           (pin_perst), //  I 1
      .pld_clk             (pld_clk), //  I 1
      .pm_auxpwr           (), //  I 1
      .pm_data             (), //  I 10
      .pme_to_cr           (), //  I 1
      .pm_event            (), //  I 1
      .pme_to_sr           (), //  O 1
      .refclk              (refclk), //  I 1
      .rx_st_bar           (), //  O 8
      .rx_st_mask          (), //  I 1
      .rx_st_sop           (rx_st_sop), //  O 1
      .rx_st_eop           (rx_st_eop), //  O 1
      .rx_st_err           (), //  O 1
      .rx_st_valid         (rx_st_valid), //  O 1
      .rx_st_ready         (rx_st_ready), //  I 1
      .rx_st_data          (rx_st_data), //  O 64
      .tx_cred_data_fc     (), //  O 12
      .tx_cred_fc_hip_cons (), //  O 6
      .tx_cred_fc_infinite (), //  O 6
      .tx_cred_hdr_fc      (), //  O 8
      .tx_cred_fc_sel      (), //  I 2
      .tx_st_sop           (tx_st_sop), //  I 1
      .tx_st_eop           (tx_st_eop), //  I 1
      .tx_st_err           (), //  I 1
      .tx_st_valid         (tx_st_valid), //  I 1
      .tx_st_ready         (tx_st_ready), //  O 1
      .tx_st_data          (tx_st_data)  //  I 64
      );

endmodule // pcie_wrapper_c10
