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
#    be included in NetFPGA-1G-CML project setup scripts
# ----------------------------------------------------------------------

set RTLs [ list \
               ${TOP}/boards/netfpga/top.v \
               ${TOP}/boards/netfpga/aurora-dual.v \
               ${TOP}/boards/netfpga/netfpga-clk.v \
               \
               ${TOP}/pcie/riffa/riffa-port-k7.v \
               ${TOP}/pcie/riffa/riffa_wrapper_kc705.v \
               ${TOP}/boards/netfpga/riffa-k7.vh \
               \
               ${TOP}/serdes/aurora/aurora-port-axi.v \
               ${TOP}/serdes/aurora/aurora-port.v \
               ${TOP}/serdes/aurora/sofeof-axi.v \
               ${TOP}/serdes/aurora/k7-aurora-boot.v \
               \
               ${TOP}/icap/xilinx/pe-icap.v \
               \
               ${TOP}/core/router.v \
               ${TOP}/core/link-act.v \
              ] 

set COREs [ list \
                clk_200_50_100 \
                fifo_64x512_afull \
                fwft_64x512_afull \
                fifo_66x512_async_dprogfull \
                fifo_64x512_32_async_afull \
                netfpga_fmc_dp0_6g_frame \
                netfpga_fmc_dp1_slave \
                PCIeGen2x4If64 \
               ]

set XDCs [ list \
               ${TOP}/boards/netfpga/riffa.xdc \
               ${TOP}/boards/netfpga/netfpga.xdc \
              ]
