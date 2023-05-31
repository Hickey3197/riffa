// C testbench for vec-accum.cc

#include <stdio.h>
#include <stdint.h>
#include "hls_stream.h"

void vec_accum(hls::stream<uint64_t>& in, hls::stream<uint64_t>& out);

int main(){
  static const int len = 100;

  hls::stream<uint64_t> in, out;
  in.write(len);

  for(int i=0; i<len; i++) in.write(i);
  vec_accum(in, out);

  int result_len = (int)out.read();
  int result_sum = (int)out.read();
  
  printf("result of vec_accum(): length %d, sum %d\n",
         result_len, result_sum);

}
