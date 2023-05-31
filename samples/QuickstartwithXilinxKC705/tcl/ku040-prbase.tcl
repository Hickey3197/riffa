# ----------------------------------------------------------------------
# "THE BEER-WARE LICENSE" (Revision 42):
#    <yasu@prosou.nu> wrote this file. As long as you retain this
#    notice you can do whatever you want with this stuff. If we meet
#    some day, and you think this stuff is worth it, you can buy me a
#    beer in return Yasunori Osana at University of the Ryukyus,
#    Japan.
# ----------------------------------------------------------------------
# OpenFC project: an open FPGA accelerated cluster framework
#
# This file is to:
#    Implement static logic for partial reconfiguration with Avnet KU040
#       Development board, in SFP1+SMA1 aurora ports
#    Run with: vivado -mode batch -source ku040.tcl
#    Note: run setup.tcl in board/ku040/ip beforehand
# ----------------------------------------------------------------------

set DEV xcku040-fbva676-1-c
set DIR pr/ku040

source [file join [file dirname [info script]] "config.tcl"]
source ${TOP}/tcl/include/common-pr.tcl

create_project -in_memory -part $DEV

source ${TOP}/tcl/include/ku040-files.tcl
lappend RTLs ${TOP}/boards/ku040/aurora-dual-sfp1-sma1.v

set COREFILEs [list ]
foreach c $COREs {
    lappend COREFILEs ${TOP}/boards/ku040/ip/iploc/${c}/${c}.xci
}

lappend RTLs ${TOP}/pe-base/pe-blackbox.v

add_files $RTLs
add_files $COREFILEs
# add_files -fileset constrs_1 -norecurse $XDCs

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
# Base blackbox design synthesis
 
synth_design -mode default -flatten_hierarchy rebuilt -top top -part $DEV \
    -verilog_define GT_SFP1SMA1=1

exec mkdir -p $DIR/syn $DIR/dcp $DIR/xdc $DIR/impl $DIR/bit
write_checkpoint  -force $DIR/syn/top-synth.dcp
report_utilization -file $DIR/syn/top-utilization_synth.rpt
close_project

# ----------------------------------------------------------------------
# pe-pass RM synthesis

set MODULE pr-pass
set SRCs [ list \
               ${TOP}/pe-base/pe-pass.v ]
synth

# ----------------------------------------------------------------------
# Read checkpoints, set Pblock, implement and lock SL

open_checkpoint $DIR/syn/top-synth.dcp
read_checkpoint -cell pe $DIR/syn/pr-pass-synth.dcp

set_property HD.RECONFIGURABLE 1 [get_cells pe]
write_checkpoint -force $DIR/dcp/top-pass-link.dcp

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
# Set Pblock

startgroup
create_pblock pe_rp

resize_pblock pe_rp -add {SLICE_X0Y0:SLICE_X75Y299 DSP48E2_X0Y0:DSP48E2_X13Y119 RAMB18_X0Y0:RAMB18_X7Y119 RAMB36_X0Y0:RAMB36_X7Y59}

add_cells_to_pblock pe_rp [get_cells [list pe]] -clear_locs
endgroup
set_property RESET_AFTER_RECONFIG 1 [get_pblocks pe_rp]
set_property SNAPPING_MODE ON [get_pblocks pe_rp]

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
# run DRC

do_drc
write_xdc -force $DIR/xdc/pblocks.xdc

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
# Implement with pe-pass

read_xdc $XDCs
opt_design
place_design
route_design

write_checkpoint -force $DIR/impl/pass.dcp
report_utilization -hierarchical  -file $DIR/impl/pass.rpt
report_timing_summary -file $DIR/impl/pass.tsr

write_bitstream -force -bin_file $DIR/bit/pass.bit

set_property BITSTREAM.Config.SPI_buswidth 4 [current_design]
write_bitstream -no_partial_bitfile -force -bin_file $DIR/bit/pass-spi4.bit
write_cfgmem -format mcs -interface spix4 -size 32 -loadbit "up 0x0 $DIR/bit/pass-spi4.bit" -file $DIR/bit/pass.mcs -force

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
# Lock SL with blackbox

update_design -cell pe -black_box
lock_design -level routing
write_checkpoint -force $DIR/dcp/static_route.dcp
report_utilization -hierarchical  -file $DIR/dcp/static_route-hier.rpt
close_project
