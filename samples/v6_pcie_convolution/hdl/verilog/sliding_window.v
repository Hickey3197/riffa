`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    19:27:32 06/14/2012 
// Design Name: 
// Module Name:    sliding_window 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description:
// Saves image pixels in BRAM line buffers to support a horizontal and vertical
// scrolling window of pixels across an image. The window size is a square, 
// C_WIN_DIM on a side. C_WIN_DIM-1 line buffers will be used to support the
// window. C_PIXEL_WIDTH is the number of bits per pixel. C_MAX_LEN is the max
// horizontal length of the image. The actual horizontal length is PX_LINE_LEN. 
// PX_LINE_LEN should only change between frames. Note that the product 
// C_PIXEL_WIDTH x C_MAX_LEN determines the size of each line buffer (in bits).
//  
// A pixel is consumed when both PX_VALID and PX_TAKE are high. Once consumed,
// the next cycle PX_VALID is high should correspond to a new pixel on PX_DATA. 
// At the end of PX_LINE_LEN x PX_LINE_LEN pixels, PX_EOF should be asserted
// for 1 or more cycles.
//
// The C_WIN_DIM x C_WIN_DIM window is available on WIN. WIN_VALID is high when
// the window contains valid pixels. This means at least C_WIN_DIM x C_WIN_DIM
// pixels have been buffered. WIN_VALID will drop each new line until another
// C_WIN_DIM pixels have been buffered. When both WIN_RDY and WIN_SHIFT are 
// high, the window accepts the next pixel from PX_DATA and shifts the window. 
// WIN will reflect the new value the next cycle. WIN_RDY will fluctuate with 
// the state of the BRAMs and the input data.
//
// Let PX(x,y) be the pixel at coordinate x, y. Then the C_WIN_DIM x C_WIN_DIM 
// window is organized as follows:
// WIN[0*C_WIN_LINE_WIDTH +:C_WIN_LINE_WIDTH] == {PX(off+C_WIN_DIM-1,0) PX(off+C_WIN_DIM-2,0) ... PX(off,0)}
// WIN[1*C_WIN_LINE_WIDTH +:C_WIN_LINE_WIDTH] == {PX(off+C_WIN_DIM-1,1) PX(off+C_WIN_DIM-2,1) ... PX(off,1)}
// ...
// WIN[(C_WIN_DIM-1)*C_WIN_LINE_WIDTH +:C_WIN_LINE_WIDTH] == {PX(off+C_WIN_DIM-1,C_WIN_DIM-1) PX(off+C_WIN_DIM-2,C_WIN_DIM-1) ... PX(off,C_WIN_DIM-1)}
//
// For example, with C_WIN_DIM = 3, shift offset = 0, and C_PIXEL_WIDTH = 4:
// WIN[11:00] = {PX(2,0), PX(1,0), PX(0,0)}
// WIN[23:12] = {PX(2,1), PX(1,1), PX(0,1)}
// WIN[35:24] = {PX(2,2), PX(1,2), PX(0,2)}
// Note that top row in the window is at the lowest address. Also note that 
// the oldest pixel in each row is at the lowest address (on the right edge).
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module sliding_window #(
	parameter C_PIXEL_WIDTH = 18,					// Width of each pixel
	parameter C_MAX_LEN = 256,						// Depth of BRAM (max possible image horizontal)
	parameter C_WIN_DIM = 32,						// Size of (square) sliding window
	// Local parameters
	parameter C_WIN_LINE_WIDTH = C_WIN_DIM*C_PIXEL_WIDTH,
	parameter C_MAX_LEN_WIDTH = clog2(C_MAX_LEN)
)
(
	input RST,										// Async reset
	input CLK,										// Clock
	input PX_EOF,									// Pulsed high after each frame
	input PX_VALID,									// High when PX_DATA is valid
	input [C_PIXEL_WIDTH-1:0] PX_DATA,				// Pixel to add to the sliding window
	output PX_TAKE,									// High when the PX_DATA has been consumed
	input [C_MAX_LEN_WIDTH-1:0] PX_LINE_LEN,		// Number of pixels in a line for the current frame
	output [(C_WIN_DIM*C_WIN_LINE_WIDTH)-1:0] WIN,	// Window (C_WIN_DIM x C_WIN_DIM)
	output WIN_VALID,								// High when C_WIN_DIM x C_WIN_DIM pixels are valid
	output WIN_RDY,									// High when the window can be shifted
	input WIN_SHIFT									// High to request the window be shifted
);

`include "common_functions.v"


reg		[C_MAX_LEN_WIDTH-1:0]				rAddrA=0;
reg		[C_MAX_LEN_WIDTH-1:0]				rAddrB=0;
reg		[C_MAX_LEN_WIDTH-1:0]				rAddrBPrev=0;
reg		[10:0]								rLineCount=0;
reg											rLineValid=0;
reg		[(C_WIN_DIM*C_WIN_LINE_WIDTH)-1:0]	rWin={C_WIN_DIM*C_WIN_LINE_WIDTH{1'b0}};
reg											rAddrAEOL=0;
reg											rAddrBEOL=0;
reg											rAddrBAhead=0;
reg											rRdyToWr=0;
wire	[((C_WIN_DIM-1)*C_PIXEL_WIDTH)-1:0]	wBufData;


assign PX_TAKE = (WIN_SHIFT & WIN_RDY);
assign WIN = rWin;
assign WIN_RDY = (PX_VALID & rRdyToWr);
assign WIN_VALID = (rLineCount >= C_WIN_DIM-1) && rLineValid;


// Increment our addresses
always @ (posedge CLK) begin
	rAddrBPrev <= #1 rAddrB;
	if (RST | PX_EOF) begin
		rAddrA <= #1 0;
		rAddrB <= #1 0;
		rAddrAEOL <= #1 0;
		rAddrBEOL <= #1 0;
		rAddrBAhead <= #1 0;
		rRdyToWr <= #1 0;
	end
	else begin
		rRdyToWr <= #1 (PX_TAKE & rAddrBAhead) | (!PX_TAKE & !rAddrBAhead);
		if (PX_TAKE) begin
			rAddrB <= #1 (rAddrB + 1'd1) & {C_MAX_LEN_WIDTH{!rAddrBEOL}};
			rAddrBEOL <= #1 (rAddrB == PX_LINE_LEN-2'd2);
		end
		else if (!rRdyToWr & !rAddrBAhead & WIN_SHIFT) begin
			rAddrB <= #1 (rAddrB + 1'd1) & {C_MAX_LEN_WIDTH{!rAddrBEOL}};
			rAddrBEOL <= #1 (rAddrB == PX_LINE_LEN-2'd2);
			rAddrBAhead <= #1 1;
		end
		else if (rAddrBAhead) begin
			rAddrB <= #1 rAddrBPrev;
			rAddrBEOL <= #1 (rAddrBPrev == PX_LINE_LEN-2'd1);
			rAddrBAhead <= #1 0;
		end
		if (PX_TAKE) begin
			rAddrA <= #1 (rAddrA + 1'd1) & {C_MAX_LEN_WIDTH{!rAddrAEOL}};
			rAddrAEOL <= #1 (rAddrA == PX_LINE_LEN-2'd2);
		end
	end
end


// Track when the window becomes valid
always @ (posedge CLK) begin
	if (RST | PX_EOF) begin
		rLineCount <= #1 0;
		rLineValid <= #1 0;
	end
	else begin
		if (PX_TAKE & rAddrAEOL)
			rLineCount <= #1 rLineCount + 1'd1;
		if ((rLineCount >= C_WIN_DIM-1) && (rAddrA == C_WIN_DIM-1) && PX_TAKE)
			rLineValid <= #1 1;
		else if ((rAddrA == 0) && PX_TAKE)
			rLineValid <= #1 0;
	end
end


// Generate the BRAM line buffers. Each new pixel is added to the bottom of the
// array of BRAMs. Pixels are pushed up the column into the BRAM line buffer
// above. Every new pixel results in a new column. Values are shifted into a 
// register array to make a register window. Note that register window mirrors
// the BRAM data. This is done to support (normal HDL) little endian addressing.
//						--> discarded pixel -->
//						|
//		A	B	C	D	X	X	X 
//						^
//						|----------------		new 3x3 window after Q arrives
//		G	H	I	J	E	X	X 		|		{-----}	
//						^				------>	 E D C  B --> discard	
//						|--------------------->	 K J I  H --> discard
//		M	N	O	P	K	X	X 		------>	 Q P O  N --> discard
//						^				|
//						|----------------
// --> new pixel --> Q --
genvar i;
generate 
	for (i = 0; i < C_WIN_DIM-1; i = i + 1) begin: lines
		// Shift in the new pixel, and shift out the old one
		always @ (posedge CLK) begin
			if (PX_TAKE)
				rWin[i*C_WIN_LINE_WIDTH +:C_WIN_LINE_WIDTH] <= #1 
					{wBufData[i*C_PIXEL_WIDTH +:C_PIXEL_WIDTH], rWin[(i*C_WIN_LINE_WIDTH)+C_PIXEL_WIDTH +:C_WIN_LINE_WIDTH-C_PIXEL_WIDTH]};
		end
		// Read address is 1 cycle ahead of the write address so the output of the
		// BRAM has the existing value at the write address.
		if (i < C_WIN_DIM-2) begin: not_bot
			(* RAM_STYLE="BLOCK" *)
			ram_1clk_1w_1r #(C_PIXEL_WIDTH, C_MAX_LEN) line_i (
				.CLK(CLK), 
				.ADDRA(rAddrA), 
				.WEA(PX_TAKE), 
				.DINA(wBufData[(i+1)*C_PIXEL_WIDTH +:C_PIXEL_WIDTH]), 
				.ADDRB(rAddrB), 
				.DOUTB(wBufData[i*C_PIXEL_WIDTH +:C_PIXEL_WIDTH])
			);
		end
		else begin: bot
			// Shift in the new pixel, and shift out the old one
			always @ (posedge CLK) begin
				if (PX_TAKE)
					rWin[(i+1)*C_WIN_LINE_WIDTH +:C_WIN_LINE_WIDTH] <= #1 
						{PX_DATA, rWin[((i+1)*C_WIN_LINE_WIDTH)+C_PIXEL_WIDTH +:C_WIN_LINE_WIDTH-C_PIXEL_WIDTH]};
			end
			(* RAM_STYLE="BLOCK" *)	
			ram_1clk_1w_1r #(C_PIXEL_WIDTH, C_MAX_LEN) line_i (
				.CLK(CLK), 
				.ADDRA(rAddrA), 
				.WEA(PX_TAKE), 
				.DINA(PX_DATA), 
				.ADDRB(rAddrB), 
				.DOUTB(wBufData[i*C_PIXEL_WIDTH +:C_PIXEL_WIDTH])
			);
		end
	end
endgenerate

endmodule
