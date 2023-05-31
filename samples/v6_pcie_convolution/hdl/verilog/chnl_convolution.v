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
// Filename:			chnl_convolution.v
// Version:				1.00.a
// Verilog Standard:	Verilog-2001
// Description:			RIFFA channel adapter for the cell_sorting_top module.
// Data is received on the RX port in sequence: avg_img_data, img_data0, 
// img_data1, ... The avg_img_data is stored in a BRAM and repeatedly read out 
// with each img_data. The img_data is consumed directly from the RX FIFO. The
// resulting radius data is stored in a BRAM. The sorting is pipelined, so 2
// BRAMs are flip-flopped for storing radius data. When the RX transaction 
// begins, a TX transaction is started for sending the radius data. Reading of
// the radius data happens concurrently with the processing of the img_data and
// the saving of the new radius data to the alternative BRAM. The TX 
// transaction ends when all the img_data radius values have been sent to the
// TX FIFO.
//
// Author:				Matt Jacobsen
// History:				@mattj: Version 2.0
//-----------------------------------------------------------------------------
module chnl_convolution #(
	parameter C_PCI_DATA_WIDTH = 9'd64
)
(
	input CLK,
	input RST,
	output CHNL_RX_CLK, 
	input CHNL_RX, 
	output CHNL_RX_ACK, 
	input CHNL_RX_LAST, 
	input [31:0] CHNL_RX_LEN, 
	input [30:0] CHNL_RX_OFF, 
	input [C_PCI_DATA_WIDTH-1:0] CHNL_RX_DATA, 
	input CHNL_RX_DATA_VALID, 
	output CHNL_RX_DATA_REN,
	
	output CHNL_TX_CLK, 
	output CHNL_TX, 
	input CHNL_TX_ACK, 
	output CHNL_TX_LAST, 
	output [31:0] CHNL_TX_LEN, 
	output [30:0] CHNL_TX_OFF, 
	output [C_PCI_DATA_WIDTH-1:0] CHNL_TX_DATA, 
	output CHNL_TX_DATA_VALID, 
	input CHNL_TX_DATA_REN
);

`include "common_functions.v"


reg		[2:0]						rRxState=0;
reg		[10:0]						rFrameWidth=0;
reg		[10:0]						rFrameHeight=0;
reg		[10:0]						rFrameWidthM2=0;
reg		[10:0]						rFrameHeightM2=0;
reg		[21:0]						rInputBytes=0;
reg		[21:0]						rOutputBytes=0;
reg		[19:0]						rOutputWords=0;
reg		[21:0]						rCount=0;


reg		[1:0]						rTxState=0;

reg									rFlush0=0, rFlush1=0, rFlush2=0, rFlush3=0, rFlush4=0;    
reg									rValid0=0, rValid1=0, rValid2=0, rValid3=0;    

wire								wDBytesRen;
wire								wDBytesFlushed;
wire								wDBytesDE;
wire	[7:0]						wDBytesData;
wire 								wDBytesConsumed = (wDBytesRen & CHNL_RX_DATA_VALID);

reg									rWinRdy=0;
wire								wWinRdy;
wire								wWinRen;
wire								wWinValid;
wire	[(8*3*3)-1:0]				wWin;

wire								wAccRen;
wire								wAccFlushed;

wire	[7:0]						wP1 = wWin[0*8 +:8];
wire	[7:0]						wP2 = wWin[1*8 +:8];
wire	[7:0]						wP3 = wWin[2*8 +:8];
wire	[7:0]						wP4 = wWin[3*8 +:8];
wire	[7:0]						wP5 = wWin[4*8 +:8];
wire	[7:0]						wP6 = wWin[5*8 +:8];
wire	[7:0]						wP7 = wWin[6*8 +:8];
wire	[7:0]						wP8 = wWin[7*8 +:8];
wire	[7:0]						wP9 = wWin[8*8 +:8];

reg		[9:0]						rGx0=0;
reg		[9:0]						rGx1=0;
reg		[9:0]						rGy0=0;
reg		[9:0]						rGy1=0;
reg		[10:0]						rGx=0;
reg		[10:0]						rGy=0;
reg		[10:0]						rGxAbs=0;
reg		[10:0]						rGyAbs=0;
reg		[10:0]						rPixel=0;


assign CHNL_RX_CLK = CLK;
assign CHNL_RX_ACK = (rRxState == 3'd1);
assign CHNL_RX_DATA_REN = (rRxState == 3'd1) || (wDBytesConsumed && rRxState == 3'd4);

assign CHNL_TX_CLK = CLK;
assign CHNL_TX = (rTxState != 2'd0);
assign CHNL_TX_LAST = 1'd1;
assign CHNL_TX_LEN = rOutputWords; // in words
assign CHNL_TX_OFF = 0;


// Accepts input from the RX port in the following seq: 
// {HEIGHT, WIDTH}, 
// {PX7, ... PX1, PX0}, 
// ...
always @(posedge CLK or posedge RST) begin
	if (RST | (!CHNL_RX & !CHNL_RX_DATA_VALID)) begin
		rRxState <= #1 0;
	end
	else begin
		case (rRxState)

		3'd0: begin // Wait for the TX state machine to sync up
			rRxState <= #1 rRxState + (CHNL_RX && rTxState == 2'd0);
		end
		
		3'd1: begin // Save the image information
			rFrameWidth <= #1 CHNL_RX_DATA[10:0];
			rFrameHeight <= #1 CHNL_RX_DATA[42:32];
			rFrameWidthM2 <= #1 CHNL_RX_DATA[10:0] - 2'd2;
			rFrameHeightM2 <= #1 CHNL_RX_DATA[42:32] - 2'd2;
			rCount <= #1 0;
			rRxState <= #1 rRxState + CHNL_RX_DATA_VALID;
		end

		3'd2: begin // Calculate the limits
			rInputBytes <= #1 rFrameWidth * rFrameHeight;
			rOutputBytes <= #1 rFrameWidthM2 * rFrameHeightM2;
			rRxState <= #1 3'd3;
		end

		3'd3: begin // Calculate the limits
			rOutputWords <= #1 (rOutputBytes[1] | rOutputBytes[0]) + (rOutputBytes>>2);
			rRxState <= #1 3'd4;
		end

		3'd4: begin // Read the image until completion
			rCount <= #1 (rCount + (wDBytesConsumed*8));
			rRxState <= #1 rRxState + (rCount >= rInputBytes);
		end

		3'd5: begin // Wait for the CHNL_RX to drop
		end
		
		default: begin
			rRxState <= #1 3'd0;
		end
		
		endcase
	end
end


// Feed single bytes into the sliding window.
distribute_bytes #(
	.C_IN_BYTES(8),
	.C_OUT_BYTES(1)
) dbytes (	
	.CLK(CLK),
	.RST(RST),
	.INDATA_EN(CHNL_RX_DATA_VALID && (rRxState == 3'd4)),
	.INDATA(CHNL_RX_DATA),
	.INDATA_RD_EN(wDBytesRen),
	.FLUSH(!(rRxState == 3'd1 || rRxState == 3'd2 || rRxState == 3'd3 || rRxState == 3'd4)),
	.FLUSHED(wDBytesFlushed),
	.OUTDATA_EN(wDBytesDE),
	.OUTDATA(wDBytesData),
	.OUTDATA_RD_EN(wWinRen)
);


// Slide a 3x3 window over the input image.
sliding_window #(
	.C_PIXEL_WIDTH(8),
	.C_MAX_LEN(1920),
	.C_WIN_DIM(3)
) slidingWin (	
	.RST(RST),
	.CLK(CLK),
	.PX_EOF(wDBytesFlushed),
	.PX_VALID(wDBytesDE),
	.PX_DATA(wDBytesData),
	.PX_TAKE(wWinRen),
	.PX_LINE_LEN(rFrameWidth),
	.WIN(wWin),
	.WIN_VALID(wWinValid),
	.WIN_RDY(wWinRdy),
	.WIN_SHIFT(wAccRen)
);

// Convolve the image: sobel filter (horiz + vert)
always @ (posedge CLK) begin
	if (wAccRen) begin
		rWinRdy <= #1 wWinRdy;
		rFlush0 <= #1 wDBytesFlushed;

		rFlush1 <= #1 rFlush0;
		rValid0 <= #1 (rWinRdy & wWinValid & !rFlush0);
		rGx0 <= #1 wP1 + (wP4*2) + wP7; 
		rGx1 <= #1 wP3 + (wP6*2) + wP9;
		rGy0 <= #1 wP1 + (wP2*2) + wP3; 
		rGy1 <= #1 wP7 + (wP8*2) + wP9; 
		
		rFlush2 <= #1 rFlush1;
		rValid1 <= #1 rValid0;
		rGx <= #1 rGx1 - rGx0;
		rGy <= #1 rGy0 - rGy1;
		
		rFlush3 <= #1 rFlush2;
		rValid2 <= #1 rValid1;
		if (rGx[10])
			rGxAbs <= #1 (~rGx) + 1'd1;
		else
			rGxAbs <= #1 rGx;
		if (rGy[10])
			rGyAbs <= #1 (~rGy) + 1'd1;
		else
			rGyAbs <= #1 rGy;
			
		rFlush4 <= #1 rFlush3;
		rValid3 <= #1 rValid2;
		rPixel <= #1 rGxAbs + rGyAbs;
	end
end



// Accumulate the single byte data from the convolution.
accumulate_bytes #(
	.C_IN_BYTES(1), 
	.C_OUT_BYTES(8)
) accumulate (
	.RST(RST),
	.CLK(CLK),
	.INDATA_EN(rValid3 & wAccRen),
	.INDATA((rPixel[10] | rPixel[9] ? 8'd255 : rPixel[8:1])),
	.INDATA_RD_EN(wAccRen),
	.FLUSH(rFlush4),
	.FLUSHED(wAccFlushed),
	.OUTDATA_EN(CHNL_TX_DATA_VALID),
	.OUTDATA(CHNL_TX_DATA),
	.OUTDATA_RD_EN(CHNL_TX_DATA_REN)
);


// Wait until the RX transaction starts, then start a TX transaction for 
// the response. Output data in the following seq: 
// {PX7, ..., PX1, PX0},
// ...
always @(posedge CLK or posedge RST) begin
	if (RST) begin
		rTxState <= #1 0;
	end
	else begin
		case (rTxState)
		
		2'd0: begin // Wait for rRxState == 3'd3
			rTxState <= #1 (rRxState == 3'd3);
		end

		2'd1: begin // Wait for the CHNL_TX_ACK
			rTxState <= #1 rTxState + CHNL_TX_ACK;
		end
		
		2'd2: begin // Send data to the FIFO
			rTxState <= #1 rTxState + (!wAccFlushed);
		end

		2'd3: begin // Finish the TX transaction
			rTxState <= #1 rTxState + (wAccFlushed & !CHNL_TX_DATA_VALID);
		end

		endcase
	end
end


endmodule
