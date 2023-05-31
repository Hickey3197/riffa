# Must be loaded ** BEFORE ** netfpga.xdc

create_clock -period 10.000 -name pcie_refclk [get_pins pci/refclk_ibuf/O]

set_property IOSTANDARD LVCMOS33 [get_ports PCIE_RESET_N]
set_property PULLUP true [get_ports PCIE_RESET_N]
set_property PACKAGE_PIN L17 [get_ports PCIE_RESET_N]

# set_false_path -to [get_ports -filter {NAME=~LED*}]

set_property LOC IBUFDS_GTE2_X0Y0 [get_cells pci/refclk_ibuf]

set_property LOC GTXE2_CHANNEL_X0Y3 [get_cells -match_style ucf {*/gt_top_i/pipe_wrapper_i/pipe_lane[0].gt_wrapper_i/gtx_channel.gtxe2_channel_i}]
set_property LOC GTXE2_CHANNEL_X0Y2 [get_cells -match_style ucf {*/gt_top_i/pipe_wrapper_i/pipe_lane[1].gt_wrapper_i/gtx_channel.gtxe2_channel_i}]
set_property LOC GTXE2_CHANNEL_X0Y1 [get_cells -match_style ucf {*/gt_top_i/pipe_wrapper_i/pipe_lane[2].gt_wrapper_i/gtx_channel.gtxe2_channel_i}]
set_property LOC GTXE2_CHANNEL_X0Y0 [get_cells -match_style ucf {*/gt_top_i/pipe_wrapper_i/pipe_lane[3].gt_wrapper_i/gtx_channel.gtxe2_channel_i}]

set_false_path -from [get_ports PCIE_RESET_N]
