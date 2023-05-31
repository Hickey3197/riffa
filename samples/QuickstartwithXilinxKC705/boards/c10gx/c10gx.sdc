create_clock -name PCIE_REFCLK -period 10.000 [get_ports {PCIE_REFCLK}]
create_clock -name CLK100 -period 10.000 [get_ports {CLK100}]

derive_pll_clocks -create_base_clocks

