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

# palette
CAP    = (46, 54, 96, 255)
CAP_HI = (72, 82, 126, 255)
HAIR   = (222, 218, 210, 255)
HAIR_SH= (188, 184, 176, 255)
SKIN   = (242, 202, 166, 255)
SKIN_SH= (212, 170, 134, 255)
SHIRT  = (52, 60, 102, 255)
SHIRT_HI = (72, 82, 126, 255)
APRON  = (228, 218, 196, 255)
APRON_SH = (198, 186, 162, 255)
PANTS  = (58, 54, 74, 255)
PANTS_D= (44, 40, 56, 255)
SHOE   = (96, 74, 52, 255)
EYE    = (38, 32, 44, 255)
OUT_C  = (28, 24, 36, 255)


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
    rect(px, 8 + dxl, lL - 1, 11 + dxl, lL, SHOE)
    rect(px, 10 + dxr, lR - 1, 13 + dxr, lR, SHOE)


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


def draw_down(fi):
    im = frame(); px = im.load()
    oy = -1 if fi == 0 else 0          # passing pose bobs up 1px
    legs(px, fi)
    # body
    rect(px, 6, 12 + oy, 14, 20 + oy, SHIRT)
    rect(px, 6, 12 + oy, 14, 13 + oy, SHIRT_HI)
    rect(px, 8, 14 + oy, 12, 21 + oy, APRON)      # apron front
    rect(px, 8, 19 + oy, 12, 21 + oy, APRON_SH)
    # arms + hands
    rect(px, 4, 13 + oy, 6, 18 + oy, SHIRT); rect(px, 4, 18 + oy, 6, 20 + oy, SKIN)
    rect(px, 14, 13 + oy, 16, 18 + oy, SHIRT); rect(px, 14, 18 + oy, 16, 20 + oy, SKIN)
    # head
    rect(px, 5, 6 + oy, 15, 7 + oy, CAP)          # cap brim
    rect(px, 6, 2 + oy, 14, 6 + oy, CAP)
    rect(px, 6, 2 + oy, 14, 3 + oy, CAP_HI)
    rect(px, 5, 7 + oy, 7, 11 + oy, HAIR)         # hair sides
    rect(px, 13, 7 + oy, 15, 11 + oy, HAIR)
    rect(px, 7, 7 + oy, 13, 12 + oy, SKIN)        # face
    rect(px, 7, 11 + oy, 13, 12 + oy, SKIN_SH)
    px[8, 9 + oy] = EYE; px[11, 9 + oy] = EYE     # eyes
    return outline(im)


def draw_up(fi):
    im = frame(); px = im.load()
    oy = -1 if fi == 0 else 0
    legs(px, fi, back=True)
    # back of body
    rect(px, 6, 12 + oy, 14, 20 + oy, SHIRT)
    rect(px, 6, 12 + oy, 14, 13 + oy, SHIRT_HI)
    rect(px, 8, 13 + oy, 12, 20 + oy, SHIRT_HI)   # apron strings hint
    rect(px, 4, 13 + oy, 6, 18 + oy, SHIRT); rect(px, 4, 18 + oy, 6, 20 + oy, SKIN)
    rect(px, 14, 13 + oy, 16, 18 + oy, SHIRT); rect(px, 14, 18 + oy, 16, 20 + oy, SKIN)
    # back of head: cap + hair (no face)
    rect(px, 5, 6 + oy, 15, 7 + oy, CAP)
    rect(px, 6, 2 + oy, 14, 6 + oy, CAP)
    rect(px, 6, 2 + oy, 14, 3 + oy, CAP_HI)
    rect(px, 6, 7 + oy, 14, 12 + oy, HAIR)
    rect(px, 6, 11 + oy, 14, 12 + oy, HAIR_SH)
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
    rect(px, 7, back - 1, 10, back, SHOE)
    rect(px, 9, 20, 12, front, PANTS)             # front leg
    rect(px, 9, front - 1, 13, front, SHOE)
    # body
    rect(px, 7, 12 + oy, 13, 20 + oy, SHIRT)
    rect(px, 7, 12 + oy, 13, 13 + oy, SHIRT_HI)
    rect(px, 7, 14 + oy, 9, 21 + oy, APRON)       # apron hangs at the front (left)
    # front arm swinging
    var_y = 18 if fi == 1 else (16 if fi == 2 else 17)
    rect(px, 6, 13 + oy, 8, var_y + oy, SHIRT)
    rect(px, 6, var_y + oy, 8, var_y + 2 + oy, SKIN)
    # head (profile, faces left)
    rect(px, 5, 6 + oy, 14, 7 + oy, CAP)          # brim points left
    rect(px, 6, 2 + oy, 13, 6 + oy, CAP)
    rect(px, 6, 2 + oy, 13, 3 + oy, CAP_HI)
    rect(px, 11, 7 + oy, 13, 12 + oy, HAIR)       # hair at back (right)
    rect(px, 6, 7 + oy, 11, 12 + oy, SKIN)        # face toward left
    rect(px, 6, 11 + oy, 11, 12 + oy, SKIN_SH)
    px[7, 9 + oy] = EYE                            # one eye, left side
    rect(px, 5, 8 + oy, 6, 10 + oy, SKIN)          # little nose
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
