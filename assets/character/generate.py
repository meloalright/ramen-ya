#!/usr/bin/env python3
"""Generate the chef walk spritesheet (assets/chef_sheet.png).

3 columns (walk frames) x 3 rows (down / side-left / up), each frame 20x26 px,
authored at the on-screen size so it stays crisp (drawn ~1:1 then nearest-
zoomed). The draw code cycles columns [0,1,0,2]: col0 = passing pose,
col1 = left step, col2 = right step. Regenerate with:

    python3 assets/character/generate.py
"""
from PIL import Image
import os

FW, FH = 20, 26
COLS, ROWS = 3, 3
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "chef_sheet.png")

# palette — a cool young guy: spiky dark hair, red はちまき headband,
# charcoal jacket over a teal tee, dark jeans, white sneakers
HAIR    = (48, 42, 56, 255)
HAIR_HI = (92, 80, 104, 255)
BAND    = (214, 58, 58, 255)
BAND_D  = (158, 40, 40, 255)
SKIN    = (244, 198, 160, 255)
SKIN_SH = (214, 166, 130, 255)
JACKET  = (46, 58, 74, 255)
JACKET_HI = (70, 86, 106, 255)
TEE     = (74, 198, 186, 255)
TEE_SH  = (50, 158, 148, 255)
PANTS   = (54, 52, 70, 255)
PANTS_D = (40, 38, 52, 255)
SHOE    = (226, 226, 232, 255)
SHOE_SH = (176, 176, 188, 255)
EYE     = (34, 30, 40, 255)
OUT_C   = (26, 22, 32, 255)


def frame():
    return Image.new("RGBA", (FW, FH), (0, 0, 0, 0))


def rect(px, x0, y0, x1, y1, c):
    for y in range(y0, y1):
        for x in range(x0, x1):
            if 0 <= x < FW and 0 <= y < FH:
                px[x, y] = c


def legs(px, frame_idx, back=False):
    pc = PANTS_D if back else PANTS
    # neutral feet at y24-25; step lifts the back foot and shifts a little
    lL, lR = 25, 25
    dxl, dxr = 0, 0
    if frame_idx == 1:        # left foot forward
        lL, lR, dxl, dxr = 25, 23, -1, 1
    elif frame_idx == 2:      # right foot forward
        lL, lR, dxl, dxr = 23, 25, 1, -1
    rect(px, 8 + dxl, 20, 11 + dxl, lL, pc)
    rect(px, 10 + dxr, 20, 13 + dxr, lR, pc)
    rect(px, 8 + dxl, lL - 2, 11 + dxl, lL, SHOE)       # white sneakers
    rect(px, 8 + dxl, lL - 1, 11 + dxl, lL, SHOE_SH)
    rect(px, 10 + dxr, lR - 2, 13 + dxr, lR, SHOE)
    rect(px, 10 + dxr, lR - 1, 13 + dxr, lR, SHOE_SH)


def head_front(px, oy, side=False, back=False):
    # spiky dark hair + red headband; face unless back
    if not back:
        rect(px, 7, 7 + oy, 13, 12 + oy, SKIN)          # face
        rect(px, 7, 11 + oy, 13, 12 + oy, SKIN_SH)
    # hair block + spikes
    rect(px, 6, 2 + oy, 14, 7 + oy, HAIR)
    rect(px, 6, 2 + oy, 14, 3 + oy, HAIR_HI)
    for sx in (7, 9, 11, 13):
        px[sx, 1 + oy] = HAIR
    rect(px, 6, 7 + oy, 7, 10 + oy, HAIR)               # sideburns
    rect(px, 13, 7 + oy, 14, 10 + oy, HAIR)
    if back:
        rect(px, 6, 7 + oy, 14, 12 + oy, HAIR)          # all hair (back of head)
        rect(px, 6, 11 + oy, 14, 12 + oy, HAIR_HI)
    # red headband across the forehead/hairline
    rect(px, 5, 6 + oy, 15, 8 + oy, BAND)
    rect(px, 5, 7 + oy, 15, 8 + oy, BAND_D)
    # knotted tails on the side
    px[4, 8 + oy] = BAND; px[3, 9 + oy] = BAND_D
    if not back and not side:
        px[8, 9 + oy] = EYE                             # eyes
        px[11, 9 + oy] = EYE


def outline(im):
    px = im.load()
    src = im.copy().load()
    for y in range(FH):
        for x in range(FW):
            if src[x, y][3] != 0:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < FW and 0 <= ny < FH and src[nx, ny][3] == 255 and src[nx, ny] != OUT_C:
                    px[x, y] = OUT_C
                    break
    return im


def torso(px, oy):
    # charcoal jacket open over a teal tee
    rect(px, 6, 12 + oy, 14, 20 + oy, JACKET)
    rect(px, 6, 12 + oy, 14, 13 + oy, JACKET_HI)
    rect(px, 9, 12 + oy, 11, 20 + oy, TEE)
    rect(px, 9, 18 + oy, 11, 20 + oy, TEE_SH)
    # arms + hands
    rect(px, 4, 13 + oy, 6, 18 + oy, JACKET); rect(px, 4, 18 + oy, 6, 20 + oy, SKIN)
    rect(px, 14, 13 + oy, 16, 18 + oy, JACKET); rect(px, 14, 18 + oy, 16, 20 + oy, SKIN)


def draw_down(fi):
    im = frame(); px = im.load()
    oy = -1 if fi == 0 else 0          # passing pose bobs up 1px
    legs(px, fi)
    torso(px, oy)
    head_front(px, oy)
    return outline(im)


def draw_up(fi):
    im = frame(); px = im.load()
    oy = -1 if fi == 0 else 0
    legs(px, fi, back=True)
    rect(px, 6, 12 + oy, 14, 20 + oy, JACKET)
    rect(px, 6, 12 + oy, 14, 13 + oy, JACKET_HI)
    rect(px, 4, 13 + oy, 6, 18 + oy, JACKET); rect(px, 4, 18 + oy, 6, 20 + oy, SKIN)
    rect(px, 14, 13 + oy, 16, 18 + oy, JACKET); rect(px, 14, 18 + oy, 16, 20 + oy, SKIN)
    head_front(px, oy, back=True)
    return outline(im)


def draw_side(fi):
    # faces LEFT
    im = frame(); px = im.load()
    oy = -1 if fi == 0 else 0
    # legs (profile scissor)
    front, back = 25, 25
    if fi == 1:
        front, back = 25, 23
    elif fi == 2:
        front, back = 23, 25
    rect(px, 7, 20, 10, back, PANTS_D)            # back leg
    rect(px, 7, back - 2, 10, back, SHOE); rect(px, 7, back - 1, 10, back, SHOE_SH)
    rect(px, 9, 20, 12, front, PANTS)             # front leg
    rect(px, 9, front - 2, 13, front, SHOE); rect(px, 9, front - 1, 13, front, SHOE_SH)
    # body
    rect(px, 7, 12 + oy, 13, 20 + oy, JACKET)
    rect(px, 7, 12 + oy, 13, 13 + oy, JACKET_HI)
    rect(px, 7, 13 + oy, 9, 19 + oy, TEE)         # tee shows at the front (left)
    # front arm swinging
    var_y = 18 if fi == 1 else (16 if fi == 2 else 17)
    rect(px, 6, 13 + oy, 8, var_y + oy, JACKET)
    rect(px, 6, var_y + oy, 8, var_y + 2 + oy, SKIN)
    # head (profile, faces left): spiky hair, band, one eye, nose
    rect(px, 6, 2 + oy, 13, 7 + oy, HAIR)
    rect(px, 6, 2 + oy, 13, 3 + oy, HAIR_HI)
    for sx in (7, 9, 11):
        px[sx, 1 + oy] = HAIR
    rect(px, 11, 7 + oy, 13, 12 + oy, HAIR)       # hair at the back (right)
    rect(px, 6, 7 + oy, 11, 12 + oy, SKIN)        # face toward left
    rect(px, 6, 11 + oy, 11, 12 + oy, SKIN_SH)
    rect(px, 5, 6 + oy, 13, 8 + oy, BAND)         # headband, tail to the left
    rect(px, 5, 7 + oy, 13, 8 + oy, BAND_D)
    px[3, 8 + oy] = BAND; px[4, 9 + oy] = BAND_D  # band tail flapping
    px[7, 9 + oy] = EYE                            # one eye
    rect(px, 5, 9 + oy, 6, 11 + oy, SKIN)          # little nose/chin
    return outline(im)


def main():
    sheet = Image.new("RGBA", (FW * COLS, FH * ROWS), (0, 0, 0, 0))
    rows = [draw_down, draw_side, draw_up]         # row 0 down, 1 side, 2 up
    for r, fn in enumerate(rows):
        for c in range(COLS):
            sheet.alpha_composite(fn(c), (c * FW, r * FH))
    sheet.save(os.path.normpath(OUT))
    print("wrote", os.path.normpath(OUT), sheet.size)


if __name__ == "__main__":
    main()
