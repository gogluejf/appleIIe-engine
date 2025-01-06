#!/usr/bin/env python3

# Converts a black and white bitmap image into a 7-bits-per-byte data structure for Apple IIe white graphics.
# Export pixel art from GIMP as a C file. (Ensure the "Save Alpha Channel" option is disabled for compatibility.)
# Pixel art can have any height, but its width must be a multiple of 7.
# Each byte represents 7 pixels (the most significant bit is ignored).
 
# Data is output byte-by-byte, starting from the last row and the rightmost byte.
# It processes each row from right to left, then moves to the row above, repeating until the sprite is fully encoded.
 
# This pattern is optimized for use with `graph.engine.s`, ensuring efficient rendering directly into screen memory.
 
# Note: Bits within each byte are inverted relative to their drawing order.
# The least significant bit represents the leftmost pixel, while the most significant (7th) bit represents the rightmost pixel.
# As a result, bytes are read inversely compared to how they are drawn on the screen.



import re
import sys
import os

def parse_c_file(filename):
    try:
        with open(filename, 'r') as file:
            content = file.read()

        # Extract width and height from the pixel_data line
        pixel_data_match = re.search(r'pixel_data\[(\d+) \* (\d+) \* \d+ \+ \d+\];', content)
        if not pixel_data_match:
            raise ValueError("Unable to find pixel_data dimensions in the file.")

        width = int(pixel_data_match.group(1)) // 7
        height = int(pixel_data_match.group(2))

        lines = content.splitlines()
        sequences = []

        # Process each line to find matches with the pattern "(something here)"
        for line in lines:
            match = re.search(r'"(.*?)"', line)
            if match:
                # Split content on '\\' and filter out empty strings
                sequences.extend([s for s in match.group(1).split('\\') if s])

        print(f"Parsed sequences: {sequences[:10]}... (truncated for display)")
        print(f"Length of sequences array: {len(sequences)}")

        # Process sequences to create the bit array
        bit_array = []
        for i in range(0, len(sequences), 3):
            chunk = sequences[i:i+3]
            if len(chunk) != 3:
                raise ValueError(f"Incomplete sequence at position {i}: {chunk}")

            if all(seq == '000' for seq in chunk):
                bit_array.append(0)
            elif all(seq == '377' for seq in chunk):
                bit_array.append(1)
            else:
                raise ValueError(f"Invalid sequence at position {i}: {chunk}")

        print(f"Bit array: {bit_array[:10]}... (truncated for display)")
        print(f"Length of bit array: {len(bit_array)}")

        # Create the hex array from the bit array
        hex_array = []
        for i in range(len(bit_array) - 1, -1, -7):
            chunk = bit_array[max(0, i-6):i+1]
            chunk.reverse()  # Flip the bits
            hex_value = int(''.join(map(str, chunk)), 2)  # Convert to hex
            hex_array.append(f"{hex_value:02X}")

        print(f"Hex array: {hex_array[:10]}... (truncated for display)")
        print(f"Length of hex array: {len(hex_array)}")

        # Add width and height at the beginning
        width_byte = width & 0xFF  #width byte as 1 byte
        height_byte = height & 0xFF  # Height as 1 byte

        # Prepend width and height to the hex sequence
        hex_preamble = f"{width_byte:02X}{height_byte:02X}"
        hex_sequence = hex_preamble + ''.join(hex_array)

        # Generate the final output
        shape_name = os.path.splitext(os.path.basename(filename))[0] + "Shape"
        print("\n")  
        print("Add this to your assembly, enjoy!")
        print("\n")
        print(f"; Shape of {shape_name} width = {width}, height = {height}")
        print(f"; Structure: [width byte] [height byte] [sprite_data...]")
        print(f"{shape_name} hex {hex_sequence}")

    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: ./parse_c_file.py <path_to_c_file>")
        sys.exit(1)

    parse_c_file(sys.argv[1])

