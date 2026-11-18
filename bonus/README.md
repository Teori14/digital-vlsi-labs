# Bonus · Runtime-configurable Debayer

The extension changes image dimensions through ARM-side configuration instead of synthesizing a separate fixed-size design for every image. Bulk pixels still travel through DMA; the configuration uses a small control register.

## Key implementation files

| Area | Source | Role |
| :--- | :--- | :--- |
| Streaming datapath | [Runtime line buffers](runtime-hardware/vhdl_srcs/debayer_partA_final_line_buffers.vhd) | Form the 3×3 neighborhood using the configured image dimension |
| Color interpolation | [Pipelined core](runtime-hardware/vhdl_srcs/debayer_core_pipelined.vhd) | Calculate missing RGB components |
| System integration | [Zynq top](runtime-hardware/vhdl_srcs/dvlsi_lab6_top.vhd) | Connect configuration and pixel-stream interfaces |
| Vivado flow | [Build script](runtime-hardware/scripts/build_bonus_runtime.tcl) | Extend the supplied platform with runtime configuration |
| ARM application | [Vitis C source](runtime-software/main_bonus_runtime_separate_inputs.c) | Select input size, manage DMA/cache and compare the result |
| Reference data | [Python generator](runtime-software/generate_debayer_outputs.py) | Generate RGBX reference headers from the input images |

## Saved configurations

| Folder | Configuration |
| :--- | :--- |
| [runtime-hardware](runtime-hardware/) | VHDL and Tcl flow recovered from the `debayer_bonus` working project; AXI GPIO configuration with DMA |
| [runtime-software](runtime-software/) | Later C application with separate Bayer headers for 64, 128, 256, 512 and 1024 dimensions; Python reference-output generator |
| [earlier-vitis-software](earlier-vitis-software/) | Earlier saved Vitis application and input headers |
| [archived-ip](archived-ip/) | Submission-archive RTL using a custom AXI-Lite IP configuration path |

The custom-IP and GPIO configurations are different snapshots. Do not combine their register maps or compile their duplicate core entities together.

## Runtime flow

1. Select an input image and validate its dimensions.
2. Configure the active size through the control path.
3. Prepare DMA buffers and cache state.
4. Receive RGBX data into DDR.
5. Compare the output with the software reference and report differences.

The later application includes complete input arrays per size. Its reference generator creates expected RGBX headers locally; those generated output arrays are omitted from Git to avoid duplicating derivable data.

## Evidence scope

Saved workflow notes describe a successful 64×64 Release run with an earlier repeated-pattern input and a reported 0.56× end-to-end speedup in that example. This is not evidence of acceleration across all sizes. A separate console text file is explicitly named `estimated`, so it is not published as an observed run log.

No new runtime-hardware build, full-size run or board test was performed for this repository. The fresh 4×4 result belongs to the fixed-size Lab 6 core. The saved Tcl scripts and sources are included for inspection and restoration of the matching project.

[Build notes](../docs/BUILD.md) · [Collection](../README.md)
