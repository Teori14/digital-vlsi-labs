#include <stdio.h>
#include <string.h>
#include "bayer_input.h"
//#include "platform.h"
#include "xil_printf.h"
#include "xil_io.h"
#include "xparameters.h"
#include "xparameters_ps.h"
#include "xaxidma.h"
#include "xtime_l.h"

#define TX_DMA_ID                XPAR_PS2PL_DMA_DEVICE_ID
#define TX_DMA_MM2S_LENGTH_ADDR  (XPAR_PS2PL_DMA_BASEADDR + 0x28)

#define RX_DMA_ID                XPAR_PL2PS_DMA_DEVICE_ID
#define RX_DMA_S2MM_LENGTH_ADDR  (XPAR_PL2PS_DMA_BASEADDR + 0x58)

#ifndef XPAR_DEBAYER_CFG_BASEADDR
#define XPAR_DEBAYER_CFG_BASEADDR 0x41200000U
#endif

#define DEBAYER_CFG_DATA_OFFSET 0x0U
#define DEBAYER_CFG_TRI_OFFSET  0x4U

#define TX_BUFFER  (XPAR_DDR_MEM_BASEADDR + 0x08000000)
#define RX_BUFFER  (XPAR_DDR_MEM_BASEADDR + 0x10000000)

#define MAX_N      1024
#define MAX_PIXELS (MAX_N * MAX_N)
#define MAX_RGB    (MAX_PIXELS * 4)

static XAxiDma tx_dma, rx_dma;
static u8 sw_out[MAX_RGB];

static int valid_dim(int n)
{
    return (n == 64 || n == 128 || n == 256 || n == 512 || n == 1024);
}

static void configure_debayer_dim(u32 dim)
{
    u32 cfg = (1U << 16) | (dim & 0xFFFFU);

    /* AXI GPIO channel is output. */
    Xil_Out32(XPAR_DEBAYER_CFG_BASEADDR + DEBAYER_CFG_TRI_OFFSET, 0x00000000U);
    Xil_Out32(XPAR_DEBAYER_CFG_BASEADDR + DEBAYER_CFG_DATA_OFFSET, cfg);

    u32 rd = Xil_In32(XPAR_DEBAYER_CFG_BASEADDR + DEBAYER_CFG_DATA_OFFSET);
    xil_printf("Debayer cfg write/read: wrote 0x%08X, read 0x%08X\r\n", cfg, rd);
}

static void sw_debayer_dim(u8 *bayer, u8 *out, int n)
{
    for (int row = 0; row < n; row++) {
        for (int col = 0; col < n; col++) {
            int idx = row * n + col;

            u8 p00 = (row > 0 && col > 0)       ? bayer[(row-1)*n + (col-1)] : 0;
            u8 p01 = (row > 0)                  ? bayer[(row-1)*n + col]     : 0;
            u8 p02 = (row > 0 && col < n-1)     ? bayer[(row-1)*n + (col+1)] : 0;
            u8 p10 = (col > 0)                  ? bayer[row*n + (col-1)]     : 0;
            u8 p11 =                              bayer[row*n + col];
            u8 p12 = (col < n-1)                ? bayer[row*n + (col+1)]     : 0;
            u8 p20 = (row < n-1 && col > 0)     ? bayer[(row+1)*n + (col-1)] : 0;
            u8 p21 = (row < n-1)                ? bayer[(row+1)*n + col]     : 0;
            u8 p22 = (row < n-1 && col < n-1)   ? bayer[(row+1)*n + (col+1)] : 0;

            u8 r, g, b;
            int re = (row % 2 == 0);
            int ce = (col % 2 == 0);

            /* GBRG pattern, same as the VHDL core. */
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

static int init_dmas(void)
{
    XAxiDma_Config *tx_cfg = XAxiDma_LookupConfig(TX_DMA_ID);
    if (!tx_cfg) { xil_printf("ERROR: TX DMA config not found\r\n"); return -1; }
    int st = XAxiDma_CfgInitialize(&tx_dma, tx_cfg);
    if (st != XST_SUCCESS) { xil_printf("ERROR: TX DMA init failed: %d\r\n", st); return -1; }
    XAxiDma_Reset(&tx_dma);
    while (!XAxiDma_ResetIsDone(&tx_dma));

    XAxiDma_Config *rx_cfg = XAxiDma_LookupConfig(RX_DMA_ID);
    if (!rx_cfg) { xil_printf("ERROR: RX DMA config not found\r\n"); return -1; }
    st = XAxiDma_CfgInitialize(&rx_dma, rx_cfg);
    if (st != XST_SUCCESS) { xil_printf("ERROR: RX DMA init failed: %d\r\n", st); return -1; }
    XAxiDma_Reset(&rx_dma);
    while (!XAxiDma_ResetIsDone(&rx_dma));

    xil_printf("TX DMA base: 0x%08X, RX DMA base: 0x%08X, CFG base: 0x%08X\r\n",
               XPAR_PS2PL_DMA_BASEADDR, XPAR_PL2PS_DMA_BASEADDR, XPAR_DEBAYER_CFG_BASEADDR);
    return 0;
}

static void load_input(u8 *tx_buf, int n)
{
    int pixels = n * n;

    /*
     * For simplicity we use the first n*n bytes from bayer_input as an n x n image.
     * This is valid for testing, even though bayer_input was generated with max size 1024x1024.
     */
    for (int i = 0; i < pixels; i++)
        tx_buf[i] = bayer_input[i];
}

static void print_first_last_pixels(u8 *rx_buf, int n)
{
    int total_pixels = n * n;

    xil_printf("First 5 output pixels (R G B X):\r\n");
    for (int i = 0; i < 5; i++) {
        int base = 4 * i;
        xil_printf("pixel[%d] = %d %d %d %d\r\n",
                   i,
                   rx_buf[base + 0],
                   rx_buf[base + 1],
                   rx_buf[base + 2],
                   rx_buf[base + 3]);
    }

    xil_printf("Last 5 output pixels (R G B X):\r\n");
    for (int i = total_pixels - 5; i < total_pixels; i++) {
        int base = 4 * i;
        xil_printf("pixel[%d] = %d %d %d %d\r\n",
                   i,
                   rx_buf[base + 0],
                   rx_buf[base + 1],
                   rx_buf[base + 2],
                   rx_buf[base + 3]);
    }
}

static void run_one_image(int n)
{
    if (!valid_dim(n)) {
        xil_printf("Invalid dimension: %d\r\n", n);
        return;
    }

    u8 *tx_buf = (u8 *)TX_BUFFER;
    u8 *rx_buf = (u8 *)RX_BUFFER;
    int image_size = n * n;
    int rgb_size   = image_size * 4;

    xil_printf("\r\n=== Runtime Debayer %dx%d ===\r\n", n, n);

    configure_debayer_dim((u32)n);

    load_input(tx_buf, n);
    memset(rx_buf, 0xFF, rgb_size);

    XTime t0, t1, t2, t3;

    Xil_DCacheFlushRange((UINTPTR)tx_buf, image_size);
    Xil_DCacheFlushRange((UINTPTR)rx_buf, rgb_size);

    XTime_GetTime(&t0);

    int st = XAxiDma_SimpleTransfer(&rx_dma, (UINTPTR)rx_buf, rgb_size, XAXIDMA_DEVICE_TO_DMA);
    if (st != XST_SUCCESS) { xil_printf("RX transfer failed: %d\r\n", st); return; }

    st = XAxiDma_SimpleTransfer(&tx_dma, (UINTPTR)tx_buf, image_size, XAXIDMA_DMA_TO_DEVICE);
    if (st != XST_SUCCESS) { xil_printf("TX transfer failed: %d\r\n", st); return; }

    while (XAxiDma_Busy(&tx_dma, XAXIDMA_DMA_TO_DEVICE));
    while (XAxiDma_Busy(&rx_dma, XAXIDMA_DEVICE_TO_DMA));

    XTime_GetTime(&t1);
    Xil_DCacheInvalidateRange((UINTPTR)rx_buf, rgb_size);

    XTime_GetTime(&t2);
    sw_debayer_dim(tx_buf, sw_out, n);
    XTime_GetTime(&t3);

    int errors = 0;
    for (int i = 0; i < rgb_size; i++) {
        if (rx_buf[i] != sw_out[i]) {
            errors++;
            if (errors <= 8) {
                xil_printf("Mismatch[%d]: fpga=%d sw=%d\r\n", i, rx_buf[i], sw_out[i]);
            }
        }
    }

    u32 fpga_cyc = (u32)(t1 - t0);
    u32 sw_cyc   = (u32)(t3 - t2);
    u32 err_x100 = (u32)((u64)errors * 10000 / rgb_size);

    xil_printf("TX bytes sent    : %u\r\n", Xil_In32(TX_DMA_MM2S_LENGTH_ADDR));
    xil_printf("RX bytes received: %u\r\n", Xil_In32(RX_DMA_S2MM_LENGTH_ADDR));
    xil_printf("rx[0..7]: %d %d %d %d | %d %d %d %d\r\n",
               rx_buf[0], rx_buf[1], rx_buf[2], rx_buf[3],
               rx_buf[4], rx_buf[5], rx_buf[6], rx_buf[7]);
    print_first_last_pixels(rx_buf, n);

    xil_printf("Errors: %d/%d (%d.%02d%%)\r\n",
               errors, rgb_size, err_x100/100, err_x100%100);
    xil_printf("FPGA cycles: %u\r\n", fpga_cyc);
    xil_printf("SW   cycles: %u\r\n", sw_cyc);

    if (fpga_cyc > 0) {
        u32 sp_x100 = (u32)((u64)sw_cyc * 100 / fpga_cyc);
        xil_printf("Speedup: %u.%02ux\r\n", sp_x100/100, sp_x100%100);
    }
}

int main()
{
    //init_platform();

    xil_printf("Lab6 Bonus runtime debayer starting...\r\n");

    if (init_dmas() != 0) {
        //cleanup_platform();
        return 1;
    }

    run_one_image(64);
    run_one_image(128);
    run_one_image(256);
    run_one_image(512);
    run_one_image(1024);

    //cleanup_platform();
    return 0;
}
