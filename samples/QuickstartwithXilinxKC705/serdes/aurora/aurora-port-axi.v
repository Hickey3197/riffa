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
//    aurora_port_axi: Xilinx Aurora interface (AXI-S version) adapter
// ----------------------------------------------------------------------

`default_nettype none

module aurora_port_axi
  ( input wire         CLK, SYS_RST, PE_RST,
    input wire         AURORA_CLK, AURORA_RST,

   // Router interface
    input wire [63:0]  D,
    input wire         D_VALID,
    output wire        D_BP,

    output wire [63:0] Q,
    output wire        Q_VALID,
    input wire         Q_BP,

   // Aurora interface
    output wire [63:0] TX_TDATA,
    output wire        TX_TVALID, TX_TLAST,
    input wire         TX_TREADY,

    input wire [63:0]  RX_TDATA,
    input wire         RX_TVALID,
    input wire         RX_TLAST,

   // Aurora NFC interface 
    output wire        NFC_TVALID,
    output wire [15:0] NFC_TDATA,
    input wire         NFC_TREADY
   );

   // SOF-EOF interface signals
   wire               TX_SOF, TX_EOF, TX_READY, TX_VALID;
   wire               RX_SOF, RX_EOF, RX_VALID;
   wire [63:0]        TX_DATA, RX_DATA;

   // AXI-S adapters
   axi2sofeof # (.AXI_Width(64)) axi_rx
     ( .CLK(AURORA_CLK), .RST(AURORA_RST),

       .S_AXI_RX_TDATA (RX_TDATA),
       .S_AXI_RX_TVALID(RX_TVALID),
       .S_AXI_RX_TLAST (RX_TLAST),

       .RVALID(RX_VALID),
       .DATA  (RX_DATA),
       .SOF   (RX_SOF), .EOF(RX_EOF)
       );
   
   sofeof2axi # (.AXI_Width(64)) axi_tx
     ( .CLK(AURORA_CLK), .RST(AURORA_RST),

       // SOF/EOF interface
       .SOF   (TX_SOF), .EOF(TX_EOF), .TVALID(TX_VALID),
       .DATA  (TX_DATA),
       .TREADY(TX_READY), 

       // AXI TX interface
       .M_AXI_TX_TDATA (TX_TDATA),
       .M_AXI_TX_TVALID(TX_TVALID), .M_AXI_TX_TLAST(TX_TLAST),
       .M_AXI_TX_TREADY(TX_TREADY)
       );
   
   // SOF-EOF aurora port
   aurora_port ap
     ( // Clock and reset inputs
       .CLK(CLK), .SYS_RST(SYS_RST), .PE_RST(PE_RST),
       .AURORA_CLK(AURORA_CLK), .AURORA_RST(AURORA_RST),

       // Router I/F
       .D      (D),        .Q      (Q),
       .D_VALID(D_VALID),  .Q_VALID(Q_VALID), 
       .D_BP   (D_BP),     .Q_BP   (Q_BP),
       
       // Aurora SOF-EOF interface
       .TX_SOF    (TX_SOF),     .TX_EOF  (TX_EOF),
       .TX_DATA   (TX_DATA),
       .TX_READY  (TX_READY),   .TX_VALID(TX_VALID),

       .RX_SOF    (RX_SOF),     .RX_EOF  (RX_EOF),
       .RX_DATA   (RX_DATA),
       .RX_VALID  (RX_VALID),

       // Aurora NFC interface
       .NFC_TVALID(NFC_TVALID), .NFC_TDATA(NFC_TDATA), // O
       .NFC_TREADY(NFC_TREADY)
   );

endmodule // aurora_port_axi
