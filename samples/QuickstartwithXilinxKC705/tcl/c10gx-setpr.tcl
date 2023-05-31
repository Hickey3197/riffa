# Get ready for PR with C10GX base project

source [file join [file dirname [info script]] "config.tcl"]

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
set_instance_assignment -name EMPTY_PLACE_REGION "X0 Y59 X102 Y59-R:C-empty_region" -to |
set_global_assignment -name REVISION_TYPE PR_BASE
set_global_assignment -name GENERATE_PR_RBF_FILE ON
set_global_assignment -name ON_CHIP_BITSTREAM_DECOMPRESSION OFF

# Place PR partition
set_instance_assignment -name PARTITION pr_partition -to pe -entity top
set_instance_assignment -name PARTITION_COLOUR 4294934601 -to pe -entity top
set_instance_assignment -name PARTIAL_RECONFIGURATION_PARTITION ON -to pe -entity top
set_instance_assignment -name EXPORT_PARTITION_SNAPSHOT_FINAL c10gx_static.qdb -to | -entity top
#set_instance_assignment -name PLACE_REGION "X41 Y1 X68 Y33" -to pe
#set_instance_assignment -name ROUTE_REGION "X40 Y0 X69 Y34" -to pe
set_instance_assignment -name PLACE_REGION "X41 Y2 X44 Y59;X45 Y2 X102 Y115;X1 Y60 X44 Y115" -to pe
set_instance_assignment -name ROUTE_REGION "X40 Y1 X45 Y58;X46 Y1 X102 Y115;X0 Y59 X45 Y115" -to pe
set_instance_assignment -name RESERVE_PLACE_REGION ON -to pe
set_instance_assignment -name CORE_ONLY_PLACE_REGION ON -to pe
set_instance_assignment -name REGION_NAME pe -to pe
set_instance_assignment -name PARTITION_COLOUR 4294954910 -to top -entity top
set_instance_assignment -name RESERVE_ROUTE_REGION OFF -to pe

