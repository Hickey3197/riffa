`timescale 1ns / 1ps


module top(
	
	input				sys_clk,
	input				sys_nrst,
	
	input				gtx_ref_clk_p,
	input				gtx_ref_clk_n,
	
	input				sfp_b_rx_p,
	input				sfp_b_rx_n,
	output				sfp_b_tx_p,
	output				sfp_b_tx_n,
	output				sfp_b_disable,
	
	input				sfp_a_rx_p,
	input				sfp_a_rx_n,
	output				sfp_a_tx_p,
	output				sfp_a_tx_n,
	output				sfp_a_disable,
	
	output	[7 : 0]		leds
);
	
	assign sfp_a_disable = 1'b0;
	assign sfp_b_disable = 1'b0;
	
	assign leds = ~{8'b0000_0000};
	
	wire q4_clk1_mgtrefclk;
	
	wire [35:0] control0;
	
	IBUFDS_GTXE1 U_Q4_CLK1_MGTREFCLK(

	.O			(q4_clk1_mgtrefclk),
	.ODIV2		(),
	.CEB		(1'b0),
	.I			(gtx_ref_clk_p),
	.IB			(gtx_ref_clk_n)
	);

	chipscope_icon_1 U_ICON(
		.CONTROL0	(control0)
	);
	
	ibert_check U_IBERT_CHECK(
		
		.X0Y17_RX_P_IPAD		(sfp_b_rx_p),
		.X0Y17_RX_N_IPAD		(sfp_b_rx_n),
		.X0Y17_TX_P_OPAD		(sfp_b_tx_p),
		.X0Y17_TX_N_OPAD		(sfp_b_tx_n),
		
		.X0Y19_RX_P_IPAD		(sfp_a_rx_p),
		.X0Y19_RX_N_IPAD		(sfp_a_rx_n),
		.X0Y19_TX_P_OPAD		(sfp_a_tx_p),
		.X0Y19_TX_N_OPAD		(sfp_a_tx_n),
		
		.X0Y17_RXRECCLK_O 	(),
		
		.Q4_CLK1_MGTREFCLK_I	(q4_clk1_mgtrefclk),
		.CONTROL				(control0),
		.IBERT_SYSCLOCK_I		(sys_clk)
	);
	
endmodule
