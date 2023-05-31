set_global_assignment -name PRESERVE_UNUSED_XCVR_CHANNEL ON
set_global_assignment -name FLOW_ENABLE_INTERACTIVE_TIMING_ANALYZER OFF

# RST on user_pb0
set_location_assignment PIN_AE4 -to RST_N
set_instance_assignment -name IO_STANDARD "1.8 V" -to RST_N

# CLKUSR as CLK100
set_location_assignment PIN_Y15 -to CLK100
set_instance_assignment -name IO_STANDARD "1.8 V" -to CLK100 -entity top
set_instance_assignment -name GLOBAL_SIGNAL GLOBAL_CLOCK -to CLK100 -entity top
set_global_assignment -name AUTO_RESERVE_CLKUSR_FOR_CALIBRATION OFF

# LEDs
set_location_assignment PIN_AC7 -to LED[3]
set_location_assignment PIN_AC6 -to LED[2]
set_location_assignment PIN_AE6 -to LED[1]
set_location_assignment PIN_AF6 -to LED[0]
set_instance_assignment -name IO_STANDARD "1.8 V" -to LED[0]
set_instance_assignment -name IO_STANDARD "1.8 V" -to LED[1]
set_instance_assignment -name IO_STANDARD "1.8 V" -to LED[2]
set_instance_assignment -name IO_STANDARD "1.8 V" -to LED[3]

# PCIe stuff
set_location_assignment PIN_AB11 -to PCIE_RESET_N
set_instance_assignment -name IO_STANDARD "1.8 V" -to PCIE_RESET_N

set_location_assignment PIN_R24  -to PCIE_REFCLK
set_location_assignment PIN_R23 -to "PCIE_REFCLK(n)"

set_instance_assignment -name IO_STANDARD LVDS -to PCIE_REFCLK
set_instance_assignment -name XCVR_REFCLK_PIN_TERMINATION AC_COUPLING -to PCIE_REFCLK

set_location_assignment PIN_N28  -to PCIE_TX[3]
set_location_assignment PIN_R28  -to PCIE_TX[2]
set_location_assignment PIN_U28  -to PCIE_TX[1]
set_location_assignment PIN_W28  -to PCIE_TX[0]


set_instance_assignment -name IO_STANDARD "HIGH SPEED DIFFERENTIAL I/O" -to PCIE_TX

set_location_assignment PIN_M26  -to PCIE_RX[3]
set_location_assignment PIN_P26  -to PCIE_RX[2]
set_location_assignment PIN_T26  -to PCIE_RX[1]
set_location_assignment PIN_V26  -to PCIE_RX[0]

set_instance_assignment -name IO_STANDARD "CURRENT MODE LOGIC (CML)" -to PCIE_RX

# MGT REFCLK
set_location_assignment PIN_N24 -to REFCLK644P
set_location_assignment PIN_N23 -to REFCLK644N
set_instance_assignment -name IO_STANDARD LVDS -to REFCLK644P
set_instance_assignment -name XCVR_REFCLK_PIN_TERMINATION AC_COUPLING -to REFCLK644P

# SFP
set_location_assignment PIN_G28 -to SFP_TXP[0]
set_location_assignment PIN_F26 -to SFP_RXP[0]
set_location_assignment PIN_J28 -to SFP_TXP[1]
set_location_assignment PIN_H26 -to SFP_RXP[1]

set_instance_assignment -name IO_STANDARD "HSSI DIFFERENTIAL I/O" -to SFP_TXP
set_instance_assignment -name IO_STANDARD "HSSI DIFFERENTIAL I/O" -to SFP_RXP

set_instance_assignment -name XCVR_C10_RX_TERM_SEL R_R1 -to SFP_RXP
set_instance_assignment -name XCVR_C10_RX_ONE_STAGE_ENABLE NON_S1_MODE -to SFP_RXP
set_instance_assignment -name XCVR_C10_RX_EQ_DC_GAIN_TRIM NO_DC_GAIN -to SFP_RXP
set_instance_assignment -name XCVR_VCCR_VCCT_VOLTAGE 1_0V -to SFP_RXP
set_instance_assignment -name XCVR_C10_RX_ADP_VGA_SEL RADP_VGA_SEL_4 -to SFP_RXP
set_instance_assignment -name XCVR_C10_RX_ADP_CTLE_ACGAIN_4S RADP_CTLE_ACGAIN_4S_15 -to SFP_RXP

set_instance_assignment -name XCVR_C10_TX_VOD_OUTPUT_SWING_CTRL 31 -to SFP_TXP
set_instance_assignment -name XCVR_VCCR_VCCT_VOLTAGE 1_0V -to SFP_TXP
set_instance_assignment -name XCVR_C10_TX_COMPENSATION_EN ENABLE -to SFP_TXP
set_instance_assignment -name XCVR_C10_TX_PRE_EMP_SWITCHING_CTRL_1ST_POST_TAP 3 -to SFP_TXP
set_instance_assignment -name XCVR_C10_TX_PRE_EMP_SIGN_1ST_POST_TAP FIR_POST_1T_NEG -to SFP_TXP
set_instance_assignment -name XCVR_C10_TX_PRE_EMP_SWITCHING_CTRL_PRE_TAP_1T 3 -to SFP_TXP
set_instance_assignment -name XCVR_C10_TX_PRE_EMP_SIGN_PRE_TAP_1T FIR_PRE_1T_NEG -to SFP_TXP
set_instance_assignment -name XCVR_C10_TX_PRE_EMP_SWITCHING_CTRL_2ND_POST_TAP 3 -to SFP_TXP
set_instance_assignment -name XCVR_C10_TX_PRE_EMP_SIGN_2ND_POST_TAP FIR_POST_2T_POS -to SFP_TXP
set_instance_assignment -name XCVR_C10_TX_PRE_EMP_SWITCHING_CTRL_PRE_TAP_2T 0 -to SFP_TXP
set_instance_assignment -name XCVR_C10_TX_PRE_EMP_SIGN_PRE_TAP_2T FIR_PRE_2T_POS -to SFP_TXP
 
