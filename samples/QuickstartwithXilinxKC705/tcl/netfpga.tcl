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
#    Setup base project for NetFPGA-1G_CML, in Vivado project mode
#       To setup, run this script in an empty Vivado project
# ----------------------------------------------------------------------

source [file join [file dirname [info script]] "config.tcl"]

set_property part xc7k325tffg676-1 [current_project]
set_property simulator_language Verilog [current_project]
set_property source_mgmt_mode All [current_project]

source ${TOP}/tcl/include/netfpga-files.tcl
source ${TOP}/tcl/include/riffa-common.tcl

set COREFILEs [list ]
foreach c $COREs {
    lappend COREFILEs ${TOP}/boards/netfpga/ip/${c}.xci
}

lappend RTLs ${TOP}/pe-base/pe-pass.v

add_files $RTLs
import_files -flat $COREFILEs
add_files -fileset constrs_1 -norecurse $XDCs

# Performance options for NetFPGA x RIFFA

set_property strategy Flow_PerfOptimized_high [get_runs synth_1]
set_property STEPS.SYNTH_DESIGN.ARGS.RETIMING true [get_runs synth_1]
