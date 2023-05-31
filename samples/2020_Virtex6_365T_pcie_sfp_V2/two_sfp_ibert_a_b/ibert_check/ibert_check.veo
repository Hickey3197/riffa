///////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2020 Xilinx, Inc.
// All Rights Reserved
///////////////////////////////////////////////////////////////////////////////
//   ____  ____
//  /   /\/   /
// /___/  \  /    Vendor     : Xilinx
// \   \   \/     Version    : 14.7
//  \   \         Application: Xilinx CORE Generator
//  /   /         Filename   : ibert_check.veo
// /___/   /\     Timestamp  : Wed Apr 29 07:34:02 中国标准时间 2020
// \   \  /  \
//  \___\/\___\
//
// Design Name: ISE Instantiation template
///////////////////////////////////////////////////////////////////////////////

// The following must be inserted into your Verilog file for this
// core to be instantiated. Change the instance name and port connections
// (in parentheses) to your own signal names.

//----------- Begin Cut here for INSTANTIATION Template ---// INST_TAG
ibert_check YourInstanceName (
    .X0Y17_TX_P_OPAD(X0Y17_TX_P_OPAD), // OUT
    .X0Y17_TX_N_OPAD(X0Y17_TX_N_OPAD), // OUT
    .X0Y19_TX_P_OPAD(X0Y19_TX_P_OPAD), // OUT
    .X0Y19_TX_N_OPAD(X0Y19_TX_N_OPAD), // OUT
    .X0Y17_RXRECCLK_O(X0Y17_RXRECCLK_O), // OUT
    .X1Y24_TX_P_OPAD(X1Y24_TX_P_OPAD), // OUT
    .X1Y24_TX_N_OPAD(X1Y24_TX_N_OPAD), // OUT
    .X1Y25_TX_P_OPAD(X1Y25_TX_P_OPAD), // OUT
    .X1Y25_TX_N_OPAD(X1Y25_TX_N_OPAD), // OUT
    .X1Y26_TX_P_OPAD(X1Y26_TX_P_OPAD), // OUT
    .X1Y26_TX_N_OPAD(X1Y26_TX_N_OPAD), // OUT
    .X1Y27_TX_P_OPAD(X1Y27_TX_P_OPAD), // OUT
    .X1Y27_TX_N_OPAD(X1Y27_TX_N_OPAD), // OUT
    .X1Y28_TX_P_OPAD(X1Y28_TX_P_OPAD), // OUT
    .X1Y28_TX_N_OPAD(X1Y28_TX_N_OPAD), // OUT
    .X1Y29_TX_P_OPAD(X1Y29_TX_P_OPAD), // OUT
    .X1Y29_TX_N_OPAD(X1Y29_TX_N_OPAD), // OUT
    .X1Y30_TX_P_OPAD(X1Y30_TX_P_OPAD), // OUT
    .X1Y30_TX_N_OPAD(X1Y30_TX_N_OPAD), // OUT
    .X1Y31_TX_P_OPAD(X1Y31_TX_P_OPAD), // OUT
    .X1Y31_TX_N_OPAD(X1Y31_TX_N_OPAD), // OUT
    .X1Y32_TX_P_OPAD(X1Y32_TX_P_OPAD), // OUT
    .X1Y32_TX_N_OPAD(X1Y32_TX_N_OPAD), // OUT
    .X1Y33_TX_P_OPAD(X1Y33_TX_P_OPAD), // OUT
    .X1Y33_TX_N_OPAD(X1Y33_TX_N_OPAD), // OUT
    .X1Y34_TX_P_OPAD(X1Y34_TX_P_OPAD), // OUT
    .X1Y34_TX_N_OPAD(X1Y34_TX_N_OPAD), // OUT
    .X1Y35_TX_P_OPAD(X1Y35_TX_P_OPAD), // OUT
    .X1Y35_TX_N_OPAD(X1Y35_TX_N_OPAD), // OUT
    .X1Y24_RXRECCLK_O(X1Y24_RXRECCLK_O), // OUT
    .X1Y25_RXRECCLK_O(X1Y25_RXRECCLK_O), // OUT
    .X1Y26_RXRECCLK_O(X1Y26_RXRECCLK_O), // OUT
    .X1Y27_RXRECCLK_O(X1Y27_RXRECCLK_O), // OUT
    .X1Y28_RXRECCLK_O(X1Y28_RXRECCLK_O), // OUT
    .X1Y29_RXRECCLK_O(X1Y29_RXRECCLK_O), // OUT
    .X1Y30_RXRECCLK_O(X1Y30_RXRECCLK_O), // OUT
    .X1Y31_RXRECCLK_O(X1Y31_RXRECCLK_O), // OUT
    .X1Y32_RXRECCLK_O(X1Y32_RXRECCLK_O), // OUT
    .X1Y33_RXRECCLK_O(X1Y33_RXRECCLK_O), // OUT
    .X1Y34_RXRECCLK_O(X1Y34_RXRECCLK_O), // OUT
    .X1Y35_RXRECCLK_O(X1Y35_RXRECCLK_O), // OUT
    .CONTROL(CONTROL), // INOUT BUS [35:0]
    .X0Y17_RX_P_IPAD(X0Y17_RX_P_IPAD), // IN
    .X0Y17_RX_N_IPAD(X0Y17_RX_N_IPAD), // IN
    .X0Y19_RX_P_IPAD(X0Y19_RX_P_IPAD), // IN
    .X0Y19_RX_N_IPAD(X0Y19_RX_N_IPAD), // IN
    .X1Y24_RX_P_IPAD(X1Y24_RX_P_IPAD), // IN
    .X1Y24_RX_N_IPAD(X1Y24_RX_N_IPAD), // IN
    .X1Y25_RX_P_IPAD(X1Y25_RX_P_IPAD), // IN
    .X1Y25_RX_N_IPAD(X1Y25_RX_N_IPAD), // IN
    .X1Y26_RX_P_IPAD(X1Y26_RX_P_IPAD), // IN
    .X1Y26_RX_N_IPAD(X1Y26_RX_N_IPAD), // IN
    .X1Y27_RX_P_IPAD(X1Y27_RX_P_IPAD), // IN
    .X1Y27_RX_N_IPAD(X1Y27_RX_N_IPAD), // IN
    .X1Y28_RX_P_IPAD(X1Y28_RX_P_IPAD), // IN
    .X1Y28_RX_N_IPAD(X1Y28_RX_N_IPAD), // IN
    .X1Y29_RX_P_IPAD(X1Y29_RX_P_IPAD), // IN
    .X1Y29_RX_N_IPAD(X1Y29_RX_N_IPAD), // IN
    .X1Y30_RX_P_IPAD(X1Y30_RX_P_IPAD), // IN
    .X1Y30_RX_N_IPAD(X1Y30_RX_N_IPAD), // IN
    .X1Y31_RX_P_IPAD(X1Y31_RX_P_IPAD), // IN
    .X1Y31_RX_N_IPAD(X1Y31_RX_N_IPAD), // IN
    .X1Y32_RX_P_IPAD(X1Y32_RX_P_IPAD), // IN
    .X1Y32_RX_N_IPAD(X1Y32_RX_N_IPAD), // IN
    .X1Y33_RX_P_IPAD(X1Y33_RX_P_IPAD), // IN
    .X1Y33_RX_N_IPAD(X1Y33_RX_N_IPAD), // IN
    .X1Y34_RX_P_IPAD(X1Y34_RX_P_IPAD), // IN
    .X1Y34_RX_N_IPAD(X1Y34_RX_N_IPAD), // IN
    .X1Y35_RX_P_IPAD(X1Y35_RX_P_IPAD), // IN
    .X1Y35_RX_N_IPAD(X1Y35_RX_N_IPAD), // IN
    .Q4_CLK1_MGTREFCLK_I(Q4_CLK1_MGTREFCLK_I), // IN
    .IBERT_SYSCLOCK_I(IBERT_SYSCLOCK_I) // IN
);

// INST_TAG_END ------ End INSTANTIATION Template ---------

