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
//   pcie_port: Implements Kintex-U PCIe port (x8 PCIe, 4 router ports)
// ----------------------------------------------------------------------

`default_nettype none

module pcie_port #
  ( parameter C_NUM_CHNL = 4,
    parameter C_NUM_LANES = 8,
    parameter IBUFDS_GTE = 3 )
   ( output wire [C_NUM_LANES-1:0] PCIE_TXP,
     output wire [C_NUM_LANES-1:0]   PCIE_TXN,
     input wire [ C_NUM_LANES-1:0]   PCIE_RXP,
     input wire [ C_NUM_LANES-1:0]   PCIE_RXN,

     input wire                      PCIE_REFCLK_P, PCIE_REFCLK_N,
     input wire                      PCIE_RESET_N,

     output wire                     RST_OUT, CLK_OUT,

    // To PE
     input wire [ C_NUM_CHNL-1:0]    D_BP,
     output wire [C_NUM_CHNL-1:0]    D_VALID,
     output wire [C_NUM_CHNL*64-1:0] D,

    // From PE
     output wire [C_NUM_CHNL-1:0]    Q_BP,
     input wire [C_NUM_CHNL-1:0]     Q_VALID,
     input wire [C_NUM_CHNL*64-1:0]  Q
    );


   // PCIe clock buffer
   wire                 PCIE_REFCLK, PCIE_DRPCLK;

   generate
      if (IBUFDS_GTE != 4) begin : uscale_ibuf_gen
         IBUFDS_GTE3 pcie_ckbuf0 
           ( .O    (PCIE_REFCLK),
             .ODIV2(PCIE_DRPCLK),
             .CEB  (1'b0),
             .I    (PCIE_REFCLK_P),
             .IB   (PCIE_REFCLK_N) );
      end else begin : uscaleplus_ibuf_gen
         IBUFDS_GTE4 pcie_ckbuf0 
           ( .O    (PCIE_REFCLK),
             .ODIV2(PCIE_DRPCLK),
             .CEB  (1'b0),
             .I    (PCIE_REFCLK_P),
             .IB   (PCIE_REFCLK_N) );
      end
   endgenerate

   // AXI clk and rst
   wire                 RST_N;
   assign RST_OUT = ~RST_N;
   
   wire [255:0] XDMA_C2H_TDATA [C_NUM_CHNL-1:0],
                XDMA_H2C_TDATA [C_NUM_CHNL-1:0];
   wire [31:0]  XDMA_C2H_TKEEP [C_NUM_CHNL-1:0],
                XDMA_H2C_TKEEP [C_NUM_CHNL-1:0];
   wire [C_NUM_CHNL-1:0] XDMA_C2H_TLAST,  XDMA_H2C_TLAST,
                         XDMA_C2H_TVALID, XDMA_H2C_TVALID,
                         XDMA_C2H_TREADY, XDMA_H2C_TREADY;
   
   xdma_st xdma_inst
     ( .sys_clk             (PCIE_DRPCLK),         // I
       .sys_clk_gt          (PCIE_REFCLK),         // I
       .sys_rst_n           (PCIE_RESET_N),        // I
       .user_lnk_up         (),                    // O
       .pci_exp_txp         (PCIE_TXP),            // O [7:0]
       .pci_exp_txn         (PCIE_TXN),            // O [7:0]
       .pci_exp_rxp         (PCIE_RXP),            // I [7:0]
       .pci_exp_rxn         (PCIE_RXN),            // I [7:0]
       .axi_aclk            (CLK_OUT),             // O
       .axi_aresetn         (RST_N),               // O
       .usr_irq_req         (1'b0),                // I [0:0]
       .usr_irq_ack         (),                    // O [0:0]
       .msi_enable          (),                    // O
       .msi_vector_width    (),                    // O [2:0]
       
       .s_axis_c2h_tdata_0  (XDMA_C2H_TDATA [0]),  // I [255:0]
       .s_axis_c2h_tlast_0  (XDMA_C2H_TLAST [0]),  // I
       .s_axis_c2h_tvalid_0 (XDMA_C2H_TVALID[0]),  // I
       .s_axis_c2h_tready_0 (XDMA_C2H_TREADY[0]),  // O
       .s_axis_c2h_tkeep_0  (XDMA_C2H_TKEEP [0]),  // I [31:0]
       .m_axis_h2c_tdata_0  (XDMA_H2C_TDATA [0]),  // O [255:0]
       .m_axis_h2c_tlast_0  (XDMA_H2C_TLAST [0]),  // O
       .m_axis_h2c_tvalid_0 (XDMA_H2C_TVALID[0]),  // O
       .m_axis_h2c_tready_0 (XDMA_H2C_TREADY[0]),  // I
       .m_axis_h2c_tkeep_0  (XDMA_H2C_TKEEP [0]),  // O [31:0]

       .s_axis_c2h_tdata_1  (XDMA_C2H_TDATA [1]),  // I [255:0]
       .s_axis_c2h_tlast_1  (XDMA_C2H_TLAST [1]),  // I
       .s_axis_c2h_tvalid_1 (XDMA_C2H_TVALID[1]),  // I
       .s_axis_c2h_tready_1 (XDMA_C2H_TREADY[1]),  // O
       .s_axis_c2h_tkeep_1  (XDMA_C2H_TKEEP [1]),  // I [31:0]
       .m_axis_h2c_tdata_1  (XDMA_H2C_TDATA [1]),  // O [255:0]
       .m_axis_h2c_tlast_1  (XDMA_H2C_TLAST [1]),  // O
       .m_axis_h2c_tvalid_1 (XDMA_H2C_TVALID[1]),  // O
       .m_axis_h2c_tready_1 (XDMA_H2C_TREADY[1]),  // I
       .m_axis_h2c_tkeep_1  (XDMA_H2C_TKEEP [1]),  // O [31:0]

       .s_axis_c2h_tdata_2  (XDMA_C2H_TDATA [2]),  // I [255:0]
       .s_axis_c2h_tlast_2  (XDMA_C2H_TLAST [2]),  // I
       .s_axis_c2h_tvalid_2 (XDMA_C2H_TVALID[2]),  // I
       .s_axis_c2h_tready_2 (XDMA_C2H_TREADY[2]),  // O
       .s_axis_c2h_tkeep_2  (XDMA_C2H_TKEEP [2]),  // I [31:0]
       .m_axis_h2c_tdata_2  (XDMA_H2C_TDATA [2]),  // O [255:0]
       .m_axis_h2c_tlast_2  (XDMA_H2C_TLAST [2]),  // O
       .m_axis_h2c_tvalid_2 (XDMA_H2C_TVALID[2]),  // O
       .m_axis_h2c_tready_2 (XDMA_H2C_TREADY[2]),  // I
       .m_axis_h2c_tkeep_2  (XDMA_H2C_TKEEP [2]),  // O [31:0]

       .s_axis_c2h_tdata_3  (XDMA_C2H_TDATA [3]),  // I [255:0]
       .s_axis_c2h_tlast_3  (XDMA_C2H_TLAST [3]),  // I
       .s_axis_c2h_tvalid_3 (XDMA_C2H_TVALID[3]),  // I
       .s_axis_c2h_tready_3 (XDMA_C2H_TREADY[3]),  // O
       .s_axis_c2h_tkeep_3  (XDMA_C2H_TKEEP [3]),  // I [31:0]
       .m_axis_h2c_tdata_3  (XDMA_H2C_TDATA [3]),  // O [255:0]
       .m_axis_h2c_tlast_3  (XDMA_H2C_TLAST [3]),  // O
       .m_axis_h2c_tvalid_3 (XDMA_H2C_TVALID[3]),  // O
       .m_axis_h2c_tready_3 (XDMA_H2C_TREADY[3]),  // I
       .m_axis_h2c_tkeep_3  (XDMA_H2C_TKEEP [3])   // O [31:0]
       );

   wire                  CLK = CLK_OUT;
   generate
      genvar             ch;
      for (ch=0; ch<C_NUM_CHNL; ch=ch+1) begin : port_gen

         wire [63:0] C2H_TDATA,  C2H_TDATAi,  H2C_TDATA;
         wire        C2H_TVALID, C2H_TVALIDi, H2C_TVALID,
                     C2H_TREADY, C2H_TREADYi, H2C_TREADY,
                     C2H_TLAST,  C2H_TLASTi,  H2C_TLAST;

         // ------------------------------
         // Host 2 Card width/protocol conversion
         
         axis_32to8 conv_h2c
           ( .aclk          (CLK),                  // I
             .aresetn       (RST_N),                // I
             .s_axis_tvalid (XDMA_H2C_TVALID[ch]),  // I
             .s_axis_tready (XDMA_H2C_TREADY[ch]),  // O
             .s_axis_tdata  (XDMA_H2C_TDATA [ch]),  // I [255:0]
             .s_axis_tkeep  (XDMA_H2C_TKEEP [ch]),  // I [31:0]
             .s_axis_tlast  (XDMA_H2C_TLAST [ch]),  // I
             .m_axis_tvalid (H2C_TVALID),           // O
             .m_axis_tready (H2C_TREADY),           // I
             .m_axis_tdata  (H2C_TDATA),            // O [63:0]
             .m_axis_tkeep  (),                     // O [7:0]
             .m_axis_tlast  (H2C_TLAST)             // O
             );
         

         axis2port port_h2c
           ( .CLK (CLK),
             .RST (~RST_N),
             .S_AXIS_TVALID(H2C_TVALID),            // I
             .S_AXIS_TLAST (H2C_TLAST ),            // I
             .S_AXIS_TDATA (H2C_TDATA ),            // I [63:0]
             .S_AXIS_TREADY(H2C_TREADY),            // O
             .Q            (D[ch*64+63 : ch*64]),   // O [63:0]
             .Q_VALID      (D_VALID[ch]),           // O
             .Q_BP         (D_BP[ch])               // I
            );

         // ------------------------------
         // Card 2 Host width/protocol conversion + header adjustment
         

         port2axis # (.TLAST_Enable(1) ) port_c2h
           ( .CLK (CLK),
             .RST (~RST_N),
             .D             (Q[ch*64+63 : ch*64]),  // I [63:0]
             .D_VALID       (Q_VALID[ch]),          // I
             .D_BP          (Q_BP   [ch]),          // O
             .M_AXIS_TDATA  (C2H_TDATA ),           // O [63:0]
             .M_AXIS_TVALID (C2H_TVALID),           // O
             .M_AXIS_TLAST  (C2H_TLAST ),           // O
             .M_AXIS_TREADY (C2H_TREADY)            // I
            );

         header_adj hdr_adj_c2h
           ( .CLK (CLK),
             .RST (~RST_N),
             .S_AXIS_TVALID(C2H_TVALID), .M_AXIS_TVALID(C2H_TVALIDi),
             .S_AXIS_TREADY(C2H_TREADY), .M_AXIS_TREADY(C2H_TREADYi),
             .S_AXIS_TLAST (C2H_TLAST ), .M_AXIS_TLAST (C2H_TLASTi ),
             .S_AXIS_TDATA (C2H_TDATA ), .M_AXIS_TDATA (C2H_TDATAi ) );
         
         
         axis_8to32 conv_c2h
           ( .aclk           (CLK),                 // I
             .aresetn        (RST_N),               // I
             .s_axis_tvalid  (C2H_TVALIDi),         // I
             .s_axis_tready  (C2H_TREADYi),         // O
             .s_axis_tdata   (C2H_TDATAi),          // I [63:0]
             .s_axis_tlast   (C2H_TLASTi),          // I
             .s_axis_tkeep   (8'hff),               // I [7:0]
             .m_axis_tvalid  (XDMA_C2H_TVALID[ch]), // O
             .m_axis_tready  (XDMA_C2H_TREADY[ch]), // I
             .m_axis_tdata   (XDMA_C2H_TDATA [ch]), // O [255:0]
             .m_axis_tkeep   (XDMA_C2H_TKEEP [ch]), // O [31:0]
             .m_axis_tlast   (XDMA_C2H_TLAST [ch])  // O
             );
         
      end // port_gen
   endgenerate

endmodule // pcie_port
   
`default_nettype wire
