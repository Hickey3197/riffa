// ----------------------------------------------------------------------
// Copyright (c) 2016, The Regents of the University of California All
// rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//
//     * Redistributions of source code must retain the above copyright
//       notice, this list of conditions and the following disclaimer.
//
//     * Redistributions in binary form must reproduce the above
//       copyright notice, this list of conditions and the following
//       disclaimer in the documentation and/or other materials provided
//       with the distribution.
//
//     * Neither the name of The Regents of the University of California
//       nor the names of its contributors may be used to endorse or
//       promote products derived from this software without specific
//       prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL REGENTS OF THE
// UNIVERSITY OF CALIFORNIA BE LIABLE FOR ANY DIRECT, INDIRECT,
// INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
// BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
// OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
// ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
// TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
// USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
// DAMAGE.
// ----------------------------------------------------------------------
// Modified for latest Vivado 2018.x and Quartus 18.x + KC705 / NetFPGA-1G
//      by Yasunori Osana at University of the Ryukyus
// License of the Vivado/Quartus patch follows the original license above.
//
// Based on KC705_Gen2x8If128.v for Xilinx KC705 board in RIFFA 2.2.2
//      written by Dustin Richmond (@darichmond)
// ----------------------------------------------------------------------
// OpenFC project: an open FPGA accelerated cluster framework
// 
// Modules in this file:
//    pcie_port: RIFFA PCIe wrapper with OpenFC standard Source/Sink ports
// ----------------------------------------------------------------------
  
`include "xilinx.vh"
`include "riffa.vh"
`include "trellis.vh"
`include "riffa-k7.vh"  // per board setting stuff

// KC705
`ifdef Gen2x8
 `define PCIECORE PCIeGen2x8If128 
 `define SRCFIFO fifo_128x512_64_afull
 `define SINKFIFO fifo_64x1024_128_afull
`else
 `define PCIECORE PCIeGen1x8If64
 `define SRCFIFO fifo_64x512_afull
 `define SINKFIFO fifo_64x512_afull
`endif

// NetFPGA
`ifdef Gen2x4
 `undef PCIECORE
 `define PCIECORE PCIeGen2x4If64
`endif

`default_nettype none

module pcie_port #
  (
   parameter C_NUM_CHNL = 2,
     
`ifdef Gen2x4
   parameter C_NUM_LANES = 4,
`else
   parameter C_NUM_LANES = 8,
`endif
  
`ifdef Gen2x8
   parameter C_PCI_DATA_WIDTH = 128,
`else
   parameter C_PCI_DATA_WIDTH = 64,
`endif
  
   parameter C_MAX_PAYLOAD_BYTES = 256,
   parameter C_LOG_NUM_TAGS = 5
   )
   (
    output wire [C_NUM_LANES-1:0] PCIE_TXP,
    output wire [C_NUM_LANES-1:0] PCIE_TXN,
    input wire [ C_NUM_LANES-1:0] PCIE_RXP,
    input wire [ C_NUM_LANES-1:0] PCIE_RXN,
   
    input wire                    PCIE_REFCLK_P, PCIE_REFCLK_N,
    input wire                    PCIE_RESET_N,

    output wire                   RST_OUT, CLK_OUT,
   
    // To PE 
    input wire [1:0]              D_BP,
    output wire [1:0]             D_VALID,
    output wire [127:0]           D,

    // From PE
    output wire [1:0]             Q_BP,
    input wire [1:0]              Q_VALID,
    input wire [127:0]            Q
    );
   
   wire                           user_reset;
   wire                           user_lnk_up;
   wire                           user_app_rdy;
   
   wire                           tx_cfg_gnt;
   wire                           rx_np_ok;
   wire                           rx_np_req;
   wire                           cfg_turnoff_ok;
   wire                           cfg_trn_pending;
   wire                           cfg_pm_halt_aspm_l0s;
   wire                           cfg_pm_halt_aspm_l1;
   wire                           cfg_pm_force_state_en;
   wire [1:0]                     cfg_pm_force_state;
   wire                           cfg_pm_wake;
   wire [63:0]                    cfg_dsn;

   wire [11 : 0]                  fc_cpld;
   wire [7 : 0]                   fc_cplh;
   wire [11 : 0]                  fc_npd;
   wire [7 : 0]                   fc_nph;
   wire [11 : 0]                  fc_pd;
   wire [7 : 0]                   fc_ph;
   wire [2 : 0]                   fc_sel;
   
   wire [15 : 0]                  cfg_status;
   wire [15 : 0]                  cfg_command;
   wire [15 : 0]                  cfg_dstatus;
   wire [15 : 0]                  cfg_dcommand;
   wire [15 : 0]                  cfg_lstatus;
   wire [15 : 0]                  cfg_lcommand;
   wire [15 : 0]                  cfg_dcommand2;
   
   wire [2 : 0]                   cfg_pcie_link_state;
   wire                           cfg_pmcsr_pme_en;
   wire [1 : 0]                   cfg_pmcsr_powerstate;
   wire                           cfg_pmcsr_pme_status;
   wire                           cfg_received_func_lvl_rst;
   wire [4 : 0]                   cfg_pciecap_interrupt_msgnum;
   wire                           cfg_to_turnoff;
   wire [7 : 0]                   cfg_bus_number;
   wire [4 : 0]                   cfg_device_number;
   wire [2 : 0]                   cfg_function_number;

   wire                           cfg_interrupt;
   wire                           cfg_interrupt_rdy;
   wire                           cfg_interrupt_assert;
   wire [7 : 0]                   cfg_interrupt_di;
   wire [7 : 0]                   cfg_interrupt_do;
   wire [2 : 0]                   cfg_interrupt_mmenable;
   wire                           cfg_interrupt_msienable;
   wire                           cfg_interrupt_msixenable;
   wire                           cfg_interrupt_msixfm;
   wire                           cfg_interrupt_stat;
   
   wire                           s_axis_tx_tready;
   wire [C_PCI_DATA_WIDTH-1 : 0]  s_axis_tx_tdata;
   wire [(C_PCI_DATA_WIDTH/8)-1 : 0] s_axis_tx_tkeep;
   wire                              s_axis_tx_tlast;
   wire                              s_axis_tx_tvalid;
   wire [`SIG_XIL_TX_TUSER_W : 0]    s_axis_tx_tuser;
   
   wire [C_PCI_DATA_WIDTH-1 : 0]     m_axis_rx_tdata;
   wire [(C_PCI_DATA_WIDTH/8)-1 : 0] m_axis_rx_tkeep;
   wire                              m_axis_rx_tlast;
   wire                              m_axis_rx_tvalid;
   wire                              m_axis_rx_tready;
   wire [`SIG_XIL_RX_TUSER_W - 1 : 0] m_axis_rx_tuser;

   // RIFFA channel signals

   wire [C_NUM_CHNL-1:0]              chnl_rx_clk; 
   wire [C_NUM_CHNL-1:0]              chnl_rx; 
   wire [C_NUM_CHNL-1:0]              chnl_rx_ack; 
   wire [C_NUM_CHNL-1:0]              chnl_rx_last; 
   wire [(C_NUM_CHNL*`SIG_CHNL_LENGTH_W)-1:0] chnl_rx_len; 
   wire [(C_NUM_CHNL*`SIG_CHNL_OFFSET_W)-1:0] chnl_rx_off; 
   wire [(C_NUM_CHNL*C_PCI_DATA_WIDTH)-1:0]   chnl_rx_data; 
   wire [C_NUM_CHNL-1:0]                      chnl_rx_data_valid; 
   wire [C_NUM_CHNL-1:0]                      chnl_rx_data_ren;

   wire [C_NUM_CHNL-1:0]                      chnl_tx_clk; 
   wire [C_NUM_CHNL-1:0]                      chnl_tx; 
   wire [C_NUM_CHNL-1:0]                      chnl_tx_ack;
   wire [C_NUM_CHNL-1:0]                      chnl_tx_last; 
   wire [(C_NUM_CHNL*`SIG_CHNL_LENGTH_W)-1:0] chnl_tx_len; 
   wire [(C_NUM_CHNL*`SIG_CHNL_OFFSET_W)-1:0] chnl_tx_off; 
   wire [(C_NUM_CHNL*C_PCI_DATA_WIDTH)-1:0]   chnl_tx_data; 
   wire [C_NUM_CHNL-1:0]                      chnl_tx_data_valid; 
   wire [C_NUM_CHNL-1:0]                      chnl_tx_data_ren;

   genvar                                     chnl;

   assign cfg_turnoff_ok = 0;
   assign cfg_trn_pending = 0;
   assign cfg_pm_halt_aspm_l0s = 0;
   assign cfg_pm_halt_aspm_l1 = 0;
   assign cfg_pm_force_state_en = 0;
   assign cfg_pm_force_state = 0;
   assign cfg_dsn = 0;
   assign cfg_interrupt_assert = 0;
   assign cfg_interrupt_di = 0;
   assign cfg_interrupt_stat = 0;
   assign cfg_pciecap_interrupt_msgnum = 0;
   assign cfg_turnoff_ok = 0;
   assign cfg_pm_wake = 0;

   // PCIe signals
   
   wire                                       pcie_refclk;
   wire                                       pcie_reset_n;

   IBUF 
     #()  
   pci_reset_n_ibuf 
     (.O(pcie_reset_n), 
      .I(PCIE_RESET_N));

   IBUFDS_GTE2 
     #()
   refclk_ibuf 
     (.O(pcie_refclk), 
      .ODIV2(), 
      .I(PCIE_REFCLK_P), 
      .CEB(1'b0), 
      .IB(PCIE_REFCLK_N));



   // ----------------------------------------------------------------------
   // Core Top Level Wrapper

   `PCIECORE PCIe_i
     (//---------------------------------------------------------------------
      // PCI Express (pci_exp) Interface                                     
      //---------------------------------------------------------------------
      // Tx
      .pci_exp_txn                               ( PCIE_TXN ),
      .pci_exp_txp                               ( PCIE_TXP ),
      
      // Rx
      .pci_exp_rxn                               ( PCIE_RXN ),
      .pci_exp_rxp                               ( PCIE_RXP ),
      
      //---------------------------------------------------------------------
      // AXI-S Interface                                                     
      //---------------------------------------------------------------------
      // Common
      .user_clk_out                              ( CLK_OUT ),
      .user_reset_out                            ( user_reset ),
      .user_lnk_up                               ( user_lnk_up ),
      .user_app_rdy                              ( user_app_rdy ),
      
      // TX
      .s_axis_tx_tready                          ( s_axis_tx_tready ),
      .s_axis_tx_tdata                           ( s_axis_tx_tdata ),
      .s_axis_tx_tkeep                           ( s_axis_tx_tkeep ),
      .s_axis_tx_tuser                           ( s_axis_tx_tuser ),
      .s_axis_tx_tlast                           ( s_axis_tx_tlast ),
      .s_axis_tx_tvalid                          ( s_axis_tx_tvalid ),
      
      // Rx
      .m_axis_rx_tdata                           ( m_axis_rx_tdata ),
      .m_axis_rx_tkeep                           ( m_axis_rx_tkeep ),
      .m_axis_rx_tlast                           ( m_axis_rx_tlast ),
      .m_axis_rx_tvalid                          ( m_axis_rx_tvalid ),
      .m_axis_rx_tready                          ( m_axis_rx_tready ),
      .m_axis_rx_tuser                           ( m_axis_rx_tuser ),

      .tx_cfg_gnt                                ( tx_cfg_gnt ),
      .rx_np_ok                                  ( rx_np_ok ),
      .rx_np_req                                 ( rx_np_req ),
      .cfg_trn_pending                           ( cfg_trn_pending ),
      .cfg_pm_halt_aspm_l0s                      ( cfg_pm_halt_aspm_l0s ),
      .cfg_pm_halt_aspm_l1                       ( cfg_pm_halt_aspm_l1 ),
      .cfg_pm_force_state_en                     ( cfg_pm_force_state_en ),
      .cfg_pm_force_state                        ( cfg_pm_force_state ),
      .cfg_dsn                                   ( cfg_dsn ),
      .cfg_turnoff_ok                            ( cfg_turnoff_ok ),
      .cfg_pm_wake                               ( cfg_pm_wake ),
      .cfg_pm_send_pme_to                        ( 1'b0 ),
      .cfg_ds_bus_number                         ( 8'b0 ),
      .cfg_ds_device_number                      ( 5'b0 ),
      .cfg_ds_function_number                    ( 3'b0 ),

      //---------------------------------------------------------------------
      // Flow Control Interface                                              
      //---------------------------------------------------------------------
      .fc_cpld                                   ( fc_cpld ),
      .fc_cplh                                   ( fc_cplh ),
      .fc_npd                                    ( fc_npd ),
      .fc_nph                                    ( fc_nph ),
      .fc_pd                                     ( fc_pd ),
      .fc_ph                                     ( fc_ph ),
      .fc_sel                                    ( fc_sel ),
      
      //---------------------------------------------------------------------
      // Configuration (CFG) Interface                                       
      //---------------------------------------------------------------------
      .cfg_device_number                         ( cfg_device_number ),
      .cfg_dcommand2                             ( cfg_dcommand2 ),
      .cfg_pmcsr_pme_status                      ( cfg_pmcsr_pme_status ),
      .cfg_status                                ( cfg_status ),
      .cfg_to_turnoff                            ( cfg_to_turnoff ),
      .cfg_received_func_lvl_rst                 ( cfg_received_func_lvl_rst ),
      .cfg_dcommand                              ( cfg_dcommand ),
      .cfg_bus_number                            ( cfg_bus_number ),
      .cfg_function_number                       ( cfg_function_number ),
      .cfg_command                               ( cfg_command ),
      .cfg_dstatus                               ( cfg_dstatus ),
      .cfg_lstatus                               ( cfg_lstatus ),
      .cfg_pcie_link_state                       ( cfg_pcie_link_state ),
      .cfg_lcommand                              ( cfg_lcommand ),
      .cfg_pmcsr_pme_en                          ( cfg_pmcsr_pme_en ),
      .cfg_pmcsr_powerstate                      ( cfg_pmcsr_powerstate ),
      
      //------------------------------------------------//
      // EP Only                                        //
      //------------------------------------------------//
      .cfg_interrupt                             ( cfg_interrupt ),
      .cfg_interrupt_rdy                         ( cfg_interrupt_rdy ),
      .cfg_interrupt_assert                      ( cfg_interrupt_assert ),
      .cfg_interrupt_di                          ( cfg_interrupt_di ),
      .cfg_interrupt_do                          ( cfg_interrupt_do ),
      .cfg_interrupt_mmenable                    ( cfg_interrupt_mmenable ),
      .cfg_interrupt_msienable                   ( cfg_interrupt_msienable ),
      .cfg_interrupt_msixenable                  ( cfg_interrupt_msixenable ),
      .cfg_interrupt_msixfm                      ( cfg_interrupt_msixfm ),
      .cfg_interrupt_stat                        ( cfg_interrupt_stat ),
      .cfg_pciecap_interrupt_msgnum              ( cfg_pciecap_interrupt_msgnum ),
      //---------------------------------------------------------------------
      // System  (SYS) Interface                                             
      //---------------------------------------------------------------------
      .sys_clk                                    ( pcie_refclk ),
      .sys_rst_n                                  ( pcie_reset_n )
      );

   // ----------------------------------------------------------------------
   // Riffa KC705 wrapper
   
   riffa_wrapper_kc705
     #(/*AUTOINSTPARAM*/
       // Parameters
       .C_LOG_NUM_TAGS               (C_LOG_NUM_TAGS),
       .C_NUM_CHNL                   (C_NUM_CHNL),
       .C_PCI_DATA_WIDTH             (C_PCI_DATA_WIDTH),
       .C_MAX_PAYLOAD_BYTES          (C_MAX_PAYLOAD_BYTES))
   riffa
     (
      // Outputs
      .CFG_INTERRUPT                 (cfg_interrupt),
      .M_AXIS_RX_TREADY              (m_axis_rx_tready),
      .S_AXIS_TX_TDATA               (s_axis_tx_tdata[C_PCI_DATA_WIDTH-1:0]),
      .S_AXIS_TX_TKEEP               (s_axis_tx_tkeep[(C_PCI_DATA_WIDTH/8)-1:0]),
      .S_AXIS_TX_TLAST               (s_axis_tx_tlast),
      .S_AXIS_TX_TVALID              (s_axis_tx_tvalid),
      .S_AXIS_TX_TUSER               (s_axis_tx_tuser[`SIG_XIL_TX_TUSER_W-1:0]),
      .FC_SEL                        (fc_sel[`SIG_FC_SEL_W-1:0]),
      .RST_OUT                       (RST_OUT),
      .CHNL_RX                       (chnl_rx[C_NUM_CHNL-1:0]),
      .CHNL_RX_LAST                  (chnl_rx_last[C_NUM_CHNL-1:0]),
      .CHNL_RX_LEN                   (chnl_rx_len[(C_NUM_CHNL*`SIG_CHNL_LENGTH_W)-1:0]),
      .CHNL_RX_OFF                   (chnl_rx_off[(C_NUM_CHNL*`SIG_CHNL_OFFSET_W)-1:0]),
      .CHNL_RX_DATA                  (chnl_rx_data[(C_NUM_CHNL*C_PCI_DATA_WIDTH)-1:0]),
      .CHNL_RX_DATA_VALID            (chnl_rx_data_valid[C_NUM_CHNL-1:0]),
      .CHNL_TX_ACK                   (chnl_tx_ack[C_NUM_CHNL-1:0]),
      .CHNL_TX_DATA_REN              (chnl_tx_data_ren[C_NUM_CHNL-1:0]),
      // Inputs
      .M_AXIS_RX_TDATA               (m_axis_rx_tdata[C_PCI_DATA_WIDTH-1:0]),
      .M_AXIS_RX_TKEEP               (m_axis_rx_tkeep[(C_PCI_DATA_WIDTH/8)-1:0]),
      .M_AXIS_RX_TLAST               (m_axis_rx_tlast),
      .M_AXIS_RX_TVALID              (m_axis_rx_tvalid),
      .M_AXIS_RX_TUSER               (m_axis_rx_tuser[`SIG_XIL_RX_TUSER_W-1:0]),
      .S_AXIS_TX_TREADY              (s_axis_tx_tready),
      .CFG_BUS_NUMBER                (cfg_bus_number[`SIG_BUSID_W-1:0]),
      .CFG_DEVICE_NUMBER             (cfg_device_number[`SIG_DEVID_W-1:0]),
      .CFG_FUNCTION_NUMBER           (cfg_function_number[`SIG_FNID_W-1:0]),
      .CFG_COMMAND                   (cfg_command[`SIG_CFGREG_W-1:0]),
      .CFG_DCOMMAND                  (cfg_dcommand[`SIG_CFGREG_W-1:0]),
      .CFG_LSTATUS                   (cfg_lstatus[`SIG_CFGREG_W-1:0]),
      .CFG_LCOMMAND                  (cfg_lcommand[`SIG_CFGREG_W-1:0]),
      .FC_CPLD                       (fc_cpld[`SIG_FC_CPLD_W-1:0]),
      .FC_CPLH                       (fc_cplh[`SIG_FC_CPLH_W-1:0]),
      .CFG_INTERRUPT_MSIEN           (cfg_interrupt_msienable),// TODO: Rename
      .CFG_INTERRUPT_RDY             (cfg_interrupt_rdy),
      .USER_CLK                      (CLK_OUT),
      .USER_RESET                    (user_reset),
      .CHNL_RX_CLK                   (chnl_rx_clk[C_NUM_CHNL-1:0]),
      .CHNL_RX_ACK                   (chnl_rx_ack[C_NUM_CHNL-1:0]),
      .CHNL_RX_DATA_REN              (chnl_rx_data_ren[C_NUM_CHNL-1:0]),
      .CHNL_TX_CLK                   (chnl_tx_clk[C_NUM_CHNL-1:0]),
      .CHNL_TX                       (chnl_tx[C_NUM_CHNL-1:0]),
      .CHNL_TX_LAST                  (chnl_tx_last[C_NUM_CHNL-1:0]),
      .CHNL_TX_LEN                   (chnl_tx_len[(C_NUM_CHNL*`SIG_CHNL_LENGTH_W)-1:0]),
      .CHNL_TX_OFF                   (chnl_tx_off[(C_NUM_CHNL*`SIG_CHNL_OFFSET_W)-1:0]),
      .CHNL_TX_DATA                  (chnl_tx_data[(C_NUM_CHNL*C_PCI_DATA_WIDTH)-1:0]),
      .CHNL_TX_DATA_VALID            (chnl_tx_data_valid[C_NUM_CHNL-1:0]),
      .RX_NP_OK                      (rx_np_ok),
      .TX_CFG_GNT                    (tx_cfg_gnt),
      .RX_NP_REQ                     (rx_np_req)
      /*AUTOINST*/);


   // ----------------------------------------------------------------------
   // Riffa channel interface <-> Xillybus compat FIFO interface
   
   wire [C_NUM_CHNL-1:0]                      FIFO_WE, FIFO_RE, FIFO_FULL, FIFO_EMPTY;
   wire [C_PCI_DATA_WIDTH-1:0]                FIFO_D [C_NUM_CHNL-1:0], 
                                              FIFO_Q [C_NUM_CHNL-1:0];

   
   generate
      for (chnl = 0; chnl < C_NUM_CHNL; chnl = chnl + 1) begin : riffa_channels
         xillybus_compat
                  # (
                     .C_PCI_DATA_WIDTH(C_PCI_DATA_WIDTH)
                     ) 
         compat
                  (
                   .CLK(CLK_OUT),
                   .RST(RST_OUT),  

                   // Rx interface
                   .CHNL_RX_CLK(chnl_rx_clk[chnl]), 
                   .CHNL_RX(chnl_rx[chnl]), 
                   .CHNL_RX_ACK(chnl_rx_ack[chnl]), 
                   .CHNL_RX_LAST(chnl_rx_last[chnl]), 
                   .CHNL_RX_LEN(chnl_rx_len[32*chnl +:32]), 
                   .CHNL_RX_OFF(chnl_rx_off[31*chnl +:31]), 
                   .CHNL_RX_DATA(chnl_rx_data[C_PCI_DATA_WIDTH*chnl +:C_PCI_DATA_WIDTH]), 
                   .CHNL_RX_DATA_VALID(chnl_rx_data_valid[chnl]), 
                   .CHNL_RX_DATA_REN(chnl_rx_data_ren[chnl]),
                   // Tx interface
                   .CHNL_TX_CLK(chnl_tx_clk[chnl]), 
                   .CHNL_TX(chnl_tx[chnl]), 
                   .CHNL_TX_ACK(chnl_tx_ack[chnl]), 
                   .CHNL_TX_LAST(chnl_tx_last[chnl]), 
                   .CHNL_TX_LEN(chnl_tx_len[32*chnl +:32]), 
                   .CHNL_TX_OFF(chnl_tx_off[31*chnl +:31]), 
                   .CHNL_TX_DATA(chnl_tx_data[C_PCI_DATA_WIDTH*chnl +:C_PCI_DATA_WIDTH]), 
                   .CHNL_TX_DATA_VALID(chnl_tx_data_valid[chnl]), 
                   .CHNL_TX_DATA_REN(chnl_tx_data_ren[chnl]),

                   .FIFO_W_WREN   (FIFO_WE  [chnl]),   // O
                   .FIFO_W_FULL   (FIFO_FULL[chnl]), // I
                   .FIFO_W_D      (FIFO_D   [chnl]),    // O
                   
                   .FIFO_R_EMPTY  (FIFO_EMPTY[chnl]), // I
                   .FIFO_R_RDEN   (FIFO_RE   [chnl]), // O
                   .FIFO_R_D      (FIFO_Q    [chnl]) // I
                   );
      end
   endgenerate


   // ----------------------------------------------------------------------
   // Source / Sink FIFOs
   
   // ------------------------------
   // Source FIFOs

   wire         SRC_FIFO_RDEN [1:0], SRC_FIFO_RDENt [1:0];
   wire         SRC_FIFO_EMPTY[1:0], SRC_FIFO_EMPTYt[1:0];
   wire [63:0]  SRC_FIFO_Q    [1:0];

   // - - - - - - - - - - - - - - - 
   // Word order control
   
`ifdef Gen2x8
   wire [127:0] SRC1_Dt = FIFO_D[0];
   wire [127:0] SRC2_Dt = FIFO_D[1];
   wire [127:0] SRC1_D = {SRC1_Dt[63:0], SRC1_Dt[127:64]};
   wire [127:0] SRC2_D = {SRC2_Dt[63:0], SRC2_Dt[127:64]};
   wire [127:0] SINK_Qt, SINK_Qt2;
   assign  FIFO_Q[0] = {SINK_Qt [63:0], SINK_Qt [127:64]};
   assign  FIFO_Q[1] = {SINK_Qt2[63:0], SINK_Qt2[127:64]};
`else
   wire [63:0]  SRC1_D = FIFO_D[0];
   wire [63:0]  SRC2_D = FIFO_D[1];
   wire [63:0]  SINK_Qt, SINK_Qt2;
   assign FIFO_Q[0] = SINK_Qt;
   assign FIFO_Q[1] = SINK_Qt2;
`endif

   // - - - - - - - - - - - - - - - 
   // Tail padding mask

`ifdef Gen2x8
   generate
      genvar    src_ch;
      for (src_ch=0; src_ch<2; src_ch=src_ch+1) begin : src_padding_gen
         reg [3:0] SRC_PADDING_STAT;
         reg       SRC_Q_VALID;
         reg [63:0] HEADER_LEN, SRC_PADDING_TOGO;
         reg        HAVE_PADDING;
         wire [63:0] FIFO_OUT = SRC_FIFO_Q[src_ch];
         wire [63:0] FRAME_LEN = (HEADER_LEN + FIFO_OUT + 1);
         
         always @ (posedge CLK_OUT) begin
            SRC_Q_VALID <= SRC_FIFO_RDEN[src_ch] & ~SRC_FIFO_EMPTY[src_ch];
            
            if (RST_OUT) begin
               SRC_PADDING_STAT <= 4'b0001;
               HEADER_LEN <= 0;
               HAVE_PADDING <= 0;
            end else begin
               case (SRC_PADDING_STAT)
                 4'b0001: begin
                    if (SRC_Q_VALID) begin
                       if (FIFO_OUT[63:56]==1) begin // routing header
                          HEADER_LEN  <= HEADER_LEN + 1;
                       end else begin // payload len
                          HAVE_PADDING <= FRAME_LEN[0];
                          SRC_PADDING_TOGO  <= FIFO_OUT;
                          SRC_PADDING_STAT <= 4'b0010;
                       end
                    end
                 end

                 4'b0010: begin
                    if (SRC_Q_VALID) begin
                       SRC_PADDING_TOGO  <= SRC_PADDING_TOGO - 1;
                       if (SRC_PADDING_TOGO == 1) begin
                          SRC_PADDING_STAT <= 4'b0001;
                          HEADER_LEN  <= 0;
                          HAVE_PADDING <= 0;
                       end
                    end
                 end
                 
                 default:
                   SRC_PADDING_STAT <= 4'b0001;
               endcase
            end
         end // always @ (posedge CLK)

         wire EMPTY_MASK = ( SRC_PADDING_STAT[1] & 
                             (SRC_PADDING_TOGO ==1) & 
                             HAVE_PADDING & SRC_Q_VALID );
         assign SRC_FIFO_EMPTY[src_ch] = EMPTY_MASK | SRC_FIFO_EMPTYt[src_ch];
         assign SRC_FIFO_RDENt[src_ch] = EMPTY_MASK | SRC_FIFO_RDEN[src_ch];
      end // block: src_padding_gen
   endgenerate
`else // !`ifdef Gen2x8
   assign SRC_FIFO_EMPTY[0] = SRC_FIFO_EMPTYt[0];
   assign SRC_FIFO_EMPTY[1] = SRC_FIFO_EMPTYt[1];
   assign SRC_FIFO_RDENt[0] = SRC_FIFO_RDEN[0];
   assign SRC_FIFO_RDENt[1] = SRC_FIFO_RDEN[1];
`endif // !`ifdef Gen2x8

   // - - - - - - - - - - - - - - - 
   // Source FIFO instances
   
   `SRCFIFO src1_fifo
     (
      .clk  (CLK_OUT),
      .srst (RST_OUT),
      .din  (SRC1_D),
      .wr_en(FIFO_WE[0]),
      .full (FIFO_FULL[0]),
      .rd_en(SRC_FIFO_RDENt[0]),
      .dout (SRC_FIFO_Q[0]),
      .empty(SRC_FIFO_EMPTYt[0])
      );

   `SRCFIFO src2_fifo
     (
      .clk  (CLK_OUT),
      .srst (RST_OUT),
      .din  (SRC2_D),
      .wr_en(FIFO_WE[1]),
      .full (FIFO_FULL[1]),
      .rd_en(SRC_FIFO_RDENt[1]),
      .dout (SRC_FIFO_Q[1]),
      .empty(SRC_FIFO_EMPTYt[1])
      );
   
   reg        SRC_FIFO1_VALID, SRC_FIFO2_VALID;
   
   assign SRC_FIFO_RDEN[0] = ~D_BP[0] & ~SRC_FIFO_EMPTY[0];
   assign SRC_FIFO_RDEN[1] = ~D_BP[1] & ~SRC_FIFO_EMPTY[1];

   always @ (posedge CLK_OUT) begin
      SRC_FIFO1_VALID <= SRC_FIFO_RDEN[0];
      SRC_FIFO2_VALID <= SRC_FIFO_RDEN[1];
   end

   assign D_VALID = {SRC_FIFO2_VALID, SRC_FIFO1_VALID};

   assign D[63:0] = SRC_FIFO_Q[0];
   assign D[127:64] = SRC_FIFO_Q[1];

   // ------------------------------
   // Sink FIFO

   // padding generator
   wire [1:0] SINK_PADDING_ACTIVE;
`ifdef Gen2x8
   genvar     sink_ch;
   for (sink_ch=0; sink_ch<2; sink_ch=sink_ch+1) begin : sink_padding_gen
      reg [3:0]   SINK_PADDING_STAT;
      reg [63:0]  SINK_PADDING_TOGO;
      reg         SINK_PADDING_REQUIRED;

      always @ (posedge CLK_OUT) begin
         if (RST_OUT) begin
            SINK_PADDING_STAT <= 4'b0001;
         end else begin
            case (SINK_PADDING_STAT) 
              4'b0001: begin
                 if (Q_VALID[sink_ch]) begin
                    SINK_PADDING_STAT <= 4'b0010;
                    // Padding is required if payload length is an even #
                    SINK_PADDING_REQUIRED <= ~Q[64*sink_ch];
                    SINK_PADDING_TOGO <= Q[64*sink_ch+63:64*sink_ch];
                 end end
              4'b0010: begin
                 if (Q_VALID[sink_ch]) begin
                    SINK_PADDING_TOGO <= SINK_PADDING_TOGO - 1;
                    if (SINK_PADDING_TOGO == 1) 
                      SINK_PADDING_STAT <= SINK_PADDING_REQUIRED ? 4'b0100 : 4'b0001;
                 end
              end
              4'b0100: begin
                 SINK_PADDING_STAT <= 4'b0001;  end
              default:
                SINK_PADDING_STAT <= 4'b0001;
              
            endcase
         end
      end // always @ (posedge CLK_OUT)

      assign SINK_PADDING_ACTIVE[sink_ch] = SINK_PADDING_STAT[2];
   end // block: sink_padding_gen
`else // !`ifdef Gen2x8
   assign SINK_PADDING_ACTIVE = 0;
`endif
   
   `SINKFIFO sink1_fifo
     (
      .clk  (CLK_OUT),
      .srst (RST_OUT),
      .rd_en(FIFO_RE[0]),
      .dout (SINK_Qt),
      .empty(FIFO_EMPTY[0]),
      .din  (Q[63:0]),
      .wr_en(Q_VALID[0] | SINK_PADDING_ACTIVE[0]),
      .full (),
      .prog_full(Q_BP[0])
      );

   `SINKFIFO sink2_fifo
     (
      .clk  (CLK_OUT),
      .srst (RST_OUT),
      .rd_en(FIFO_RE[1]),
      .dout (SINK_Qt2),
      .empty(FIFO_EMPTY[1]),
      .din  (Q[127:64]), 
      .wr_en(Q_VALID[1] | SINK_PADDING_ACTIVE[1]),
      .full (),
      .prog_full(Q_BP[1])
      );

endmodule // pcie_port

`default_nettype wire
