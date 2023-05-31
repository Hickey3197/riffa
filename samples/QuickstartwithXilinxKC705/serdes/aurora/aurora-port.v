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
//    aurora_port: Xilinx Aurora interface adapter
// ----------------------------------------------------------------------

`default_nettype none

module aurora_port
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
    output wire        TX_SOF, TX_EOF,
    output wire [63:0] TX_DATA,
    input wire         TX_READY,
    output wire        TX_VALID,
                      
    input wire         RX_SOF, RX_EOF,
    input wire [63:0]  RX_DATA,
    input wire         RX_VALID,

    output wire        NFC_TVALID,
    output wire [15:0] NFC_TDATA,
    input wire         NFC_TREADY
   );
   
   wire               TX_ALMOST_FULL, RX_ALMOST_FULL;
   assign D_BP = TX_ALMOST_FULL; //  | RX_ALMOST_FULL;

   
   // ----------------------------------------------------------------------
   // Aurora interface kernel : TX

   // input register
   reg                D_VALID_R;
   reg [63:0]         D_R;
   
   always @ (posedge CLK) begin
      D_VALID_R <= D_VALID;
      D_R       <= D;
   end
   
   // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
   // Xillybus FIFO -> SOF/EOF signals
  
   reg [3:0] TX_STAT;
   reg [63:0] TX_TOGO;
   always @ (posedge CLK) begin
      if (PE_RST | SYS_RST) begin
         TX_STAT <= 4'b0001;
      end else begin
         case (TX_STAT) // routing header or payload length
           4'b0001: if (D_VALID_R) begin
              if (D_R[63:56]==0) begin
                 TX_TOGO  <= D_R; // payload length received
                 TX_STAT  <= 4'b0100; end
              else
                TX_STAT <= 4'b0010; 
           end
           4'b0010: if (D_VALID_R) begin // routing header passthrough
              if (D_R[63:56]==0) begin
                 TX_TOGO  <= D_R; // payload length received
                 TX_STAT  <= 4'b0100; end
           end
           4'b0100: if (D_VALID_R) begin // Payload
              if (TX_TOGO == 1) TX_STAT <= 4'b0001;
              else TX_TOGO <= TX_TOGO - (D_VALID_R ? 1 : 0);
           end
         endcase
      end
   end
   
   wire PORT_TX_SOF = TX_STAT[0] & D_VALID_R;
   wire PORT_TX_EOF = TX_STAT[2] & D_VALID_R & (TX_TOGO == 1);

   // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
   // SOF/EOF signals -> TX FIFO

   wire TX_FIFO_FULL, TX_FIFO_EMPTY, TX_SOF_i, TX_EOF_i;

   wire TX_FIFO_WE = D_VALID_R | PORT_TX_EOF;

   wire TX_VALIDi;
   
   fifo_66x512_async_dprogfull tx_fifo 
     (
      .prog_full_thresh_assert(312), 
      .prog_full_thresh_negate(150),
      
      .rst(SYS_RST), // System reset, not PEL_RST
      .wr_clk(CLK), 
      .full(TX_FIFO_FULL),
      .prog_full(TX_ALMOST_FULL),
      .din({PORT_TX_SOF, PORT_TX_EOF, D_R}),
      .wr_en(TX_FIFO_WE),

      .rd_clk(AURORA_CLK),
      .rd_en(TX_READY),
      .dout({TX_SOF_i, TX_EOF_i, TX_DATA}), 
      .empty(TX_FIFO_EMPTY),
      .valid(TX_VALIDi)
      );

   reg TX_VALID_WHILE_NOT_READY;
         
   always @ (posedge AURORA_CLK) begin
      if (AURORA_RST) begin
        TX_VALID_WHILE_NOT_READY <= 0;
      end else begin
         case (TX_VALID_WHILE_NOT_READY)
           0: TX_VALID_WHILE_NOT_READY <= (TX_VALIDi & ~TX_READY);
           1: TX_VALID_WHILE_NOT_READY <= ~TX_READY;
         endcase
      end
   end
     
   assign TX_SOF = TX_SOF_i & TX_VALID;
   assign TX_EOF = TX_EOF_i & TX_VALID;
   assign TX_VALID = TX_VALIDi | TX_VALID_WHILE_NOT_READY;

   // ----------------------------------------------------------------------
   // Aurora interface kernel : RX

   wire [63:0] PORT_RX_DATA;
   wire        PORT_RX_SOF, PORT_RX_EOF;
   wire        RX_FIFO_EMPTY;

   assign RX_ALMOST_FULL = 0;
   wire        RX_FIFO_AFULL;
  
   wire        RX_FIFO_VALID;
   
   fifo_66x512_async_dprogfull rx_fifo 
     (
      .prog_full_thresh_assert(400), 
      .prog_full_thresh_negate(399),
      
      .rst(AURORA_RST),
      .wr_clk(AURORA_CLK),
      .full(),
      .prog_full(RX_FIFO_AFULL),
      .din({RX_SOF, RX_EOF, RX_DATA}),
      .wr_en(RX_VALID),

      .rd_clk(CLK),
      .rd_en(~Q_BP),
      .dout({PORT_RX_SOF, PORT_RX_EOF, PORT_RX_DATA}), 
      .empty(RX_FIFO_EMPTY),
      .valid(RX_FIFO_VALID)
      );

   assign Q = PORT_RX_DATA;
   assign Q_VALID = RX_FIFO_VALID;

   // ------------------------------
   // SOF-EOF state machine
   
   reg RX_STAT;
   
   always @ (posedge CLK) begin
      if (SYS_RST) begin
         RX_STAT <= 0;
      end else begin
         if (PORT_RX_EOF) RX_STAT <= 0;
         else if (PORT_RX_SOF) RX_STAT <= 1;
      end
   end

   // ------------------------------
   // Flow control message control

   // detection
   reg RX_FIFO_AFULL_R, AURORA_RST_R;
   always @ (posedge AURORA_CLK) begin
      RX_FIFO_AFULL_R <= RX_FIFO_AFULL;
      AURORA_RST_R    <= AURORA_RST;
   end

   wire RX_FC_MASK = ~(AURORA_RST | AURORA_RST_R);
       
   wire RX_FC_PAUSE    = ~RX_FIFO_AFULL_R &  RX_FIFO_AFULL & RX_FC_MASK; // asserted
   wire RX_FC_CONTINUE =  RX_FIFO_AFULL_R & ~RX_FIFO_AFULL & RX_FC_MASK; // negated   

   // message xmit

   reg [4:0] RX_FC_STAT;
   always @ (posedge AURORA_CLK) begin
      if (AURORA_RST) begin
         RX_FC_STAT <= 5'b00001;
      end else begin
         case (RX_FC_STAT)
           5'b00001:
             RX_FC_STAT <= RX_FC_PAUSE ? 5'b00010 : RX_FC_CONTINUE ? 5'b00100 : 5'b00001;
           5'b00010: // transmit pause
             RX_FC_STAT <= NFC_TREADY ? 5'b01000 : 5'b00010;
           5'b00100: // transmit continue
             RX_FC_STAT <= NFC_TREADY ? 5'b10000 : 5'b00100;
           5'b01000: // check after pause transmission
             RX_FC_STAT <= ~RX_FIFO_AFULL ? 5'b00100 : 5'b00001; // retransmit cont if ~afull
           5'b10000: // check after continue transmission
             RX_FC_STAT <=  RX_FIFO_AFULL ? 5'b00010 : 5'b00001; // retransmit pause if afull
             
           default:
             RX_FC_STAT <= 5'b00001;
         endcase
      end
   end

   assign NFC_TVALID = |RX_FC_STAT[2:1];
   assign NFC_TDATA  = RX_FC_STAT[1] ? 16'b0000_000_1_0000_0000 :
                       RX_FC_STAT[2] ? 16'b0 : 16'b0;
   
endmodule // kernel

`default_nettype wire
