# Lab 02 · Clocked arithmetic

This laboratory moves arithmetic across clock boundaries. The design task includes not only the arithmetic function, but also aligning operands and partial results through pipeline stages.

| Design | Application | Source |
| :--- | :--- | :--- |
| Synchronous adder | Register sum and carry on the clock | [RTL](rtl/synchronous_adder.vhd) |
| Pipelined adder | Compose clocked arithmetic stages | [RTL](rtl/pipeline_full_adder.vhd) |
| Synchronous multiplier cell | Multiply one-bit operands and combine incoming sum/carry | [RTL](rtl/mul_cell_sync.vhd) |
| Four-bit systolic multiplier | Arrange cells and align signals through the array | [RTL](rtl/multiplier_4bit_systolic.vhd) |

[All testbenches](sim/)

## Pipeline alignment

The multiplier uses clocked cells that forward operand and partial-result signals. Its testbench maintains an expected-result pipeline so the reference value is compared at the intended output cycle. This illustrates the difference between computing the right value and presenting it on the right clock cycle.

Two synchronous-adder interfaces are retained: `synchronous_adder` and the reset-capable `full_adder_sync` used by the multiplier. The latter was recovered from an older report and matches the saved multiplier cell's interface.

All eight report-recovered units passed VHDL-2008 analysis in Vivado 2022.2. No new multiplier or pipeline simulation result is claimed.

[Build notes](../docs/BUILD.md) · [Collection](../README.md)
