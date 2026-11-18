# Lab 06 · Debayer on Zynq

The streaming interpolator is integrated with the Zynq processing system. ARM software sends a Bayer image from DDR to the programmable logic through DMA, receives RGBX output, and compares it with a C software reference.

| Folder | Role |
| :--- | :--- |
| [rtl](rtl/) | Fixed-size line buffers and pipelined color interpolation |
| [sim](sim/) | File-driven VHDL testbench |
| [software](software/) | ARM application and archived Bayer input |
| [integration](integration/) | Saved Zynq wrapper, Debayer top and Vivado project Tcl |

## Image path

The core uses a GBRG Bayer pattern, two line buffers, a 3×3 window and zero padding. The integration top selects `N = 1024`. RGB results are packed into a 32-bit word with a padding byte for the DDR-side layout.

The saved C program initializes transmit/receive DMA, invokes the software reference and compares returned bytes. It requires the BSP and address definitions generated from the corresponding hardware export.

## Fresh simulation evidence

On **18 November 2026**, the saved testbench ran in **Vivado Simulator 2022.2** with a deterministic **4×4** image. It completed at simulation time **265 ns**. An independent software calculation matched all **16 output pixels / 48 RGB channels**, with zero mismatches.

[Input, actual output and result](../evidence/debayer-4x4/README.md) · [Comparison script and replay instructions](../tests/README.md)

This small simulation checks one input fixture and the fixed-size core. It does not establish full-size timing, backpressure behavior, DMA operation or runtime reconfiguration.

## Historical report

The saved course report describes simulation, a 1024×1024 Zynq comparison and post-place-and-route resource tables. Those are historical report statements, not new measurements made during repository preparation. The pipeline fill threshold is visible in the RTL, but no exact latency or speedup claim is derived from it here.

[Build notes](../docs/BUILD.md) · [Collection](../README.md)
