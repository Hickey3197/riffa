set_global_assignment -name PRESERVE_UNUSED_XCVR_CHANNEL ON
set_global_assignment -name FLOW_ENABLE_INTERACTIVE_TIMING_ANALYZER OFF

set_location_assignment PIN_AA16 -to CLK125
set_instance_assignment -name GLOBAL_SIGNAL  GLOBAL_CLOCK -to CLK125

# PCIe stuff

set_location_assignment PIN_AB11 -to PCIE_RESET_N
set_instance_assignment -name IO_STANDARD "1.8 V" -to PCIE_RESET_N

set_location_assignment PIN_R24 -to PCIE_REFCLK
set_instance_assignment -name IO_STANDARD HCSL -to PCIE_REFCLK

set_location_assignment PIN_W28 -to PCIE_TX[0]
set_location_assignment PIN_U28 -to PCIE_TX[1]
set_location_assignment PIN_R28 -to PCIE_TX[2]
set_location_assignment PIN_N28 -to PCIE_TX[3]
set_location_assignment PIN_L28 -to PCIE_TX[4]
set_location_assignment PIN_J28 -to PCIE_TX[5]
set_location_assignment PIN_G28 -to PCIE_TX[6]
set_location_assignment PIN_E28 -to PCIE_TX[7]

set_instance_assignment -name IO_STANDARD "HSSI DIFFERENTIAL I/O" -to PCIE_TX
set_instance_assignment -name XCVR_VCCR_VCCT_VOLTAGE 0_9V -to PCIE_TX

set_location_assignment PIN_V26 -to PCIE_RX[0]
set_location_assignment PIN_T26 -to PCIE_RX[1]
set_location_assignment PIN_P26 -to PCIE_RX[2]
set_location_assignment PIN_M26 -to PCIE_RX[3]
set_location_assignment PIN_K26 -to PCIE_RX[4]
set_location_assignment PIN_H26 -to PCIE_RX[5]
set_location_assignment PIN_F26 -to PCIE_RX[6]
set_location_assignment PIN_D26 -to PCIE_RX[7]

set_instance_assignment -name IO_STANDARD CML -to PCIE_RX
set_instance_assignment -name XCVR_A10_RX_TERM_SEL R_R1 -to PCIE_RX
set_instance_assignment -name XCVR_VCCR_VCCT_VOLTAGE 0_9V -to PCIE_RX

# MGT refclk

set_location_assignment PIN_W24 -to CLK644P
set_instance_assignment -name IO_STANDARD LVDS -to CLK644P
set_instance_assignment -name XCVR_REFCLK_PIN_TERMINATION AC_COUPLING -to CLK644P
set_instance_assignment -name XCVR_A10_REFCLK_TERM_TRISTATE TRISTATE_OFF -to CLK644P

# SFP [d:a] = [3:0]

set_location_assignment PIN_AF26 -to SFP_RXP[0]
set_location_assignment PIN_AG28 -to SFP_TXP[0]
set_location_assignment PIN_AD26 -to SFP_RXP[1]
set_location_assignment PIN_AE28 -to SFP_TXP[1]
set_location_assignment PIN_AB26 -to SFP_RXP[2]
set_location_assignment PIN_AC28 -to SFP_TXP[2]
set_location_assignment PIN_Y26 -to SFP_RXP[3]
set_location_assignment PIN_AA28 -to SFP_TXP[3]

set_instance_assignment -name IO_STANDARD "HSSI DIFFERENTIAL I/O" -to SFP_TXP
set_instance_assignment -name IO_STANDARD "CURRENT MODE LOGIC (CML)" -to SFP_RXP

set_instance_assignment -name XCVR_A10_RX_TERM_SEL R_R1 -to SFP_RXP
set_instance_assignment -name XCVR_A10_RX_ONE_STAGE_ENABLE NON_S1_MODE -to SFP_RXP
set_instance_assignment -name XCVR_VCCR_VCCT_VOLTAGE 0_9V -to SFP_RXP
set_instance_assignment -name XCVR_A10_RX_ADP_VGA_SEL RADP_VGA_SEL_4 -to SFP_RXP
set_instance_assignment -name XCVR_A10_RX_EQ_DC_GAIN_TRIM NO_DC_GAIN -to SFP_RXP
set_instance_assignment -name XCVR_A10_RX_ADP_CTLE_ACGAIN_4S RADP_CTLE_ACGAIN_4S_15 -to SFP_RXP

set_instance_assignment -name XCVR_A10_TX_VOD_OUTPUT_SWING_CTRL 23 -to SFP_TXP
set_instance_assignment -name XCVR_VCCR_VCCT_VOLTAGE 0_9V -to SFP_TXP
set_instance_assignment -name XCVR_A10_TX_PRE_EMP_SWITCHING_CTRL_1ST_POST_TAP 5 -to SFP_TXP
set_instance_assignment -name XCVR_A10_TX_PRE_EMP_SIGN_1ST_POST_TAP FIR_POST_1T_NEG -to SFP_TXP
set_instance_assignment -name XCVR_A10_TX_PRE_EMP_SWITCHING_CTRL_PRE_TAP_1T 1 -to SFP_TXP
set_instance_assignment -name XCVR_A10_TX_PRE_EMP_SIGN_PRE_TAP_1T FIR_PRE_1T_NEG -to SFP_TXP
set_instance_assignment -name XCVR_A10_TX_PRE_EMP_SWITCHING_CTRL_2ND_POST_TAP 2 -to SFP_TXP
set_instance_assignment -name XCVR_A10_TX_PRE_EMP_SIGN_2ND_POST_TAP FIR_POST_2T_NEG -to SFP_TXP
