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
//    top: a top-level module for Avnet Kintex Ultrascale 040 Dev Board
// ----------------------------------------------------------------------

`default_nettype none

module top
  ( // Clock signals
    input wire        CLK156P, CLK156N,
    input wire        CLK250P, CLK250N,
    
    // SerDes channels: SFP1 + SMA1 / SFP1 + SFP2
    output wire       SFP1_TXP, SFP1_TXN, 
    input wire        SFP1_RXP, SFP1_RXN,
                      
`ifdef GT_SFP1SFP2
    output wire       SFP2_TXP, SFP2_TXN,
    input wire        SFP2_RXP, SFP2_RXN,
`endif

`ifdef GT_SFP1SMA1
    output wire       SMA1_TXP, SMA1_TXN,
    input wire        SMA1_RXP, SMA1_RXN,
`endif

    // LEDs
    output wire [7:0] LED
    );
   
   // ------------------------------------------------------------
   // Clock managers 
   //   - no CLK50 is required in Aurora Ultrascale
   //   - no PCIe clock: 250MHz supplied externally
   //   - RST driven by DCM_LOCKED

   wire               CLK, RST;
   wire               CLK100, CLK200, GTREFCLK156;
   wire               DCM_LOCKED;

   ku040_clk cm
     ( .CLK250P(CLK250P), .CLK250N(CLK250N), // I 
       .CLK156P(CLK156P), .CLK156N(CLK156N), // I

       .CLK100(CLK100),  .CLK250(CLK),       // O
       .GTREFCLK156  (GTREFCLK156),          // O
       .DCM_LOCKED   (DCM_LOCKED)            // O
    );    

    assign RST = ~DCM_LOCKED;

   // ------------------------------------------------------------
   // Aurora interface: {SFP1, SMA1} = {SFP1, SMA1} or {SFP1, SFP2}
   
   wire               SFP1_PE_RST, SFP2_PE_RST, SMA1_PE_RST;
   wire [1:0]         GT_UP;

   wire [127:0]       GT_D, GT_Q;
   wire [1:0]         GT_D_VALID, GT_Q_VALID, GT_D_BP, GT_Q_BP;

`ifdef GT_SFP1SMA1   
   aurora_dual au
     ( .CLK250(CLK),  .SYS_RST(RST), .PE_RST({SFP1_PE_RST, SMA1_PE_RST}),
       .CLK100(CLK100),
       .GTREFCLK156(GTREFCLK156),
       .DCM_LOCKED (DCM_LOCKED),

       .SFP1_TXP(SFP1_TXP), .SFP1_TXN(SFP1_TXN),
       .SFP1_RXP(SFP1_RXP), .SFP1_RXN(SFP1_RXN),
       .SMA1_TXP(SMA1_TXP), .SMA1_TXN(SMA1_TXN),
       .SMA1_RXP(SMA1_RXP), .SMA1_RXN(SMA1_RXN),

       .SFP1_D      (GT_D[63:0]),    .SFP1_Q   (GT_Q[63:0]), 
       .SFP1_D_VALID(GT_D_VALID[0]), .SFP1_D_BP(GT_D_BP[0]),
       .SFP1_Q_VALID(GT_Q_VALID[0]), .SFP1_Q_BP(GT_Q_BP[0]),
       .SMA1_D      (GT_D[127:64]),  .SMA1_Q   (GT_Q[127:64]), 
       .SMA1_D_VALID(GT_D_VALID[1]), .SMA1_D_BP(GT_D_BP[1]),
       .SMA1_Q_VALID(GT_Q_VALID[1]), .SMA1_Q_BP(GT_Q_BP[1]),

       .CH_UP(GT_UP) );
`endif

`ifdef GT_SFP1SFP2
   aurora_dual au
     ( .CLK250(CLK),  .SYS_RST(RST), .PE_RST({SFP1_PE_RST, SMA1_PE_RST}),
       .CLK100(CLK100),
       .GTREFCLK156(GTREFCLK156),
       .DCM_LOCKED (DCM_LOCKED),

       .SFP1_TXP(SFP1_TXP), .SFP1_TXN(SFP1_TXN),
       .SFP1_RXP(SFP1_RXP), .SFP1_RXN(SFP1_RXN),
       .SFP2_TXP(SFP2_TXP), .SFP2_TXN(SFP2_TXN),
       .SFP2_RXP(SFP2_RXP), .SFP2_RXN(SFP2_RXN),

       .SFP1_D      (GT_D[63:0]),    .SFP1_Q   (GT_Q[63:0]), 
       .SFP1_D_VALID(GT_D_VALID[0]), .SFP1_D_BP(GT_D_BP[0]),
       .SFP1_Q_VALID(GT_Q_VALID[0]), .SFP1_Q_BP(GT_Q_BP[0]),
       .SFP2_D      (GT_D[127:64]),  .SFP2_Q   (GT_Q[127:64]), 
       .SFP2_D_VALID(GT_D_VALID[1]), .SFP2_D_BP(GT_D_BP[1]),
       .SFP2_Q_VALID(GT_Q_VALID[1]), .SFP2_Q_BP(GT_Q_BP[1]),

       .CH_UP(GT_UP) );
`endif
   
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

   // Port 4, 5 = SFP1, SMA1 (or SFP1, SFP2)
   // Port    3 = ICAP
   // Port 1, 2 = PE

   wire  [4:0] ROUTER_Q_SOF;
   
   defparam ro.NumPorts = 5;
   defparam ro.PassThrough = 5'b00111; // Note: PE_ICAP requires PT!
   router ro
     ( .CLK(CLK), .RST(RST),
       .D      ({GT_Q,       ICAP_Q,       PE_Q      }), // I
       .D_VALID({GT_Q_VALID, ICAP_Q_VALID, PE_Q_VALID}), // I
       .D_BP   ({GT_Q_BP,    ICAP_Q_BP,    PE_Q_BP   }), // O
       
       .Q      ({GT_D,       ICAP_D,       PE_D      }), // O
       .Q_VALID({GT_D_VALID, ICAP_D_VALID, PE_D_VALID}), // O
       .Q_BP   ({GT_D_BP,    ICAP_D_BP,    PE_D_BP   }), // I
       .Q_SOF  (ROUTER_Q_SOF) ); // O: to generate PE_RST

   assign PE_RST      = ROUTER_Q_SOF[0];
   assign ICAP_PE_RST = ROUTER_Q_SOF[2];
   assign SFP1_PE_RST  = 0;
   assign SMA1_PE_RST  = 0;
   assign SFP2_PE_RST  = 0;

   // ------------------------------------------------------------
   // State LEDs

   // 0: PCIe Clock    4: 
   // 1: PCIe 0        5:
   // 2: PCIe 1        6: Aurora SFP1
   // 3:               7: Aurora SMA1

   wire [7:0] LED_LINK = { GT_UP[1:0],  // Aurora 
                           5'b0,        // Not connected (no PCIe)
                           1'b1 };      // Sysclk

   wire [7:0] LED_ACT  = { GT_D_VALID[1] | GT_Q_VALID[1], 
                           GT_D_VALID[0] | GT_Q_VALID[0],
                           5'b0,        // Not connected
                           1'b1 };      // Sys clock 

   generate
      genvar  i;
      for (i=0; i<8; i=i+1) begin : led_gen
         link_act led ( .CLK(CLK), .RST(RST), .LED(LED[i]), 
                        .LINK(LED_LINK[i]),   .ACT(LED_ACT[i])); 
      end
   endgenerate
   
endmodule // top

`default_nettype wire
