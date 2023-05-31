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
//   header_adj: Adjusts length of "dummy routing header" on final
//               card-to-host DMA stream for XDMA: remaining routing
//               headers are discarded and replaced with fixed # of routing
//               headers defined with HeaderMax parameter.
// ----------------------------------------------------------------------

`timescale 1ns/1ps
`default_nettype none

module header_adj
  ( input wire CLK, RST,

    input wire         S_AXIS_TVALID,
    output wire        S_AXIS_TREADY,
    input wire         S_AXIS_TLAST,
    input wire [63:0]  S_AXIS_TDATA,
    
    output wire        M_AXIS_TVALID,
    input wire         M_AXIS_TREADY,
    output wire        M_AXIS_TLAST,
    output wire [63:0] M_AXIS_TDATA );

   parameter HeaderMax = 10; // Must be same with fpga-tools.h
   parameter time      DummyHeader = {8'h01, 56'h0};

   // ------------------------------------------------------------
   // Incoming payload length counter

   reg [31:0] PAYLOAD_TOGO;
   reg        LEN_DETECT;
   wire       LEN_HEADER = ~LEN_DETECT & (S_AXIS_TDATA[63:56] != 8'h01);
   
   always @ (posedge CLK) begin
      if (RST) begin
         LEN_DETECT <= 0;
      end else begin
         if (S_AXIS_TVALID & S_AXIS_TREADY) begin
            if (~LEN_DETECT) begin
               if (LEN_HEADER) begin
                  PAYLOAD_TOGO = S_AXIS_TDATA[31:0];
                  LEN_DETECT <= 1;
               end
            end else begin
               if (PAYLOAD_TOGO==1) LEN_DETECT <= 0;
               PAYLOAD_TOGO <= PAYLOAD_TOGO - 1;
            end
         end
      end
   end

   wire PAYLOAD_END = ( S_AXIS_TVALID & S_AXIS_TREADY & LEN_DETECT &
                        (PAYLOAD_TOGO==1 ) );


   // ------------------------------------------------------------
   // Dummy header transmission ctrl

   reg [15:0] HDR_CNT;
   reg [3:0]  HDR_STAT; // Idle -> Armed -> Done
   always @ (posedge CLK) begin
      if (RST | PAYLOAD_END) begin
         HDR_STAT <= 'b0001;
      end else begin
         case (HDR_STAT)
           'b0001: begin
              if (S_AXIS_TVALID) begin 
                 HDR_STAT <= 'b0010;
                 HDR_CNT  <= HeaderMax-1;
              end end

           'b0010: begin // transmit dummy routing header
              if (M_AXIS_TREADY) begin
                 HDR_CNT <= HDR_CNT - 1;
                 if (HDR_CNT==1) HDR_STAT <= 'b0100;
              end end

           'b0100: begin // wait for length + transmit it
              if (LEN_DETECT & M_AXIS_TREADY) HDR_STAT <= 'b1000;
              // length may be already arrived but we don't care
           end
           
           'b1000: begin // wait for tail of payload
              if (PAYLOAD_END) HDR_STAT <= 'b0001;
           end

           default:
             HDR_STAT <= 'b0001;
         endcase
      end

   end
   
   // ------------------------------------------------------------
   // AXIS forwarding

   wire IN_TVALID = S_AXIS_TVALID & HDR_STAT[3];

   reg [63:0]          TDATA_R;
   reg                 TLAST_R;
   reg                 REG_VALID;

   wire                BOTH_IN_OUT = ( IN_TVALID &  M_AXIS_TREADY);
   wire                DRAIN  = M_AXIS_TREADY & M_AXIS_TVALID;

   // AXIS Forwarding
   always @ (posedge CLK) begin
      if (RST) begin
         TDATA_R <= 0;
         TLAST_R <= 0;
         REG_VALID <= 0;
      end else begin
         if (REG_VALID) begin // has valid reg'd data
            if (BOTH_IN_OUT) begin
               TDATA_R <= S_AXIS_TDATA;
               TLAST_R <= S_AXIS_TLAST;
            end
            REG_VALID <= (BOTH_IN_OUT | ~M_AXIS_TREADY);

         end else begin       // no valid reg'd data 
            if (IN_TVALID) begin
               TDATA_R <= S_AXIS_TDATA;
               TLAST_R <= S_AXIS_TLAST;
               REG_VALID <= 1;
            end
         end
      end
   end

   assign S_AXIS_TREADY = ~LEN_DETECT ? (|HDR_STAT[2:0]) :
                          HDR_STAT[3] & (M_AXIS_TREADY | ~REG_VALID) ;
   assign M_AXIS_TDATA  = HDR_STAT[1] ? DummyHeader : 
                          HDR_STAT[2] ? PAYLOAD_TOGO :
                          TDATA_R;
   assign M_AXIS_TLAST  = TLAST_R;
   assign M_AXIS_TVALID = HDR_STAT[1] ? 1 :
                          HDR_STAT[2] ? LEN_DETECT :
                          REG_VALID;

endmodule

// ----------------------------------------------------------------------

`ifdef ENABLE_HEADER_ADJ_TB

module tb();
   parameter real Step = 10.0;

   reg            CLK = 1;
   always # (Step/2) CLK <= ~CLK;

   reg            RST;
   initial begin
      $shm_open();
      $shm_probe("SA");
      RST <= 1;

      #(15.1*Step)
      RST <= 0;

      #(3000*Step)
      $finish;
      
   end // initial begin

   parameter TDataMax = 200;
   // parameter HeaderLen = 5;
   parameter HeaderLen = 0;


   // parameter SAXI_Rate = 220; // slower
   parameter SAXI_Rate = 20; // faster
   
   wire S_AXIS_TREADY;
   reg [63:0] TDATA_CNT;
   reg        M_AXIS_TREADY;
   reg        S_AXIS_TVALID_R;
   wire       S_AXIS_TVALID = (RST | TDATA_CNT==(TDataMax)) ? 0: S_AXIS_TVALID_R;

   always @ (posedge CLK) begin
      M_AXIS_TREADY <= ( ($random() & 8'hff) > 200 );

      S_AXIS_TVALID_R 
        <= (S_AXIS_TREADY & S_AXIS_TVALID) ? (($random()&8'hff)>100) :      
           (~S_AXIS_TVALID) ? (($random()&8'hff)>SAXI_Rate) : 
           S_AXIS_TVALID;
      
      TDATA_CNT
        <= RST ? 0 :
           (TDATA_CNT == TDataMax) ? TDATA_CNT :
           (S_AXIS_TREADY & S_AXIS_TVALID) ? TDATA_CNT + 1 :
           TDATA_CNT;

      if (uut.S_AXIS_TVALID & S_AXIS_TREADY) 
        $display("in  %d", TDATA_CNT);
      if (uut.M_AXIS_TVALID & uut.M_AXIS_TREADY) 
        $display("out %d", uut.M_AXIS_TDATA);
   end
   

   defparam uut.DummyHeader = 10000;
   header_adj uut
     ( .CLK(CLK), .RST(RST),
       .S_AXIS_TREADY(S_AXIS_TREADY),
       .S_AXIS_TLAST (),
       .S_AXIS_TDATA ( (TDATA_CNT <HeaderLen) ? (TDATA_CNT | {8'h01, 56'h0}) :
                       (TDATA_CNT==HeaderLen) ? TDataMax-(HeaderLen+1) : TDATA_CNT ),
       .S_AXIS_TVALID(S_AXIS_TVALID),
       .M_AXIS_TREADY(M_AXIS_TREADY),
       .M_AXIS_TDATA(),
       .M_AXIS_TVALID(),
       .M_AXIS_TLAST() );
   
endmodule // tb

`endif

`default_nettype wire
  
