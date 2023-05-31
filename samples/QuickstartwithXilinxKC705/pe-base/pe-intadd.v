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
//    pe(_intadd): adding uint64 vector
//    tb_pe      : simple testbench
// ----------------------------------------------------------------------

`default_nettype none
`timescale 1ns/1ps

module pe #
  ( parameter Stages=4 )
   (
    input wire         CLK, SYS_RST,
    input wire         PE_RST,

    output wire        D_BP,    D2_BP,
    input wire [63:0]  D,       D2,
    input wire         D_VALID, D2_VALID,

    input wire         Q_BP,    Q2_BP,
    output wire [63:0] Q,       Q2,
    output wire        Q_VALID, Q2_VALID
   );

   // ------------------------------
   // Back pressure register
   reg                 Q_BP_R;
   always @ (posedge CLK) Q_BP_R <= Q_BP;

   // ------------------------------
   // Input synchronization FIFOs
   wire [63:0]         F1_Q, F2_Q;
   wire                F1_EMPTY, F2_EMPTY, F1_VALID, F2_VALID;
   wire                FIFO_RE = ~F1_EMPTY & ~F2_EMPTY & ~Q_BP_R;
   
   fwft_64x512_afull fifo1 
     ( .clk (CLK),  .srst (SYS_RST),
       .din (D),    .wr_en(D_VALID),  .prog_full(D_BP),
       .dout(F1_Q), .rd_en(FIFO_RE),  .empty    (F1_EMPTY), .valid(F1_VALID) );

   fwft_64x512_afull fifo2
     ( .clk (CLK),  .srst (SYS_RST),
       .din (D2),   .wr_en(D2_VALID), .prog_full(D2_BP),
       .dout(F2_Q), .rd_en(FIFO_RE),  .empty    (F2_EMPTY), .valid(F2_VALID) );

   // ------------------------------
   reg                 IDLE, Q_VR;
   reg [63:0]          Q_R;
   reg [31:0]          D_TOGO;

   always @ (posedge CLK) begin
      Q_VR <= FIFO_RE;
      
      if (SYS_RST | PE_RST) begin
         IDLE   <= 1;
         D_TOGO <= 0;
      end else begin
         if (IDLE) begin
            if (FIFO_RE) begin
               IDLE   <= 0;
               D_TOGO <= F1_Q[31:0];
               Q_R    <= F1_Q;
            end
         end else begin
            if (FIFO_RE) begin
               D_TOGO <= D_TOGO - 1;
               Q_R    <= F1_Q + F2_Q;
               if (D_TOGO==1) IDLE <= 1;
            end
         end
      end
   end

   assign Q_VALID  = Q_VR;
   assign Q        = Q_R;
   
   assign Q2_VALID = 0;
   
endmodule // pe

`ifdef USE_PE_INTADD_TB
module pe_intadd_tb();
   parameter Step = 10;
   reg CLK = 1;
   always #(Step/2) CLK <= ~CLK;

   reg RST;
   reg [63:0] D, D2;
   reg        D_VALID, D2_VALID, Q_BP, Q2_BP;

   initial begin
      $shm_open();
      $shm_probe("SA");

      RST     <= 1;
      D_VALID <= 0; D2_VALID <= 0;
      Q_BP    <= 0; Q2_BP    <= 0;

      #(10.1*Step)
      RST <= 0;

      #(10*Step) D_VALID <= 1;  D <= 8;
      #( 1*Step) D_VALID <= 0;

      #( 3*Step)  D_VALID <= 1; D <= 64'h10;
      #( 1*Step)  D_VALID <= 1; D <= 64'h11;
      #( 1*Step)  D_VALID <= 1; D <= 64'h12;
      #( 1*Step)  D_VALID <= 1; D <= 64'h13;
      #( 1*Step)  D_VALID <= 0;

      #(16*Step)  D_VALID <= 1; D <= 64'h14;
      #( 1*Step)  D_VALID <= 1; D <= 64'h15;
      #( 1*Step)  D_VALID <= 1; D <= 64'h16;
      #( 1*Step)  D_VALID <= 1; D <= 64'h17;
      #( 1*Step)  D_VALID <= 0;
      
   end

   initial begin
      #(10.1*Step)
      D2_VALID <= 0;
      
      #(12*Step) D2_VALID <= 1;  D2 <= 4;
      #( 1*Step) D2_VALID <= 0;

      #( 3*Step)  D2_VALID <= 1; D2 <= 64'h20;
      #( 1*Step)  D2_VALID <= 0;
      #( 2*Step)  D2_VALID <= 1; D2 <= 64'h21;
      #( 1*Step)  D2_VALID <= 0;
      #( 2*Step)  D2_VALID <= 1; D2 <= 64'h22;
      #( 1*Step)  D2_VALID <= 0;
      #( 2*Step)  D2_VALID <= 1; D2 <= 64'h23;
      #( 1*Step)  D2_VALID <= 0;
      #(10*Step)  D2_VALID <= 1; D2 <= 64'h24;
      #( 1*Step)  D2_VALID <= 1; D2 <= 64'h25;
      #( 1*Step)  D2_VALID <= 1; D2 <= 64'h26;
      #( 1*Step)  D2_VALID <= 1; D2 <= 64'h28;
      #( 1*Step)  D2_VALID <= 0;

      #(10*Step)  $finish;
   end

   always @ (posedge CLK) begin
      if (uut.Q_VALID) $display("%d: Q=%x", $time, uut.Q);
   end

  
   pe uut
     ( .CLK(CLK), .SYS_RST(RST), .PE_RST(RST),
       .D (D),  .D_VALID (D_VALID),  .D_BP(),
       .D2(D2), .D2_VALID(D2_VALID), .D2_BP(),
       .Q (),   .Q_VALID (),         .Q_BP(Q_BP),
       .Q2(),   .Q2_VALID(),         .Q2_BP(Q2_BP) );
   
endmodule // pe_intadd_tb
`endif

`default_nettype wire
