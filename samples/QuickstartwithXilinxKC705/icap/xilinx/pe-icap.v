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
//    pe_icap: ICAP controller with router interface
// ----------------------------------------------------------------------

`default_nettype none

module pe_icap
  (
   input wire         CLK250, CLK100, // 250MHz
   input wire         SYS_RST, // Power-on reset
   input wire         PE_RST, 

   input wire [63:0]  D, 
   input wire         D_VALID,
   output reg         D_BP, 
   
   output wire [63:0] Q,
   output wire        Q_VALID, 
   input wire         Q_BP,

   output wire        BUSY
   );
   
   // 100MHz clock region stuff
   reg                RST_TMP, RST100;
   reg                PE_RST_TMP, PE_RST100;

   // PE_RST may not captured by CLK100...
   //    (but it should work without resetting)
   always @ (posedge CLK100) begin
      RST_TMP <= SYS_RST;  RST100 <= RST_TMP;
      PE_RST_TMP <= PE_RST; PE_RST100 <= PE_RST_TMP;
   end

   // ------------------------------
   // Ignore length header

   reg PASS_D_VALID;
   always @ (posedge CLK250) begin
      if (PE_RST)
        PASS_D_VALID <= 0;
      else
        if (D_VALID) PASS_D_VALID <= 1;
   end
   
   // ------------------------------
   // FIFO 

   wire FIFO_FULL, FIFO_AFULL;
   wire              FIFO_RE, FIFO_EMPTY;
   wire [31:0]       FIFO_Q;
        
   fifo_64x512_32_async_afull fifo
     (
      .rst(SYS_RST),              // I rst
      .wr_clk(CLK250),            // I wr_clk
      .rd_clk(CLK100),            // I rd_clk
      .din({D[31:0], D[63:32]}),  // I [63 : 0] din
      .wr_en(D_VALID & PASS_D_VALID), // I wr_en

      .rd_en(FIFO_RE),            // I rd_en
      .dout(FIFO_Q),              // O [31 : 0] dout
      .full(FIFO_FULL),           // O full
      .empty(FIFO_EMPTY),         // O empty
      .prog_full(FIFO_AFULL)      // O prog_full
      );
   
   always @ (posedge CLK250) D_BP <= FIFO_FULL | FIFO_AFULL;
   
   // ------------------------------
   // Reply frame generator

   reg [3:0]         STAT_REPLY;
   reg [3:0]         REPLY_CNT;
   reg [63:0]        D_TOGO;
   
   always @ (posedge CLK250) begin
      if (SYS_RST | PE_RST) begin
         STAT_REPLY <= 4'b0001;
      end else begin
         case (STAT_REPLY)
           4'b0001: begin
              REPLY_CNT  <= 0;
              if (D_VALID) begin
                 D_TOGO <= D;
                 STAT_REPLY <= 4'b0010;
              end
           end
           4'b0010: begin // receiving
              if (D_VALID) D_TOGO <= D_TOGO-1;
              if (D_TOGO==0) STAT_REPLY <= 4'b0100;
           end

           4'b0100: begin
              if (~BUSY) STAT_REPLY <= 4'b1000;
           end
           
           4'b1000: begin
              REPLY_CNT <= REPLY_CNT+ 1;
              if (REPLY_CNT==10) STAT_REPLY <= 4'b0001;
           end
         
           default:
             STAT_REPLY <= 4'b0001;
         endcase // case (STAT_REPLY)
      end
   end

   assign Q       = (REPLY_CNT==7) ? 1 : 0;
   assign Q_VALID = (REPLY_CNT==7 | REPLY_CNT==8);
   
   // ------------------------------
   // 100MHz region
   
   reg [3:0]         STAT;
   reg [31:0]        CFG_DATA_TOGO, CFG_DATA_LEN;
   reg               FIFO_VALID;

   reg [3:0]         CSI_WAIT;
   
   assign FIFO_RE = STAT[2] | STAT[0];

   always @ (posedge CLK100) begin
      FIFO_VALID <= (STAT[2] | STAT[0]) & (~FIFO_EMPTY);
      
      if (PE_RST100 | RST100) begin
         STAT <= 4'b0001;
      end else begin
         if (STAT[1]) CSI_WAIT <= CSI_WAIT + 1;

         case (STAT)
           4'b0001: begin
              if (~FIFO_EMPTY) begin
                 STAT <= 4'b0010;
                 CSI_WAIT <= 0;
              end
           end

           4'b0010: begin
              if (FIFO_VALID) begin
                 CFG_DATA_TOGO <= FIFO_Q;
                 CFG_DATA_LEN  <= FIFO_Q;
              end
              if (&CSI_WAIT) STAT <= 4'b0100;
           end
           
           4'b0100: begin
              if (FIFO_VALID) begin
                 CFG_DATA_TOGO <= CFG_DATA_TOGO - 4; // 32bit word
                 if (CFG_DATA_TOGO == 4) STAT <= 4'b1000;
              end
           end

           4'b1000: STAT <= 4'b0001;
           default: STAT <= 4'b0001;
         endcase // case (STAT)
      end
   end

   wire ICAP_RDWR_B = ~|STAT[2:1];
   wire ICAP_CSI_B  = ~(STAT[2] & FIFO_VALID);

   wire ICAP_DONE = STAT[3];

   // ------------------------------
   // BUSY signal in 250MHz region

   // Double flopping
   
   wire IDLE100 = STAT[0];
   reg  IDLE_R, IDLE_R2;
   wire BUSYi = ~IDLE_R2;

   always @ (posedge CLK250) begin
      IDLE_R  <= IDLE100;
      IDLE_R2 <= IDLE_R;
   end

   // Additional delay for startup

   reg [11:0] BUSY_CNT;
   parameter  BusyCntInit = 12'hf_ff;
   
   always @ (posedge CLK250) begin
      if (SYS_RST | PE_RST) begin
         BUSY_CNT <= 0;
      end else begin
         if (BUSYi) BUSY_CNT <= BusyCntInit;
         else if (BUSY_CNT !=0) BUSY_CNT <= BUSY_CNT-1;
      end
   end

   assign BUSY = BUSYi | (BUSY_CNT!=0);
   
   // ------------------------------
   // ICAP instance

   function [7:0] reverse8;
      input [7:0] IN;
      
      reverse8 = { IN[0], IN[1], IN[2], IN[3], IN[4], IN[5], IN[6], IN[7] };
   endfunction // reverse8

   wire [31:0] ICAP_D = { reverse8(FIFO_Q[31:24]), reverse8(FIFO_Q[23:16]),
                          reverse8(FIFO_Q[15: 8]), reverse8(FIFO_Q[ 7: 0]) };

`ifndef RTL_SIM
   ICAPE2 #(
            .DEVICE_ID(32'h365_1093),  // deice ID for simulation
            .ICAP_WIDTH("X32")         // I/O data width
            )
   ICAPE2_inst (
                .O    (), 
                .CLK  (CLK100),
                .CSIB (ICAP_CSI_B),
                .I    (ICAP_D),   
                .RDWRB(ICAP_RDWR_B)
                );
 `endif

   // ------------------------------
/* -----\/----- EXCLUDED -----\/-----

   // stuff to display:
   //   CFG_DATA_LEN[23:0], CFG_DATA_TOGO[23:0]
   //   CSI_B, RDWR_B, STAT[3:0]

   wire [255:0] DISP;

   // upper line
   
   assign DISP[255:248] = 8'h4c; // 'L'
   
   bin2asc #(.Width(24)) 
   disp_cfg_data_tg ( .CLK(CLK100), .D(CFG_DATA_TOGO[23:0]), .Q(DISP[247:200]));

   assign DISP[199:176] = 24'h20_2f_20; // ' / '
   
   bin2asc #(.Width(24)) 
   disp_cfg_data_len ( .CLK(CLK100), .D(CFG_DATA_LEN[23:0]), .Q(DISP[175:128]));

   // lower line

   assign DISP[127: 96] = 32'h43_53_49_3a;        // 'CSI:'
   assign DISP[ 95: 88] = ICAP_CSI_B ? 8'h48 : 8'h4c;  // H / L
   assign DISP[ 87: 56] = 32'h20_52_57_3a;        // ' RW:'
   assign DISP[ 55: 48] = ICAP_RDWR_B ? 8'h48 : 8'h4c; // H / L
   assign DISP[ 47:  8] = 40'h20_53_54_41_3a  ; // ' STA:'

   bin2asc #(.Width(4)) 
   disp_icap_stat ( .CLK(CLK100), .D(STAT), .Q(DISP[7:0]));

//   assign DISP[31:0] = 32'h20_20_20_20;

   // output

   reg [255:0]  DISP_R1, DISP_R2;

   always @ (posedge CLK) begin
      DISP_R1 <= DISP;
      DISP_R2 <= DISP_R1;
   end

   assign LCD = DISP_R2;
   
 -----/\----- EXCLUDED -----/\----- */
   
endmodule


`default_nettype wire
  
