///////////////////////////////////////////////////////////////////////////////////////////
//  Copyright (c) 2009 Xilinx, Inc.
//
//   ____  ____
//  /   /\/   /
// /___/  \  /   This   document  contains  proprietary information  which   is
// \   \   \/    protected by  copyright. All rights  are reserved. No  part of
//  \   \        this  document may be photocopied, reproduced or translated to
//  /   /        another  program  language  without  prior written  consent of
// /___/   /\    XILINX Inc., San Jose, CA. 95125                              
// \   \  /  \ 
//  \___\/\___\
// 
//  Xilinx Template Revision:
//   $RCSfile: example_prime_top.ejava,v $
//   $Revision: 1.4 $
//   Modify $Date: 2011/12/08 14:40:47 $
//   Application : Virtex-6 IBERT
//   Version : 1.4
//
//  Description:
//   This file is an example top wrapper for the ibert design with the required
//   clock buffers. User logic can be instantiated in this wrapper along with 
//   the ibert design.
//

`timescale 1ns / 1ps
//***************************** Module ****************************
module example_ibert_check
  (
  //Input Declarations
  input IBERT_SYSCLOCK_P_IPAD,
  input IBERT_SYSCLOCK_N_IPAD,
  input X0Y17_RX_P_IPAD,
  input X0Y17_RX_N_IPAD,
  input X0Y19_RX_P_IPAD,
  input X0Y19_RX_N_IPAD,
  input Q4_CLK1_MGTREFCLK_P_IPAD,
  input Q4_CLK1_MGTREFCLK_N_IPAD,
  //Output Decalarations
  output X0Y17_TX_P_OPAD,
  output X0Y17_TX_N_OPAD,
  output X0Y19_TX_P_OPAD,
  output X0Y19_TX_N_OPAD,
  //User Ports
  output X0Y17_RXRECCLK_P_OPAD,
  output X0Y17_RXRECCLK_N_OPAD
  );

  //local signals declaration
  wire q4_clk1_mgtrefclk;
  wire ibert_sysclock;
  wire x0y17_rxrecclk;
  wire x0y17_rxrecclk_oddr_out;
  wire [35:0] control0;
  //User Signals
  //Icon core instance
  chipscope_icon_1 U_ICON
    ( 
    .CONTROL0(control0));
  // Ibert Core Wrapper Instance
  ibert_check U_IBERT_CHECK
    (
    .X0Y17_TX_P_OPAD(X0Y17_TX_P_OPAD),
    .X0Y17_TX_N_OPAD(X0Y17_TX_N_OPAD),
    .X0Y19_TX_P_OPAD(X0Y19_TX_P_OPAD),
    .X0Y19_TX_N_OPAD(X0Y19_TX_N_OPAD),
    .X0Y17_RXRECCLK_O(x0y17_rxrecclk),
    .X0Y17_RX_P_IPAD(X0Y17_RX_P_IPAD),
    .X0Y17_RX_N_IPAD(X0Y17_RX_N_IPAD),
    .X0Y19_RX_P_IPAD(X0Y19_RX_P_IPAD),
    .X0Y19_RX_N_IPAD(X0Y19_RX_N_IPAD),
    .Q4_CLK1_MGTREFCLK_I(q4_clk1_mgtrefclk),
    .CONTROL(control0),
    .IBERT_SYSCLOCK_I(ibert_sysclock)
    );

  // GT Refclock Instances
  //---- Refclk Q4-Refclk1 sources GT(s) X0Y19 X0Y17
  IBUFDS_GTXE1 U_Q4_CLK1_MGTREFCLK
   (
   .O(q4_clk1_mgtrefclk),
   .ODIV2(),
   .CEB(1'b0),
   .I(Q4_CLK1_MGTREFCLK_P_IPAD),
   .IB(Q4_CLK1_MGTREFCLK_N_IPAD)
   );

  // Sysclock Source
  assign ibert_sysclock = IBERT_SYSCLOCK_P_IPAD;


endmodule

// Black box declaration
module ibert_check
  (
  output X0Y17_TX_P_OPAD,
  output X0Y17_TX_N_OPAD,
  output X0Y19_TX_P_OPAD,
  output X0Y19_TX_N_OPAD,
  output X0Y17_RXRECCLK_O,
  input X0Y17_RX_P_IPAD,
  input X0Y17_RX_N_IPAD,
  input X0Y19_RX_P_IPAD,
  input X0Y19_RX_N_IPAD,
  input Q4_CLK1_MGTREFCLK_I,
  inout [35:0] CONTROL,
  input IBERT_SYSCLOCK_I
  );
endmodule
module chipscope_icon_1
  (
  inout [35:0] CONTROL0);
endmodule
