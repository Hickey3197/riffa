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
//    fpga-tools.c: Common host C API interface, DMA engine independent
// ----------------------------------------------------------------------

#include <stdlib.h> // malloc
#include <stdint.h> // uint64_t
#include <pthread.h>
#include <sys/types.h>
#include <unistd.h>
#include <fcntl.h>

#define _FPGA_TOOLS_C_
#include "fpga-tools.h"

// ------------------------------
// setup / cleanup wrapper

void setup_bus(channel_handles_t *h){
  for (int ch=0; ch<NUM_WR_THR+NUM_RD_THR; ch++) wr_thr_args[ch].fd = -2;
  open_channels(h);
  launch_rw_thread();
}

void cleanup_bus(channel_handles_t *h){
  terminate_rw_thread();
  close_channels(h);
}

// ------------------------------
// buffer allocation and free

void* buf_alloc(size_t p_size){
  size_t bufsize = HEADER_MAX*8 + p_size;
  
  void *buf;
  posix_memalign((void**)&buf, 4096, bufsize*8);
  if (buf==NULL) return NULL;

  // initial header length = 0
  uint64_t *b = (uint64_t*)buf;
  b[0] = 0;

  return buf+(HEADER_MAX*8);
}

void buf_free(void* p){
  free(p-8*HEADER_MAX);
}

// ------------------------------
// Buffer & Header manipulation

void buf_set_header_default(void* b, uint64_t *header, size_t len){
  uint64_t* buf = (uint64_t*) b;

  // may be called multiple times: save length at buf[-HEADER_MAX]
  size_t init_len = buf[-HEADER_MAX];
  len += init_len;
  
  for (size_t i=0; i<len-init_len; i++)
    buf[-len+i] = header[i];
  
  buf[-HEADER_MAX] = len;
}

void buf_clear_header_default(void* b){
  uint64_t* buf = (uint64_t*) b;
  buf[-HEADER_MAX] = 0;
}

void buf_send_default(int fd, void* b, size_t len){
  uint64_t* buf = (uint64_t*) b;
  size_t header_len = buf[-HEADER_MAX];
  write_all(fd, (char*)&buf[-header_len], header_len*8 + len);
}

void buf_recv_default(int fd, void* b, size_t len){
  uint64_t* buf = (uint64_t*) b;
  read_all (fd,  (char*)&buf[-1], 8+len);
}

// ------------------------------
// Threaded write stuff

void buf_send_async(int fd, void* b, size_t len){
  uint64_t* buf = (uint64_t*) b;

  for (int ch=0; ch<NUM_WR_THR; ch++){
    if (fd == wr_thr_args[ch].fd){
      pthread_mutex_lock  (&wr_thr_args[ch].mtx);
      wr_thr_args[ch].data = (char*)buf;
      wr_thr_args[ch].len  = len;
      pthread_mutex_unlock(&wr_thr_args[ch].mtx);
      pthread_cond_signal (&wr_thr_args[ch].cv);
    }
  }
}

void buf_recv_async(int fd, void* b, size_t len){
  uint64_t* buf = (uint64_t*) b;

  for (int ch=0; ch<NUM_RD_THR; ch++){
    if (fd == wr_thr_args[NUM_WR_THR+ch].fd){
      pthread_mutex_lock  (&wr_thr_args[NUM_WR_THR+ch].mtx);
      wr_thr_args[NUM_WR_THR+ch].data = (char*)buf;
      wr_thr_args[NUM_WR_THR+ch].len  = len;
      pthread_mutex_unlock(&wr_thr_args[NUM_WR_THR+ch].mtx);
      pthread_cond_signal (&wr_thr_args[NUM_WR_THR+ch].cv);
    }
  }
}

void wait_buf_send_async(int fd){
  for (int ch=0; ch<NUM_WR_THR; ch++){
    if (fd == wr_thr_args[ch].fd){
      pthread_mutex_lock  (&wr_thr_args[ch].mtx_rw);
      pthread_mutex_unlock(&wr_thr_args[ch].mtx_rw);
    }
  }
}

void wait_buf_recv_async(int fd){
  for (int ch=0; ch<NUM_RD_THR; ch++){
    if (fd == wr_thr_args[NUM_WR_THR+ch].fd){
      pthread_mutex_lock  (&wr_thr_args[NUM_WR_THR+ch].mtx_rw);
      pthread_mutex_unlock(&wr_thr_args[NUM_WR_THR+ch].mtx_rw);
    }
  }
}

void* rw_thread(void* arg){
  rw_thread_params_t *p = (rw_thread_params_t*) arg;
  while(1==1){
    pthread_cond_wait(&(p->cv), &(p->mtx));
    // Mutex is locked on pthread_cont_wait() exit
    if(p->fd == -1) return NULL;
    else{
      uint64_t *buf = (uint64_t*)p->data;
      pthread_mutex_lock(&(p->mtx_rw));
      if (p->reader) buf_recv(p->fd, buf, p->len);
      else           buf_send(p->fd, buf, p->len);
      pthread_mutex_unlock(&(p->mtx_rw));
    }
  }
  return NULL;
}

void launch_rw_thread(){
  for (int t=0; t<NUM_WR_THR+NUM_RD_THR; t++){
    pthread_cond_init (&(wr_thr_args[t].cv),  NULL);
    pthread_mutex_init(&(wr_thr_args[t].mtx), NULL);
    pthread_mutex_init(&(wr_thr_args[t].mtx_rw), NULL);

    // mutex will unlocked by pthread_cond_wait()
    pthread_mutex_lock(&(wr_thr_args[t].mtx));

    wr_thr_args[t].reader = (t>=NUM_WR_THR);

    pthread_create(&(wr_thr_args[t].thr), NULL, rw_thread,
                   (void*)&wr_thr_args[t]);
  }

  // Lock & unlock mutexes to make sure pthread_cond_wait() is running
  for (int t=0; t<NUM_WR_THR+NUM_RD_THR; t++){
    pthread_mutex_lock  (&(wr_thr_args[t].mtx));
    pthread_mutex_unlock(&(wr_thr_args[t].mtx));
  }
}

void terminate_rw_thread(){
  for (int t=0; t<NUM_WR_THR+NUM_RD_THR; t++){
    wr_thr_args[t].fd = -1;
    pthread_cond_signal(&wr_thr_args[t].cv);
    pthread_join       (wr_thr_args[t].thr, NULL);
    pthread_detach     (wr_thr_args[t].thr);
  }
}
