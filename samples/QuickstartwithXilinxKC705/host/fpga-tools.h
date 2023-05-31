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
//    fpga-tools.h: Common host C API interface
// ----------------------------------------------------------------------

#include <stdint.h>
#include <pthread.h>
#include <stdbool.h>

#ifndef _FPGA_TOOLS_H_
#define _FPGA_TOOLS_H_

#define NUM_WR_THR 4
#define NUM_RD_THR 4
#define HEADER_MAX 10

#define ICAP_BYTE_ORDER_K7  1  // 7 series
#define ICAP_BYTE_ORDER_KU  2  // Ultrascale
#define ICAP_BYTE_ORDER_C10 3  // Cyclone 10 GX

typedef struct {
  pthread_t thr;
  pthread_cond_t cv;
  pthread_mutex_t mtx;
  pthread_mutex_t mtx_rw;
  int fd;
  int reader; // true if reader thread
  char *data;
  size_t len;
} rw_thread_params_t;

typedef struct {
  int fd_o1, fd_o2;
  int fd_i,  fd_i2;
} channel_handles_t;
  
#ifdef RIFFA
  fpga_t* fpga;
#endif

#ifdef _FPGA_TOOLS_C_
rw_thread_params_t wr_thr_args[NUM_WR_THR+NUM_RD_THR];
#else
extern rw_thread_params_t wr_thr_args[NUM_WR_THR+NUM_RD_THR];
#endif

// ------------------------------
// Platform specfic stuff

void open_channels(channel_handles_t *h);
void close_channels(channel_handles_t *h);
int read_all(int fd, char* buf, int len);
int write_all(int fd, char* buf, int len);

// ------------------------------
// Platform independent stuff

// setup/cleanup
void setup_bus(channel_handles_t *h);
void cleanup_bus(channel_handles_t *h);

// buffer allocation and free
void* buf_alloc(size_t p_size);
void buf_free(void* p);

// Buffer & Header manipulation
void buf_set_header(void* b, uint64_t *header, size_t len);
void buf_clear_header(void* b);
void buf_send(int fd, void* b, size_t len);
void buf_recv(int fd, void* b, size_t len);

void buf_set_header_default(void* b, uint64_t *header, size_t len);
void buf_clear_header_default(void* b);
void buf_send_default(int fd, void* b, size_t len);
void buf_recv_default(int fd, void* b, size_t len);

// Threaded write stuff
void buf_send_async(int fd, void* b, size_t len);
void buf_recv_async(int fd, void* b, size_t len);

void wait_buf_send_async(int fd);
void wait_buf_recv_async(int fd);

void* rw_thread(void* arg);
void launch_rw_thread();
void terminate_rw_thread();

#endif
