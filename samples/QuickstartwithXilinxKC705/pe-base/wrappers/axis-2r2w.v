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
//    pe: 2-input + 2-output AXI Stream, Vivado HLS PE wrapper
// To use:
//    1. Modify "HLS PE instance" to fit your HLS module.
//    2. If your HLS module has only 1 input (or output) port,
//       don't forget to edit 'Disable port' section of this file
// ----------------------------------------------------------------------

`default_nettype none

module pe
  ( input wire         CLK, SYS_RST,
    input wire         PE_RST,

    output wire        D_BP, D2_BP,
    input wire [63:0]  D, D2,
    input wire         D_VALID, D2_VALID,

    input wire         Q_BP, Q2_BP,
    output wire [63:0] Q, Q2,
    output wire        Q_VALID, Q2_VALID
    );

   // ------------------------------
   // Register input signals
   
   reg [1:0]           DV_R ;
   reg [63:0]          D_R [1:0];

   always @ (posedge CLK) begin
      DV_R[0] <= D_VALID;
      DV_R[1] <= D2_VALID;
      D_R [0] <= D;
      D_R [1] <= D2;
   end

   // ------------------------------
   // Input FIFOs

   wire               PE_BP;
   wire [63:0]        FIFO_Q[1:0];

   wire [1:0]         FULL, AFULL, EMPTY, VALID, READY;

   assign D_BP  = |{AFULL[0], FULL[0] };
   assign D2_BP = |{AFULL[1], FULL[1] };

   fwft_64x512_afull dfifo1
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

   fwft_64x512_afull dfifo2
     (
      .clk      (CLK),        // I
      .srst     (SYS_RST),    // I
      .din      (D_R[1]),     // I [63:0]
      .wr_en    (DV_R[1]),    // I
      .rd_en    (READY[1]),         // I
      .dout     (FIFO_Q[1]),  // O [63:0]
      .full     (FULL  [1]),  // O
      .empty    (EMPTY [1]),  // O
      .valid    (VALID [1]),  // O
      .prog_full(AFULL [1])   // O
      );

   
   // ------------------------------
   // Output FIFOs

   wire [1:0]         Q_AFULL, Q_FULL;
   wire [63:0]        PE_Q [1:0];
   wire [1:0]         PE_Q_VALID, PE_Q_READY;
   wire [1:0]         QF_VALID;

   fwft_64x512_afull qfifo1
     (
      .clk      (CLK),           // I
      .srst     (SYS_RST),       // I
      .din      (PE_Q[0]),       // I [63:0]
      .wr_en    (PE_Q_VALID[0] & PE_Q_READY[0]), // I
      .rd_en    (~Q_BP  ),       // I
      .dout     (Q      ),       // O [63:0]
      .full     (Q_FULL[0]   ),  // O
      .empty    (),              // O
      .valid    (QF_VALID[0] ),  // O
      .prog_full(Q_AFULL[0]  )   // O
      );

   fwft_64x512_afull qfifo2
     (
      .clk      (CLK),           // I
      .srst     (SYS_RST),       // I
      .din      (PE_Q[1]),       // I [63:0]
      .wr_en    (PE_Q_VALID[1] & PE_Q_READY[1]), // I
      .rd_en    (~Q2_BP ),       // I
      .dout     (Q2     ),       // O [63:0]
      .full     (Q_FULL[1]   ),  // O
      .empty    (),              // O
      .valid    (QF_VALID[1] ),  // O
      .prog_full(Q_AFULL[1]  )   // O
      );

   assign Q_VALID  = QF_VALID[0] & ~Q_BP;
   assign Q2_VALID = QF_VALID[1] & ~Q2_BP;
   assign PE_Q_READY = ~(Q_AFULL|Q_FULL);

   // ------------------------------
   // HLS PE instance

   // If your PE has no "in2" and/or "out2" port, please
   // comment out them, and also please modify the "Disable port"
   // section below.
   
   CHANGE_ME prpe
     (
      .ap_clk  (CLK),
      .ap_rst_n(~SYS_RST),
      .ap_start(1'b1),
      .ap_done (),
      .ap_idle (),
      .ap_ready(),

      .in1_V_TDATA (FIFO_Q[0]),
      .in1_V_TVALID(VALID[0]),
      .in1_V_TREADY(READY[0]),
      .in2_V_TDATA (FIFO_Q[1]),
      .in2_V_TVALID(VALID[1]),
      .in2_V_TREADY(READY[1]),
      .out1_V_TDATA (PE_Q[0]),
      .out1_V_TVALID(PE_Q_VALID[0]),
      .out1_V_TREADY(PE_Q_READY[0]),
      .out2_V_TDATA (PE_Q[1]),
      .out2_V_TVALID(PE_Q_VALID[1]),
      .out2_V_TREADY(PE_Q_READY[1])
      );

   // ------------------------------
   // Disable port

   // If your PE has no "in2", remove "//": 
   // assign READY[1] = 0;

   // If your PE has no "out2", remove "//":
   // assign PE_Q_VALID[1] = 0;
   
endmodule // pe

`default_nettype wire
