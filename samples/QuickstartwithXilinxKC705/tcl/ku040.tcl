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
#    Setup base project for KU040 DB, SFP1+SMA1, in Vivado project mode
#       To setup, run this script in an empty Vivado project
# ----------------------------------------------------------------------

source [file join [file dirname [info script]] "config.tcl"]

set_property part xcku040-fbva676-1-c [current_project]
set_property simulator_language Verilog [current_project]
set_property source_mgmt_mode All [current_project]

# `define GT_SFP1SMA1
set_property verilog_define GT_SFP1SMA1=1 [current_fileset]

source ${TOP}/tcl/include/ku040-files.tcl
lappend RTLs ${TOP}/boards/ku040/aurora-dual-sfp1-sma1.v

set COREFILEs [list ]
foreach c $COREs {
    lappend COREFILEs ${TOP}/boards/ku040/ip/${c}.xci
}

lappend RTLs ${TOP}/pe-base/pe-pass.v

add_files $RTLs
import_files -flat $COREFILEs
add_files -fileset constrs_1 -norecurse $XDCs

