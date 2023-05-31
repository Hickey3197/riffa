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
  
  uint64_t* out = (uint64_t*)buf_alloc(vec_len*8);
  uint64_t* in  = (uint64_t*)buf_alloc(8);

  // Header
  uint64_t header[HEADER_MAX];

  header[0] = ROUTING_HEADER | 1;  // SPE
  header[1] = ROUTING_HEADER | 6;  // PCIe 
  header[2] = vec_len; 
  buf_set_header((uint64_t*)out, header, 3);

  // Payload 
  for(int i=0; i<vec_len; i++){
    out[i] = i;
  }

  buf_send_async(handles.fd_o1, (uint64_t*)out, vec_len*8);
  buf_recv(handles.fd_i, (uint64_t*)in, 8);

  printf("done. length=%d, sum=%d\n", (int)in[-1], (int)in[0]);

  buf_free(out);
  buf_free(in);
  
  cleanup_bus(&handles);
  
  return 0;
}
