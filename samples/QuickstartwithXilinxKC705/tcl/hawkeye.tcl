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
#    Setup base project for Gidel HawkEye board in Quartus II
#       To setup, run this script in an empty Quartus II project
# ----------------------------------------------------------------------

source [file join [file dirname [info script]] "config.tcl"]

set_global_assignment -name FAMILY "Arria 10"
set_global_assignment -name TOP_LEVEL_ENTITY top
set_global_assignment -name MIN_CORE_JUNCTION_TEMP 0
set_global_assignment -name MAX_CORE_JUNCTION_TEMP 100
set_global_assignment -name DEVICE 10AX048E4F29E3SG
set_global_assignment -name SEARCH_PATH ${TOP}/pcie/riffa/src-riffa/
set_global_assignment -name PROJECT_OUTPUT_DIRECTORY output_files
set_global_assignment -name SDC_FILE ${TOP}/boards/hawkeye/hawkeye.sdc

source ${TOP}/tcl/include/hawkeye-files.tcl
source ${TOP}/tcl/include/riffa-intel.tcl
lappend RTLs ${TOP}/pe-base/pe-pass.v

foreach r $RTLs {
    set_global_assignment -name VERILOG_FILE $r
}

foreach c $COREs {
    set_global_assignment -name IP_FILE $c
}

foreach c $XDCs {
    source $c
}

export_assignments
