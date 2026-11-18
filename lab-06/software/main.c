#include <stdio.h>
#include "bayer_input.h"
#include "platform.h"
#include "xil_printf.h"
#include "xparameters.h"
#include "xparameters_ps.h"
#include "xaxidma.h"
#include "xtime_l.h"

#define TX_DMA_ID                XPAR_PS2PL_DMA_DEVICE_ID
#define TX_DMA_MM2S_LENGTH_ADDR  (XPAR_PS2PL_DMA_BASEADDR + 0x28)

#define RX_DMA_ID                XPAR_PL2PS_DMA_DEVICE_ID
#define RX_DMA_S2MM_LENGTH_ADDR  (XPAR_PL2PS_DMA_BASEADDR + 0x58)

#define TX_BUFFER  (XPAR_DDR_MEM_BASEADDR + 0x08000000)
#define RX_BUFFER  (XPAR_DDR_MEM_BASEADDR + 0x10000000)

#define IMAGE_N    1024
#define IMAGE_SIZE (IMAGE_N * IMAGE_N)  /* 1024 bytes input  */
#define RGB_SIZE   (IMAGE_SIZE * 4)     /* 4096 bytes output */

static XAxiDma tx_dma, rx_dma;

static void sw_debayer(u8 *bayer, u8 *out)
{
    for (int row = 0; row < IMAGE_N; row++) {
        for (int col = 0; col < IMAGE_N; col++) {
            int idx = row * IMAGE_N + col;

            u8 p00 = (row>0 && col>0)               ? bayer[(row-1)*IMAGE_N+(col-1)] : 0;
            u8 p01 = (row>0)                         ? bayer[(row-1)*IMAGE_N+ col   ] : 0;
            u8 p02 = (row>0 && col<IMAGE_N-1)        ? bayer[(row-1)*IMAGE_N+(col+1)] : 0;
            u8 p10 = (col>0)                         ? bayer[ row   *IMAGE_N+(col-1)] : 0;
            u8 p11 =                                   bayer[ row   *IMAGE_N+ col   ];
            u8 p12 = (col<IMAGE_N-1)                 ? bayer[ row   *IMAGE_N+(col+1)] : 0;
            u8 p20 = (row<IMAGE_N-1 && col>0)        ? bayer[(row+1)*IMAGE_N+(col-1)] : 0;
            u8 p21 = (row<IMAGE_N-1)                 ? bayer[(row+1)*IMAGE_N+ col   ] : 0;
            u8 p22 = (row<IMAGE_N-1 && col<IMAGE_N-1)? bayer[(row+1)*IMAGE_N+(col+1)] : 0;

            u8 r, g, b;
            int re = (row % 2 == 0), ce = (col % 2 == 0);

            if (re && ce) {
                g = p11;
                r = ((u16)p01 + p21) >> 1;
                b = ((u16)p10 + p12) >> 1;
            } else if (re && !ce) {
                b = p11;
                g = ((u16)p01 + p10 + p12 + p21) >> 2;
                r = ((u16)p00 + p02 + p20 + p22) >> 2;
            } else if (!re && ce) {
                r = p11;
                g = ((u16)p01 + p10 + p12 + p21) >> 2;
                b = ((u16)p00 + p02 + p20 + p22) >> 2;
            } else {
                g = p11;
                r = ((u16)p10 + p12) >> 1;
                b = ((u16)p01 + p21) >> 1;
            }

            out[idx*4 + 0] = r;
            out[idx*4 + 1] = g;
            out[idx*4 + 2] = b;
            out[idx*4 + 3] = 0;
        }
    }
}

int main()
{
    Xil_DCacheDisable();

    XTime t0, t1, t2, t3;

    print("Lab6 starting...\r\n");

    init_platform();

    u8 *tx_buf = (u8 *)TX_BUFFER;
    u8 *rx_buf = (u8 *)RX_BUFFER;
    static u8 sw_out[RGB_SIZE];

    /* Address sanity check */
    xil_printf("tx_buf addr : 0x%08X\r\n", (unsigned int)tx_buf);
    xil_printf("rx_buf addr : 0x%08X\r\n", (unsigned int)rx_buf);
    xil_printf("TX DMA base : 0x%08X\r\n", XPAR_PS2PL_DMA_BASEADDR);
    xil_printf("RX DMA base : 0x%08X\r\n", XPAR_PL2PS_DMA_BASEADDR);

    /* Sentinel: fill rx_buf with 0xFF so we can detect if DMA wrote anything */
    memset(rx_buf, 0xFF, RGB_SIZE);
    xil_printf("rx[0] before DMA: %d (expect 255)\r\n", rx_buf[0]);

    /* Load bayer input from bayer32x32_2026_new.txt */
    for (int i = 0; i < IMAGE_SIZE; i++)
        tx_buf[i] = bayer_input[i];

    /* Step 1: Init TX-DMA */
    XAxiDma_Config *tx_cfg = XAxiDma_LookupConfig(TX_DMA_ID);
    if (!tx_cfg) { xil_printf("ERROR: TX DMA config not found\r\n"); return 1; }
    xil_printf("TX DMA has SG: %d (0=simple)\r\n", tx_cfg->HasSg);

    int st;
    st = XAxiDma_CfgInitialize(&tx_dma, tx_cfg);
    xil_printf("TX init: %d (0=ok)\r\n", st);
    XAxiDma_Reset(&tx_dma);
    while (!XAxiDma_ResetIsDone(&tx_dma));

    /* Step 2: Init RX-DMA */
    XAxiDma_Config *rx_cfg = XAxiDma_LookupConfig(RX_DMA_ID);
    if (!rx_cfg) { xil_printf("ERROR: RX DMA config not found\r\n"); return 1; }
    xil_printf("RX DMA has SG: %d (0=simple)\r\n", rx_cfg->HasSg);

    st = XAxiDma_CfgInitialize(&rx_dma, rx_cfg);
    xil_printf("RX init: %d (0=ok)\r\n", st);
    XAxiDma_Reset(&rx_dma);
    while (!XAxiDma_ResetIsDone(&rx_dma));

    /* Step 3: FPGA processing */
    XTime_GetTime(&t0);

    /* 3a: RX first, then TX */
    st = XAxiDma_SimpleTransfer(&rx_dma, (UINTPTR)rx_buf, RGB_SIZE, XAXIDMA_DEVICE_TO_DMA);
    xil_printf("RX SimpleTransfer: %d (0=ok)\r\n", st);

    st = XAxiDma_SimpleTransfer(&tx_dma, (UINTPTR)tx_buf, IMAGE_SIZE, XAXIDMA_DMA_TO_DEVICE);
    xil_printf("TX SimpleTransfer: %d (0=ok)\r\n", st);

    xil_printf("DMAs started, waiting...\r\n");

    while (XAxiDma_Busy(&tx_dma, XAXIDMA_DMA_TO_DEVICE));
    xil_printf("TX done\r\n");

    while (XAxiDma_Busy(&rx_dma, XAXIDMA_DEVICE_TO_DMA));
    xil_printf("RX done\r\n");

    xil_printf("TX bytes sent    : %u\r\n", Xil_In32(TX_DMA_MM2S_LENGTH_ADDR));
    xil_printf("RX bytes received: %u\r\n", Xil_In32(RX_DMA_S2MM_LENGTH_ADDR));
    xil_printf("rx[0..7]: %d %d %d %d | %d %d %d %d\r\n",
               rx_buf[0], rx_buf[1], rx_buf[2], rx_buf[3],
               rx_buf[4], rx_buf[5], rx_buf[6], rx_buf[7]);

    XTime_GetTime(&t1);

    /* Step 5: SW reference debayer */
    XTime_GetTime(&t2);
    sw_debayer(tx_buf, sw_out);
    XTime_GetTime(&t3);

    /* Step 6: Compare */
    int errors = 0;
    for (int i = 0; i < RGB_SIZE; i++)
        if (rx_buf[i] != sw_out[i]) errors++;

    u32 fpga_cyc = (u32)(t1 - t0);
    u32 sw_cyc   = (u32)(t3 - t2);
    u32 err_x100 = (u32)((u64)errors * 10000 / RGB_SIZE);

    xil_printf("FPGA_OUTPUT_START\r\n");
    for (int i = 0; i < IMAGE_SIZE; i++)
        xil_printf("%d %d %d\r\n", rx_buf[i*4+0], rx_buf[i*4+1], rx_buf[i*4+2]);
    xil_printf("FPGA_OUTPUT_END\r\n");

    xil_printf("Errors: %d/%d (%d.%02d%%)\r\n",
               errors, RGB_SIZE, err_x100/100, err_x100%100);
    xil_printf("FPGA cycles: %u\r\n", fpga_cyc);
    xil_printf("SW   cycles: %u\r\n", sw_cyc);

    if (fpga_cyc > 0) {
        u32 sp_x100 = (u32)((u64)sw_cyc * 100 / fpga_cyc);
        xil_printf("Speedup: %u.%02ux\r\n", sp_x100/100, sp_x100%100);
    }

    cleanup_platform();
    return 0;
}
