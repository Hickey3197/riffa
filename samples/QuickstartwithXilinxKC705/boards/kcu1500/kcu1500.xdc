## Board clock

set_property PACKAGE_PIN BA34     [get_ports SYSCLK0_300_P]
set_property PACKAGE_PIN BB34     [get_ports SYSCLK0_300_N]
set_property IOSTANDARD  DIFF_SSTL12 [get_ports {SYSCLK0_300_P SYSCLK0_300_N}]

## PCIe clock
set_property PACKAGE_PIN AT11     [get_ports PCIE_REFCLK_P]; # 225 ref0
set_property PACKAGE_PIN AT10     [get_ports PCIE_REFCLK_N]

create_clock -period 10.000 -name pcie_refclk \
             [get_pins -hierarchical -filter {NAME =~ *pcie_ckbuf0/O}]

# set_property PACKAGE_PIN AM11     [get_ports PCIE_REFCLKP[1]]; # 226 ref0
# set_property PACKAGE_PIN AM10     [get_ports PCIE_REFCLKN[1]]

set_property PACKAGE_PIN AR26     [get_ports PCIE_RESET_N]
set_property IOSTANDARD  LVCMOS18 [get_ports PCIE_RESET_N]

## QSFP0 signals

set_property PACKAGE_PIN AV38     [get_ports QSFP0_REFCLKP]
set_property PACKAGE_PIN AV39     [get_ports QSFP0_REFCLKN]

set_property PACKAGE_PIN AP38     [get_ports QSFP0_TXP[3]]
set_property PACKAGE_PIN AP43     [get_ports QSFP0_RXP[3]]
set_property PACKAGE_PIN AP44     [get_ports QSFP0_RXN[3]]
set_property PACKAGE_PIN AP39     [get_ports QSFP0_TXN[3]]

set_property PACKAGE_PIN AR40     [get_ports QSFP0_TXP[2]]
set_property PACKAGE_PIN AR45     [get_ports QSFP0_RXP[2]]
set_property PACKAGE_PIN AR46     [get_ports QSFP0_RXN[2]]
set_property PACKAGE_PIN AR41     [get_ports QSFP0_TXN[2]]

set_property PACKAGE_PIN AT38     [get_ports QSFP0_TXP[1]]
set_property PACKAGE_PIN AT43     [get_ports QSFP0_RXP[1]]
set_property PACKAGE_PIN AT44     [get_ports QSFP0_RXN[1]]
set_property PACKAGE_PIN AT39     [get_ports QSFP0_TXN[1]]

set_property PACKAGE_PIN AU40     [get_ports QSFP0_TXP[0]]
set_property PACKAGE_PIN AU45     [get_ports QSFP0_RXP[0]]
set_property PACKAGE_PIN AU46     [get_ports QSFP0_RXN[0]]
set_property PACKAGE_PIN AU41     [get_ports QSFP0_TXN[0]]

set_property PACKAGE_PIN AR36     [get_ports QSFP1_REFCLKP]
set_property PACKAGE_PIN AR37     [get_ports QSFP1_REFCLKN]

set_property PACKAGE_PIN AK38     [get_ports QSFP1_TXP[3]]
set_property PACKAGE_PIN AK43     [get_ports QSFP1_RXP[3]]
set_property PACKAGE_PIN AK44     [get_ports QSFP1_RXN[3]]
set_property PACKAGE_PIN AK39     [get_ports QSFP1_TXN[3]]

set_property PACKAGE_PIN AL40     [get_ports QSFP1_TXP[2]]
set_property PACKAGE_PIN AL45     [get_ports QSFP1_RXP[2]]
set_property PACKAGE_PIN AL46     [get_ports QSFP1_RXN[2]]
set_property PACKAGE_PIN AL41     [get_ports QSFP1_TXN[2]]

set_property PACKAGE_PIN AM38     [get_ports QSFP1_TXP[1]]
set_property PACKAGE_PIN AM43     [get_ports QSFP1_RXP[1]]
set_property PACKAGE_PIN AM44     [get_ports QSFP1_RXN[1]]
set_property PACKAGE_PIN AM39     [get_ports QSFP1_TXN[1]]

set_property PACKAGE_PIN AN40     [get_ports QSFP1_TXP[0]]
set_property PACKAGE_PIN AN45     [get_ports QSFP1_RXP[0]]
set_property PACKAGE_PIN AN46     [get_ports QSFP1_RXN[0]]
set_property PACKAGE_PIN AN41     [get_ports QSFP1_TXN[0]]

## LEDs
set_property PACKAGE_PIN AW25     [get_ports LED[0]]
set_property PACKAGE_PIN AY25     [get_ports LED[1]]
set_property PACKAGE_PIN BA27     [get_ports LED[2]]
set_property PACKAGE_PIN BA28     [get_ports LED[3]]
set_property PACKAGE_PIN BB26     [get_ports LED[4]]
set_property PACKAGE_PIN BB27     [get_ports LED[5]]
set_property PACKAGE_PIN BA25     [get_ports LED[6]]
set_property PACKAGE_PIN BB25     [get_ports LED[7]]
set_property IOSTANDARD  LVCMOS18 [get_ports {LED[*]}]

## ICAP false path
set_false_path -from [get_clocks -of_objects [get_pins icap/fifo/wr_clk]] \
               -to   [get_clocks -of_objects [get_pins icap/fifo/rd_clk]]

set_false_path -from [get_clocks -of_objects [get_pins icap/fifo/rd_clk]] \
               -to   [get_clocks -of_objects [get_pins icap/fifo/wr_clk]]




