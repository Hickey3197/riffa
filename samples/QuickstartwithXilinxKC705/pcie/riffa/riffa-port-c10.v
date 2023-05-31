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
// Modified for latest Vivado 2018.x and Quartus 18.x + Cyclone 10 GX
//      by Yasunori Osana at University of the Ryukyus
// License of the Vivado/Quartus patch follows the original license above.
//
// Based on DE5QGen1x8If64.v for Altera DE5 board in RIFFA 2.2.2
//      written by Dustin Richmond (@darichmond)
// ----------------------------------------------------------------------
// OpenFC project: an open FPGA accelerated cluster framework
// 
// Modules in this file:
//    pcie_port: RIFFA PCIe wrapper with OpenFC standard Source/Sink ports
// ----------------------------------------------------------------------

`include "functions.vh"
`include "riffa.vh"
`include "altera.vh"
`timescale 1ps / 1ps

`default_nettype none

module pcie_port
    #(// Number of RIFFA Channels
      parameter C_NUM_CHNL = 2,
      // Number of PCIe Lanes
      parameter C_NUM_LANES =  4,
      // Settings from Quartus IP Library
      parameter C_PCI_DATA_WIDTH = 64,
      parameter C_MAX_PAYLOAD_BYTES = 256,
      parameter C_LOG_NUM_TAGS = 5
      )
    (
     output wire [3:0]             LED,

     input wire                    PCIE_RESET_N,
     input wire                    PCIE_REFCLK,
     
     input wire [C_NUM_LANES-1:0]  PCIE_RX,
     output wire [C_NUM_LANES-1:0] PCIE_TX,

     output wire                   CLK_OUT, RST_OUT,

     // To PE 
     input wire [1:0]              D_BP,
     output wire [1:0]             D_VALID,
     output wire [127:0]           D,

     // From PE
     output wire [1:0]             Q_BP,
     input wire [1:0]              Q_VALID,
     input wire [127:0]            Q
     );

    wire                     npor;
    wire                     pin_perst;

    // ----------TL Config interface----------
    wire [3:0]               tl_cfg_add;
    wire [31:0]              tl_cfg_ctl;
    wire [52:0]              tl_cfg_sts;

    // ----------Rx/TX Interfaces----------
    wire [0:0]               rx_st_sop;
    wire [0:0]               rx_st_eop;
    wire [0:0]               rx_st_err;
    wire [0:0]               rx_st_valid;
    wire                     rx_st_ready;
    wire [C_PCI_DATA_WIDTH-1:0] rx_st_data;
    wire [0:0]                  rx_st_empty;
    
    wire [0:0]                  tx_st_sop;
    wire [0:0]                  tx_st_eop;
    wire [0:0]                  tx_st_err;
    wire [0:0]                  tx_st_valid;
    wire                        tx_st_ready;
    wire [C_PCI_DATA_WIDTH-1:0] tx_st_data;
    wire [0:0]                  tx_st_empty;
    
    // ----------Clocks & Locks----------
    wire                        pld_clk;
    wire                        coreclkout_hip;
    wire                        refclk;
    wire                        pld_core_ready;
    wire                        reset_status;
    wire                        serdes_pll_locked;

    // ----------Interrupt Interfaces----------
    wire                        app_msi_req;
    wire                        app_msi_ack;
    
    // ----------Reconfiguration Controller signals----------
    wire                        mgmt_clk_clk;
    wire                        mgmt_rst_reset;

    // ----------Reconfiguration Driver Signals----------
    wire                        reconfig_xcvr_clk;
    wire                        reconfig_xcvr_rst;

    wire [7:0]                  rx_in;
    wire [7:0]                  tx_out;
    
    // ------------Status Interface------------
    wire                        derr_cor_ext_rcv;
    wire                        derr_cor_ext_rpl;
    wire                        derr_rpl;
    wire                        dlup;
    wire                        dlup_exit;
    wire                        ev128ns;
    wire                        ev1us;
    wire                        hotrst_exit;
    wire [3:0]                  int_status;
    wire                        l2_exit;
    wire [3:0]                  lane_act;
    wire [4:0]                  ltssmstate;
    wire                        rx_par_err;
    wire [1:0]                  tx_par_err;
    wire                        cfg_par_err;
    wire [7:0]                  ko_cpl_spc_header;
    wire [11:0]                 ko_cpl_spc_data;

    // ----------Clocks----------
    assign pld_clk = coreclkout_hip;
    assign mgmt_clk_clk = PCIE_REFCLK;
    assign reconfig_xcvr_clk = PCIE_REFCLK;
    assign refclk = PCIE_REFCLK;
    assign pld_core_ready = serdes_pll_locked;
    
    // ----------Resets----------
    assign reconfig_xcvr_rst = 1'b0;
    assign mgmt_rst_reset = 1'b0;
    assign pin_perst = PCIE_RESET_N;
    assign npor = PCIE_RESET_N;

    // ----------LED's----------
    assign LED[3:0] = 4'hff;


   pcie_wrapper_c10 pcie_system_inst
     (
      .tl_cfg_add(tl_cfg_add), // O [3:0]  
      .tl_cfg_ctl(tl_cfg_ctl), // O [31:0] 
      .tl_cfg_sts(tl_cfg_sts), // O [52:0] 
      .coreclkout_hip(coreclkout_hip), // O        
      .pld_core_ready(pld_core_ready), // I         
      .serdes_pll_locked(serdes_pll_locked), // O        
      .reset_status(reset_status), // O        
      .PCIE_RX_IN(PCIE_RX),  // I [3:0]   
      .PCIE_TX_OUT(PCIE_TX), // O [3:0]  
      .derr_cor_ext_rcv(derr_cor_ext_rcv), // O        
      .derr_cor_ext_rpl(derr_cor_ext_rpl), // O        
      .derr_rpl(derr_rpl), // O        
      .dlup(dlup), // O        
      .dlup_exit(dlup_exit), // O        
      .ev128ns(ev128ns), // O        
      .ev1us(ev1us), // O        
      .hotrst_exit(hotrst_exit), // O        
      .int_status(int_status), // O [3:0]  
      .l2_exit(l2_exit), // O        
      .lane_act(lane_act), // O [3:0]  
      .ltssmstate(ltssmstate), // O [4:0]  
      .rx_par_err(rx_par_err), // O        
      .tx_par_err(tx_par_err), // O [1:0]  
      .cfg_par_err(cfg_par_err), // O        
      .ko_cpl_spc_header(ko_cpl_spc_header), // O [7:0]  
      .ko_cpl_spc_data(ko_cpl_spc_data), // O [11:0] 
      .app_int_ack(), // O        
      .app_msi_req(app_msi_req), // I         
      .app_msi_ack(app_msi_ack), // O        
      .npor       (npor), // I         
      .pin_perst  (pin_perst), // I         
      .pld_clk    (pld_clk), // I         
      .refclk     (refclk), // I         
      .rx_st_sop  (rx_st_sop), // O        
      .rx_st_eop  (rx_st_eop), // O        
      .rx_st_valid(rx_st_valid), // O        
      .rx_st_ready(rx_st_ready),  // I         
      .rx_st_data (rx_st_data), // O [63:0] 
      .tx_st_sop  (tx_st_sop),  // I         
      .tx_st_eop  (tx_st_eop),  // I         
      .tx_st_valid(tx_st_valid),  // I         
      .tx_st_ready(tx_st_ready), // O        
      .tx_st_data (tx_st_data) // I [63:0]  
   );

   
    // -------------------- BEGIN RIFFA INSTANTAION --------------------

    // RIFFA channel interface
    wire [C_NUM_CHNL-1:0]       chnl_rx_clk;
    wire [C_NUM_CHNL-1:0]       chnl_rx;
    wire [C_NUM_CHNL-1:0]       chnl_rx_ack;
    wire [C_NUM_CHNL-1:0]       chnl_rx_last;
    wire [(C_NUM_CHNL*32)-1:0]  chnl_rx_len;
    wire [(C_NUM_CHNL*31)-1:0]  chnl_rx_off;
    wire [(C_NUM_CHNL*C_PCI_DATA_WIDTH)-1:0] chnl_rx_data;
    wire [C_NUM_CHNL-1:0]                    chnl_rx_data_valid;
    wire [C_NUM_CHNL-1:0]                    chnl_rx_data_ren;
    
    wire [C_NUM_CHNL-1:0]                    chnl_tx_clk;
    wire [C_NUM_CHNL-1:0]                    chnl_tx;
    wire [C_NUM_CHNL-1:0]                    chnl_tx_ack;
    wire [C_NUM_CHNL-1:0]                    chnl_tx_last;
    wire [(C_NUM_CHNL*32)-1:0]               chnl_tx_len;
    wire [(C_NUM_CHNL*31)-1:0]               chnl_tx_off;
    wire [(C_NUM_CHNL*C_PCI_DATA_WIDTH)-1:0] chnl_tx_data;
    wire [C_NUM_CHNL-1:0]                    chnl_tx_data_valid;
    wire [C_NUM_CHNL-1:0]                    chnl_tx_data_ren;

    wire                                     chnl_reset;
    wire                                     chnl_clk;
    wire                                     riffa_reset;
    wire                                     riffa_clk;
    assign riffa_reset = reset_status;
    assign riffa_clk = pld_clk;
    assign chnl_clk = pld_clk;
    assign chnl_reset = RST_OUT;
    
    riffa_wrapper_c10
        #(/*AUTOINSTPARAM*/
          // Parameters
          .C_LOG_NUM_TAGS               (C_LOG_NUM_TAGS),
          .C_NUM_CHNL                   (C_NUM_CHNL),
          .C_PCI_DATA_WIDTH             (C_PCI_DATA_WIDTH),
          .C_MAX_PAYLOAD_BYTES          (C_MAX_PAYLOAD_BYTES))
    riffa
        (
         // Outputs
         .RX_ST_READY                   (rx_st_ready),
         .TX_ST_DATA                    (tx_st_data[C_PCI_DATA_WIDTH-1:0]),
         .TX_ST_VALID                   (tx_st_valid[0:0]),
         .TX_ST_EOP                     (tx_st_eop[0:0]),
         .TX_ST_SOP                     (tx_st_sop[0:0]),
         .TX_ST_EMPTY                   (tx_st_empty[0:0]),
         .APP_MSI_REQ                   (app_msi_req),
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
         .RX_ST_DATA                    (rx_st_data[C_PCI_DATA_WIDTH-1:0]),
         .RX_ST_EOP                     (rx_st_eop[0:0]),
         .RX_ST_SOP                     (rx_st_sop[0:0]),
         .RX_ST_VALID                   (rx_st_valid[0:0]),
         .RX_ST_EMPTY                   (rx_st_empty[0:0]),
         .TX_ST_READY                   (tx_st_ready),
         .TL_CFG_CTL                    (tl_cfg_ctl[`SIG_CFG_CTL_W-1:0]),
         .TL_CFG_ADD                    (tl_cfg_add[`SIG_CFG_ADD_W-1:0]),
         .TL_CFG_STS                    (tl_cfg_sts[`SIG_CFG_STS_W-1:0]),
         .KO_CPL_SPC_HEADER             (ko_cpl_spc_header[`SIG_KO_CPLH_W-1:0]),
         .KO_CPL_SPC_DATA               (ko_cpl_spc_data[`SIG_KO_CPLD_W-1:0]),
         .APP_MSI_ACK                   (app_msi_ack),
         .PLD_CLK                       (pld_clk),
         .RESET_STATUS                  (reset_status),
         .CHNL_RX_CLK                   (chnl_rx_clk[C_NUM_CHNL-1:0]),
         .CHNL_RX_ACK                   (chnl_rx_ack[C_NUM_CHNL-1:0]),
         .CHNL_RX_DATA_REN              (chnl_rx_data_ren[C_NUM_CHNL-1:0]),
         .CHNL_TX_CLK                   (chnl_tx_clk[C_NUM_CHNL-1:0]),
         .CHNL_TX                       (chnl_tx[C_NUM_CHNL-1:0]),
         .CHNL_TX_LAST                  (chnl_tx_last[C_NUM_CHNL-1:0]),
         .CHNL_TX_LEN                   (chnl_tx_len[(C_NUM_CHNL*`SIG_CHNL_LENGTH_W)-1:0]),
         .CHNL_TX_OFF                   (chnl_tx_off[(C_NUM_CHNL*`SIG_CHNL_OFFSET_W)-1:0]),
         .CHNL_TX_DATA                  (chnl_tx_data[(C_NUM_CHNL*C_PCI_DATA_WIDTH)-1:0]),
         .CHNL_TX_DATA_VALID            (chnl_tx_data_valid[C_NUM_CHNL-1:0]));

    // --------------------  END RIFFA INSTANTAION --------------------

   // ----------------------------------------------------------------------
   // Riffa channel interface <-> Xillybus compat FIFO interface

   assign CLK_OUT = chnl_clk;
   
   wire [C_NUM_CHNL-1:0]                      FIFO_WE, FIFO_RE, FIFO_FULL, FIFO_EMPTY;
   wire [C_PCI_DATA_WIDTH-1:0]                FIFO_D [C_NUM_CHNL-1:0], 
                                              FIFO_Q [C_NUM_CHNL-1:0];

   generate
      genvar                                  chnl;
      for (chnl=0; chnl < C_NUM_CHNL; chnl = chnl + 1) begin : riffa_channels
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

                   .FIFO_W_WREN   (FIFO_WE  [chnl]), // O
                   .FIFO_W_FULL   (FIFO_FULL[chnl]), // I
                   .FIFO_W_D      (FIFO_D   [chnl]), // O
                   
                   .FIFO_R_EMPTY  (FIFO_EMPTY[chnl]), // I
                   .FIFO_R_RDEN   (FIFO_RE   [chnl]), // O
                   .FIFO_R_D      (FIFO_Q    [chnl])  // I
                   ); 
      end
   endgenerate

   // ----------------------------------------------------------------------
   // Source / Sink FIFOs

   // ------------------------------
   // Source FIFOs

   wire [1:0]        SRC_FIFO_RDEN, SRC_FIFO_EMPTY;
   wire [63:0]       SRC_FIFO_Q [1:0];
   reg [1:0]         SRC_FIFO_VALID;

   fifo_64x512_afull src1_fifo
     ( .clk  (CLK_OUT),
      .srst (RST_OUT),
      .din  (FIFO_D        [0]),
      .wr_en(FIFO_WE       [0]),
      .full (FIFO_FULL     [0]),
      .rd_en(SRC_FIFO_RDEN [0]),
      .dout (SRC_FIFO_Q    [0]),
      .empty(SRC_FIFO_EMPTY[0]) );

   fifo_64x512_afull src2_fifo
     ( .clk  (CLK_OUT),
      .srst (RST_OUT),
      .din  (FIFO_D        [1]),
      .wr_en(FIFO_WE       [1]),
      .full (FIFO_FULL     [1]),
      .rd_en(SRC_FIFO_RDEN [1]),
      .dout (SRC_FIFO_Q    [1]),
      .empty(SRC_FIFO_EMPTY[1]) );

   assign SRC_FIFO_RDEN = ~D_BP & ~SRC_FIFO_EMPTY;

   always @ (posedge CLK_OUT) SRC_FIFO_VALID <= SRC_FIFO_RDEN;
   assign D_VALID = SRC_FIFO_VALID;

   assign D[127:0] = { SRC_FIFO_Q[1], SRC_FIFO_Q[0] };
   
   // ------------------------------
   // Sink FIFOs

   fifo_64x512_afull sink1_fifo
     ( .clk  (CLK_OUT),
      .srst (RST_OUT),
      .rd_en(FIFO_RE[0]),
      .dout (FIFO_Q[0]),
      .empty(FIFO_EMPTY[0]),
      .din  (Q[63:0]),
      .wr_en(Q_VALID[0]),
      .full (),
      .prog_full(Q_BP[0]) );

   fifo_64x512_afull sink2_fifo
     ( .clk  (CLK_OUT),
      .srst (RST_OUT),
      .rd_en(FIFO_RE[1]),
      .dout (FIFO_Q[1]),
      .empty(FIFO_EMPTY[1]),
      .din  (Q[127:64]),
      .wr_en(Q_VALID[1]),
      .full (),
      .prog_full(Q_BP[1]) );

endmodule // pcie_port

`default_nettype wire
