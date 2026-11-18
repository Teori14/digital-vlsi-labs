#include <stdint.h>
#include "platform.h"
#include "xparameters.h"
#include "xil_io.h"
#include "xil_printf.h"
#include "sleep.h"

#define FIR_BASEADDR XPAR_FIR_IP_0_S00_AXI_BASEADDR
#define REG_A 0x00
#define REG_B 0x04

static inline uint32_t pack_input(uint8_t x, uint8_t valid_in, uint8_t rst)
{
    return ((uint32_t)x) | ((uint32_t)valid_in << 8) | ((uint32_t)rst << 9);
}

static inline uint32_t get_y(uint32_t B)
{
    return (B & 0x7FFFF);
}

static inline uint32_t get_valid(uint32_t B)
{
    return ((B >> 19) & 1);
}

int main()
{
    uint32_t A, B;
    int i;
    uint8_t x[28] = {
        208, 231, 32, 233, 161, 24,
        71, 140, 245, 247, 40, 248,
        245, 124, 204, 36, 107, 234,
        202, 245,0, 0, 0, 0, 0, 0, 0,0
    };

    init_platform();

    xil_printf("start\r\n");

    A = pack_input(0, 0, 1);
    Xil_Out32(FIR_BASEADDR + REG_A, A);
    usleep(1000);

    A = pack_input(0, 0, 0);
    Xil_Out32(FIR_BASEADDR + REG_A, A);
    usleep(1000);

    for (i = 0; i < 28; i++) {
        A = pack_input(x[i], 1, 0);
        Xil_Out32(FIR_BASEADDR + REG_A, A);

        do {
            B = Xil_In32(FIR_BASEADDR + REG_B);
        } while (get_valid(B) == 0);

        xil_printf("x=%d  y=%ld  B=0x%08lx\r\n",
                   x[i],
                   (long)get_y(B),
                   (unsigned long)B);
    }

    xil_printf("end\r\n");

    cleanup_platform();
    return 0;
}
