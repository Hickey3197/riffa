// ----------------------------------------------------------------------
// "THE BEER-WARE LICENSE" (Revision 42):
//    <yasu@prosou.nu> wrote this file. As long as you retain this
//    notice you can do whatever you want with this stuff. If we meet
//    some day, and you think this stuff is worth it, you can buy me a
//    beer in return Yasunori Osana and Shuna Maehara at University of 
//    the Ryukyus, Japan.
// ----------------------------------------------------------------------
// OpenFC project: an open FPGA accelerated cluster toolkit
// 
//    fpga-tools-xdma.c: Common host C API interface with Xilinx XDMA
// ----------------------------------------------------------------------

#include <stdio.h>  // printf()
#include <stdint.h> // uint64_t
#include <unistd.h> // read(), open(), close()
#include <pthread.h>
#include <fcntl.h>
#include "fpga-tools.h"
#include "routing.h"

void open_channels(channel_handles_t *handles){
  handles->fd_o1 = open("/dev/xdma0_h2c_0", O_WRONLY);
  handles->fd_o2 = open("/dev/xdma0_h2c_1", O_WRONLY);
  handles->fd_i  = open("/dev/xdma0_c2h_0", O_RDONLY);

  wr_thr_args[0].fd = handles->fd_o1;
  wr_thr_args[1].fd = handles->fd_o2;
  wr_thr_args[NUM_WR_THR+0].fd = handles->fd_i;
}

void close_channels(channel_handles_t *h){
  close(h->fd_o1);
  close(h->fd_o2);
  close(h->fd_i);
}

int write_all(int fd, char* buf, int len){
  int wrote = 0;
  do {
    wrote += write(fd, &buf[wrote], len-wrote);
  } while(wrote < len);
  return wrote;
}

int read_all(int fd, char* buf, int len){
  int got = 0;
  do {
    got += read(fd, &buf[got], len-got);
  } while(got < len);
  return got;
}

// ----------------------------------------------------------------------
// "aligned" buffer manipulators

void buf_set_header(void* b, uint64_t *header, size_t len){
  buf_clear_header(b);

  uint64_t* buf = (uint64_t*)b;
  int pos = 0;
  while ((header[pos] & ROUTING_HEADER)!=0 && pos<HEADER_MAX-1){
    buf[-HEADER_MAX+pos] = header[pos];
    pos++;
  }

  // length header should be here
  buf[-1] = header[pos];
}

void buf_clear_header(void* b){
  uint64_t* buf = (uint64_t*)b;
  for (int i=-HEADER_MAX; i<0; i++)
    buf[i] = ROUTING_HEADER; // empty destination
}


void buf_send(int fd, void* b, size_t len){
  uint64_t* buf = (uint64_t*)b;
  write_all(fd, (char*)&buf[-HEADER_MAX], HEADER_MAX*8 + len);
}

void buf_recv(int fd, void* b, size_t len){
  uint64_t* buf = (uint64_t*)b;
  read_all(fd, (char*)&buf[-HEADER_MAX], HEADER_MAX*8 + len);
}

