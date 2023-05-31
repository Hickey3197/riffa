create_clock -period 10.000 -name pcie_refclk [get_pins pci/refclk_ibuf/O]

set_property IOSTANDARD LVCMOS25 [get_ports PCIE_RESET_N]
set_property PULLUP true [get_ports PCIE_RESET_N]
set_property PACKAGE_PIN G25 [get_ports PCIE_RESET_N]

set_false_path -to [get_ports -filter {NAME=~LED*}]

set_property LOC IBUFDS_GTE2_X0Y1 [get_cells pci/refclk_ibuf]

set_false_path -from [get_ports PCIE_RESET_N]

