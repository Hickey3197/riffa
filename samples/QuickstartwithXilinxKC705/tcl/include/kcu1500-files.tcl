# ----------------------------------------------------------------------
# "THE BEER-WARE LICENSE" (Revision 42):
#    <yasu@prosou.nu> wrote this file. As long as you retain this
#    notice you can do whatever you want with this stuff. If we meet
#    some day, and you think this stuff is worth it, you can buy me a
#    beer in return Yasunori Osana at University of the Ryukyus,
#    Japan.
# ----------------------------------------------------------------------
# OpenFC project: an open FPGA accelerated cluster tooklit
#
# This file is to:
#    be included in KCU1500 project setup scripts
# ----------------------------------------------------------------------

set RTLs [ list \
               ${TOP}/boards/kcu1500/top.v \
               ${TOP}/boards/kcu1500/kcu1500-clk.v \
               \
               ${TOP}/serdes/aurora/aurora-quad-uscale.v \
               ${TOP}/serdes/aurora/aurora-port-axi.v \
               ${TOP}/serdes/aurora/aurora-port.v \
               ${TOP}/serdes/aurora/sofeof-axi.v \
               ${TOP}/serdes/aurora/ku-aurora-boot.v \
               \
               ${TOP}/icap/xilinx/pe-icap.v \
               ${TOP}/icap/xilinx/icap-wrapper.v \
               \
               ${TOP}/core/port2axis.v \
               ${TOP}/pcie/xdma/xdma-port-ku.v \
               ${TOP}/pcie/xdma/header-adj.v \
               \
               ${TOP}/core/router.v \
               ${TOP}/core/link-act.v \
              ] 

set COREs [ list \
                aurora_w_qpll \
                aurora_wo_qpll \
                axis_8to32 \
                axis_32to8 \
                clk_300_100 \
                fifo_64x512_32_async_afull \
                fifo_66x512_async_dprogfull \
                fwft_64x512_afull \
                xdma_st \
               ]

set XDCs [ list \
               ${TOP}/boards/kcu1500/kcu1500.xdc \
              ]
