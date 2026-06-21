#!/usr/bin/env python3
"""Procedural walk spritesheet for the hero — a cool white-haired young guy.

Layout matches what the game expects (assets/chef_sheet.png):
  4 columns (walk cycle, col0 = idle) x 3 rows (0=front, 1=side-left, 2=back)
  each frame 52x68.  Side art faces LEFT; the game mirrors it for right.
Regenerate:  python3 assets/character/gen_walk.py
"""
from PIL import Image
import os

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "chef_sheet.png")
FW, FH = 52, 68
COLS, ROWS = 4, 3

OUTLINE = (38, 34, 44, 255)
SKIN    = (242, 202, 168, 255)
SKIN_SH = (214, 166, 136, 255)
HAIR    = (236, 238, 246, 255)
HAIR_SH = (198, 204, 220, 255)
SHIRT   = (245, 247, 249, 255)
SHIRT_SH= (208, 213, 222, 255)
PANTS   = (58, 72, 112, 255)
PANTS_SH= (42, 53, 86, 255)
SHOE    = (236, 239, 244, 255)
SHOE_SH = (198, 203, 214, 255)
EYE     = (52, 52, 70, 255)
MOUTH   = (196, 150, 128, 255)


def blank():
    return Image.new("RGBA", (FW, FH), (0, 0, 0, 0))


def R(px, x0, y0, x1, y1, col):
    for y in range(int(y0), int(y1)):
        for x in range(int(x0), int(x1)):
            if 0 <= x < FW and 0 <= y < FH:
                px[x, y] = col


def outline(im):
    px = im.load()
    src = im.copy().load()
    for y in range(FH):
        for x in range(FW):
            if src[x, y][3] != 0:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1), (1, 1), (-1, -1), (1, -1), (-1, 1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < FW and 0 <= ny < FH and src[nx, ny][3] == 255 and src[nx, ny] != OUTLINE:
                    px[x, y] = OUTLINE
                    break
    return im


# walk cycle params: leg stride, arm swing, vertical bob (col0 = idle)
PHASES = [
    dict(leg=0,  arm=0,  bob=0),   # idle / contact
    dict(leg=1,  arm=1,  bob=-1),  # stride A
    dict(leg=0,  arm=0,  bob=0),   # passing
    dict(leg=-1, arm=-1, bob=-1),  # stride B
]

CX = 26


def head_front(px, top, back=False):
    # hair cap + tousled spikes (varied heights = cool, not a hat)
    R(px, 18, top + 0, 34, top + 9, HAIR)
    R(px, 17, top + 3, 35, top + 11, HAIR)
    for sx, h in ((17, 3), (20, 6), (23, 2), (26, 5), (29, 3), (31, 5)):
        R(px, sx, top + 1 - h, sx + 2, top + 2, HAIR)
        R(px, sx, top + 1 - h, sx + 1, top + 2, HAIR_SH)
    R(px, 18, top + 9, 34, top + 11, HAIR_SH)        # under-hair shadow
    # face (skin) below hair
    R(px, 19, top + 9, 33, top + 17, SKIN)
    R(px, 19, top + 15, 33, top + 17, SKIN_SH)       # jaw shadow
    if not back:
        R(px, 22, top + 12, 24, top + 14, EYE)
        R(px, 28, top + 12, 30, top + 14, EYE)
        R(px, 25, top + 15, 27, top + 16, MOUTH)
    else:
        R(px, 18, top + 4, 34, top + 13, HAIR)       # hair covers the back of head
        R(px, 19, top + 13, 33, top + 16, SKIN_SH)   # nape


def body_front(px, ph, back=False):
    bob = ph["bob"]
    base = 63 + 0
    # legs (pants) with stride + shoes
    s = ph["leg"] * 2
    # left leg
    R(px, 19, 45 + bob, 25, 58 + max(0, -s), PANTS)
    R(px, 19, 45 + bob, 21, 58, PANTS_SH)
    R(px, 18, 57 + max(0, -s), 26, 62 + max(0, -s), SHOE)
    R(px, 18, 60 + max(0, -s), 26, 62 + max(0, -s), SHOE_SH)
    # right leg
    R(px, 27, 45 + bob, 33, 58 + max(0, s), PANTS)
    R(px, 27, 45 + bob, 29, 58, PANTS_SH)
    R(px, 26, 57 + max(0, s), 34, 62 + max(0, s), SHOE)
    R(px, 26, 60 + max(0, s), 34, 62 + max(0, s), SHOE_SH)
    # torso (white tee)
    R(px, 18, 26 + bob, 34, 46 + bob, SHIRT)
    R(px, 18, 26 + bob, 20, 46 + bob, SHIRT_SH)
    R(px, 18, 43 + bob, 34, 46 + bob, SHIRT_SH)
    # neck
    R(px, 23, 24 + bob, 29, 27 + bob, SKIN)
    # arms (skin) swinging
    a = ph["arm"] * 2
    R(px, 15, 27 + bob + a, 19, 41 + bob + a, SKIN)   # left arm
    R(px, 15, 38 + bob + a, 19, 41 + bob + a, SKIN_SH)
    R(px, 33, 27 + bob - a, 37, 41 + bob - a, SKIN)   # right arm
    R(px, 33, 38 + bob - a, 37, 41 + bob - a, SKIN_SH)
    # sleeves (shirt over shoulders)
    R(px, 15, 26 + bob + a, 19, 31 + bob + a, SHIRT)
    R(px, 33, 26 + bob - a, 37, 31 + bob - a, SHIRT)


def draw_front(ph, back=False):
    im = blank()
    px = im.load()
    body_front(px, ph, back)
    head_front(px, 6 + ph["bob"], back)
    return outline(im)


def draw_side(ph):
    im = blank()
    px = im.load()
    bob = ph["bob"]
    dx = ph["leg"] * 3
    # legs: front leg (+dx) and back leg (-dx)
    R(px, 24 - dx, 45 + bob, 30 - dx, 59, PANTS_SH)        # back leg
    R(px, 22 - dx, 58, 31 - dx, 62, SHOE_SH)
    R(px, 23 + dx, 45 + bob, 29 + dx, 59, PANTS)           # front leg
    R(px, 21 + dx, 58, 31 + dx, 62, SHOE)
    R(px, 21 + dx, 60, 31 + dx, 62, SHOE_SH)
    # torso (white tee), slightly leaning
    R(px, 21, 26 + bob, 32, 46 + bob, SHIRT)
    R(px, 21, 26 + bob, 23, 46 + bob, SHIRT_SH)
    # neck + head (profile facing LEFT)
    R(px, 24, 24 + bob, 29, 27 + bob, SKIN)
    top = 6 + bob
    R(px, 20, top + 0, 32, top + 9, HAIR)                 # hair cap
    for sx, h in ((20, 3), (23, 6), (26, 3), (29, 5)):    # tousled spikes
        R(px, sx, top + 1 - h, sx + 2, top + 2, HAIR)
        R(px, sx, top + 1 - h, sx + 1, top + 2, HAIR_SH)
    R(px, 19, top + 4, 23, top + 11, HAIR)                # hair down the back
    R(px, 20, top + 9, 31, top + 17, SKIN)                # face
    R(px, 18, top + 11, 20, top + 15, SKIN)               # nose/brow bump (left)
    R(px, 21, top + 12, 23, top + 14, EYE)                # eye
    R(px, 20, top + 15, 31, top + 17, SKIN_SH)
    # one swinging arm (front)
    a = ph["arm"] * 3
    R(px, 25 + a, 27 + bob, 29 + a, 41 + bob, SKIN)
    R(px, 25 + a, 26 + bob, 29 + a, 31 + bob, SHIRT)
    R(px, 25 + a, 39 + bob, 29 + a, 41 + bob, SKIN_SH)
    return outline(im)


def main():
    sheet = Image.new("RGBA", (FW * COLS, FH * ROWS), (0, 0, 0, 0))
    for c in range(COLS):
        sheet.paste(draw_front(PHASES[c], back=False), (c * FW, 0 * FH))   # row 0 front
        sheet.paste(draw_side(PHASES[c]),              (c * FW, 1 * FH))   # row 1 side-left
        sheet.paste(draw_front(PHASES[c], back=True),  (c * FW, 2 * FH))   # row 2 back
    sheet.save(os.path.normpath(OUT))
    print("wrote", os.path.normpath(OUT), sheet.size)


if __name__ == "__main__":
    main()
