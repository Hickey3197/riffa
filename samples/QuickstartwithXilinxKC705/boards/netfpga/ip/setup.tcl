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
#    Setup IP location directory in ./iploc.
#    Run with: vivado -mode batch -source setup.tcl
#    Note: to generate .xcix, use import_files instead of add_files
#          (and some more hacks are required to generate everything
#          correctly because the .xci files are loaded in different
#          place with import_files)
# ----------------------------------------------------------------------

set COREDIR [ file dirname [ file normalize [ info script ] ] ] 
set PROJDIR ${COREDIR}/iploc
set DEV xc7k325tffg676-1

set COREs [ list \
                PCIeGen2x4If64 \
                clk_200_50_100 \
                fifo_64x512_32_async_afull \
                fifo_64x512_afull \
                fifo_66x512_async_dprogfull \
                fwft_64x512_afull \
                netfpga_fmc_dp0_6g_frame \
                netfpga_fmc_dp1_slave \
               ]

create_project managed_ip_project ${PROJDIR}/managed_ip_project -part ${DEV} -ip -force
set_property simulator_language Verilog [current_project]
set_property target_simulator IES [current_project]

foreach c $COREs {
    lappend CORESRCS ${c}.xci
    lappend PROJCOREs ${PROJDIR}/${c}/${c}.xci
    lappend SYNTH_RUNS ${c}_synth_1
}

add_files -norecurse -force -copy_to ${PROJDIR} ${CORESRCS}
generate_target all [get_files $PROJCOREs ]

foreach c $PROJCOREs {
    export_ip_user_files -of_objects [get_files $c] -no_script -sync -force -quiet
    create_ip_run -force [get_files -of_objects [get_fileset sources_1] $c]
}

launch_runs -jobs 4 $SYNTH_RUNS
set SIMLIB managed_ip_project/managed_ip_project.cache/compile_simlib

# Join all synthesis runs
foreach c $COREs {
    wait_on_run ${c}_synth_1
    export_simulation -of_objects [get_files ${PROJDIR}/${c}/${c}.xci] \
        -directory ${PROJDIR}/ip_user_files/sim_scripts \
        -ip_user_files_dir ${PROJDIR}/ip_user_files \
        -ipstatic_source_dir ${PROJDIR}/ip_user_files/ipstatic \
        -lib_map_path \
        [list \
             {modelsim=${PROJDIR}/${SIMLIB}/modelsim} \
             {questa=${PROJDIR}/${SIMLIB}/questa} \
             {ies=${PROJDIR}/${SIMLIB}/ies} \
             {xcelium=${PROJDIR}/${SIMLIB}/xcelium} \
             {vcs=${PROJDIR}/${SIMLIB}/vcs} \
             {riviera=${PROJDIR}/${SIMLIB}/riviera}] \
        -use_ip_compiled_libs -force -quiet
}
