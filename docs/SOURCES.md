# Source provenance

## Course archive

The semester archive provided RAM/ROM variants, FIR AXI wrappers and C software, Debayer RTL/testbench/C, image headers and bonus submission sources. Generated output headers and large project caches were not copied.

Text-based VHDL was recovered from the Lab 1 and Lab 2 reports, the older Lab 2 report for `full_adder_sync`, and the Lab 3 ROM report. Word non-breaking spaces were normalized. Source statements were not redesigned during recovery.

## External Vivado working folder

Additional sources were found under the separately supplied `DVLSI` working directory:

| Original area | Repository use |
| :--- | :--- |
| `Ergasthrio1_PartB` | Missing half/full/four-bit adder sources and testbenches |
| `Ergasthrio3/fir_filter` | Complete `fir_top` dependency set |
| `Ergasthrio3/erg3_3` through `erg3_6` | RAM/MAC/controller exercises and alternative FIR configuration |
| `Ergasthrio5/erg5_1` through `erg5_4_final_pipelined` | Debayer development stages |
| `Ergasthrio6/dvlsi_lab6_2025` | Fixed-size integrated top, wrapper and project Tcl |
| `Ergasthrio_bonus/chat/debayer_bonus` | Runtime GPIO configuration hardware and build flow |
| `Ergasthrio_bonus/chat/vitis_ws/debayer_bonus_app` | Earlier Vitis software snapshot |

The folder names describe archive provenance, not proof that a particular file was the final assessed revision. Files labeled final in the original archive may coexist with later work.

## Supplied and generated code

`reference/zybo-led-demo` retains its course/Digilent attribution. `lab-05/reference-platform` is the supplied stream loopback/reference infrastructure. AXI templates, block-design wrappers and project Tcl retain their original comments. They are not attributed as wholly original work.

No repository-wide license has been selected while authorship and third-party terms are still being checked. The repository remains private for review.
