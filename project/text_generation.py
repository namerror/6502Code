import os

def generate_kim1_lcd_bytes(text):
    words = text.split()
    lines = []
    current_line = ""

    for word in words:
        # Add a space before word if the line isn't empty
        if current_line:
            if len(current_line) + 1 + len(word) <= 20:
                current_line += " " + word
            else:
                # Line full, push it and start new one
                lines.append(current_line.ljust(20))
                current_line = word
        else:
            # Start new line with word
            current_line = word

    # Don't forget the last line
    if current_line:
        lines.append(current_line.ljust(20))

    # Ensure exactly 4 lines
    while len(lines) < 4:
        lines.append(" " * 20)
    lines = lines[:4]  # trim extra lines if more than 80 chars

    # LCD addresses for each visual line
    lcd_addresses = [0x00, 0x40, 0x14, 0x54]

    # Generate .byte output
    output = []
    for i, line in enumerate(lines):
        if i > 0:
            output.append(f".byte 0xFE, 0x45, 0x{lcd_addresses[i]:02X}")
        output.append('.byte ' + ', '.join(f'"{char}"' for char in line))

    output.append(".byte 0")  # Null terminator
    return "\n".join(output)


if __name__ == "__main__":
    example_text = "Hello this is Leon Long's project. Please DO NOT TOUCH!!!"
    output_code = generate_kim1_lcd_bytes(example_text)

    # Write output to file.txt
    output_path = os.path.join(os.path.dirname(__file__), "file.txt")
    with open(output_path, "w") as f:
        f.write(output_code)

    print("Output written to file.txt")

