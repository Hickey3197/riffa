// ----------------------------------------------------------------------
// "THE BEER-WARE LICENSE" (Revision 42):
//    <yasu@prosou.nu> wrote this file. As long as you retain this
//    notice you can do whatever you want with this stuff. If we meet
//    some day, and you think this stuff is worth it, you can buy me a
//    beer in return Yasunori Osana at University of the Ryukyus,
//    Japan.
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

  static const int vec_len = 1000;
  
  double* out_1 = (double*)buf_alloc(vec_len*8);
  double* out_2 = (double*)buf_alloc(vec_len*8);
  double* in    = (double*)buf_alloc(vec_len*8);

  // Header
  uint64_t header_1[HEADER_MAX], header_2[HEADER_MAX];

  header_1[0] = ROUTING_HEADER | 1;  // SPE
  header_1[1] = ROUTING_HEADER | 6;  // PCIe 
  header_1[2] = vec_len; 
  buf_set_header((uint64_t*)out_1, header_1, 3);

  header_2[0] = ROUTING_HEADER | 2;  // SPE
  header_2[1] = vec_len; 
  buf_set_header((uint64_t*)out_2, header_2, 2);
  
  // Payload 
  for(int i=0; i<vec_len; i++){
    out_1[i] = (double)i;
    out_2[i] = ((double)i)*0.0001;
  }

  buf_send_async(handles.fd_o1, (double*)out_1, vec_len*8);
  buf_send_async(handles.fd_o2, (double*)out_2, vec_len*8);
  buf_recv(handles.fd_i, (double*)in, vec_len*8);

  for(int i=0; i<vec_len; i++){
    printf("[%d] %lf\n", i, in[i]);
  }
  
  buf_free(out_1);
  buf_free(out_2);
  buf_free(in);
  
  cleanup_bus(&handles);
  
  return 0;
}
