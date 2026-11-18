import re
from pathlib import Path


SIZES = [64, 128, 256, 512, 1024]


def read_c_array(header_path: Path) -> list[int]:
    """
    Reads a C header that contains an unsigned char array.
    Example accepted formats:
        static const unsigned char bayer_input_64[4096] = { ... };
        static const uint8_t bayer_input_64[] = { ... };
    """
    text = header_path.read_text(encoding="utf-8", errors="ignore")

    start = text.find("{")
    end = text.rfind("}")

    if start == -1 or end == -1 or end <= start:
        raise ValueError(f"Could not find C array braces in {header_path}")

    array_text = text[start + 1:end]

    # Remove C/C++ comments
    array_text = re.sub(r"/\*.*?\*/", "", array_text, flags=re.DOTALL)
    array_text = re.sub(r"//.*", "", array_text)

    # Read decimal or hex numbers
    tokens = re.findall(r"0x[0-9a-fA-F]+|\d+", array_text)

    values = []
    for tok in tokens:
        val = int(tok, 0)
        if not (0 <= val <= 255):
            raise ValueError(f"Value out of uint8 range in {header_path}: {val}")
        values.append(val)

    return values


def debayer_gbrg(bayer: list[int], n: int) -> list[int]:
    """
    Software reference debayer, same logic as the C main.

    Bayer pattern:
        row even, col even: G
        row even, col odd : B
        row odd,  col even: R
        row odd,  col odd : G

    Output format per pixel:
        R, G, B, 0
    """
    out = [0] * (n * n * 4)

    def pix(row: int, col: int) -> int:
        if 0 <= row < n and 0 <= col < n:
            return bayer[row * n + col]
        return 0

    for row in range(n):
        for col in range(n):
            idx = row * n + col

            p00 = pix(row - 1, col - 1)
            p01 = pix(row - 1, col)
            p02 = pix(row - 1, col + 1)

            p10 = pix(row, col - 1)
            p11 = pix(row, col)
            p12 = pix(row, col + 1)

            p20 = pix(row + 1, col - 1)
            p21 = pix(row + 1, col)
            p22 = pix(row + 1, col + 1)

            row_even = (row % 2 == 0)
            col_even = (col % 2 == 0)

            if row_even and col_even:
                # G pixel
                g = p11
                r = (p01 + p21) >> 1
                b = (p10 + p12) >> 1

            elif row_even and not col_even:
                # B pixel
                b = p11
                g = (p01 + p10 + p12 + p21) >> 2
                r = (p00 + p02 + p20 + p22) >> 2

            elif not row_even and col_even:
                # R pixel
                r = p11
                g = (p01 + p10 + p12 + p21) >> 2
                b = (p00 + p02 + p20 + p22) >> 2

            else:
                # G pixel
                g = p11
                r = (p10 + p12) >> 1
                b = (p01 + p21) >> 1

            base = idx * 4
            out[base + 0] = r
            out[base + 1] = g
            out[base + 2] = b
            out[base + 3] = 0

    return out


def write_c_array(header_path: Path, array_name: str, values: list[int], values_per_line: int = 16):
    guard = header_path.name.upper().replace(".", "_").replace("-", "_")

    with header_path.open("w", encoding="utf-8") as f:
        f.write(f"#ifndef {guard}\n")
        f.write(f"#define {guard}\n\n")
        f.write("#include <stdint.h>\n\n")
        f.write(f"#define {array_name.upper()}_SIZE {len(values)}\n\n")
        f.write(f"static const uint8_t {array_name}[{len(values)}] = {{\n")

        for i in range(0, len(values), values_per_line):
            chunk = values[i:i + values_per_line]
            line = ", ".join(f"{v}" for v in chunk)
            if i + values_per_line < len(values):
                f.write(f"    {line},\n")
            else:
                f.write(f"    {line}\n")

        f.write("};\n\n")
        f.write(f"#endif /* {guard} */\n")


def generate_for_size(n: int):
    input_header = Path(f"bayer_input_{n}.h")
    output_header = Path(f"debayer_output_{n}.h")

    if not input_header.exists():
        print(f"[SKIP] Missing {input_header}")
        return

    bayer = read_c_array(input_header)
    expected_pixels = n * n

    if len(bayer) != expected_pixels:
        raise ValueError(
            f"{input_header} has {len(bayer)} bytes, "
            f"but {n}x{n} needs {expected_pixels} bytes."
        )

    out = debayer_gbrg(bayer, n)
    expected_output_bytes = n * n * 4

    if len(out) != expected_output_bytes:
        raise RuntimeError("Internal error: wrong output size")

    write_c_array(output_header, f"debayer_output_{n}", out)

    print(f"[OK] {input_header} -> {output_header}")
    print(f"     input bytes : {len(bayer)}")
    print(f"     output bytes: {len(out)}")


def main():
    for n in SIZES:
        generate_for_size(n)


if __name__ == "__main__":
    main()
