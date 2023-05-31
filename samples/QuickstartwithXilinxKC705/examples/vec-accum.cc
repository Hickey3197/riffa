#include <stdint.h>
#include "hls_stream.h"

void vec_accum(hls::stream<uint64_t>& in, hls::stream<uint64_t>& out){
#pragma HLS INTERFACE axis register both port=in
#pragma HLS INTERFACE axis register both port=out
 
  uint64_t len, sum=0;
  len = in.read();
 
  for(uint64_t i=0; i<len; i++) sum += in.read();
 
  out.write(1);  // output length is always 1
  out.write(sum);
}
