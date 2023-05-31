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
//    simple-intadd.c: pe-intadd host program example
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

  //  static const int vec_len = 20000;
  static const int vec_len = 4000;
  
  uint64_t* out_1 = (uint64_t*)buf_alloc(vec_len*8);
  uint64_t* out_2 = (uint64_t*)buf_alloc(vec_len*8);
  uint64_t* in    = (uint64_t*)buf_alloc(vec_len*8);

  // Header
  uint64_t header_1[HEADER_MAX], header_2[HEADER_MAX];

  // PCIe loopback
  header_1[0] = ROUTING_HEADER | 1;  // PE
  header_1[1] = ROUTING_HEADER | 6;  // PCIe: 4 for Cyclone 10, 6 for Kintex-7
  header_1[2] = vec_len; 
  buf_set_header((uint64_t*)out_1, header_1, 3);

  header_2[0] = ROUTING_HEADER | 2;  // PE D2
  header_2[1] = vec_len; 
  buf_set_header((uint64_t*)out_2, header_2, 2);


  // Payload 
  for(int i=0; i<vec_len; i++){
    out_1[i] = i;
    out_2[i] = i + 10000;
  }

  buf_send_async(handles.fd_o1, (uint64_t*)out_1, vec_len*8);
  buf_send_async(handles.fd_o2, (uint64_t*)out_2, vec_len*8);
  buf_recv(handles.fd_i, (uint64_t*)in, vec_len*8);

  for(int i=0; i<vec_len; i++){
    printf("%lu + %lu = %lu\n", out_1[i], out_2[i], in[i]);
  }

  buf_free(out_1);
  buf_free(out_2);
  buf_free(in);
  
  cleanup_bus(&handles);
  
  return 0;
}
