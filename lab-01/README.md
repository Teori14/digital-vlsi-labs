# Lab 01 · Digital building blocks

The first laboratory explores how the same digital behavior can be expressed through behavioral, dataflow and structural VHDL, then inspected with simulation and RTL schematics.

| Circuit | Available work | Main concept |
| :--- | :--- | :--- |
| 3-to-8 decoder | Behavioral and dataflow descriptions; decoder testbench | One-hot selection from a binary input |
| Sliding register | Four-bit state and clocked updates | Sequential behavior and reset |
| Up/down counter | Design and testbench | Direction and enable control |
| Modulo counter | Design and testbench | Programmable wrap condition |
| Binary arithmetic | Half adder, full adder, four-bit parallel adder and tests | Composition of smaller arithmetic blocks |
| BCD arithmetic | BCD full adder, four-digit parallel adder and tests | Decimal correction and carry propagation |

## Structural arithmetic

The arithmetic hierarchy builds larger circuits from smaller cells. The BCD stage first forms a binary sum, detects the need for decimal correction, then adds six when required. Four BCD stages propagate decimal carry across a multi-digit result.

[Design source](rtl/) · [Testbenches](sim/)

## Where the sources came from

The initial units were recovered from the Lab 1 report; the missing half/full/four-bit adder sources and tests were located in the external Vivado working folder. These are saved source versions, not newly invented replacements. Entity names are preserved even where a decoder's historical filename calls it a mux.

The report-recovered units passed VHDL-2008 analysis during portfolio preparation. Their complete simulation suite and implementation timing were not rerun.

[Build notes](../docs/BUILD.md) · [Collection](../README.md)
