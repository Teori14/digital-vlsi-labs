# Verification record

## New checks during publication

**18 November 2026 · Vivado 2022.2**

- VHDL-2008 analysis passed for 22 units recovered from the Lab 1–3 reports.
- The fixed-size Lab 6 testbench analyzed, elaborated and completed on a deterministic 4×4 fixture.
- Its 16 output pixels matched an independent GBRG/zero-padding software calculation: 48 channels compared, zero mismatches.
- Comment translations preserve functional source code; report recovery normalizes Word non-breaking spaces.

The small simulation used the files in `lab-06/rtl` and `lab-06/sim`. No new board run, full-size synthesis, timing closure or bonus-runtime result is claimed.

## Historical and generated material

The course report describes a 1024×1024 Zynq test and Vivado resource results. Workflow notes describe later bonus work. Those statements are kept separate from freshly observed results.

Expected-output generators produce references, not observations of FPGA hardware. The archived console text named `putty_estimated_full_output.txt` is not treated as a real log and is not included as evidence.

## Remaining checks

| Area | Scope still to verify |
| :--- | :--- |
| Arithmetic and FIR | Fresh elaboration and execution of the full saved test suite |
| FIR testbench | `fir_top_tb` has commented output assertions; restore/check its intended verification logic |
| AXI/DMA | Matching IP/BSP, stream backpressure, reset and transfer completion |
| Runtime variants | Associate the GPIO/custom-IP snapshots with their actual software and bitstreams |
| Large images | Full-size correctness, throughput and resource measurements under recorded conditions |
| Attribution | Confirm which portions were supplied framework code and which were jointly developed |

Use actual logs or captures labeled with source revision, board, clock and tools. No performance number should be inferred from a descriptive report template or an estimated console example.
