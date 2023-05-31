`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    19:27:32 06/14/2012 
// Design Name: 
// Module Name:    accumulate_bytes 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description:
// Accumulates bytes, C_IN_BYTES at a time until C_OUT_BYTES bytes have been
// collected. At which point, the OUTDATA_EN will pulse high. C_OUT_BYTES must be
// an integer multiple of C_IN_BYTES and C_OUT_BYTES >= C_IN_BYTES. When 
// FLUSH is high, any data collected but not yet outputted will be shifted 
// (padded with garbage) until it can be outputted as the next contiguous
// C_OUT_BYTES byte block. After the last OUTDATA_EN is pulsed, FLUSHED will go
// high.
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module accumulate_bytes #(
	parameter C_IN_BYTES = 1,			// Input number of bytes
	parameter C_OUT_BYTES = 4,			// Output number of bytes
	// Local parameters
	parameter C_IN_WIDTH = 8*C_IN_BYTES,
	parameter C_OUT_WIDTH = 8*C_OUT_BYTES,
	parameter C_POS_WIDTH = clog2s(C_OUT_WIDTH+1)
)
(
	input CLK,							// Clock
	input RST,							// Async reset
	input INDATA_EN,					// Input data is valid
	input [C_IN_WIDTH-1:0] INDATA,		// Input data (narrow)
	output INDATA_RD_EN,				// Input data will be read if valid
	input FLUSH,						// End of data when INDATA_EN goes low, no waiting for more
	output FLUSHED,						// Pulsed high when last C_OUT_BYTES bytes have been outputted (after FLUSH pulse)
	output OUTDATA_EN,					// Output data is valid
	output [C_OUT_WIDTH-1:0] OUTDATA,	// Output data (wide)
	input OUTDATA_RD_EN					// Output data has been read
);

`include "common_functions.v"

reg		[C_POS_WIDTH-1:0]	rPosIn=0;
reg							rFlush=0;
reg		[C_OUT_WIDTH-1:0]	rData=0;
reg		[C_OUT_WIDTH-1:0]	rDataMask=0;

assign INDATA_RD_EN = (!OUTDATA_EN | (OUTDATA_EN & OUTDATA_RD_EN));
assign OUTDATA = rData;
assign OUTDATA_EN = (rPosIn == C_OUT_WIDTH || (rFlush && rPosIn != 0));
assign FLUSHED = rFlush;


// Shift the input data into the output register and signal OUTDATA_EN when full.
always @ (posedge CLK or posedge RST) begin
	if (RST) begin
		rDataMask <= #1 {C_OUT_WIDTH{1'b0}};
		rPosIn <= #1 0;
	end
	else if (!OUTDATA_EN) begin // Register not yet full
		if (INDATA_EN) begin
			// Push new data
			rDataMask <= #1 (rDataMask<<C_IN_WIDTH) | {C_IN_WIDTH{1'b1}};
			rPosIn <= #1 rPosIn + C_IN_WIDTH;
			rData <= #1 (rData & rDataMask) | (INDATA<<rPosIn);
		end
	end
	else begin // Register full
		if (OUTDATA_RD_EN) begin // Output being consumed
			if (INDATA_EN) begin
				// Push new data
				rDataMask <= #1 {C_IN_WIDTH{1'b1}};
				rPosIn <= #1 C_IN_WIDTH;
				rData <= #1 INDATA;
			end
			else begin
				rDataMask <= #1 {C_OUT_WIDTH{1'b0}};
				rPosIn <= #1 0;
			end
		end
	end
end


// Flush through to the output.
always @ (posedge CLK or posedge RST) begin
	if (RST)
		rFlush <= #1 0;
	else
		rFlush <= #1 FLUSH;
end


endmodule
