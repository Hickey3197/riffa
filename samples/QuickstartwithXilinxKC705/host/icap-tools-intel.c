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
//    icap-tools-intel.c: Intel PR PE C API interface
// ----------------------------------------------------------------------

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h> // uint64_t
#include <unistd.h>
#include <fcntl.h>
#include <pthread.h>

#include "routing.h"
#include "fpga-tools.h"


bool write_icap(char *config_file, int bs, uint64_t* header, size_t header_len,
                channel_handles_t* handles){

  int rbf_fd = open(config_file, O_RDONLY);
  if (rbf_fd<0){
    printf("Can't open %s\n", config_file);
    return false;
  }
  
  // Check RBF file size
  size_t rbf_size = lseek(rbf_fd, 0, SEEK_END);
  lseek(rbf_fd, 0, SEEK_SET);
  // printf("RBF size: %lu \n", rbf_size);
  
  // Allocate buffer
  uint64_t* pr_stat = (uint64_t*)buf_alloc(8);
  
  size_t rbf_buf_size = rbf_size + 4;
  if (rbf_buf_size % 8 != 0) rbf_buf_size += (8 - rbf_buf_size % 8);
  // printf("RBF buf size: %lu \n", rbf_buf_size);
  
  char* config_rbf = (char*)buf_alloc(rbf_buf_size);
  if (config_rbf==NULL){
    printf("malloc() failed\n");
    return false;
  }

  int* buf_int = (int*)config_rbf;
  buf_int[0] = (int)rbf_size;

  // Load RBF
  ssize_t got = 0;
  char* read_ptr = config_rbf + 4;
  while (got < rbf_size){
    ssize_t got_tmp;
    got_tmp = read(rbf_fd, read_ptr, rbf_size - got);
    if (got_tmp < -1){
      printf("read error\n");
      return false;
    }
    got += got_tmp;
    read_ptr += got_tmp;
  }
  // printf("Successfully loaded RBF.\n");

  // DW (32bit) swap, including 32bit header
  for (int dw=0; dw<rbf_buf_size/4; dw+=2){
    int a;
    a = buf_int[dw];
    buf_int[dw] = buf_int[dw+1];
    buf_int[dw+1] = a;
  }

  header[header_len] = rbf_buf_size/8;
  buf_set_header((uint64_t*)config_rbf, header, 3);
    
  buf_send_async(handles->fd_o1, (uint64_t*)config_rbf, rbf_buf_size);
  buf_recv(handles->fd_i,  (uint64_t*)pr_stat, 8);
  // printf("done, status = %d\n", (int)pr_stat[0]);
  buf_free(config_rbf);
  buf_free(pr_stat);

  return ((int)pr_stat[0]==1);
}


#ifdef USE_ICAP_TOOLS_EXAMPLE

int main(int argc, char *argv[]){
  if (argc !=2 ){
    printf("usage: c10-pr hogehoge.rbf\n");
    return -1;
  }

  // Setup RIFFA
  channel_handles_t handles;

  setup_bus(&handles);
  printf("FDs: o1 %d, o2 %d, i %d\n",
         handles.fd_o1, handles.fd_o2, handles.fd_i);

  // Setup header
  uint64_t header[HEADER_MAX];
  header[0] = ROUTING_HEADER | 3;  // ICAP
  header[1] = ROUTING_HEADER | 4;  // PCIe

  bool done = write_icap(argv[1], ICAP_BYTE_ORDER_C10, header, 2, &handles);
  if (done) printf("PR OK!\n");
  
  return 0;
}

#endif
