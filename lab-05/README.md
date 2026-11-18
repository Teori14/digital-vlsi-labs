# Lab 05 · Streaming Debayer development

This laboratory develops a Bayer-to-RGB interpolator in stages: from a supplied 3×3 neighborhood to a complete pipelined image stream.

| Stage folder | Saved design scope |
| :--- | :--- |
| [01](stages/01/) | Interpolation core, stream/top logic and testbenches |
| [02](stages/02/) | Expanded stage-two Debayer implementation and testbench |
| [03](stages/03/) | Saved complete-image version and its testbench |
| [04](stages/04/) | Pipelined core, line buffers and file-driven testbench |

Each folder is a separate development configuration. Repeated entity names must not be compiled together indiscriminately.

## From stream to neighborhood

For GBRG input, row and column parity determine which component is already known. Neighboring values provide the missing components. Line buffers retain previous image rows; shift registers expose the three columns required by the interpolation core. Zero padding defines behavior at image boundaries.

The pipelined version feeds this window into registered arithmetic. [Lab 6](../lab-06/README.md) carries the corresponding filter into a Zynq DMA system.

## Supplied integration framework

[reference-platform](reference-platform/) contains the saved 2025 reference platform: Zynq wrapper, Tcl project-generation scripts and example ARM code. Its original top is a stream loopback/replication example, not the completed Debayer integration. It is labeled as supplied infrastructure and is not presented as original accelerator logic.

[Build notes](../docs/BUILD.md) · [Collection](../README.md)
