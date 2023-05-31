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
#    be included in HawkEye project setup scripts
# ----------------------------------------------------------------------

set RTLs [ list \
               ${TOP}/boards/hawkeye/top.v \
               \
               ${TOP}/pcie/riffa/pcie-wrapper-hawkeye.v \
               ${TOP}/pcie/riffa/riffa-port-hawkeye.v \
               ${TOP}/pcie/riffa/riffa_wrapper_c10.v \
               \
               ${TOP}/core/router.v \
               ${TOP}/core/link-act.v \
               ${TOP}/icap/intel/pe-icap.v \
               \
               ${TOP}/boards/hawkeye/xilinx_compat/fifo_64x1024_128_afull.v \
               ${TOP}/boards/hawkeye/xilinx_compat/fifo_128x512_64_afull.v \
               ${TOP}/boards/c10gx/xilinx_compat/fwft_64x512_afull.v \
               ${TOP}/boards/c10gx/xilinx_compat/fifo_64x512_afull.v \
               ${TOP}/boards/c10gx/xilinx_compat/fwft_64x512_32_async_afull.v \
               ] 

set COREs [ list \
                ${TOP}/boards/hawkeye/ip/a10pcie_gen2x8.ip \
                ${TOP}/boards/hawkeye/ip/icap_dcm.ip \
                ${TOP}/boards/hawkeye/ip/pr_ip.ip \
               ]

set XDCs [ list \
               ${TOP}/boards/hawkeye/hawkeye.tcl \
              ]
