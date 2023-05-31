create_clock -name PCIE_REFCLK -period 10.000 [get_ports {PCIE_REFCLK}]

derive_pll_clocks -create_base_clocks

