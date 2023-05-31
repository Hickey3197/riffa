#include <stdint.h>
#include "hls_stream.h"
#include "ap_int.h"

typedef hls::stream<ap_uint<64> > my_str;
typedef union {
  uint32_t u;
  float f;
} uf_t;

void vecadd_float(my_str& in1, my_str& in2, my_str& out1){
#pragma HLS INTERFACE axis register both port=in1
#pragma HLS INTERFACE axis register both port=in2
#pragma HLS INTERFACE axis register both port=out1
 
  uint64_t len;
  len = in1.read();
  in2.read(); // in1 and in2 must have exactly same length
  out1.write(len);  // output length = input length;
 
  for(uint64_t i=0; i<len; i++){
#pragma HLS PIPELINE
    ap_uint<64> au, bu, xu;
    uf_t a[2], b[2], x[2];

    au = in1.read();
    bu = in2.read();
    
    a[0].u = au.range(31,0);  b[0].u = bu.range(31,0);
    a[1].u = au.range(63,32); b[1].u = bu.range(63,32);

    x[0].f = a[0].f + b[0].f;
    x[1].f = a[1].f + b[1].f;

    xu.range(31,0) = x[0].u;  xu.range(63,32) = x[1].u;
    
    out1.write(xu);
  }
}
