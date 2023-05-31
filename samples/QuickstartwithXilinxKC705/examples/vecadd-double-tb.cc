#include <stdio.h>
#include "hls_stream.h"

typedef hls::stream<double> my_str;
void vecadd_double(my_str& in1, my_str& in2, my_str& out1);

typedef union {
  uint64_t u;
  double d;
} ud_t;

int main(){
  hls::stream<double> in1, in2, out1;

  ud_t len;
  len.u = 100;
  in1.write(len.d);
  in2.write(len.d);

  for (int i=0; i<len.u; i++){
    in1.write(i);
    in2.write(0.0001*i);
  }

  vecadd_double(in1, in2, out1);

  len.d = out1.read();
  printf("Result length: %d\n", (int)len.u);

  for (int i=0; i<len.u; i++)
    printf("[%d] %lf\n", i, out1.read());
}
