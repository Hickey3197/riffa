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
#    be included in KCU1500 (w/RIFFA) project setup scripts
# ----------------------------------------------------------------------

set RTLs [ list \
               ${TOP}/boards/kcu1500/top-riffa.v \
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
               ${TOP}/core/router.v \
               ${TOP}/core/link-act.v \
              ] 

set COREs [ list \
                aurora_w_qpll \
                aurora_wo_qpll \
                clk_300_100 \
                fifo_64x512_32_async_afull \
                fifo_66x512_async_dprogfull \
                fwft_64x512_afull \
                PCIeGen3x4If128 \
                fifo_128x512_64_afull \
                fifo_64x1024_128_afull \
               ]

set XDCs [ list \
               ${TOP}/boards/kcu1500/kcu1500.xdc \
              ]
