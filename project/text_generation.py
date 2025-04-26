import os
def wrap_manual_pages(raw_text, width=20, lines_per_page=4):
    # Split pages manually using '---' as the separator
    page_texts = [page.strip() for page in raw_text.split('---')]
    pages = []

    for page in page_texts:
        chars = list(page)
        lines = []
        for i in range(0, width * lines_per_page, width):
            line_chars = chars[i:i+width]
            line = ''.join(line_chars).ljust(width)
            lines.append(line)
        pages.append(lines)

    return pages


def generate_kim1_lcd_pages_manual(text):
    lcd_addresses = [0x00, 0x40, 0x14, 0x54]
    pages = wrap_manual_pages(text)
    output = []

    for page in pages:
        for i, line in enumerate(page):
            if i > 0:
                output.append(f".byte 0xFE, 0x45, 0x{lcd_addresses[i]:02X}")
            output.append('.byte ' + ', '.join(f'"{c}"' if c not in ('"', "'") else f"'\\{c}'" for c in line))
        output.append(".byte 0")  # End of page

    return "\n".join(output)


if __name__ == "__main__":
    example_text = """
THE QUICK BROWN FOX JUMPS OVER THE LAZY DOG. THIS IS PAGE ONE.
---
PAGE TWO STARTS HERE AND SHOULD ALSO BE PADDING SPACES IF SHORT.
---
SHORT PAGE
"""

    output_code = generate_kim1_lcd_pages_manual(example_text)

    with open(os.path.join(__file__, "file.txt"), "w") as f:
        f.write(output_code)

    print("Manual pages written to file.txt")



