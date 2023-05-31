# Get ready for PR with Hawkeye base project

source [file join [file dirname [info script]] "../config.tcl"]

# Replace pe-pass,v with pe-intadd.v
set vfiles [get_all_global_assignments -name VERILOG_FILE]
set pe_remove "\/pe-pass.v"

foreach_in_collection v $vfiles {
    set f [lindex $v 2] 
    if { [regexp $pe_remove $f] } {
        set_global_assignment -name VERILOG_FILE -remove $f
    }
}

set_global_assignment -name VERILOG_FILE ${TOP}/pe-base/pe-intadd.v

# Set base revision
set_global_assignment -name REVISION_TYPE PR_BASE
set_global_assignment -name GENERATE_PR_RBF_FILE ON
set_global_assignment -name ON_CHIP_BITSTREAM_DECOMPRESSION OFF

set_instance_assignment -name PARTITION pr_partition -to pe -entity top
set_instance_assignment -name PARTITION_COLOUR 4294921152 -to pe -entity top
set_instance_assignment -name PARTIAL_RECONFIGURATION_PARTITION ON -to pe -entity top
set_instance_assignment -name EXPORT_PARTITION_SNAPSHOT_FINAL hawkeye_static.qdb -to | -entity top

# set_instance_assignment -name PLACE_REGION "X21 Y58 X142 Y112" -to pe
# set_instance_assignment -name ROUTE_REGION "X20 Y57 X143 Y113" -to pe

set_instance_assignment -name PLACE_REGION "X1 Y58 X147 Y169" -to pe
set_instance_assignment -name ROUTE_REGION "X0 Y57 X148 Y170" -to pe

set_instance_assignment -name RESERVE_PLACE_REGION ON -to pe
set_instance_assignment -name CORE_ONLY_PLACE_REGION ON -to pe
set_instance_assignment -name REGION_NAME pr_partition -to pe
set_instance_assignment -name PARTITION_COLOUR 4284918783 -to top -entity top
set_instance_assignment -name PARTITION_COLOUR 4286753023 -to auto_fab_0 -entity top
set_instance_assignment -name RESERVE_ROUTE_REGION OFF -to pe
