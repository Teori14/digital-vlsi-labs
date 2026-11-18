#include <stdio.h>
#include <string.h>

#include "bayer_input_64.h"
#include "bayer_input_128.h"
#include "bayer_input_256.h"
#include "bayer_input_512.h"
#include "bayer_input_1024.h"
//#include "platform.h"
#include "xil_printf.h"
#include "xil_io.h"
#include "xparameters.h"
#include "xparameters_ps.h"
#include "xaxidma.h"
#include "xtime_l.h"
#include "xil_cache.h"

/*
 * Runtime debayer test for Lab6 bonus.
 *
 * Changes compared with the previous version:
 * 1. Separate exact Bayer input header per image size.
 * 2. Debug prints after every important step.
 * 3. Timeout-based DMA waits, so the program never hangs forever.
 * 4. DMA status register dump on timeout.
 * 5. stdout unbuffered and DCache disabled in main() for first debugging pass.
 */

#define TX_DMA_ID                XPAR_PS2PL_DMA_DEVICE_ID
#define RX_DMA_ID                XPAR_PL2PS_DMA_DEVICE_ID

#define TX_DMA_BASEADDR          XPAR_PS2PL_DMA_BASEADDR
#define RX_DMA_BASEADDR          XPAR_PL2PS_DMA_BASEADDR

#define TX_DMA_MM2S_LENGTH_ADDR  (TX_DMA_BASEADDR + 0x28U)
#define RX_DMA_S2MM_LENGTH_ADDR  (RX_DMA_BASEADDR + 0x58U)

#define MM2S_DMACR_OFFSET        0x00U
#define MM2S_DMASR_OFFSET        0x04U
#define S2MM_DMACR_OFFSET        0x30U
#define S2MM_DMASR_OFFSET        0x34U

#ifndef XPAR_DEBAYER_CFG_BASEADDR
#define XPAR_DEBAYER_CFG_BASEADDR 0x41200000U
#endif

#define DEBAYER_CFG_DATA_OFFSET  0x0U
#define DEBAYER_CFG_TRI_OFFSET   0x4U

/* Keep buffers in DDR, away from program/code area. */
#define TX_BUFFER                (XPAR_DDR_MEM_BASEADDR + 0x08000000U)
#define RX_BUFFER                (XPAR_DDR_MEM_BASEADDR + 0x10000000U)

#define MAX_N                    1024
#define MAX_PIXELS               (MAX_N * MAX_N)
#define MAX_RGB                  (MAX_PIXELS * 4)

#define DMA_TIMEOUT              100000000U

static XAxiDma tx_dma;
static XAxiDma rx_dma;
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

            u8 p00 = (row > 0 && col > 0)       ? bayer[(row - 1) * n + (col - 1)] : 0;
            u8 p01 = (row > 0)                  ? bayer[(row - 1) * n + col]       : 0;
            u8 p02 = (row > 0 && col < n - 1)   ? bayer[(row - 1) * n + (col + 1)] : 0;
            u8 p10 = (col > 0)                  ? bayer[row * n + (col - 1)]       : 0;
            u8 p11 =                              bayer[row * n + col];
            u8 p12 = (col < n - 1)              ? bayer[row * n + (col + 1)]       : 0;
            u8 p20 = (row < n - 1 && col > 0)   ? bayer[(row + 1) * n + (col - 1)] : 0;
            u8 p21 = (row < n - 1)              ? bayer[(row + 1) * n + col]       : 0;
            u8 p22 = (row < n - 1 && col < n-1) ? bayer[(row + 1) * n + (col + 1)] : 0;

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

            out[idx * 4 + 0] = r;
            out[idx * 4 + 1] = g;
            out[idx * 4 + 2] = b;
            out[idx * 4 + 3] = 0;
        }
    }
}

static int wait_reset_done(XAxiDma *dma, const char *name)
{
    volatile u32 timeout = DMA_TIMEOUT;

    while (!XAxiDma_ResetIsDone(dma)) {
        timeout--;
        if (timeout == 0U) {
            xil_printf("ERROR: %s DMA reset timeout\r\n", name);
            return -1;
        }
    }

    xil_printf("%s DMA reset done\r\n", name);
    return 0;
}

static int init_dmas(void)
{
    XAxiDma_Config *tx_cfg = XAxiDma_LookupConfig(TX_DMA_ID);
    if (!tx_cfg) {
        xil_printf("ERROR: TX DMA config not found\r\n");
        return -1;
    }

    int st = XAxiDma_CfgInitialize(&tx_dma, tx_cfg);
    if (st != XST_SUCCESS) {
        xil_printf("ERROR: TX DMA init failed: %d\r\n", st);
        return -1;
    }

    XAxiDma_Reset(&tx_dma);
    if (wait_reset_done(&tx_dma, "TX") != 0) {
        return -1;
    }

    XAxiDma_Config *rx_cfg = XAxiDma_LookupConfig(RX_DMA_ID);
    if (!rx_cfg) {
        xil_printf("ERROR: RX DMA config not found\r\n");
        return -1;
    }

    st = XAxiDma_CfgInitialize(&rx_dma, rx_cfg);
    if (st != XST_SUCCESS) {
        xil_printf("ERROR: RX DMA init failed: %d\r\n", st);
        return -1;
    }

    XAxiDma_Reset(&rx_dma);
    if (wait_reset_done(&rx_dma, "RX") != 0) {
        return -1;
    }

    xil_printf("TX DMA base: 0x%08X, RX DMA base: 0x%08X, CFG base: 0x%08X\r\n",
               TX_DMA_BASEADDR, RX_DMA_BASEADDR, XPAR_DEBAYER_CFG_BASEADDR);

    return 0;
}

typedef struct {
    int n;
    const u8 *data;
    u32 bytes;
    const char *name;
} bayer_image_t;

static const bayer_image_t bayer_images[] = {
    {64,   bayer_input_64,   BAYER_INPUT_64_BYTES,   "bayer_input_64.h"},
    {128,  bayer_input_128,  BAYER_INPUT_128_BYTES,  "bayer_input_128.h"},
    {256,  bayer_input_256,  BAYER_INPUT_256_BYTES,  "bayer_input_256.h"},
    {512,  bayer_input_512,  BAYER_INPUT_512_BYTES,  "bayer_input_512.h"},
    {1024, bayer_input_1024, BAYER_INPUT_1024_BYTES, "bayer_input_1024.h"}
};

static const bayer_image_t *find_bayer_image(int n)
{
    unsigned int count = sizeof(bayer_images) / sizeof(bayer_images[0]);

    for (unsigned int i = 0; i < count; i++) {
        if (bayer_images[i].n == n) {
            return &bayer_images[i];
        }
    }

    return NULL;
}

static int load_input(u8 *tx_buf, int n)
{
    int pixels = n * n;
    const bayer_image_t *img = find_bayer_image(n);

    if (img == NULL) {
        xil_printf("ERROR: no Bayer input header selected for %dx%d\r\n", n, n);
        return -1;
    }

    if (img->bytes != (u32)pixels) {
        xil_printf("ERROR: %s has %d bytes but %dx%d needs %d bytes\r\n",
                   img->name, img->bytes, n, n, pixels);
        return -1;
    }

    memcpy(tx_buf, img->data, pixels);
    xil_printf("Input loaded from %s: pixels=%d, source_bytes=%d\r\n",
               img->name, pixels, img->bytes);

    return 0;
}

static void dump_dma_regs(void)
{
    xil_printf("TX MM2S_DMACR=0x%08X, TX MM2S_DMASR=0x%08X, TX MM2S_LEN=%d\r\n",
               Xil_In32(TX_DMA_BASEADDR + MM2S_DMACR_OFFSET),
               Xil_In32(TX_DMA_BASEADDR + MM2S_DMASR_OFFSET),
               Xil_In32(TX_DMA_MM2S_LENGTH_ADDR));

    xil_printf("RX S2MM_DMACR=0x%08X, RX S2MM_DMASR=0x%08X, RX S2MM_LEN=%d\r\n",
               Xil_In32(RX_DMA_BASEADDR + S2MM_DMACR_OFFSET),
               Xil_In32(RX_DMA_BASEADDR + S2MM_DMASR_OFFSET),
               Xil_In32(RX_DMA_S2MM_LENGTH_ADDR));
}

static int wait_dma_done(XAxiDma *dma, int direction, const char *name)
{
    volatile u32 timeout = DMA_TIMEOUT;

    while (XAxiDma_Busy(dma, direction)) {
        timeout--;
        if (timeout == 0U) {
            xil_printf("TIMEOUT waiting for %s DMA\r\n", name);
            dump_dma_regs();
            return -1;
        }
    }

    xil_printf("%s DMA done\r\n", name);
    return 0;
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
    xil_printf("Image bytes=%d, RGB bytes=%d\r\n", image_size, rgb_size);

    configure_debayer_dim((u32)n);

    if (load_input(tx_buf, n) != 0) {
        return;
    }

    memset(rx_buf, 0xFF, rgb_size);
    xil_printf("RX buffer cleared\r\n");

    /* With DCache disabled this is not strictly needed, but it is safe and useful
     * when you later re-enable DCache and switch to flush/invalidate mode. */
    Xil_DCacheFlushRange((UINTPTR)tx_buf, image_size);
    Xil_DCacheFlushRange((UINTPTR)rx_buf, rgb_size);
    xil_printf("Cache flush done\r\n");

    XTime t0, t1, t2, t3;
    XTime_GetTime(&t0);

    xil_printf("Starting RX DMA, bytes=%d\r\n", rgb_size);
    int st = XAxiDma_SimpleTransfer(&rx_dma, (UINTPTR)rx_buf, rgb_size, XAXIDMA_DEVICE_TO_DMA);
    if (st != XST_SUCCESS) {
        xil_printf("RX transfer failed: %d\r\n", st);
        dump_dma_regs();
        return;
    }

    xil_printf("Starting TX DMA, bytes=%d\r\n", image_size);
    st = XAxiDma_SimpleTransfer(&tx_dma, (UINTPTR)tx_buf, image_size, XAXIDMA_DMA_TO_DEVICE);
    if (st != XST_SUCCESS) {
        xil_printf("TX transfer failed: %d\r\n", st);
        dump_dma_regs();
        return;
    }

    xil_printf("Waiting TX DMA...\r\n");
    if (wait_dma_done(&tx_dma, XAXIDMA_DMA_TO_DEVICE, "TX") != 0) {
        return;
    }

    xil_printf("Waiting RX DMA...\r\n");
    if (wait_dma_done(&rx_dma, XAXIDMA_DEVICE_TO_DMA, "RX") != 0) {
        return;
    }

    XTime_GetTime(&t1);

    Xil_DCacheInvalidateRange((UINTPTR)rx_buf, rgb_size);
    xil_printf("RX cache invalidate done\r\n");

    XTime_GetTime(&t2);
    sw_debayer_dim(tx_buf, sw_out, n);
    XTime_GetTime(&t3);
    xil_printf("Software reference done\r\n");

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
    u32 err_x100 = (u32)((u64)errors * 10000U / (u32)rgb_size);

    xil_printf("TX bytes sent    : %d\r\n", Xil_In32(TX_DMA_MM2S_LENGTH_ADDR));
    xil_printf("RX bytes received: %d\r\n", Xil_In32(RX_DMA_S2MM_LENGTH_ADDR));
    xil_printf("rx[0..7]: %d %d %d %d | %d %d %d %d\r\n",
               rx_buf[0], rx_buf[1], rx_buf[2], rx_buf[3],
               rx_buf[4], rx_buf[5], rx_buf[6], rx_buf[7]);

    print_first_last_pixels(rx_buf, n);

    xil_printf("Errors: %d/%d (%d.%02d%%)\r\n",
               errors, rgb_size, err_x100 / 100, err_x100 % 100);
    xil_printf("FPGA cycles: %d\r\n", fpga_cyc);
    xil_printf("SW   cycles: %d\r\n", sw_cyc);

    if (fpga_cyc > 0U) {
        u32 sp_x100 = (u32)((u64)sw_cyc * 100U / fpga_cyc);
        xil_printf("Speedup: %d.%02dx\r\n", sp_x100 / 100, sp_x100 % 100);
    }
}

int main(void)
{
    //init_platform();

    setvbuf(stdout, NULL, _IONBF, 0);

    /* First debugging pass: disable DCache to remove cache coherency as a cause.
     * Later, if everything works, you can remove this and rely on Flush/Invalidate. */
    Xil_DCacheDisable();

    xil_printf("START RELEASE\r\n");
    xil_printf("Lab6 Bonus runtime debayer starting...\r\n");

    if (init_dmas() != 0) {
        //cleanup_platform();
        return 1;
    }

    /* Start with 64 only while debugging. Uncomment larger sizes after 64 works. */
    run_one_image(64);

    /* Uncomment after 64x64 completes without DMA timeout. */
    //run_one_image(128);
    //run_one_image(256);
    //run_one_image(512);
    //run_one_image(1024);

    //cleanup_platform();
    return 0;
}
