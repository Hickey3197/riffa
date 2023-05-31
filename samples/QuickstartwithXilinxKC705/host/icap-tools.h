// ----------------------------------------------------------------------
// "THE BEER-WARE LICENSE" (Revision 42):
//    <yasu@prosou.nu> wrote this file. As long as you retain this
//    notice you can do whatever you want with this stuff. If we meet
//    some day, and you think this stuff is worth it, you can buy me a
//    beer in return Yasunori Osana at University of the Ryukyus,
//    Japan.
// ----------------------------------------------------------------------
// OpenFC project: an open FPGA accelerated cluster framework
// 
//    icap-tools.h: Xilinx ICAP PE C API interface
// ----------------------------------------------------------------------

#include <stdbool.h>

#include "fpga-tools.h"
#include "routing.h"

#ifndef _ICAP_TOOLS_H_
#define _ICAP_TOOLS_H_

// ICAP
void* setup_icap_buf(char *config_file, int bs, size_t *tx_len);
bool write_icap(char *config_file, int bs, uint64_t* header, size_t header_len,
                channel_handles_t* handles);

#endif
