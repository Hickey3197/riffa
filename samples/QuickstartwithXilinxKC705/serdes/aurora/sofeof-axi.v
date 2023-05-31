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
//    sof2of2axi: SOF-EOF interface adapter for AXI-S Aurora TX port
//    axi2sofeof: SOF-EOF interface adapter for AXI-S Aurora RX port
// ----------------------------------------------------------------------

`default_nettype none

module sofeof2axi
  # ( parameter AXI_Width = 16 )
   ( input wire                  CLK, RST,

     // SOF/EOF interface
     input wire                  SOF, EOF, TVALID,
     input wire [AXI_Width-1:0]  DATA,
     output wire                 TREADY, 

     // AXI TX interface
     output wire [AXI_Width-1:0] M_AXI_TX_TDATA,
     output wire                 M_AXI_TX_TVALID, M_AXI_TX_TLAST,
     input wire                  M_AXI_TX_TREADY
    );

   // passthrough signals
   assign TREADY = M_AXI_TX_TREADY;
   assign M_AXI_TX_TDATA = DATA;
   assign M_AXI_TX_TLAST = EOF;

   reg                          IN_XMIT;

   always @ (posedge CLK) begin
      if (RST) begin
         IN_XMIT <= 0;
      end else begin
         IN_XMIT <= SOF ? 1 : EOF ? 0 : IN_XMIT;
      end
   end

   assign M_AXI_TX_TVALID = (IN_XMIT & TVALID) | SOF | EOF;
endmodule

module axi2sofeof
  # ( parameter AXI_Width = 16 )
   ( input wire                  CLK, RST,

     input wire [AXI_Width-1:0]  S_AXI_RX_TDATA,
     input wire                  S_AXI_RX_TVALID,
     input wire                  S_AXI_RX_TLAST,

     output wire                 RVALID,
     output wire [AXI_Width-1:0] DATA,
     output wire                 SOF, EOF                
    );

   // passthrough signals
   assign RVALID = S_AXI_RX_TVALID;
   assign DATA   = S_AXI_RX_TDATA;
   assign EOF    = S_AXI_RX_TLAST;

   reg                          IN_FRAME;

   always @ (posedge CLK) begin
      if (RST) begin
         IN_FRAME <= 0;
      end else begin
         if (EOF)
           IN_FRAME <= 0;
         else
           if (RVALID) IN_FRAME <= 1;
      end
   end

   assign SOF = RVALID & ~IN_FRAME;
   
endmodule // axi2sofeof

`default_nettype wire
