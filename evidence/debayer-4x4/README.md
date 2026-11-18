# Debayer 4×4 simulation result

**Observed on 18 November 2026 using Vivado Simulator 2022.2.**

| Check | Result |
| :--- | :--- |
| Input | Deterministic 4×4 GBRG fixture |
| VHDL analysis | Passed, VHDL-2008 |
| Elaboration | Passed |
| Simulation | Completed at 265 ns |
| RGB output | 16 pixels |
| Comparison | All 48 channels match the software calculation |
| Mismatches | 0 |

[Input fixture](../../tests/fixtures/input_pixels.txt) · [Actual simulator output](dut_rgb.txt) · [Result data](result.json)

The saved Lab 6 testbench printed `Simulation finished successfully` and stopped. Its output file was then compared with an independent software calculation using the same GBRG pattern and zero-padding boundary rule.

The check covers this fixed-size fixture. It does not test ARM software, DMA, runtime configuration, full-size images or board behavior. 265 ns is the testbench stop time, not an accelerator performance measurement.
