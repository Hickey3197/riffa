# LEDs
set_property PACKAGE_PIN E17 [get_ports {BOARD_LED[0]}]
set_property PACKAGE_PIN AF14 [get_ports {BOARD_LED[1]}]
set_property PACKAGE_PIN F17 [get_ports {BOARD_LED[2]}]
set_property PACKAGE_PIN W19 [get_ports {BOARD_LED[3]}]

set_property IOSTANDARD LVCMOS33 [get_ports {BOARD_LED[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {BOARD_LED[2]}]
set_property IOSTANDARD LVCMOS18 [get_ports {BOARD_LED[1]}]
set_property IOSTANDARD LVCMOS18 [get_ports {BOARD_LED[3]}]

set_property PACKAGE_PIN D19 [get_ports {PMOD_LED[0]}]
set_property PACKAGE_PIN E13 [get_ports {PMOD_LED[1]}]
set_property PACKAGE_PIN D25 [get_ports {PMOD_LED[2]}]
set_property PACKAGE_PIN F23 [get_ports {PMOD_LED[3]}]
set_property PACKAGE_PIN F19 [get_ports {PMOD_LED[4]}]
set_property PACKAGE_PIN G22 [get_ports {PMOD_LED[5]}]
set_property PACKAGE_PIN D24 [get_ports {PMOD_LED[6]}]
set_property PACKAGE_PIN E21 [get_ports {PMOD_LED[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {PMOD_LED[*]}]

# DP0 and DP1 ports
set_property PACKAGE_PIN B2 [get_ports DP0_TXP]
set_property PACKAGE_PIN C4 [get_ports DP0_RXP]
set_property PACKAGE_PIN B1 [get_ports DP0_TXN]
set_property PACKAGE_PIN C3 [get_ports DP0_RXN]

set_property PACKAGE_PIN D2 [get_ports DP1_TXP]
set_property PACKAGE_PIN E3 [get_ports DP1_RXP]
set_property PACKAGE_PIN D1 [get_ports DP1_TXN]
set_property PACKAGE_PIN E4 [get_ports DP1_RXN]

# SYS_CLK
set_property PACKAGE_PIN AA3 [get_ports CLK200P]
set_property PACKAGE_PIN AA2 [get_ports CLK200N]
set_property IOSTANDARD LVDS [get_ports CLK200P]
set_property IOSTANDARD LVDS [get_ports CLK200N]
create_clock -period 5.000 [get_ports CLK200P]

# FMC Clock
set_property PACKAGE_PIN F6 [get_ports CLK156P]
set_property PACKAGE_PIN F5 [get_ports CLK156N]

# ICAP false path
set_false_path -from [get_clocks -of_objects [get_pins icap/fifo/wr_clk]] -to [get_clocks -of_objects [get_pins icap/fifo/rd_clk]]

set_false_path -from [get_clocks -of_objects [get_pins icap/fifo/rd_clk]] -to [get_clocks -of_objects [get_pins icap/fifo/wr_clk]]


