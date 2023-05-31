`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    19:27:32 06/14/2012 
// Design Name: 
// Module Name:    distribute_bytes 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description:
// Distributes bytes, C_OUT_BYTES at a time from a small cache. Reads in
// C_IN_BYTES bytes at a time from a connected FWFT FIFO interface. C_IN_BYTES 
// must be an integer multiple of C_OUT_BYTES and C_IN_BYTES >= C_OUT_BYTES.
// When FLUSH pulses high, this module will pulse FLUSHED after all the 
// remaining bytes in the FWFT FIFO are read and distributed (that is, as soon
// as INDATA_EN goes low after the FLUSH pulse). The module will not wait for 
// more data to be made available in the FWFT FIFO.
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module distribute_bytes #(
	parameter C_IN_BYTES = 4,			// Number of bytes read from the FIFO each read
	parameter C_OUT_BYTES = 1,			// Number of bytes to distribute each read
	// Local parameters
	parameter C_IN_WIDTH = 8*C_IN_BYTES,
	parameter C_OUT_WIDTH = 8*C_OUT_BYTES,
	parameter C_IN_OUT_MULTPL = C_IN_BYTES/C_OUT_BYTES,
	parameter C_IN_OUT_MULTPL_WIDTH = clog2(C_IN_OUT_MULTPL)
)
(
	input CLK,							// Clock
	input RST,							// Async reset
	input INDATA_EN,					// Input data is valid
	input [C_IN_WIDTH-1:0] INDATA,		// Input data (wide)
	output INDATA_RD_EN,				// Input data has been read
	input FLUSH,						// End of data when INDATA_EN goes low, no waiting for more
	output FLUSHED,						// Pulsed high when last C_OUT_BYTES bytes have been outputted (after FLUSH pulse)
	output OUTDATA_EN,					// Output data is valid
	output [C_OUT_WIDTH-1:0] OUTDATA,	// Output data (narrow)
	input OUTDATA_RD_EN					// Output data has been read
);

`include "common_functions.v"

reg	[C_IN_OUT_MULTPL_WIDTH-1:0]	rPos=0;
reg								rFlush=0;

wire 							wOnLastOutWord = (rPos == C_IN_OUT_MULTPL - 1);
wire							rHaveData=INDATA_EN;

assign INDATA_RD_EN = (wOnLastOutWord && INDATA_EN ? OUTDATA_RD_EN : 0);
assign OUTDATA = INDATA[rPos*C_OUT_WIDTH +:C_OUT_WIDTH];
assign OUTDATA_EN = rHaveData;
assign FLUSHED = (!rHaveData && rFlush);

// Read from a FWFT FIFO interface.
always @ (posedge CLK or posedge RST) begin
	if (RST) begin
		rPos <= #1 0;
		//rHaveData <= #1 0;
		rFlush <= #1 0;
	end
	else if (OUTDATA_RD_EN) begin // OUTDATA read
		rPos <= #1 (!rHaveData ? rPos : (wOnLastOutWord ? 0 : rPos + 1));
		//rHaveData <= #1 (rHaveData ? !(wOnLastOutWord && !INDATA_EN) : INDATA_EN);
		rFlush <= #1 (FLUSHED ? FLUSH : (rFlush | FLUSH));
	end
	else begin
		//rHaveData <= #1 (rHaveData | INDATA_EN);
		rFlush <= #1 (FLUSHED ? FLUSH : (rFlush | FLUSH));
	end
end

endmodule
