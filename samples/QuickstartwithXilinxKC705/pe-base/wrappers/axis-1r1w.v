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
//    pe: 1-input + 1-output AXI Stream, Vivado HLS PE wrapper
// To use:
//    1. Modify "HLS PE instance" to fit your HLS module.
//    2. If your HLS module has more input/output port, please
//       use axis-2r2w.v instead.
// ----------------------------------------------------------------------

`default_nettype none

module pe
  ( input wire         CLK, SYS_RST,
    input wire         PE_RST,

    output wire        D_BP,    D2_BP,
    input wire [63:0]  D,       D2,
    input wire         D_VALID, D2_VALID,

    input wire         Q_BP,    Q2_BP,
    output wire [63:0] Q,       Q2,
    output wire        Q_VALID, Q2_VALID
   );

   // ------------------------------
   // Register input signals
   
   reg [0:0]          DV_R ;
   reg [63:0]         D_R [0:0];

   always @ (posedge CLK) begin
      DV_R[0] <= D_VALID;
      D_R [0] <= D;
   end

   // ------------------------------
   // Tie down unused ports
   
   assign D2_BP = 0;
   assign Q2_VALID = 0;

   // ------------------------------
   // Input FIFOs and synchronous readout control
   
   wire               PE_BP;
   wire [63:0]        FIFO_Q[0:0];
       
   wire [0:0]         FULL, AFULL, EMPTY, VALID, READY;

   assign D_BP  = |{AFULL[0], FULL[0] };
   
   fwft_64x512_afull dfifo_1
     (
      .clk      (CLK),        // I
      .srst     (SYS_RST),    // I
      .din      (D_R[0]),     // I [63:0]
      .wr_en    (DV_R[0]),    // I
      .rd_en    (READY[0]),         // I
      .dout     (FIFO_Q[0]),  // O [63:0]
      .full     (FULL  [0]),  // O
      .empty    (EMPTY [0]),  // O
      .valid    (VALID [0]),  // O
      .prog_full(AFULL [0])   // O
      );
   

   // ------------------------------
   // Output FIFO

   wire               Q_AFULL, Q_FULL;
   wire [63:0]        PE_Q;
   wire               PE_Q_VALID;

   wire               Q_READY = ~(Q_AFULL | Q_FULL);
   wire               Q_WE = PE_Q_VALID & Q_READY;

   wire               QF_VALID;
   
   fwft_64x512_afull qfifo
     (
      .clk      (CLK),        // I
      .srst     (SYS_RST),    // I
      .din      (PE_Q),       // I [63:0]
      .wr_en    (Q_WE), // I
      .rd_en    (~Q_BP  ),    // I
      .dout     (Q      ),    // O [63:0]
      .full     (Q_FULL   ),  // O
      .empty    (),  // O
      .valid    (QF_VALID  ),  // O
      .prog_full(Q_AFULL  )   // O
      );

   assign Q_VALID = QF_VALID & ~Q_BP;
   
   // ------------------------------
   // HLS PE instance

   CHANGE_ME hls_core
     (
      .ap_clk  (CLK),
      .ap_rst_n(~PE_RST),
      .ap_start(1'b1),
      .ap_done (),
      .ap_idle (),
      .ap_ready(),
      
      .in_V_TDATA (FIFO_Q[0]),
      .in_V_TVALID(VALID[0]),
      .in_V_TREADY(READY[0]),
      .out_V_TDATA (PE_Q),
      .out_V_TVALID(PE_Q_VALID),
      .out_V_TREADY(Q_READY)
      );
   
endmodule // pe

`default_nettype wire
