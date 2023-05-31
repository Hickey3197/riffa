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
#    be included in Cyclone 10 GX project setup scripts
# ----------------------------------------------------------------------

set RTLs [ list \
               ${TOP}/boards/c10gx/top.v \
               \
               ${TOP}/pcie/riffa/pcie-wrapper-c10.v \
               ${TOP}/pcie/riffa/riffa-port-c10.v \
               ${TOP}/pcie/riffa/riffa_wrapper_c10.v \
               \
               ${TOP}/core/router.v \
               ${TOP}/core/link-act.v \
               ${TOP}/icap/intel/pe-icap.v \
               \
               ${TOP}/boards/c10gx/xilinx_compat/fifo_64x512_afull.v \
               ${TOP}/boards/c10gx/xilinx_compat/fwft_64x512_afull.v \
               ${TOP}/boards/c10gx/xilinx_compat/fwft_64x512_32_async_afull.v \
              ] 

set COREs [ list \
                ${TOP}/boards/c10gx/ip/c10pcie_gen2x4.ip \
                ${TOP}/boards/c10gx/ip/icap_dcm.ip \
                ${TOP}/boards/c10gx/ip/pr_ip.ip \
               ]

set XDCs [ list \
               ${TOP}/boards/c10gx/c10gx.tcl \
              ]
