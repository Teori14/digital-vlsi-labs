# Lab 03 · FIR architecture

This laboratory builds a sequential FIR datapath from memories, a multiply-accumulate unit and a controller. The complete `fir_top` implementation was recovered from the external Vivado project.

| Folder | Contents | Purpose |
| :--- | :--- | :--- |
| [fir/rtl](fir/rtl/) | `mlab_rom`, `mlab_ram`, `mac_unit`, `control_unit`, `fir_top` | One complete FIR source configuration |
| [fir/sim](fir/sim/) | `fir_top_tb` | Input-stimulus testbench for that configuration |
| [exercises](exercises/) | Separate RAM-for-FIR, MAC and controller exercises | Develop and inspect the building blocks |
| [alternative-fir](alternative-fir/) | Saved ROM/RAM/MAC/CU/FIR configuration and testbench | An alternative project, built separately |
| [rtl](rtl/) and [sim](sim/) | ROM and ROM testbench recovered from the report | Report-associated memory exercise |
| [reference](reference/) | Original saved RAM/ROM variants | Comparison with the earlier memory descriptions |

## Datapath and sequencing

Coefficient addresses select ROM values, sample addresses select RAM values, and the MAC combines products into the output accumulator. The controller determines the sequence and marks valid output. The saved `fir_top` interface accepts an 8-bit input sample and produces a 19-bit result with `valid_out`.

## Verification detail

The recovered ROM and its testbench passed VHDL-2008 analysis. The complete FIR project has not been simulated again in this publication workflow. In `fir_top_tb`, the output-equality assertions are commented out; running that file alone therefore does not establish correct FIR output. The MAC exercise has its own assertion-based cases in its saved testbench.

Avoid compiling all memory variants into one library: several folders reuse entity names with different implementations.

[Build notes](../docs/BUILD.md) · [Collection](../README.md)
