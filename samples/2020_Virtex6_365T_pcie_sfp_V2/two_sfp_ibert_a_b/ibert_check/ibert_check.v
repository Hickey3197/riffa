///////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2020 Xilinx, Inc.
// All Rights Reserved
///////////////////////////////////////////////////////////////////////////////
//   ____  ____
//  /   /\/   /
// /___/  \  /    Vendor     : Xilinx
// \   \   \/     Version    : 14.7
//  \   \         Application: Xilinx CORE Generator
//  /   /         Filename   : ibert_check.v
// /___/   /\     Timestamp  : Wed Apr 29 07:34:02 中国标准时间 2020
// \   \  /  \
//  \___\/\___\
//
// Design Name: Verilog Synthesis Wrapper
///////////////////////////////////////////////////////////////////////////////
// This wrapper is used to integrate with Project Navigator and PlanAhead

`timescale 1ns/1ps

module ibert_check(
    X0Y17_TX_P_OPAD,
    X0Y17_TX_N_OPAD,
    X0Y19_TX_P_OPAD,
    X0Y19_TX_N_OPAD,
    X0Y17_RXRECCLK_O,
    X1Y24_TX_P_OPAD,
    X1Y24_TX_N_OPAD,
    X1Y25_TX_P_OPAD,
    X1Y25_TX_N_OPAD,
    X1Y26_TX_P_OPAD,
    X1Y26_TX_N_OPAD,
    X1Y27_TX_P_OPAD,
    X1Y27_TX_N_OPAD,
    X1Y28_TX_P_OPAD,
    X1Y28_TX_N_OPAD,
    X1Y29_TX_P_OPAD,
    X1Y29_TX_N_OPAD,
    X1Y30_TX_P_OPAD,
    X1Y30_TX_N_OPAD,
    X1Y31_TX_P_OPAD,
    X1Y31_TX_N_OPAD,
    X1Y32_TX_P_OPAD,
    X1Y32_TX_N_OPAD,
    X1Y33_TX_P_OPAD,
    X1Y33_TX_N_OPAD,
    X1Y34_TX_P_OPAD,
    X1Y34_TX_N_OPAD,
    X1Y35_TX_P_OPAD,
    X1Y35_TX_N_OPAD,
    X1Y24_RXRECCLK_O,
    X1Y25_RXRECCLK_O,
    X1Y26_RXRECCLK_O,
    X1Y27_RXRECCLK_O,
    X1Y28_RXRECCLK_O,
    X1Y29_RXRECCLK_O,
    X1Y30_RXRECCLK_O,
    X1Y31_RXRECCLK_O,
    X1Y32_RXRECCLK_O,
    X1Y33_RXRECCLK_O,
    X1Y34_RXRECCLK_O,
    X1Y35_RXRECCLK_O,
    CONTROL,
    X0Y17_RX_P_IPAD,
    X0Y17_RX_N_IPAD,
    X0Y19_RX_P_IPAD,
    X0Y19_RX_N_IPAD,
    X1Y24_RX_P_IPAD,
    X1Y24_RX_N_IPAD,
    X1Y25_RX_P_IPAD,
    X1Y25_RX_N_IPAD,
    X1Y26_RX_P_IPAD,
    X1Y26_RX_N_IPAD,
    X1Y27_RX_P_IPAD,
    X1Y27_RX_N_IPAD,
    X1Y28_RX_P_IPAD,
    X1Y28_RX_N_IPAD,
    X1Y29_RX_P_IPAD,
    X1Y29_RX_N_IPAD,
    X1Y30_RX_P_IPAD,
    X1Y30_RX_N_IPAD,
    X1Y31_RX_P_IPAD,
    X1Y31_RX_N_IPAD,
    X1Y32_RX_P_IPAD,
    X1Y32_RX_N_IPAD,
    X1Y33_RX_P_IPAD,
    X1Y33_RX_N_IPAD,
    X1Y34_RX_P_IPAD,
    X1Y34_RX_N_IPAD,
    X1Y35_RX_P_IPAD,
    X1Y35_RX_N_IPAD,
    Q4_CLK1_MGTREFCLK_I,
    IBERT_SYSCLOCK_I) /* synthesis syn_black_box syn_noprune=1 */;


output X0Y17_TX_P_OPAD;
output X0Y17_TX_N_OPAD;
output X0Y19_TX_P_OPAD;
output X0Y19_TX_N_OPAD;
output X0Y17_RXRECCLK_O;
output X1Y24_TX_P_OPAD;
output X1Y24_TX_N_OPAD;
output X1Y25_TX_P_OPAD;
output X1Y25_TX_N_OPAD;
output X1Y26_TX_P_OPAD;
output X1Y26_TX_N_OPAD;
output X1Y27_TX_P_OPAD;
output X1Y27_TX_N_OPAD;
output X1Y28_TX_P_OPAD;
output X1Y28_TX_N_OPAD;
output X1Y29_TX_P_OPAD;
output X1Y29_TX_N_OPAD;
output X1Y30_TX_P_OPAD;
output X1Y30_TX_N_OPAD;
output X1Y31_TX_P_OPAD;
output X1Y31_TX_N_OPAD;
output X1Y32_TX_P_OPAD;
output X1Y32_TX_N_OPAD;
output X1Y33_TX_P_OPAD;
output X1Y33_TX_N_OPAD;
output X1Y34_TX_P_OPAD;
output X1Y34_TX_N_OPAD;
output X1Y35_TX_P_OPAD;
output X1Y35_TX_N_OPAD;
output X1Y24_RXRECCLK_O;
output X1Y25_RXRECCLK_O;
output X1Y26_RXRECCLK_O;
output X1Y27_RXRECCLK_O;
output X1Y28_RXRECCLK_O;
output X1Y29_RXRECCLK_O;
output X1Y30_RXRECCLK_O;
output X1Y31_RXRECCLK_O;
output X1Y32_RXRECCLK_O;
output X1Y33_RXRECCLK_O;
output X1Y34_RXRECCLK_O;
output X1Y35_RXRECCLK_O;
inout [35 : 0] CONTROL;
input X0Y17_RX_P_IPAD;
input X0Y17_RX_N_IPAD;
input X0Y19_RX_P_IPAD;
input X0Y19_RX_N_IPAD;
input X1Y24_RX_P_IPAD;
input X1Y24_RX_N_IPAD;
input X1Y25_RX_P_IPAD;
input X1Y25_RX_N_IPAD;
input X1Y26_RX_P_IPAD;
input X1Y26_RX_N_IPAD;
input X1Y27_RX_P_IPAD;
input X1Y27_RX_N_IPAD;
input X1Y28_RX_P_IPAD;
input X1Y28_RX_N_IPAD;
input X1Y29_RX_P_IPAD;
input X1Y29_RX_N_IPAD;
input X1Y30_RX_P_IPAD;
input X1Y30_RX_N_IPAD;
input X1Y31_RX_P_IPAD;
input X1Y31_RX_N_IPAD;
input X1Y32_RX_P_IPAD;
input X1Y32_RX_N_IPAD;
input X1Y33_RX_P_IPAD;
input X1Y33_RX_N_IPAD;
input X1Y34_RX_P_IPAD;
input X1Y34_RX_N_IPAD;
input X1Y35_RX_P_IPAD;
input X1Y35_RX_N_IPAD;
input Q4_CLK1_MGTREFCLK_I;
input IBERT_SYSCLOCK_I;

endmodule
