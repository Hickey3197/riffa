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
#    Setup base project for KCU1500 with RIFFA, in Vivado project mode
#       To setup, run this script in an empty Vivado project
# ----------------------------------------------------------------------

source [file join [file dirname [info script]] "config.tcl"]

set_property part xcku115-flvb2104-2-e [current_project]
set_property simulator_language Verilog [current_project]
set_property source_mgmt_mode All [current_project]

source ${TOP}/tcl/include/kcu1500-riffa-files.tcl
source ${TOP}/tcl/include/riffa-common.tcl

set RTLs [concat $RTLs \
              [ list \
                    ${TOP}/pcie/riffa/riffa-port-ku.v \
                    ${TOP}/pcie/riffa/riffa_wrapper_kcu1500.v \
                   ] ]


set COREFILEs [list ]
foreach c $COREs {
    lappend COREFILEs ${TOP}/boards/kcu1500/ip/${c}.xci
}

lappend RTLs ${TOP}/pe-base/pe-pass.v

add_files $RTLs
import_files -flat $COREFILEs
add_files -fileset constrs_1 -norecurse $XDCs

