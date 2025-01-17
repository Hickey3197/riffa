`timescale 1ns/1ns
//----------------------------------------------------------------------------
// This software is Copyright © 2012 The Regents of the University of 
// California. All Rights Reserved.
//
// Permission to copy, modify, and distribute this software and its 
// documentation for educational, research and non-profit purposes, without 
// fee, and without a written agreement is hereby granted, provided that the 
// above copyright notice, this paragraph and the following three paragraphs 
// appear in all copies.
//
// Permission to make commercial use of this software may be obtained by 
// contacting:
// Technology Transfer Office
// 9500 Gilman Drive, Mail Code 0910
// University of California
// La Jolla, CA 92093-0910
// (858) 534-5815
// invent@ucsd.edu
// 
// This software program and documentation are copyrighted by The Regents of 
// the University of California. The software program and documentation are 
// supplied "as is", without any accompanying services from The Regents. The 
// Regents does not warrant that the operation of the program will be 
// uninterrupted or error-free. The end-user understands that the program was 
// developed for research purposes and is advised not to rely exclusively on 
// the program for any reason.
// 
// IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO
// ANY PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR
// CONSEQUENTIAL DAMAGES, INCLUDING LOST PROFITS, ARISING
// OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION,
// EVEN IF THE UNIVERSITY OF CALIFORNIA HAS BEEN ADVISED OF
// THE POSSIBILITY OF SUCH DAMAGE. THE UNIVERSITY OF
// CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
// INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
// MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
// THE SOFTWARE PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, 
// AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATIONS TO
// PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR
// MODIFICATIONS.
//----------------------------------------------------------------------------
//----------------------------------------------------------------------------
// Filename:			riffa_endpoint_64.v
// Version:				1.00.a
// Verilog Standard:	Verilog-2001
// Description:			Connects to all the RIFFA channels and cycles through 
// 						each to service data transfers. Supports a 64 bit data 
//						interface.
// Author:				Matt Jacobsen
// History:				@mattj: Version 2.0
//-----------------------------------------------------------------------------
module riffa_endpoint_64 #(
	parameter C_PCI_DATA_WIDTH = 9'd64,
	parameter C_NUM_CHNL = 4'd12,
	// Local parameters
	parameter C_NUM_CHNL_WIDTH = clog2s(C_NUM_CHNL),
	parameter C_PCI_DATA_WORD_WIDTH = clog2((C_PCI_DATA_WIDTH/32)+1)
)
(
	input CLK,
	input RST_IN,
	output RST_OUT,

	input [C_PCI_DATA_WIDTH-1:0] M_AXIS_RX_TDATA,
	input [(C_PCI_DATA_WIDTH/8)-1:0] M_AXIS_RX_TKEEP,
	input M_AXIS_RX_TLAST,
	input M_AXIS_RX_TVALID,
	output M_AXIS_RX_TREADY,
	input [6:0] M_AXIS_RBAR_HIT,
	input RERR_FWD,
	
	output [C_PCI_DATA_WIDTH-1:0] S_AXIS_TX_TDATA,
	output [(C_PCI_DATA_WIDTH/8)-1:0] S_AXIS_TX_TKEEP,
	output S_AXIS_TX_TLAST,
	output S_AXIS_TX_TVALID,
	output S_AXIS_SRC_DSC,
	input S_AXIS_TX_TREADY,
	
	input [15:0] COMPLETER_ID,
	input CFG_BUS_MSTR_ENABLE,	
	input [5:0] CFG_LINK_WIDTH,			// cfg_lstatus[9:4] (from Link Status Register): 000001=x1, 000010=x2, 000100=x4, 001000=x8, 001100=x12, 010000=x16, 100000=x32, others=? 
	input [1:0] CFG_LINK_RATE,			// cfg_lstatus[1:0] (from Link Status Register): 01=2.5GT/s, 10=5.0GT/s, others=?
	input [2:0] MAX_READ_REQUEST_SIZE,	// cfg_dcommand[14:12] (from Device Control Register): 000=128B, 001=256B, 010=512B, 011=1024B, 100=2048B, 101=4096B
	input [2:0] MAX_PAYLOAD_SIZE, 		// cfg_dcommand[7:5] (from Device Control Register): 000=128B, 001=256B, 010=512B, 011=1024B
	input INTR_LEGACY_CLR,				// Pulsed high to ack the legacy interrupt and clear it
	input CFG_INTERRUPT_MSIENABLE,		// 1 if MSI interrupts are enable, 0 if only legacy are supported
	output CFG_INTERRUPT_ASSERT,		// Legacy interrupt message type
	input CFG_INTERRUPT_RDY,			// High when interrupt is able to be sent
	output CFG_INTERRUPT,				// High to request interrupt, when both CFG_INTERRUPT_RDY and CFG_INTERRUPT are high, interrupt is sent
	
	input [C_NUM_CHNL-1:0] CHNL_RX_CLK, 
	output [C_NUM_CHNL-1:0] CHNL_RX, 
	input [C_NUM_CHNL-1:0] CHNL_RX_ACK, 
	output [C_NUM_CHNL-1:0] CHNL_RX_LAST, 
	output [(C_NUM_CHNL*32)-1:0] CHNL_RX_LEN, 
	output [(C_NUM_CHNL*31)-1:0] CHNL_RX_OFF, 
	output [(C_NUM_CHNL*C_PCI_DATA_WIDTH)-1:0] CHNL_RX_DATA, 
	output [C_NUM_CHNL-1:0] CHNL_RX_DATA_VALID, 
	input [C_NUM_CHNL-1:0] CHNL_RX_DATA_REN,
	
	input [C_NUM_CHNL-1:0] CHNL_TX_CLK, 
	input [C_NUM_CHNL-1:0] CHNL_TX, 
	output [C_NUM_CHNL-1:0] CHNL_TX_ACK,
	input [C_NUM_CHNL-1:0] CHNL_TX_LAST, 
	input [(C_NUM_CHNL*32)-1:0] CHNL_TX_LEN, 
	input [(C_NUM_CHNL*31)-1:0] CHNL_TX_OFF, 
	input [(C_NUM_CHNL*C_PCI_DATA_WIDTH)-1:0] CHNL_TX_DATA, 
	input [C_NUM_CHNL-1:0] CHNL_TX_DATA_VALID, 
	output [C_NUM_CHNL-1:0] CHNL_TX_DATA_REN
);

`include "common_functions.v"

wire	[31:0]										wIntr0;
wire	[31:0]										wIntr1;

wire												wRxEngReqWr;
wire												wRxEngReqWrDone;
wire												wRxEngReqRd;
wire												wRxEngReqRdDone;
wire	[9:0]										wRxEngReqLen;
wire	[29:0]										wRxEngReqAddr;
wire	[31:0]										wRxEngReqData;
wire	[3:0]										wRxEngReqBE;
wire	[2:0]										wRxEngReqTC;
wire												wRxEngReqTD;
wire												wRxEngReqEP;
wire	[1:0]										wRxEngReqAttr;
wire	[15:0]										wRxEngReqId;
wire	[7:0]										wRxEngReqTag;

wire	[C_PCI_DATA_WIDTH-1:0]						wRxEngData;
wire	[(C_NUM_CHNL*C_PCI_DATA_WORD_WIDTH)-1:0]	wRxEngMainDataEn;
wire	[C_NUM_CHNL-1:0]							wRxEngMainDone;
wire	[C_NUM_CHNL-1:0]							wRxEngMainErr;
wire	[(C_NUM_CHNL*C_PCI_DATA_WORD_WIDTH)-1:0]	wRxEngSgRxDataEn;
wire	[C_NUM_CHNL-1:0]							wRxEngSgRxDone;
wire	[C_NUM_CHNL-1:0]							wRxEngSgRxErr;
wire	[(C_NUM_CHNL*C_PCI_DATA_WORD_WIDTH)-1:0]	wRxEngSgTxDataEn;
wire	[C_NUM_CHNL-1:0]							wRxEngSgTxDone;
wire	[C_NUM_CHNL-1:0]							wRxEngSgTxErr;

wire												wRxEngReqAddr00 = (wRxEngReqAddr[3:0] == 4'b0000);
wire												wRxEngReqAddr01 = (wRxEngReqAddr[3:0] == 4'b0001);
wire												wRxEngReqAddr02 = (wRxEngReqAddr[3:0] == 4'b0010);
wire												wRxEngReqAddr03 = (wRxEngReqAddr[3:0] == 4'b0011);
wire												wRxEngReqAddr04 = (wRxEngReqAddr[3:0] == 4'b0100);
wire												wRxEngReqAddr05 = (wRxEngReqAddr[3:0] == 4'b0101);
wire												wRxEngReqAddr06 = (wRxEngReqAddr[3:0] == 4'b0110);
wire												wRxEngReqAddr07 = (wRxEngReqAddr[3:0] == 4'b0111);
wire												wRxEngReqAddr08 = (wRxEngReqAddr[3:0] == 4'b1000);
wire												wRxEngReqAddr09 = (wRxEngReqAddr[3:0] == 4'b1001);
wire												wRxEngReqAddr10 = (wRxEngReqAddr[3:0] == 4'b1010);
wire												wRxEngReqAddr11 = (wRxEngReqAddr[3:0] == 4'b1011);
wire												wRxEngReqAddr12 = (wRxEngReqAddr[3:0] == 4'b1100);
wire												wRxEngReqAddr13 = (wRxEngReqAddr[3:0] == 4'b1101);
wire												wRxEngReqAddr14 = (wRxEngReqAddr[3:0] == 4'b1110);

reg		[1:0]										rTxEngReq=0, _rTxEngReq=0;
reg		[31:0]										rTxEngReqData=0, _rTxEngReqData=0;
reg		[31:0]										rTxnTxLen=0, _rTxnTxLen=0;
reg		[31:0]										rTxnTxOffLast=0, _rTxnTxOffLast=0;
reg		[31:0]										rTxnRxDoneLen=0, _rTxnRxDoneLen=0;
reg		[31:0]										rTxnTxDoneLen=0, _rTxnTxDoneLen=0;
wire	[31:0]										wTxEngReqDataSent;
wire												wTxEngReqDone;

wire	[C_NUM_CHNL-1:0]							wTxEngWrReq;
wire	[(C_NUM_CHNL*64)-1:0]						wTxEngWrAddr;
wire	[(C_NUM_CHNL*10)-1:0]						wTxEngWrLen;
wire	[(C_NUM_CHNL*C_PCI_DATA_WIDTH)-1:0]			wTxEngWrData;
wire	[C_NUM_CHNL-1:0]							wTxEngWrDataRen;
wire	[C_NUM_CHNL-1:0]							wTxEngWrAck;
wire	[C_NUM_CHNL-1:0]							wTxEngWrSent;

wire	[C_NUM_CHNL-1:0]							wTxEngRdReq;
wire	[(C_NUM_CHNL*2)-1:0]						wTxEngRdSgChnl;
wire	[(C_NUM_CHNL*64)-1:0]						wTxEngRdAddr;
wire	[(C_NUM_CHNL*10)-1:0]						wTxEngRdLen;
wire	[C_NUM_CHNL-1:0]							wTxEngRdAck;

wire	[C_NUM_CHNL-1:0] 							wSgRxBufRecvd;
wire	[C_NUM_CHNL-1:0] 							wSgRxLenValid;
wire	[C_NUM_CHNL-1:0] 							wSgRxAddrHiValid;
wire	[C_NUM_CHNL-1:0] 							wSgRxAddrLoValid;

wire	[C_NUM_CHNL-1:0] 							wSgTxBufRecvd;
wire	[C_NUM_CHNL-1:0] 							wSgTxLenValid;
wire	[C_NUM_CHNL-1:0] 							wSgTxAddrHiValid;
wire	[C_NUM_CHNL-1:0] 							wSgTxAddrLoValid;

wire	[C_NUM_CHNL-1:0] 							wTxnRxLenValid;
wire	[C_NUM_CHNL-1:0] 							wTxnRxOffLastValid;
wire	[(C_NUM_CHNL*32)-1:0] 						wTxnRxDoneLen;
wire	[C_NUM_CHNL-1:0] 							wTxnRxDone;
wire	[C_NUM_CHNL-1:0] 							wTxnRxDoneAck; // ACK'd on length read

wire	[C_NUM_CHNL-1:0] 							wTxnTx;
wire	[C_NUM_CHNL-1:0] 							wTxnTxAck; // ACK'd on length read
wire	[(C_NUM_CHNL*32)-1:0]						wTxnTxLen;
wire	[(C_NUM_CHNL*32)-1:0] 						wTxnTxOffLast;
wire	[(C_NUM_CHNL*32)-1:0] 						wTxnTxDoneLen;
wire	[C_NUM_CHNL-1:0] 							wTxnTxDone;
wire	[C_NUM_CHNL-1:0] 							wTxnTxDoneAck; // ACK'd on length read

reg		[4:0]										rWideRst=0;
reg													rRst=0;

// The Mem/IO read/write address space should be at least 8 bits wide. This 
// means we'll need at least 10 bits of BAR 0, at least 1024 bytes. The bottom
// two bits must always be zero (i.e. all addresses are 4 byte word aligned).
// The Mem/IO read/write address space is partitioned as illustrated below.
// {CHANNEL_NUM} {DATA_OFFSETS} {ZERO}
// ------4-------------4-----------2--
// The lower 2 bits are always zero. The middle 4 bits are used according to
// the listing below. The top 4 bits differentiate between channels for values
// defined in the table below.
// 0000 = Length of SG buffer for RX transaction						(Write only)
// 0001 = PC low address of SG buffer for RX transaction				(Write only)
// 0010 = PC high address of SG buffer for RX transaction				(Write only)
// 0011 = Transfer length for RX transaction							(Write only)
// 0100 = Offset/Last for RX transaction								(Write only)
// 0101 = Length of SG buffer for TX transaction						(Write only)
// 0110 = PC low address of SG buffer for TX transaction				(Write only)
// 0111 = PC high address of SG buffer for TX transaction				(Write only)
// 1000 = Transfer length for TX transaction							(Read only) (ACK'd on read)
// 1001 = Offset/Last for TX transaction								(Read only)
// 1010 = Link rate, link width, bus master enabled, number of channels	(Read only)
// 1011 = Interrupt vector 1											(Read only) (Reset on read)
// 1100 = Interrupt vector 2											(Read only) (Reset on read)
// 1101 = Transferred length for RX transaction							(Read only) (ACK'd on read)
// 1110 = Transferred length for TX transaction							(Read only) (ACK'd on read)

// Generate a wide reset on PC reset.
assign RST_OUT = rRst;
always @ (posedge CLK) begin
	rRst <= #1 rWideRst[4]; 
	if (RST_IN | (wRxEngReqAddr10 & wRxEngReqRdDone)) 
		rWideRst <= #1 5'b11111;
	else 
		rWideRst <= (rWideRst<<1);
end


// Manage tx_engine read completions.
always @ (posedge CLK) begin
	rTxEngReq <= #1 (rRst ? {2{1'd0}} : _rTxEngReq);
	rTxEngReqData <= #1 _rTxEngReqData;
	rTxnTxLen <= #1 _rTxnTxLen;
	rTxnTxOffLast <= #1 _rTxnTxOffLast;
	rTxnRxDoneLen <= #1 _rTxnRxDoneLen;
	rTxnTxDoneLen <= #1 _rTxnTxDoneLen;
end

always @ (*) begin
	if (wTxEngReqDone)
		_rTxEngReq = 0;
	else
		_rTxEngReq = ((rTxEngReq<<1) | wRxEngReqRd);

	_rTxnTxLen = wTxnTxLen[(32*wRxEngReqAddr[7:4]) +:32];
	_rTxnTxOffLast = wTxnTxOffLast[(32*wRxEngReqAddr[7:4]) +:32];
	_rTxnRxDoneLen = wTxnRxDoneLen[(32*wRxEngReqAddr[7:4]) +:32];
	_rTxnTxDoneLen = wTxnTxDoneLen[(32*wRxEngReqAddr[7:4]) +:32];

	case (wRxEngReqAddr[2:0])
	3'b000: _rTxEngReqData = rTxnTxLen;
	3'b001: _rTxEngReqData = rTxnTxOffLast;
	3'b010: _rTxEngReqData = {9'd0, C_PCI_DATA_WIDTH[8:5], MAX_PAYLOAD_SIZE, MAX_READ_REQUEST_SIZE, CFG_LINK_RATE, CFG_LINK_WIDTH, CFG_BUS_MSTR_ENABLE, C_NUM_CHNL};
	3'b011: _rTxEngReqData = wIntr0;
	3'b100: _rTxEngReqData = wIntr1;
	3'b101: _rTxEngReqData = rTxnRxDoneLen;
	3'b110: _rTxEngReqData = rTxnTxDoneLen;
	3'b111: _rTxEngReqData = 'bX;
	endcase
end


// Demultiplex the input PIO write notifications to one of the channels.
demux_1_to_n #(C_NUM_CHNL, 1) muxSgRxLenValid (     .IN(wRxEngReqAddr00), .OUT(wSgRxLenValid),      .SEL(wRxEngReqAddr[4 +:C_NUM_CHNL_WIDTH]));
demux_1_to_n #(C_NUM_CHNL, 1) muxSgRxAddrHiValid (  .IN(wRxEngReqAddr02), .OUT(wSgRxAddrHiValid),   .SEL(wRxEngReqAddr[4 +:C_NUM_CHNL_WIDTH]));
demux_1_to_n #(C_NUM_CHNL, 1) muxSgRxAddrLoValid (  .IN(wRxEngReqAddr01), .OUT(wSgRxAddrLoValid),   .SEL(wRxEngReqAddr[4 +:C_NUM_CHNL_WIDTH]));

demux_1_to_n #(C_NUM_CHNL, 1) muxSgTxLenValid (     .IN(wRxEngReqAddr05), .OUT(wSgTxLenValid),      .SEL(wRxEngReqAddr[4 +:C_NUM_CHNL_WIDTH]));
demux_1_to_n #(C_NUM_CHNL, 1) muxSgTxAddrHiValid (  .IN(wRxEngReqAddr07), .OUT(wSgTxAddrHiValid),   .SEL(wRxEngReqAddr[4 +:C_NUM_CHNL_WIDTH]));
demux_1_to_n #(C_NUM_CHNL, 1) muxSgTxAddrLoValid (  .IN(wRxEngReqAddr06), .OUT(wSgTxAddrLoValid),   .SEL(wRxEngReqAddr[4 +:C_NUM_CHNL_WIDTH]));

demux_1_to_n #(C_NUM_CHNL, 1) muxTxnRxLenValid (    .IN(wRxEngReqAddr03), .OUT(wTxnRxLenValid),     .SEL(wRxEngReqAddr[4 +:C_NUM_CHNL_WIDTH]));
demux_1_to_n #(C_NUM_CHNL, 1) muxTxnRxOffLastValid (.IN(wRxEngReqAddr04), .OUT(wTxnRxOffLastValid), .SEL(wRxEngReqAddr[4 +:C_NUM_CHNL_WIDTH]));
demux_1_to_n #(C_NUM_CHNL, 1) muxTxnRxDoneAck (     .IN(wRxEngReqAddr13), .OUT(wTxnRxDoneAck),      .SEL(wRxEngReqAddr[4 +:C_NUM_CHNL_WIDTH]));

demux_1_to_n #(C_NUM_CHNL, 1) muxTxnTxAck (         .IN(wRxEngReqAddr08), .OUT(wTxnTxAck),          .SEL(wRxEngReqAddr[4 +:C_NUM_CHNL_WIDTH])); // ACK'd on length read
demux_1_to_n #(C_NUM_CHNL, 1) muxTxnTxDoneAck (     .IN(wRxEngReqAddr14), .OUT(wTxnTxDoneAck),      .SEL(wRxEngReqAddr[4 +:C_NUM_CHNL_WIDTH]));


// Generate and link up the channels.
genvar i;
generate
for (i = 0; i < C_NUM_CHNL; i = i + 1) begin : channels
	channel_64 #(.C_DATA_WIDTH(C_PCI_DATA_WIDTH)) channel (
		.RST(rRst), 
		.CLK(CLK), 
		.MAX_READ_REQUEST_SIZE(MAX_READ_REQUEST_SIZE), 
		.MAX_PAYLOAD_SIZE(MAX_PAYLOAD_SIZE), 

		.PIO_DATA(wRxEngReqData), 
		.ENG_DATA(wRxEngData), 
		
		.SG_RX_BUF_RECVD(wSgRxBufRecvd[i]),
		.SG_RX_BUF_LEN_VALID(wRxEngReqWr & wSgRxLenValid[i]),
		.SG_RX_BUF_ADDR_HI_VALID(wRxEngReqWr & wSgRxAddrHiValid[i]),
		.SG_RX_BUF_ADDR_LO_VALID(wRxEngReqWr & wSgRxAddrLoValid[i]),
		
		.SG_TX_BUF_RECVD(wSgTxBufRecvd[i]),
		.SG_TX_BUF_LEN_VALID(wRxEngReqWr & wSgTxLenValid[i]),
		.SG_TX_BUF_ADDR_HI_VALID(wRxEngReqWr & wSgTxAddrHiValid[i]),
		.SG_TX_BUF_ADDR_LO_VALID(wRxEngReqWr & wSgTxAddrLoValid[i]),
		
		.TXN_RX_LEN_VALID(wRxEngReqWr & wTxnRxLenValid[i]), 
		.TXN_RX_OFF_LAST_VALID(wRxEngReqWr & wTxnRxOffLastValid[i]), 
		.TXN_RX_DONE_LEN(wTxnRxDoneLen[(32*i) +:32]),
		.TXN_RX_DONE(wTxnRxDone[i]),
		.TXN_RX_DONE_ACK(wRxEngReqRdDone & wTxnRxDoneAck[i]), // ACK'd on length read
		
		.TXN_TX(wTxnTx[i]),
		.TXN_TX_ACK(wRxEngReqRdDone & wTxnTxAck[i]), // ACK'd on length read
		.TXN_TX_LEN(wTxnTxLen[(32*i) +:32]),
		.TXN_TX_OFF_LAST(wTxnTxOffLast[(32*i) +:32]),
		.TXN_TX_DONE_LEN(wTxnTxDoneLen[(32*i) +:32]),
		.TXN_TX_DONE(wTxnTxDone[i]),
		.TXN_TX_DONE_ACK(wRxEngReqRdDone & wTxnTxDoneAck[i]), // ACK'd on length read
		
		.RX_REQ(wTxEngRdReq[i]),
		.RX_REQ_ACK(wTxEngRdAck[i]),
		.RX_REQ_TAG(wTxEngRdSgChnl[(2*i) +:2]),
		.RX_REQ_ADDR(wTxEngRdAddr[(64*i) +:64]),
		.RX_REQ_LEN(wTxEngRdLen[(10*i) +:10]),

		.TX_REQ(wTxEngWrReq[i]), 
		.TX_REQ_ACK(wTxEngWrAck[i]),
		.TX_ADDR(wTxEngWrAddr[(64*i) +:64]), 
		.TX_LEN(wTxEngWrLen[(10*i) +:10]), 
		.TX_DATA(wTxEngWrData[(C_PCI_DATA_WIDTH*i) +:C_PCI_DATA_WIDTH]),
		.TX_DATA_REN(wTxEngWrDataRen[i]), 
		.TX_SENT(wTxEngWrSent[i]),
		
		.MAIN_DATA_EN(wRxEngMainDataEn[(C_PCI_DATA_WORD_WIDTH*i) +:C_PCI_DATA_WORD_WIDTH]), 
		.MAIN_DONE(wRxEngMainDone[i]), 
		.MAIN_ERR(wRxEngMainErr[i]),
		
		.SG_RX_DATA_EN(wRxEngSgRxDataEn[(C_PCI_DATA_WORD_WIDTH*i) +:C_PCI_DATA_WORD_WIDTH]),  
		.SG_RX_DONE(wRxEngSgRxDone[i]), 
		.SG_RX_ERR(wRxEngSgRxErr[i]),

		.SG_TX_DATA_EN(wRxEngSgTxDataEn[(C_PCI_DATA_WORD_WIDTH*i) +:C_PCI_DATA_WORD_WIDTH]), 
		.SG_TX_DONE(wRxEngSgTxDone[i]), 
		.SG_TX_ERR(wRxEngSgTxErr[i]),

		.CHNL_RX_CLK(CHNL_RX_CLK[i]), 
		.CHNL_RX(CHNL_RX[i]), 
		.CHNL_RX_ACK(CHNL_RX_ACK[i]), 
		.CHNL_RX_LAST(CHNL_RX_LAST[i]), 
		.CHNL_RX_LEN(CHNL_RX_LEN[(32*i) +:32]), 
		.CHNL_RX_OFF(CHNL_RX_OFF[(31*i) +:31]), 
		.CHNL_RX_DATA(CHNL_RX_DATA[(C_PCI_DATA_WIDTH*i) +:C_PCI_DATA_WIDTH]), 
		.CHNL_RX_DATA_VALID(CHNL_RX_DATA_VALID[i]), 
		.CHNL_RX_DATA_REN(CHNL_RX_DATA_REN[i]),

		.CHNL_TX_CLK(CHNL_TX_CLK[i]), 
		.CHNL_TX(CHNL_TX[i]), 
		.CHNL_TX_ACK(CHNL_TX_ACK[i]),
		.CHNL_TX_LAST(CHNL_TX_LAST[i]), 
		.CHNL_TX_LEN(CHNL_TX_LEN[(32*i) +:32]), 
		.CHNL_TX_OFF(CHNL_TX_OFF[(31*i) +:31]), 
		.CHNL_TX_DATA(CHNL_TX_DATA[(C_PCI_DATA_WIDTH*i) +:C_PCI_DATA_WIDTH]), 
		.CHNL_TX_DATA_VALID(CHNL_TX_DATA_VALID[i]), 
		.CHNL_TX_DATA_REN(CHNL_TX_DATA_REN[i])
	);
end
endgenerate


// Connect up the rx_engine
assign wRxEngReqWrDone = wRxEngReqWr;
assign wRxEngReqRdDone = wTxEngReqDone;
rx_engine_64 #(
	.C_PCI_DATA_WIDTH(C_PCI_DATA_WIDTH), 
	.C_NUM_CHNL(C_NUM_CHNL)
) rxEng (
	.CLK(CLK), 
	.RST(rRst), 
	.M_AXIS_RX_TDATA(M_AXIS_RX_TDATA), 
	.M_AXIS_RX_TKEEP(M_AXIS_RX_TKEEP),
	.M_AXIS_RX_TLAST(M_AXIS_RX_TLAST), 
	.M_AXIS_RX_TVALID(M_AXIS_RX_TVALID), 
	.M_AXIS_RX_TREADY(M_AXIS_RX_TREADY), 
	.M_AXIS_RBAR_HIT(M_AXIS_RBAR_HIT), 
	.RERR_FWD(RERR_FWD),
	
	.REQ_WR(wRxEngReqWr), 
	.REQ_WR_DONE(wRxEngReqWrDone), 
	.REQ_RD(wRxEngReqRd), 
	.REQ_RD_DONE(wRxEngReqRdDone), 
	.REQ_LEN(wRxEngReqLen), 
	.REQ_ADDR(wRxEngReqAddr), 
	.REQ_DATA(wRxEngReqData), 
	.REQ_BE(wRxEngReqBE), 
	.REQ_TC(wRxEngReqTC), 
	.REQ_TD(wRxEngReqTD), 
	.REQ_EP(wRxEngReqEP), 
	.REQ_ATTR(wRxEngReqAttr), 
	.REQ_ID(wRxEngReqId), 
	.REQ_TAG(wRxEngReqTag),

	.ENG_DATA(wRxEngData),
	.MAIN_DATA_EN(wRxEngMainDataEn),
	.MAIN_DONE(wRxEngMainDone), 
	.MAIN_ERR(wRxEngMainErr), 
	.SG_RX_DATA_EN(wRxEngSgRxDataEn),
	.SG_RX_DONE(wRxEngSgRxDone), 
	.SG_RX_ERR(wRxEngSgRxErr), 
	.SG_TX_DATA_EN(wRxEngSgTxDataEn),
	.SG_TX_DONE(wRxEngSgTxDone), 
	.SG_TX_ERR(wRxEngSgTxErr)
);


// Connect up the tx_engine
tx_engine_64 #(
	.C_PCI_DATA_WIDTH(C_PCI_DATA_WIDTH),
	.C_NUM_CHNL(C_NUM_CHNL)
) txEng (
	.CLK(CLK), 
	.RST(rRst), 
	.COMPLETER_ID(COMPLETER_ID),
	.MAX_PAYLOAD_SIZE(MAX_PAYLOAD_SIZE),

	.S_AXIS_TX_TDATA(S_AXIS_TX_TDATA), 
	.S_AXIS_TX_TKEEP(S_AXIS_TX_TKEEP), 
	.S_AXIS_TX_TLAST(S_AXIS_TX_TLAST), 
	.S_AXIS_TX_TVALID(S_AXIS_TX_TVALID), 
	.S_AXIS_SRC_DSC(S_AXIS_SRC_DSC), 
	.S_AXIS_TX_TREADY(S_AXIS_TX_TREADY), 

	.WR_REQ(wTxEngWrReq), 
	.WR_ADDR(wTxEngWrAddr), 
	.WR_LEN(wTxEngWrLen),
	.WR_DATA(wTxEngWrData), 
	.WR_DATA_REN(wTxEngWrDataRen), 
	.WR_ACK(wTxEngWrAck),
	.WR_SENT(wTxEngWrSent), 
	
	.RD_REQ(wTxEngRdReq), 
	.RD_SG_CHNL(wTxEngRdSgChnl),
	.RD_ADDR(wTxEngRdAddr), 
	.RD_LEN(wTxEngRdLen), 
	.RD_ACK(wTxEngRdAck),

	.COMPL_REQ(rTxEngReq[1]), 
	.COMPL_DONE(wTxEngReqDone),
	.REQ_TC(wRxEngReqTC), 
	.REQ_TD(wRxEngReqTD), 
	.REQ_EP(wRxEngReqEP), 
	.REQ_ATTR(wRxEngReqAttr), 
	.REQ_LEN(wRxEngReqLen), 
	.REQ_ID(wRxEngReqId), 
	.REQ_TAG(wRxEngReqTag), 
	.REQ_BE(wRxEngReqBE), 
	.REQ_ADDR(wRxEngReqAddr), 
	.REQ_DATA(rTxEngReqData), 
	.REQ_DATA_SENT(wTxEngReqDataSent)
);


// Connect the interrupt vector and controller.
interrupt #(.C_NUM_CHNL(C_NUM_CHNL)) intr (
	.CLK(CLK),
	.RST(rRst),
	.RX_SG_BUF_RECVD(wSgRxBufRecvd),
	.RX_TXN_DONE(wTxnRxDone),
	.TX_TXN(wTxnTx),
	.TX_SG_BUF_RECVD(wSgTxBufRecvd),
	.TX_TXN_DONE(wTxnTxDone),
	.VECT_0_RST(wRxEngReqRdDone && wRxEngReqAddr11),
	.VECT_1_RST(wRxEngReqRdDone && wRxEngReqAddr12),
	.VECT_RST(wTxEngReqDataSent),
	.VECT_0(wIntr0),
	.VECT_1(wIntr1),
	.INTR_LEGACY_CLR(INTR_LEGACY_CLR),
	.CFG_INTERRUPT_MSIENABLE(CFG_INTERRUPT_MSIENABLE),
	.CFG_INTERRUPT_ASSERT(CFG_INTERRUPT_ASSERT),
	.CFG_INTERRUPT_RDY(CFG_INTERRUPT_RDY),
	.CFG_INTERRUPT(CFG_INTERRUPT)
);


/*
wire [35:0] wControl0;
chipscope_icon_1 cs_icon(
	.CONTROL0(wControl0)
);

chipscope_ila_t8_512 a0(
	.CLK(CLK), 
	.CONTROL(wControl0), 
	.TRIG0({wRxEngReqAddr[3], (wRxEngMainDataEn | wRxEngSgRxDataEn | wRxEngSgTxDataEn) != 0, wTxEngWrSent != 0, 
			wTxEngWrAck != 0, wTxEngRdAck != 0, wTxEngWrReq != 0, wTxEngRdReq != 0, wRxEngReqWr || wRxEngReqRd || (wTxnRxDone != 0) || (wTxnTxDone != 0)}),
	.DATA({13'd0,
			6'd0, // 6
			CHNL_TX_DATA_REN[0], // 1*C_NUM_CHNL
			CHNL_TX_DATA_VALID[0], // 1*C_NUM_CHNL
			S_AXIS_SRC_DSC, // 1
			S_AXIS_TX_TREADY, // 1
			S_AXIS_TX_TVALID, // 1
			S_AXIS_TX_TLAST, // 1
			S_AXIS_TX_TKEEP, // 8
			S_AXIS_TX_TDATA, // 64
			//32'd0,
			//wIntr0, // 32
			wTxEngWrDataRen[0], // 1*C_NUM_CHNL
			wTxEngWrData[63:0], // 64*C_NUM_CHNL
			rTxEngReqData, // 32
			wTxEngReqDone, // 1
			rTxEngReq[1], // 1
			wTxEngRdLen[9:0], // 10*C_NUM_CHNL
			wTxEngRdAddr[63:0], // 64*C_NUM_CHNL
			wTxEngRdSgChnl[1:0], // 2*C_NUM_CHNL
			wTxEngRdAck[0], // 1*C_NUM_CHNL
			wTxEngRdReq[0], // 1*C_NUM_CHNL
			wTxEngWrLen[9:0], // 10*C_NUM_CHNL
			wTxEngWrAddr[63:0], // 64*C_NUM_CHNL
			wTxEngWrSent[0], // 1*C_NUM_CHNL
			wTxEngWrAck[0], // 1*C_NUM_CHNL
			wTxEngWrReq[0], // 1*C_NUM_CHNL
			1'd0, // 1
//			CHNL_TX_DATA, // 64
			wRxEngData, // 64
			wRxEngSgTxErr[0], // 1*C_NUM_CHNL
			wRxEngSgTxDone[0], // 1*C_NUM_CHNL
			wRxEngSgTxDataEn[1:0], // 2*C_NUM_CHNL
			wRxEngSgRxErr[0], // 1*C_NUM_CHNL
			wRxEngSgRxDone[0], // 1*C_NUM_CHNL
			wRxEngSgRxDataEn[1:0], // 2*C_NUM_CHNL
			wRxEngMainErr[0], // 1*C_NUM_CHNL
			wRxEngMainDone[0], // 1*C_NUM_CHNL
			wRxEngMainDataEn[1:0], // 2*C_NUM_CHNL
			wRxEngReqTag, // 8
			wRxEngReqData, // 32
			wRxEngReqAddr, // 30
			wRxEngReqLen, // 10
			wRxEngReqRdDone, // 1
			wRxEngReqRd, // 1
			wRxEngReqWrDone, // 1
			wRxEngReqWr}) // 1
);
*/

endmodule
