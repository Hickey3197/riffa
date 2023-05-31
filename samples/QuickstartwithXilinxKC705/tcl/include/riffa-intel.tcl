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
#    setup RIFFA based project with Intel FPGAs
# ----------------------------------------------------------------------

set RTLs \
    [ concat $RTLs \
          [ list \
                ${TOP}/pcie/riffa/src-riffa/txr_engine_ultrascale.v \
                ${TOP}/pcie/riffa/src-riffa/txr_engine_classic.v \
                ${TOP}/pcie/riffa/src-riffa/txc_engine_ultrascale.v \
                ${TOP}/pcie/riffa/src-riffa/txc_engine_classic.v \
                ${TOP}/pcie/riffa/src-riffa/tx_port_writer.v \
                ${TOP}/pcie/riffa/src-riffa/tx_port_monitor_64.v \
                ${TOP}/pcie/riffa/src-riffa/tx_port_monitor_32.v \
                ${TOP}/pcie/riffa/src-riffa/tx_port_monitor_128.v \
                ${TOP}/pcie/riffa/src-riffa/tx_port_channel_gate_64.v \
                ${TOP}/pcie/riffa/src-riffa/tx_port_channel_gate_32.v \
                ${TOP}/pcie/riffa/src-riffa/tx_port_channel_gate_128.v \
                ${TOP}/pcie/riffa/src-riffa/tx_port_buffer_64.v \
                ${TOP}/pcie/riffa/src-riffa/tx_port_buffer_32.v \
                ${TOP}/pcie/riffa/src-riffa/tx_port_buffer_128.v \
                ${TOP}/pcie/riffa/src-riffa/tx_port_64.v \
                ${TOP}/pcie/riffa/src-riffa/tx_port_32.v \
                ${TOP}/pcie/riffa/src-riffa/tx_port_128.v \
                ${TOP}/pcie/riffa/src-riffa/tx_multiplexer_64.v \
                ${TOP}/pcie/riffa/src-riffa/tx_multiplexer_32.v \
                ${TOP}/pcie/riffa/src-riffa/tx_multiplexer_128.v \
                ${TOP}/pcie/riffa/src-riffa/tx_multiplexer.v \
                ${TOP}/pcie/riffa/src-riffa/tx_hdr_fifo.v \
                ${TOP}/pcie/riffa/src-riffa/tx_engine_ultrascale.v \
                ${TOP}/pcie/riffa/src-riffa/tx_engine_selector.v \
                ${TOP}/pcie/riffa/src-riffa/tx_engine_classic.v \
                ${TOP}/pcie/riffa/src-riffa/tx_engine.v \
                ${TOP}/pcie/riffa/src-riffa/tx_data_shift.v \
                ${TOP}/pcie/riffa/src-riffa/tx_data_pipeline.v \
                ${TOP}/pcie/riffa/src-riffa/tx_data_fifo.v \
                ${TOP}/pcie/riffa/src-riffa/tx_alignment_pipeline.v \
                ${TOP}/pcie/riffa/src-riffa/translation_xilinx.v \
                ${TOP}/pcie/riffa/src-riffa/translation_altera.v \
                ${TOP}/pcie/riffa/src-riffa/syncff.v \
                ${TOP}/pcie/riffa/src-riffa/sync_fifo.v \
                ${TOP}/pcie/riffa/src-riffa/shiftreg.v \
                ${TOP}/pcie/riffa/src-riffa/sg_list_requester.v \
                ${TOP}/pcie/riffa/src-riffa/sg_list_reader_64.v \
                ${TOP}/pcie/riffa/src-riffa/sg_list_reader_32.v \
                ${TOP}/pcie/riffa/src-riffa/sg_list_reader_128.v \
                ${TOP}/pcie/riffa/src-riffa/scsdpram.v \
                ${TOP}/pcie/riffa/src-riffa/rxr_engine_ultrascale.v \
                ${TOP}/pcie/riffa/src-riffa/rxr_engine_classic.v \
                ${TOP}/pcie/riffa/src-riffa/rxr_engine_128.v \
                ${TOP}/pcie/riffa/src-riffa/rxc_engine_ultrascale.v \
                ${TOP}/pcie/riffa/src-riffa/rxc_engine_classic.v \
                ${TOP}/pcie/riffa/src-riffa/rxc_engine_128.v \
                ${TOP}/pcie/riffa/src-riffa/rx_port_requester_mux.v \
                ${TOP}/pcie/riffa/src-riffa/rx_port_reader.v \
                ${TOP}/pcie/riffa/src-riffa/rx_port_channel_gate.v \
                ${TOP}/pcie/riffa/src-riffa/rx_port_64.v \
                ${TOP}/pcie/riffa/src-riffa/rx_port_32.v \
                ${TOP}/pcie/riffa/src-riffa/rx_port_128.v \
                ${TOP}/pcie/riffa/src-riffa/rx_engine_ultrascale.v \
                ${TOP}/pcie/riffa/src-riffa/rx_engine_classic.v \
                ${TOP}/pcie/riffa/src-riffa/rotate.v \
                ${TOP}/pcie/riffa/src-riffa/riffa.v \
                ${TOP}/pcie/riffa/src-riffa/reset_extender.v \
                ${TOP}/pcie/riffa/src-riffa/reset_controller.v \
                ${TOP}/pcie/riffa/src-riffa/reorder_queue_output.v \
                ${TOP}/pcie/riffa/src-riffa/reorder_queue_input.v \
                ${TOP}/pcie/riffa/src-riffa/reorder_queue.v \
                ${TOP}/pcie/riffa/src-riffa/registers.v \
                ${TOP}/pcie/riffa/src-riffa/register.v \
                ${TOP}/pcie/riffa/src-riffa/recv_credit_flow_ctrl.v \
                ${TOP}/pcie/riffa/src-riffa/ram_2clk_1w_1r.v \
                ${TOP}/pcie/riffa/src-riffa/ram_1clk_1w_1r.v \
                ${TOP}/pcie/riffa/src-riffa/pipeline.v \
                ${TOP}/pcie/riffa/src-riffa/one_hot_mux.v \
                ${TOP}/pcie/riffa/src-riffa/offset_to_mask.v \
                ${TOP}/pcie/riffa/src-riffa/offset_flag_to_one_hot.v \
                ${TOP}/pcie/riffa/src-riffa/mux.v \
                ${TOP}/pcie/riffa/src-riffa/interrupt_controller.v \
                ${TOP}/pcie/riffa/src-riffa/interrupt.v \
                ${TOP}/pcie/riffa/src-riffa/fifo_packer_64.v \
                ${TOP}/pcie/riffa/src-riffa/fifo_packer_32.v \
                ${TOP}/pcie/riffa/src-riffa/fifo_packer_128.v \
                ${TOP}/pcie/riffa/src-riffa/fifo.v \
                ${TOP}/pcie/riffa/src-riffa/ff.v \
                ${TOP}/pcie/riffa/src-riffa/engine_layer.v \
                ${TOP}/pcie/riffa/src-riffa/demux.v \
                ${TOP}/pcie/riffa/src-riffa/cross_domain_signal.v \
                ${TOP}/pcie/riffa/src-riffa/counter.v \
                ${TOP}/pcie/riffa/src-riffa/chnl_tester.v \
                ${TOP}/pcie/riffa/src-riffa/channel_64.v \
                ${TOP}/pcie/riffa/src-riffa/channel_32.v \
                ${TOP}/pcie/riffa/src-riffa/channel_128.v \
                ${TOP}/pcie/riffa/src-riffa/channel.v \
                ${TOP}/pcie/riffa/src-riffa/async_fifo_fwft.v \
                ${TOP}/pcie/riffa/src-riffa/async_fifo.v \
               ] ]

set RTLs [ concat $RTLs \
               [ list \
                     ${TOP}/pcie/riffa/xillybus-compat.v \
                    ] ]
