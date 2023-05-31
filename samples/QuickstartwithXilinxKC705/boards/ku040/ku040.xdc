## LEDs
set_property PACKAGE_PIN D16 [get_ports {LED[0]}]
set_property PACKAGE_PIN G16 [get_ports {LED[1]}]
set_property PACKAGE_PIN H16 [get_ports {LED[2]}]
set_property PACKAGE_PIN E18 [get_ports {LED[3]}]
set_property PACKAGE_PIN E17 [get_ports {LED[4]}]
set_property PACKAGE_PIN E16 [get_ports {LED[5]}]
set_property PACKAGE_PIN H18 [get_ports {LED[6]}]
set_property PACKAGE_PIN H17 [get_ports {LED[7]}]
set_property IOSTANDARD LVCMOS18 [get_ports {LED[*]}]

## 250MHz System Clock 
set_property IOSTANDARD DIFF_SSTL12 [get_ports CLK250P]
set_property IOSTANDARD DIFF_SSTL12 [get_ports CLK250N]
set_property PACKAGE_PIN H22 [get_ports CLK250P]
set_property PACKAGE_PIN H23 [get_ports CLK250N]
create_clock -period 4 [get_ports {CLK250P}]

## 156.25MHz on Quad 226 (SMA/SFP)
set_property PACKAGE_PIN M5  [get_ports CLK156N]
set_property PACKAGE_PIN M6  [get_ports CLK156P]
set_property IOSTANDARD LVDS [get_ports CLK156N]
set_property IOSTANDARD LVDS [get_ports CLK156P]

## SFP1 signals
set_property PACKAGE_PIN M2 [get_ports SFP1_RXN]
set_property PACKAGE_PIN M1 [get_ports SFP1_RXP]
set_property PACKAGE_PIN N3 [get_ports SFP1_TXN]
set_property PACKAGE_PIN N4 [get_ports SFP1_TXP]

# SFP2 signals
set_property PACKAGE_PIN K1 [get_ports SFP2_RXN]
set_property PACKAGE_PIN K2 [get_ports SFP2_RXP]
set_property PACKAGE_PIN L3 [get_ports SFP2_TXN]
set_property PACKAGE_PIN L4 [get_ports SFP2_TXP]

# SMA1 signals
set_property PACKAGE_PIN H1 [get_ports SMA1_RXN]
set_property PACKAGE_PIN H2 [get_ports SMA1_RXP]
set_property PACKAGE_PIN J3 [get_ports SMA1_TXN]
set_property PACKAGE_PIN J4 [get_ports SMA1_TXP]

# ICAP false path
set_false_path -from [get_clocks -of_objects [get_pins icap/fifo/wr_clk]] \
               -to   [get_clocks -of_objects [get_pins icap/fifo/rd_clk]]

set_false_path -from [get_clocks -of_objects [get_pins icap/fifo/rd_clk]] \
               -to   [get_clocks -of_objects [get_pins icap/fifo/wr_clk]]




