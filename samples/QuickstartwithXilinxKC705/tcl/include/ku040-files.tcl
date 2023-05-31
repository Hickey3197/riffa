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
#    be included in KU040 project setup scripts (SFP1+SMA1)
# ----------------------------------------------------------------------

set RTLs [ list \
               ${TOP}/boards/ku040/top.v \
               ${TOP}/boards/ku040/ku040-clk.v \
               \
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
                clk_250_100 \
                fifo_64x512_32_async_afull \
                fifo_66x512_async_dprogfull \
                fwft_64x512_afull \
                ku040_sfp1 \
                ku040_sma1_slave \
                ku040_sfp2_slave \
               ]

set XDCs [ list \
               ${TOP}/boards/ku040/ku040.xdc \
              ]
