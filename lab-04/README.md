# Lab 04 · FIR through AXI-Lite

The FIR datapath is exposed to ARM software through a memory-mapped interface. The saved source includes a custom IP wrapper, an AXI-Lite slave implementation and a C application that accesses the registers.

[IP wrapper](rtl/fir_ip_v1_0.vhd) · [AXI slave](rtl/fir_ip_v1_0_S00_AXI.vhd) · [ARM application](software/helloworld.c)

## Hardware/software boundary

Software writes input/control words and reads results through the AXI register map. The wrapper connects those transactions to `fir_top`, linking the standalone arithmetic pipeline to the Zynq processing system.

The `fir_top` interface is available in [Lab 3's FIR configuration](../lab-03/fir/rtl/). The complete system also needs the matching Zynq block design, generated IP and Vitis BSP; the three files in this folder are not a standalone software build.

The external working folder contains another `fir_axi` package. This publication retains the `fir_ip` snapshot from the course archive, without mixing wrappers from different IP configurations.

No fresh board run or AXI protocol verification is claimed. A register-transaction trace and a comparison of software-issued samples with expected FIR results would provide suitable follow-up evidence.

[Build notes](../docs/BUILD.md) · [Collection](../README.md)
