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
//    simple-loopback.c: pe-pass host program example
// ----------------------------------------------------------------------

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h> // uint64_t
#include <unistd.h>
#include <fcntl.h>
#include <pthread.h>

#include "routing.h"
#include "fpga-tools.h"

int main(){
  channel_handles_t handles;

  setup_bus(&handles);
  printf("FDs: o1 %d, o2 %d, i %d\n",
         handles.fd_o1, handles.fd_o2, handles.fd_i);

  static const int vec_len = 20000;
//  static const int vec_len = 10;
  
  uint64_t* out = (uint64_t*)buf_alloc(vec_len*8);
  uint64_t* in  = (uint64_t*)buf_alloc(vec_len*8);

  // Header
  uint64_t header[HEADER_MAX];

  // PCIe loopback
  printf("PCIe loopback\n");
  header[0] = ROUTING_HEADER | 6;  // PCIe: 4 for Cyclone 10, 6 for Kintex-7
  header[1] = vec_len; 
  buf_set_header((uint64_t*)out, header, 2);

  // Payload 
  for(int i=0; i<vec_len; i++){
    out[i] = i;
  }

  buf_send_async(handles.fd_o1, (uint64_t*)out, vec_len*8);
  buf_recv_async(handles.fd_i, (uint64_t*)in, vec_len*8);
  usleep(100);
  wait_buf_recv_async(handles.fd_i);
  
  for(int i=0; i<vec_len; i++){
    if (in[i]!=out[i]) printf("%lu, %lu\n", out[i], in[i]);
  }

  printf("done\n");

  buf_free(out);
  buf_free(in);
  
  cleanup_bus(&handles);
  
  return 0;
}
