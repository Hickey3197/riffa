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
//    fpga-tools-riffa.c: Common host C API interface with Xillybus PCIe
// ----------------------------------------------------------------------

#include <stdio.h>   // printf
#include <stdint.h> // uint64_t
#include <pthread.h>
#include <errno.h> // errno
#include <unistd.h> // open, close
#include <fcntl.h>  // O_{RD,WR}ONLY
#include "fpga-tools.h"

void open_channels(channel_handles_t *h){
  h->fd_o1 = open("/dev/xillybus_write_64",  O_WRONLY);
  h->fd_o2 = open("/dev/xillybus_write2_64", O_WRONLY);
  h->fd_i  = open("/dev/xillybus_read_64",   O_RDONLY);

  wr_thr_args[0].fd = h->fd_o1;
  wr_thr_args[1].fd = h->fd_o2;
}

void close_channels(channel_handles_t *h){
  close(h->fd_o1);
  close(h->fd_o2);
  close(h->fd_i );
}

void write_flush(int fd){
  while (1) {
    int rc = write(fd, NULL, 0);
    if ((rc < 0) && (errno == EINTR))
      continue; // Interrupted. Try again.
    if (rc < 0) {
      perror("flushing failed");
      break;
    }
    break; // Flush successful
  }
}

int read_all(int fd, char* buf, int len){
  //  printf("read_all(): reading %d bytes from %d \n", len, fd);
  int got = 0;
  do {
    got += read(fd, &buf[got], len-got);
  } while(got < len);

  return got;
}

int write_all(int fd, char* buf, int len){
  //  printf("write_all(): writing %d bytes\n", len);
  int wrote = 0;
  do {
    wrote += write(fd, &buf[wrote], len-wrote);
  } while(wrote < len);
#ifndef NO_WRITE_FLUSH
  write_flush(fd);
#endif
  //  printf("write_all(): done\n");
  return wrote;
}
