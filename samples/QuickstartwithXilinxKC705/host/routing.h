#include <stddef.h>

#ifndef _ROUTING_H_
#define _ROUTING_H_

#define ROUTING_HEADER (1ul << 56)

#define PE_LOOPBACK_1 (1ul)
#define PE_COMPUTE    (2ul) 
#define PE_ICAP       (3ul)
#define PE_COMPUTE_2  (4ul)

#define PORT_NONE             (0ul) // /dev/null
#define PORT_PCIE             (7ul) // KC705/NetFPGA/C10 <- IS NOT CORRECT!

// ------------------------------
// System specific configuration

#define PORT_KC705_TO_NETFPGA (5ul) // KC705 SMA
#define PORT_KC705_TO_KU041   (6ul) // KC705 SFP

#define PORT_KU041_TO_KU040   (5ul) // KU041 SFP1
#define PORT_KU041_TO_KC705   (6ul) // KU041 SFP2

#define PORT_KU040_TO_KU041   (5ul) // KU040 SFP1
#define PORT_KU040_TO_NETFPGA (6ul) // KU040 SMA1 

#define PORT_NETFPGA_TO_KU040 (5ul) // NetFPGA DP0
#define PORT_NETFPGA_TO_KC705 (6ul) // NetFPGA DP1

// End system specific config.
// ------------------------------

void route_verbose(void* b1, void* b2, int ro, int pe, size_t words1, size_t words2);
void route(void* b1, void* b2, int ro, int pe, size_t words1, size_t words2);
void route_help();

// STREAM+ helper

#define TARGET_KC705   0
#define TARGET_NETFPGA 1 
#define TARGET_KU040   2
#define TARGET_KU041   3

int route_icap_bswap(int route);
int route_fpga_target(int route);

#endif
