''' 
Please write a python script that takes accepts a phrase such as "This Is A Test" and hides the phrase in a 20x10 block of random letters.  The phrase should have the letters spaced randomly, but in left to right, top to bottom order.  The script should print out the 20x10 encoded block and also a 20x10 block with * that show where the phrase letters are located.
'''


import random
import string

from dataclasses import dataclass
from datetime import datetime
from uuid import uuid4
import sys
import drawsvg as dw


L_00_Holes = "rgb(0,0,0)"
L_01_Text = "rgb(0,0,255)"
L_02_Outline = "rgb(255,0,0)"
L_03_Sheet = "rgb(0,255,0)"
IN = 96
PX_TO_MM = 96.0 / 25.4  # ≈0.264583 mm per px
MM = 25.4 / 96.0  #
# light_burn_scale_fix = 0.264 
light_burn_scale_fix = 1
MM = PX_TO_MM * light_burn_scale_fix # fix lightburn

big_font = 8 * MM
small_font = 7 * MM


def hide_phrase_with_random_spacing(phrase, width=10, height=10):
    # Clean and prepare the phrase
    clean_phrase = ''.join(phrase.upper().split())
    total_cells = width * height

    if len(clean_phrase) > total_cells:
        raise ValueError("Phrase is too long to fit in the grid")

    # Pick unique positions in order for each character, left to right, top to bottom
    available_positions = list(range(total_cells))
    available_positions.sort()
    letter_positions = sorted(random.sample(available_positions, len(clean_phrase)))

    # Create flat grid of random letters
    flat_grid = [random.choice(string.ascii_uppercase) for _ in range(total_cells)]
    flat_mask = [' ' for _ in range(total_cells)]

    # Place the phrase letters and mark their positions
    for char, pos in zip(clean_phrase, letter_positions):
        flat_grid[pos] = char
        flat_mask[pos] = '*'

    # Convert flat lists to 2D grid format
    def to_grid(flat):
        return [''.join(flat[i*width:(i+1)*width]) for i in range(height)]

    encoded_grid = to_grid(flat_grid)
    mask_grid = to_grid(flat_mask)

    return encoded_grid, mask_grid


def hide_each_word_on_its_own_line(phrase, difficulty=1.5):
    
    words = phrase.upper().split()
    height = len(words)
    max_len = max(list(map(len,words)))
    width = int(max_len * difficulty)
    if len(words) > height:
        raise ValueError("Too many words to fit in the grid height")

    # Initialize empty grid and mask
    grid = [[' ' for _ in range(width)] for _ in range(height)]
    mask = [[' ' for _ in range(width)] for _ in range(height)]

    for row, word in enumerate(words):
        if len(word) > width:
            raise ValueError(f"Word '{word}' is too long for grid width")

        # Pick random unique positions for the word letters in this row
        positions = sorted(random.sample(range(width), len(word)))
        for char, col in zip(word, positions):
            grid[row][col] = char
            mask[row][col] = '*'

    # Fill the rest of the grid with random letters
    for y in range(height):
        for x in range(width):
            if grid[y][x] == ' ':
                grid[y][x] = random.choice(string.ascii_uppercase)

    # Convert to strings
    encoded_lines = [''.join(row) for row in grid]
    mask_lines = [''.join(row) for row in mask]

    return encoded_lines, mask_lines

# Example usage


# encoded, mask = hide_phrase_with_random_spacing("Hello Felix This Is a Test of encoded cards")








def draw_card_front(id,encoded):
    big_font = 8 * MM
    small_font = 7 * MM

    d = dw.Drawing(
        8.5 * IN,
        11 * IN,
        id_prefix="punch",
        font_family="Arial",
    )
    d.set_pixel_scale(1)
    d.append(dw.Rectangle(0, 0, 8.5 * IN, 11 * IN, stroke=L_03_Sheet, fill="none"))

    card = dw.Group(
        id=f"{id}outline", fill="none", stroke=L_02_Outline, stroke_width="1"
    )
    card.append(dw.Rectangle(0, 0, 5 * IN, 4 * IN, stroke=L_03_Sheet, fill="none"))
    card.append(
        dw.Text(
            encoded,
            font_size=small_font,
            x=.5* IN,
            y=.5 * IN,
            stroke=L_01_Text,
            stroke_width=0.2,
        )
    )

    d.append(card)

    return d



def make_svg(message):

    encoded, mask = hide_each_word_on_its_own_line(message)

    
    print("Encoded Grid:")
    print('\n'.join(encoded))
    print("\nPhrase Location Mask:")
    print('\n'.join(mask))

    lot_number = int(datetime.now().timestamp()) % 100000
    filename = f"card_{lot_number}.svg"
    filename = f"card_front.svg"
    d = draw_card_front(lot_number,encoded)


    # export an svg that we can import into lightburn for laser cutting
    d.save_svg(filename)
    print(f"saved output to {filename}")


def main() -> int:
    """generate the svg file"""
    msg = "Hello Felix This Is a Test of encoded cards"

    if len(sys.argv) > 1:
        msg = sys.argv[1]
    make_svg(msg)
    return 0


if __name__ == "__main__":
    sys.exit(main())  # next section explains the use of sys.exit

