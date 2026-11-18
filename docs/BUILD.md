# Build and project selection

## Use the matching configuration

VHDL entities recur across labs and saved versions. Create a separate Vivado project/library for the configuration you want to inspect; do not add all repository VHDL files to one design.

| Target | Sources and prerequisites |
| :--- | :--- |
| Lab 1 arithmetic | Relevant RTL hierarchy and one matching testbench |
| Lab 2 | Synchronous adder dependencies before pipeline/multiplier cells and tests |
| Lab 3 FIR | One complete `fir` or `alternative-fir` configuration; avoid mixing memories |
| Lab 4 | AXI wrapper, matching `fir_top`, Zynq block design and generated Vitis BSP |
| Lab 5 | One stage at a time; its associated RTL and testbench |
| Lab 6 small simulation | Two RTL files plus file-driven testbench; VHDL-2008 |
| Lab 6 Zynq | Integration wrappers, fixed-size RTL, generated IP and matching BSP |
| Bonus | One control-interface snapshot and its matching software/address map |

## Reproduce the small Debayer simulation

Use a Vivado 2022.2 command environment so `xvhdl`, `xelab` and `xsim` are on PATH. From the repository root in PowerShell:

```powershell
New-Item -ItemType Directory -Force build/debayer-4x4
Copy-Item tests/fixtures/input_pixels.txt build/debayer-4x4/input_pixels.txt
Set-Location build/debayer-4x4
xvhdl --2008 ../../lab-06/rtl/debayer_core_pipelined.vhd ../../lab-06/rtl/debayer_partA_final_line_buffers.vhd ../../lab-06/sim/debayer_partA_final_tb.vhd
xelab debayer_partA_final_tb -s debayer_tb
xsim debayer_tb -runall
Set-Location ../..
node tests/verify_debayer.mjs build/debayer-4x4/dut_rgb.txt
```

The testbench defaults to N=4 and reads `input_pixels.txt` from its working directory. Its default output is `dut_rgb.txt`. The checked-in output can be compared without Vivado using `node tests/verify_debayer.mjs`.

## Vivado/Vitis integration

The saved Lab 6 integration Tcl scripts sit beside their expected `vhdl_srcs` directory. They recreate reference infrastructure but do not by themselves establish that every final accelerator source is in the project. Check the top, compile order, `N`, AXI connections and address map.

For the bonus GPIO configuration, the saved layout is preserved under `bonus/runtime-hardware`. From that folder, the documented entry point is:

```text
vivado -mode batch -source scripts/build_bonus_runtime.tcl
```

This flow was recovered, not rerun here. Inspect version/board-part requirements and generated project paths before use. Export a matching hardware handoff, regenerate the Vitis platform/BSP, then build one application version. Xilinx headers and the Lab 6 platform support files come from that environment; they are not replaced by unrelated host libraries.

Binary XSA/bitstream files and complete vendor BSPs are omitted. Original compiler/platform settings should be retained when reproducing historical board results.
