# Debayer comparison

The original VHDL testbench is in [lab-06/sim](../lab-06/sim/). The fixture here was added during portfolio preparation to make one small result reproducible.

```text
node tests/verify_debayer.mjs
```

This compares the checked-in actual simulator output against a GBRG/zero-padding software reference. To check a fresh simulation output:

```text
node tests/verify_debayer.mjs build/debayer-4x4/dut_rgb.txt
```

Input is a deterministic 4×4 raster image with pixel i equal to `(37*i + 11) mod 256`. The comparison requires exactly 16 rows with three integer RGB channels each. It checks all 48 channels, including boundary interpolation, for this single fixture.

[Run the VHDL simulation](../docs/BUILD.md) · [Recorded evidence](../evidence/debayer-4x4/README.md)
