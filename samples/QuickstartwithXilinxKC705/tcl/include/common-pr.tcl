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
#    be included by Vivado PR scripts
# ----------------------------------------------------------------------

proc synth { {GENERIC ""} } {
    global DEV DIR MODULE SRCs
    create_project -in_memory -part $DEV

    foreach i $SRCs { add_files $i }

    if {$GENERIC eq ""} {
        synth_design -mode out_of_context -flatten_hierarchy rebuilt -top pe -part $DEV 
    } else {
        synth_design -mode out_of_context -flatten_hierarchy rebuilt -top pe -part $DEV -generic $GENERIC
    }
    write_checkpoint  -force $DIR/syn/${MODULE}-synth.dcp
    report_utilization -file $DIR/syn/${MODULE}-synth.rpt
    close_project
}

proc do_drc {} {
    global DIR
    create_drc_ruledeck ruledeck_1
    add_drc_checks -ruledeck ruledeck_1 [get_drc_checks {HDPR-52 HDPR-51 HDPR-50 HDPR-49 HDPR-48 HDPR-47 HDPR-46 HDPR-45 HDPR-44 HDPR-42 HDPR-38 HDPR-37 HDPR-36 HDPR-35 HDPR-34 HDPR-32 HDPR-31 HDPR-29 HDPR-28 HDPR-27 HDPR-26 HDPR-25 HDPR-23 HDPR-22 HDPR-19 HDPR-18 HDPR-17 HDPR-16 HDPR-15 HDPR-14 HDPR-13 HDPR-12 HDPR-11 HDPR-10 HDPR-9 HDPR-8 HDPR-7 HDPR-6 HDPR-5 HDPR-4 HDPR-3 HDPR-2 HDPR-1}]
    report_drc -ruledeck {ruledeck_1} -file $DIR/drc.report
    delete_drc_ruledeck ruledeck_1
}


proc impl_pr {} {
    global DIR MODULE

    open_checkpoint $DIR/dcp/static_route.dcp
    read_checkpoint -cell pe $DIR/syn/${MODULE}-synth.dcp
    opt_design
    place_design
    route_design
    write_checkpoint -force $DIR/impl/${MODULE}.dcp
    report_timing_summary -file $DIR/impl/${MODULE}.tsr

    pr_verify -initial $DIR/impl/pass.dcp -additional $DIR/impl/${MODULE}.dcp

    write_bitstream -force -bin_file $DIR/bit/${MODULE}.bit
    close_project
}
