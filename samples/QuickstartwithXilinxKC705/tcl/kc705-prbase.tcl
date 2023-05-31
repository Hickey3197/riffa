# ----------------------------------------------------------------------
# "THE BEER-WARE LICENSE" (Revision 42):
#    <yasu@prosou.nu> wrote this file. As long as you retain this
#    notice you can do whatever you want with this stuff. If we meet
#    some day, and you think this stuff is worth it, you can buy me a
#    beer in return Yasunori Osana at University of the Ryukyus,
#    Japan.
# ----------------------------------------------------------------------
# OpenFC project: an open FPGA accelerated cluster toolkit
#
# This file is to:
#    Implement static logic for partial reconfiguration with KC705
#    Run with: vivado -mode batch -source kc705-prbase.tcl
#    Note: run setup.tcl in board/kc705/ip beforehand
# ----------------------------------------------------------------------

set DEV xc7k325tffg900-2
set DIR pr/kc705-riffa

source [file join [file dirname [info script]] "config.tcl"]
source ${TOP}/tcl/include/common-pr.tcl

create_project -in_memory -part $DEV

source ${TOP}/tcl/include/kc705-files.tcl
source ${TOP}/tcl/include/riffa-common.tcl

set RTLs [concat $RTLs \
              [ list \
                    ${TOP}/pcie/riffa/riffa-port-k7.v \
                    ${TOP}/pcie/riffa/riffa_wrapper_kc705.v \
                    ${TOP}/boards/kc705/riffa-k7.vh \
                   ] ]

set COREFILEs [list ]
foreach c $COREs {
    lappend COREFILEs ${TOP}/boards/kc705/ip/iploc/${c}/${c}.xci
}

lappend RTLs ${TOP}/pe-base/pe-blackbox.v

add_files $RTLs
add_files $COREFILEs
# add_files -fileset constrs_1 -norecurse $XDCs

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
# Base blackbox design synthesis
 
synth_design -mode default -flatten_hierarchy rebuilt -top top -part $DEV \
    -include_dirs ${TOP}/pcie/riffa/src-riffa

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

resize_pblock pe_rp -add {SLICE_X0Y50:SLICE_X79Y249 DSP48_X0Y20:DSP48_X2Y99 RAMB18_X0Y20:RAMB18_X2Y99 RAMB36_X0Y10:RAMB36_X2Y49}

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
write_cfgmem -format mcs -interface bpix16 -size 128 -loadbit "up 0x0 $DIR/bit/pass.bit" -file $DIR/bit/pass.mcs -force

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
# Lock SL with blackbox

update_design -cell pe -black_box
lock_design -level routing
write_checkpoint -force $DIR/dcp/static_route.dcp
report_utilization -hierarchical  -file $DIR/dcp/static_route-hier.rpt
close_project
