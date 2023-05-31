set_property PACKAGE_PIN AF8 [get_ports PCIE_REFCLK_N]
set_property PACKAGE_PIN AF9 [get_ports PCIE_REFCLK_P]

set_property PACKAGE_PIN AW27 [get_ports PCIE_RESET_N]
set_property IOSTANDARD LVCMOS18 [get_ports PCIE_RESET_N]

# PCIe clock

create_clock -period 10.000 -name pcie_refclk \
             [get_pins -hierarchical -filter {NAME =~ *pcie_ckbuf0/O}]

# CMC/HBMref clk @ 100MHz

set_property PACKAGE_PIN G17 [get_ports CMC_CLKP]
set_property PACKAGE_PIN G16 [get_ports CMC_CLKN]
set_property PACKAGE_PIN BC18 [get_ports HBM_CLKN]
set_property PACKAGE_PIN BB18 [get_ports HBM_CLKP]

set_property IOSTANDARD LVDS [get_ports CMC_CLKP]
set_property IOSTANDARD LVDS [get_ports CMC_CLKN]
set_property IOSTANDARD LVDS [get_ports HBM_CLKP]
set_property IOSTANDARD LVDS [get_ports HBM_CLKN]
set_property DQS_BIAS TRUE [get_ports CMC_CLKP]
set_property DQS_BIAS TRUE [get_ports CMC_CLKN]
set_property DQS_BIAS TRUE [get_ports HBM_CLKP]
set_property DQS_BIAS TRUE [get_ports HBM_CLKN]

create_clock -period 10.000 -name cmc_clk [get_ports CMC_CLKP]
create_clock -period 10.000 -name hbm_clk [get_ports HBM_CLKP]

# QSFP GTrefclk @ 161.1328125MHz

set_property PACKAGE_PIN N37 [get_ports QSFP_REFCLKN]
set_property PACKAGE_PIN N36 [get_ports QSFP_REFCLKP]

# QSFP signals

set_property PACKAGE_PIN J46  [get_ports QSFP_RXN[0]]
set_property PACKAGE_PIN G46  [get_ports QSFP_RXN[1]]
set_property PACKAGE_PIN F44  [get_ports QSFP_RXN[2]]
set_property PACKAGE_PIN E46  [get_ports QSFP_RXN[3]]
set_property PACKAGE_PIN J45  [get_ports QSFP_RXP[0]]
set_property PACKAGE_PIN G45  [get_ports QSFP_RXP[1]]
set_property PACKAGE_PIN F43  [get_ports QSFP_RXP[2]]
set_property PACKAGE_PIN E45  [get_ports QSFP_RXP[3]]
set_property PACKAGE_PIN D43  [get_ports QSFP_TXN[0]]
set_property PACKAGE_PIN C41  [get_ports QSFP_TXN[1]]
set_property PACKAGE_PIN B43  [get_ports QSFP_TXN[2]]
set_property PACKAGE_PIN A41  [get_ports QSFP_TXN[3]]
set_property PACKAGE_PIN D42  [get_ports QSFP_TXP[0]]
set_property PACKAGE_PIN C40  [get_ports QSFP_TXP[1]]
set_property PACKAGE_PIN B42  [get_ports QSFP_TXP[2]]
set_property PACKAGE_PIN A40  [get_ports QSFP_TXP[3]]

# set_property LOC GTYE4_CHANNEL_X0Y29 [get_cells -hierarchical -filter {NAME =~ *aurora_gen[1].acX*GTYE4_CHANNEL_PRIM_INST}]
# set_property LOC GTYE4_CHANNEL_X0Y30 [get_cells -hierarchical -filter {NAME =~ *aurora_gen[2].acX*GTYE4_CHANNEL_PRIM_INST}]
# set_property LOC GTYE4_CHANNEL_X0Y31 [get_cells -hierarchical -filter {NAME =~ *aurora_gen[3].acX*GTYE4_CHANNEL_PRIM_INST}]

## LEDs
set_property PACKAGE_PIN E18      [get_ports LED_ACT]
set_property PACKAGE_PIN E16      [get_ports LED_STA_G]
set_property PACKAGE_PIN F17      [get_ports LED_STA_Y]
set_property IOSTANDARD  LVCMOS18 [get_ports {LED_STA_G LED_STA_Y LED_ACT}]

## ICAP false path
set_false_path -from [get_clocks -of_objects [get_pins icap/fifo/wr_clk]] \
               -to   [get_clocks -of_objects [get_pins icap/fifo/rd_clk]]

set_false_path -from [get_clocks -of_objects [get_pins icap/fifo/rd_clk]] \
               -to   [get_clocks -of_objects [get_pins icap/fifo/wr_clk]]
