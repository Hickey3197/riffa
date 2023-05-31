// ----------------------------------------------------------------------
// "THE BEER-WARE LICENSE" (Revision 42):
//    <yasu@prosou.nu> wrote this file. As long as you retain this
//    notice you can do whatever you want with this stuff. If we meet
//    some day, and you think this stuff is worth it, you can buy me a
//    beer in return Yasunori Osana and Shuna Maehara at University of 
//    the Ryukyus, Japan.
// ----------------------------------------------------------------------
// OpenFC project: an open FPGA accelerated cluster framework
// 
//    fpga-tools-riffa.c: Common host C API interface with RIFFA DMAC
// ----------------------------------------------------------------------

#include <stdio.h>  // printf()
#include <stdint.h> // uint64_t
#include <pthread.h>
#include "fpga-tools.h"
#include "riffa.h"

fpga_t* fpga;

void open_channels(channel_handles_t *handles){
  fpga = fpga_open(0);
  handles->fd_o1 = 0;
  handles->fd_o2 = 1;
  handles->fd_i  = 0;
  handles->fd_i2 = 1;

  wr_thr_args[0].fd = handles->fd_o1;
  wr_thr_args[1].fd = handles->fd_o2;
  wr_thr_args[NUM_WR_THR+0].fd = handles->fd_i;
  wr_thr_args[NUM_WR_THR+1].fd = handles->fd_i2;
}

void close_channels(channel_handles_t *h){
  fpga_close(fpga);
}

int read_all(int fd, char* buf, int len){
  int got = fpga_recv( fpga, fd, buf, len/4, 25000 );
  if (got!= len/4) printf("read_all: requested %d, got %d\n", len/4, got);
  return got;
}

int write_all(int fd, char* buf, int len){
  int wrote = fpga_send( fpga, fd, buf, len/4, 0, 1, 25000 );
  if (wrote != len/4)
    printf("write_all (ch %d): requested %d, wrote %d\n", fd, len/4, wrote);
  return wrote;
}

// ----------------------------------------------------------------------
// Use default buffer manipulators

void buf_set_header(void* b, uint64_t *header, size_t len){
  buf_set_header_default(b, header, len);
}

void buf_clear_header(void* b){
  buf_clear_header_default(b);
}

void buf_send(int fd, void* b, size_t len){
  buf_send_default(fd, b, len);
}

void buf_recv(int fd, void* b, size_t len){
  buf_recv_default(fd, b, len);
}

