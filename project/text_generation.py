import os

def wrap_text_preserving_words(text, width=20):
    """Wrap text into lines without breaking words across lines."""
    words = text.split()
    lines = []
    current_line = ""

    for word in words:
        if len(current_line) + len(word) + (1 if current_line else 0) <= width:
            if current_line:
                current_line += " "
            current_line += word
        else:
            lines.append(current_line)
            current_line = word

    if current_line:
        lines.append(current_line)

    return lines

def wrap_manual_pages(raw_text, width=20):
    # Split pages manually using '---' as the separator
    page_texts = [page.strip().replace('\n', ' ') for page in raw_text.split('---')]
    pages = []

    for page in page_texts:
        lines = wrap_text_preserving_words(page, width)
        pages.append(lines)

    return pages

def generate_kim1_lcd_pages_manual(text):
    lcd_addresses = [0x00, 0x40, 0x14, 0x54]
    pages = wrap_manual_pages(text)
    output = []

    for page in pages:
        for i, line in enumerate(page):
            if i >= len(lcd_addresses):
                break  # ignore extra lines beyond 4
            if i > 0:
                output.append(f".byte 0xFE, 0x45, 0x{lcd_addresses[i]:02X}")
            output.append('.byte ' + ', '.join(f'"{c}"' if c not in ('"', "'") else f"'\\{c}'" for c in line))
        output.append(".byte 0")  # End of page

    return "\n".join(output)

if __name__ == "__main__":
    example_text = """
Q: Where is the Effel Tower?
---
1. Paris
2. Prague
3. London
4. Berlin
---
Q: Who invented the telephone?
---
1. Edison
2. Alexander Graham Bell
3. Nikola Tesla
4. Einstein
---
Q: Who's the Goat?
---
1. Messi
2. Ronaldo
3. Neymar
4. Antony
---
Q: What is the capital of Australia?
---
1. Sydney
2. Sweeney
3. Canberra
4. Melbourne
---
Q: What planet is
known as the Red
Planet?
---
1. Earth
2. Mars
3. Venus
4. Jupiter
---
Q: What is the
largest ocean on
Earth?
---
1. Atlantic
2. Pacific
3. Indian
4. Arctic
---
Q: Who wrote the
play "Romeo and
Juliet"?
---
1. Dickens
2. Tolkien
3. Shakespeare
4. Hemingway
---
Q: What gas do
plants absorb from
the atmosphere?
---
1. Oxygen
2. Carbon Dioxide
3. Nitrogen
4. Hydrogen
---
Q: Which element has
the chemical symbol
'Au'?
---
1. Silver
2. Gold
3. Iron
4. Copper

"""

    output_code = generate_kim1_lcd_pages_manual(example_text)

    with open(os.path.join(os.path.dirname(__file__), "file.txt"), "w") as f:
        f.write(output_code)

    print("Manual pages written to file.txt")




