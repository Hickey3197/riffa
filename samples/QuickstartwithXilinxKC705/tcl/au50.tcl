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
#    Setup base project for Xilinx Alveo U50 board
#       To setup, run this script in an empty Vivado project
# ----------------------------------------------------------------------

source [file join [file dirname [info script]] "config.tcl"]

set_property part xcu50-fsvh2104-2-e [current_project]
set_property board_part xilinx.com:au50:1.0 [current_project]
set_property simulator_language Verilog [current_project]
set_property source_mgmt_mode All [current_project]

source ${TOP}/tcl/include/au50-files.tcl

set COREFILEs [list ]
foreach c $COREs {
    lappend COREFILEs ${TOP}/boards/au50/ip/${c}.xci
}

lappend RTLs ${TOP}/pe-base/pe-pass.v

add_files $RTLs
import_files -flat $COREFILEs
add_files -fileset constrs_1 -norecurse $XDCs

