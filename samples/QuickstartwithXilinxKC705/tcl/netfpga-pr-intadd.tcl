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
#    Implement pe_intadd as a PR module on the static logic
#    imlemented by netfpga-prbase.tcl
#    Run with: vivado -mode batch -source netfpga-pr-intadd.tcl
# ----------------------------------------------------------------------

set DEV xc7k325tffg676-1
set DIR pr/netfpga-riffa

source [file join [file dirname [info script]] "config.tcl"]
source ${TOP}/tcl/include/common-pr.tcl

create_project -in_memory -part $DEV

set MODULE intadd
set SRCs [ list \
               ${TOP}/pe-base/pe-intadd.v \
               ${TOP}/boards/netfpga/ip/iploc/fwft_64x512_afull/fwft_64x512_afull.xci ]
synth
impl_pr

