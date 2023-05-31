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
//    xillybus_compat: Xillybus compatible adapter for RIFFA
// ----------------------------------------------------------------------

`timescale 1ns/1ps
`default_nettype none

module xillybus_compat #
  (
   parameter C_PCI_DATA_WIDTH = 9'd64
   )(
     // Riffa Interface
     input wire                         CLK,
     input wire                         RST,
     output wire                        CHNL_RX_CLK, 
     input wire                         CHNL_RX, 
     output wire                        CHNL_RX_ACK, 
     input wire                         CHNL_RX_LAST, 
     input wire [31:0]                  CHNL_RX_LEN, 
     input wire [30:0]                  CHNL_RX_OFF, 
     input wire [C_PCI_DATA_WIDTH-1:0]  CHNL_RX_DATA, 
     input wire                         CHNL_RX_DATA_VALID, 
     output wire                        CHNL_RX_DATA_REN,
  
     output wire                        CHNL_TX_CLK, 
     output wire                        CHNL_TX, 
     input wire                         CHNL_TX_ACK, 
     output wire                        CHNL_TX_LAST, 
     output wire [31:0]                 CHNL_TX_LEN, 
     output wire [30:0]                 CHNL_TX_OFF, 
     output wire [C_PCI_DATA_WIDTH-1:0] CHNL_TX_DATA, 
     output wire                        CHNL_TX_DATA_VALID, 
     input wire                         CHNL_TX_DATA_REN,

     // FIFO interface
     output wire                        FIFO_W_WREN, // Source FIFO
     input wire                         FIFO_W_FULL,
     output wire [C_PCI_DATA_WIDTH-1:0] FIFO_W_D,

     input wire                         FIFO_R_EMPTY, // Sink FIFO
     output wire                        FIFO_R_RDEN,
     input wire [C_PCI_DATA_WIDTH-1:0]  FIFO_R_D                         
     );

   assign CHNL_RX_CLK = CLK;
   assign CHNL_TX_CLK = CLK;

   // ------------------------------
   // FIFO interface signals
   
   wire [C_PCI_DATA_WIDTH-1:0]          FIFO_D, FIFO_Q;
   wire                                 FIFO_WE, FIFO_RE;
   wire                                 FIFO_FULL, FIFO_EMPTY, 
                                        FIFO_AFULL;

   reg                                  FIFO_VALID;
   reg                                  FIFO_QR_VALID; // output while ~REN
   reg [C_PCI_DATA_WIDTH-1:0]           FIFO_QR;
   
   always @ (posedge CLK) begin
      FIFO_VALID <= ~FIFO_EMPTY & FIFO_RE;

      if (RST) begin
         FIFO_QR_VALID <= 0;
      end else begin
         case (FIFO_QR_VALID)
           0:
             if (FIFO_VALID & ~CHNL_TX_DATA_REN) begin
                FIFO_QR_VALID <= 1;
                FIFO_QR <= FIFO_Q;
             end
           1:
             if (CHNL_TX_DATA_REN) FIFO_QR_VALID <= 0;
         endcase // case (FIFO_QR_VALID)
      end
   end


   // ------------------------------

   wire [31:0] RX_TOGOt, TX_TOGOt, TX_LEN_Rt;
   reg [C_PCI_DATA_WIDTH-1:0]  PAYLOAD_LEN;
   
   generate
      if (C_PCI_DATA_WIDTH==128) begin : ctrl_128
         // 128bit TLP interface
         assign RX_TOGOt  = {2'b0, CHNL_RX_LEN[31:2]} + (|CHNL_RX_LEN[1:0] ? 1 : 0);
         assign TX_TOGOt  = {1'b0, FIFO_Q[31:1]};
         assign TX_LEN_Rt = {FIFO_Q[30:0], 1'b0} + 2;
      end else begin : ctrl_64
         // Default is 64bit
         assign RX_TOGOt = {1'b0, CHNL_RX_LEN[31:1]};
         assign TX_TOGOt = FIFO_Q;
         assign TX_LEN_Rt = {FIFO_Q[30:0], 1'b0} + 2;
      end

  endgenerate
   
   // ------------------------------
   // RX control logic
   
   reg [3:0]                            RX_STAT;
   reg [31:0]                           RX_LEN, RX_TOGO;

   assign CHNL_RX_ACK = RX_STAT[1];
   assign CHNL_RX_DATA_REN = RX_STAT[2] & ~FIFO_FULL;
   
   assign FIFO_WE = RX_STAT[2] & CHNL_RX_DATA_VALID & ~FIFO_FULL;
   assign FIFO_D  = CHNL_RX_DATA;
   
   always @ (posedge CLK) begin
      if (RST) begin
         RX_STAT <= 4'b0001;
         RX_TOGO <= 0;
      end else begin
         case (RX_STAT)
           4'b0001:
             if (CHNL_RX) begin
                RX_STAT <= 4'b0010;
                RX_LEN  <= CHNL_RX_LEN;
                RX_TOGO <= RX_TOGOt;
             end

           4'b0010: // ACK stage
             RX_STAT <= 4'b0100; 

           4'b0100: begin // Receive stage
              if (CHNL_RX_DATA_VALID & ~FIFO_FULL) begin
                 if (RX_TOGO == 1) RX_STAT <= 4'b1000;
                 RX_TOGO <= RX_TOGO - 1;
              end
           end

           4'b1000: begin // wait for session to terminate
              if (~CHNL_RX) RX_STAT <= 4'b0001;
           end
          
           default:
             RX_STAT <= 4'b0001;
         endcase
      end
   end

   // ------------------------------
   // TX control logic

   reg [4:0] TX_STAT;
   
   reg [31:0]  TX_LEN_R, TX_TOGO, TX_TOGOtR;
   
   assign CHNL_TX = |TX_STAT[4:2];
   assign CHNL_TX_LEN = TX_LEN_R;
   
   assign CHNL_TX_OFF = 31'b0;

   
   always @ (posedge CLK) begin
      if (RST) begin
         TX_STAT <= 5'b00001;
         TX_TOGO <= 0;
      end else begin
         case (TX_STAT)
           5'b00001: begin // idle
              if (~FIFO_EMPTY) TX_STAT <= 5'b00010;
           end

           5'b00010: begin // Length header comes from FIFO
              TX_LEN_R <= TX_LEN_Rt;
              TX_TOGOtR  <= TX_TOGOt;
              PAYLOAD_LEN <= FIFO_Q;
              TX_STAT  <= 5'b00100;
           end

           5'b00100: begin // wait for ACK
              TX_TOGO <= TX_TOGOtR + 1;
              if (CHNL_TX_ACK) TX_STAT <= 5'b01000;
           end

           5'b01000: begin // Send Header
              if (CHNL_TX_DATA_REN) begin
                 TX_TOGO <= TX_TOGO-1;
                 TX_STAT <= 5'b10000;
                 if (TX_TOGO==1) TX_STAT <= 5'b00001;
              end
           end

           5'b10000: begin // Send Payload
              if (CHNL_TX_DATA_VALID & CHNL_TX_DATA_REN) begin
                 TX_TOGO <= TX_TOGO-1;
                 if (TX_TOGO==1) TX_STAT <= (FIFO_EMPTY ? 5'b0001 : 5'b00010);
              end
           end
           
           default:
             TX_STAT <= 5'b00001;
         endcase

      end
   end

   assign FIFO_RE  = TX_STAT[0] | (TX_STAT[4] & CHNL_TX_DATA_REN);
   assign CHNL_TX_DATA_VALID = TX_STAT[3] | 
                                (TX_STAT[4] & (FIFO_VALID | FIFO_QR_VALID) );
   
   assign CHNL_TX_DATA = TX_STAT[3] ? PAYLOAD_LEN :
                          TX_STAT[4] ? (FIFO_QR_VALID ? FIFO_QR : FIFO_Q) : 0;
   
   assign CHNL_TX_LAST = 1'b1;

   // ------------------------------
   // FIFO <-> Xillybus signal conversion
   
   assign FIFO_W_WREN = FIFO_WE;
   assign FIFO_W_D    = FIFO_D;
   assign FIFO_FULL   = FIFO_W_FULL;
   
   assign FIFO_EMPTY  = FIFO_R_EMPTY;
   assign FIFO_R_RDEN = FIFO_RE;
   assign FIFO_Q      = FIFO_R_D;

   // ------------------------------

/* -----\/----- EXCLUDED -----\/-----
   wire TX_END = TX_STAT[4] & (TX_TOGO == 1);
   reg  RX_REN_R;
   always @ (posedge CLK) RX_REN_R <= CHNL_RX_DATA_REN;

   wire RX_BP = RX_REN_R & ~CHNL_RX_DATA_REN;
   
   ila_128 ila
     (
      .clk(CLK),
      .probe0
      ({ 
         RX_STAT, RX_TOGO,
         CHNL_RX, CHNL_RX_ACK, CHNL_RX_DATA_VALID, CHNL_RX_DATA_REN,
         FIFO_W_D[71:64], FIFO_W_D[7:0],
         FIFO_R_D[71:64], FIFO_R_D[7:0],
         FIFO_W_WREN, FIFO_W_FULL,
         TX_STAT, TX_TOGO,
         CHNL_TX, CHNL_TX_ACK, CHNL_TX_DATA_VALID, CHNL_TX_DATA_REN,
         FIFO_R_EMPTY, FIFO_R_RDEN, 
         TX_END, RX_BP
      })
      );
 -----/\----- EXCLUDED -----/\----- */

endmodule // xillybus_compat

`default_nettype wire

