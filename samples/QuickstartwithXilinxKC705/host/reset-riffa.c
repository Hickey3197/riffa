#include <stdlib.h>
#include <stdio.h>
#include <pthread.h>
#include "riffa.h"


int main(int argc, char** argv) {
  fpga_t * fpga;

  fpga = fpga_open(0);

  if (fpga == NULL) {
    printf("Could not get FPGA 0\n");
    return -1;
  }

  // Reset
  fpga_reset(fpga);

  // Done with device
  fpga_close(fpga);

  return 0;
}
