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
//    icap-tools.c: Xilinx ICAP PE C API interface
// ----------------------------------------------------------------------

#include <unistd.h>
#include <fcntl.h>
#include <stdint.h>

#include "icap-tools.h"

// ------------------------------
// ICAP stuff

int read_binfile(int fd, char* buf, int len){
  //  printf("Read from fd %d, length %d\n", fd, len);
  int got = 0;
  do {
    int g = read(fd, &buf[got], len-got);
    if (g==0) break;
    got += g;
  } while(got < len);
  return got;
}

// Raw ICAP setup
void* setup_icap_buf(char *config_file, int bs, size_t *tx_len){
  int config_data = open(config_file, O_RDONLY);
  if (config_data < 0) return NULL;

  // check config file len
  size_t config_file_len = lseek(config_data, 0, SEEK_END);
  lseek(config_data, 0, SEEK_SET);

  // add space for ICAP PE header
  size_t config_data_len = config_file_len + 4;
  
  if(config_data_len%8 != 0){ // round up to nearest 8n
    size_t padding_len = 8-(config_data_len%8);
    config_data_len += padding_len;
    config_file_len += padding_len;
  }

  // determine payload length, then alloc
  char* buf = (char*)buf_alloc(config_data_len);

  // set ICAP PE header (32bit)
  unsigned int *buf_len = (unsigned int*)buf;
  *buf_len = (unsigned int)config_file_len;

  // load .bin file
  read_binfile(config_data, buf+4, config_file_len);
  close(config_data);

  // byte swap if needed
  if (bs==ICAP_BYTE_ORDER_K7){
    for(int i=4; i<config_data_len; i+=4){
      char t;
      t = buf[i  ]; buf[i  ]=buf[i+3]; buf[i+3]=t;
      t = buf[i+1]; buf[i+1]=buf[i+2]; buf[i+2]=t;
    }
  }

  *tx_len = config_data_len;
  return buf;
}

// cool wrapper function for setup_icap_buf()
bool write_icap(char *config_file, int bs, uint64_t* header, size_t header_len,
                channel_handles_t* handles){

  size_t config_data_len;
  
  void *icap_tx_buf;
  icap_tx_buf = setup_icap_buf(config_file, bs, &config_data_len);

  if (icap_tx_buf == NULL) return false;
  header[header_len] = config_data_len/8;
  buf_set_header(icap_tx_buf, header, header_len+1);
  
  // Transmit the bitstream
  buf_send(handles->fd_o1, icap_tx_buf, config_data_len);

  uint64_t *icap_rx_buf = (uint64_t*)buf_alloc(16);
  buf_recv(handles->fd_i,  icap_rx_buf, 8);

  //  usleep(1000 * 50);

  uint64_t received = icap_rx_buf[-1];
  uint64_t return_code = icap_rx_buf[0];
  
  buf_free(icap_tx_buf);
  buf_free(icap_rx_buf);

  return (received==1 && return_code==0);
}

#ifdef USE_ICAP_TOOLS_EXAMPLE
// Usage example:

int main(){
  channel_handles_t handles;
  
  setup_bus(&handles);
  printf("FDs: o1 %d, o2 %d, i %d\n",
         handles.fd_o1, handles.fd_o2, handles.fd_i);

  uint64_t header[HEADER_MAX];

  header[0] = ROUTING_HEADER | 3;  // ICAP
  header[1] = ROUTING_HEADER | 6;  // PCIe 

  write_icap("../pr/netfpga/bit/intadd_pe_rp_partial.bin", ICAP_BYTE_ORDER_K7, header, 2, &handles);

  //  write_icap("../pr/kc705-riffa/bit/pass_pe_rp_partial.bin", ICAP_BYTE_ORDER_K7, header, 2, &handles);
  

}
#endif
