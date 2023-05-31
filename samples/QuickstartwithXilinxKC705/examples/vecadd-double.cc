#include <stdint.h>
#include "hls_stream.h"

typedef hls::stream<double> my_str;
typedef union {
  uint64_t u;
  double d;
} ud_t;

void vecadd_double(my_str& in1, my_str& in2, my_str& out1){
#pragma HLS INTERFACE axis register both port=in1
#pragma HLS INTERFACE axis register both port=in2
#pragma HLS INTERFACE axis register both port=out1
 
  ud_t len;
  len.d = in1.read();
  in2.read(); // in1 and in2 must have exactly same length
  out1.write(len.d);  // output length = input length;
 
  for(uint64_t i=0; i<len.u; i++){
#pragma HLS PIPELINE
    double a, b, x;
    a = in1.read(); b = in2.read();
    x = a+b;
    out1.write(x);
  }
}
