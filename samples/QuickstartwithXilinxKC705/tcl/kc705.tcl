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
#    Setup base project for KC705, in Vivado project mode
#       To setup, run this script in an empty Vivado project
# ----------------------------------------------------------------------

source [file join [file dirname [info script]] "config.tcl"]

set_property part xc7k325tffg900-2 [current_project]
set_property simulator_language Verilog [current_project]
set_property source_mgmt_mode All [current_project]

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
    lappend COREFILEs ${TOP}/boards/kc705/ip/${c}.xci
}

lappend RTLs ${TOP}/pe-base/pe-pass.v

add_files $RTLs
import_files -flat $COREFILEs
add_files -fileset constrs_1 -norecurse $XDCs
