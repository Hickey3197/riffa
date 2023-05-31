#include <stdio.h>
#include "ap_int.h"
#include "hls_stream.h"

typedef hls::stream<ap_uint<64> > my_str;
void vecadd_float(my_str& in1, my_str& in2, my_str& out1);

typedef union {
  uint32_t u;
  float f;
} uf_t;

int main(){
  my_str in1, in2, out1;

  ap_uint<64> len=50;
  in1.write(len);
  in2.write(len);

  for (int i=0; i<len*2; i+=2){
    uf_t a, b;
    ap_uint<64> au, bu;
    
    a.f = i;    b.f = 0.0001*i;
    au.range(31, 0) = a.u;
    bu.range(31, 0) = b.u;

    a.f = i+1;   b.f = 0.0001*(i+1);
    au.range(63,32) = a.u;
    bu.range(63,32) = b.u;
    
    in1.write(au);
    in2.write(bu);
  }

  vecadd_float(in1, in2, out1);

  len = out1.read();
  printf("Result length: %d\n", (int)len);

  for (int i=0; i<len; i++){
    ap_uint<64> ou = out1.read();
    uf_t o1, o2;
    o1.u = ou.range(31, 0);
    o2.u = ou.range(63,32);
    
    printf("[%d] %f %f\n", i, o1.f, o2.f);
  }
}
