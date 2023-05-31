set_property -dict "PACKAGE_PIN AB8  IOSTANDARD LVCMOS15" [get_ports "LED[0]"]
set_property -dict "PACKAGE_PIN AA8  IOSTANDARD LVCMOS15" [get_ports "LED[1]"]
set_property -dict "PACKAGE_PIN AC9  IOSTANDARD LVCMOS15" [get_ports "LED[2]"]
set_property -dict "PACKAGE_PIN AB9  IOSTANDARD LVCMOS15" [get_ports "LED[3]"]
set_property -dict "PACKAGE_PIN AE26 IOSTANDARD LVCMOS25" [get_ports "LED[4]"]
set_property -dict "PACKAGE_PIN G19  IOSTANDARD LVCMOS25" [get_ports "LED[5]"]
set_property -dict "PACKAGE_PIN E18  IOSTANDARD LVCMOS25" [get_ports "LED[6]"]
set_property -dict "PACKAGE_PIN F16  IOSTANDARD LVCMOS25" [get_ports "LED[7]"]

set_property DCI_CASCADE {32 34} [get_iobanks 33]

# SMA and SFP ports
set_property PACKAGE_PIN K2 [get_ports SMA_TXP]
set_property PACKAGE_PIN K6 [get_ports SMA_RXP]
set_property PACKAGE_PIN K1 [get_ports SMA_TXN]
set_property PACKAGE_PIN K5 [get_ports SMA_RXN]

set_property PACKAGE_PIN H2 [get_ports SFP_TXP]
set_property PACKAGE_PIN G3 [get_ports SFP_RXN]
set_property PACKAGE_PIN H1 [get_ports SFP_TXN]
set_property PACKAGE_PIN G4 [get_ports SFP_RXP]

# SYS_CLK
set_property PACKAGE_PIN AD12 [get_ports CLK200P]
set_property PACKAGE_PIN AD11 [get_ports CLK200N]
set_property IOSTANDARD LVDS  [get_ports CLK200P]
set_property IOSTANDARD LVDS  [get_ports CLK200N]
create_clock -period 5 [get_ports CLK200P]

# SGMIICLK (for MGT, not used in current design)
set_property PACKAGE_PIN G8 [get_ports CLK125P]
set_property PACKAGE_PIN G7 [get_ports CLK125N]

# USER_CLK
set_property PACKAGE_PIN K28 [get_ports CLK156P]
set_property PACKAGE_PIN K29 [get_ports CLK156N]
set_property IOSTANDARD LVDS_25 [get_ports CLK156P]
set_property IOSTANDARD LVDS_25 [get_ports CLK156N]

# ICAP false path
set_false_path -from [get_clocks -of_objects [get_pins icap/fifo/wr_clk]] \
               -to   [get_clocks -of_objects [get_pins icap/fifo/rd_clk]]

set_false_path -from [get_clocks -of_objects [get_pins icap/fifo/rd_clk]] \
               -to   [get_clocks -of_objects [get_pins icap/fifo/wr_clk]]

