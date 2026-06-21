#!/usr/bin/env python3
"""Top-down cooking sprites (assets/cook/td_*.png) for the overhead make-ramen view."""
from PIL import Image
import math
import os

OUT = os.path.dirname(os.path.abspath(__file__))

CREAM    = (238, 232, 220, 255)
CREAM_D  = (206, 198, 182, 255)
RED      = (200, 66, 66, 255)
RED_HI   = (226, 100, 100, 255)
RED_D    = (150, 46, 46, 255)
GOLD     = (208, 150, 66, 255)
GOLD_HI  = (230, 180, 96, 255)
GOLD_D   = (174, 120, 50, 255)
NOODLE   = (244, 228, 168, 255)
NOODLE_D = (212, 192, 128, 255)
BEEF     = (170, 82, 64, 255)
BEEF_HI  = (202, 112, 90, 255)
METAL    = (118, 122, 132, 255)
METAL_D  = (78, 82, 92, 255)
METAL_HI = (160, 164, 176, 255)
WOOD     = (120, 84, 52, 255)
WOOD_D   = (96, 66, 40, 255)
OUTLINE  = (38, 30, 30, 255)


def img(s):
    return Image.new("RGBA", (s, s), (0, 0, 0, 0))


def save(im, name):
    im.save(os.path.join(OUT, name))
    print("wrote", name, im.size)


def outline(im):
    px = im.load(); w, h = im.size; src = im.copy().load()
    for y in range(h):
        for x in range(w):
            if src[x, y][3] != 0:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < w and 0 <= ny < h and src[nx, ny][3] == 255 and src[nx, ny] != OUTLINE:
                    px[x, y] = OUTLINE
                    break
    return im


def disc(px, cx, cy, r, shade):
    """fill a circle; shade(dx,dy,dist) -> color or None."""
    for y in range(int(cy - r - 1), int(cy + r + 2)):
        for x in range(int(cx - r - 1), int(cx + r + 2)):
            dx, dy = x - cx, y - cy
            d = math.hypot(dx, dy)
            if d <= r:
                c = shade(dx, dy, d / r)
                if c is not None:
                    px[x, y] = c


def td_bowl(S=128):
    im = img(S); px = im.load(); c = S / 2
    R = S / 2 - 4

    def sh(dx, dy, t):
        if t > 0.86:                      # rim ring (ceramic)
            col = RED
            if dx + dy < -R * 0.4:
                col = RED_HI
            elif dx + dy > R * 0.5:
                col = RED_D
            return col
        # interior
        col = CREAM
        if t > 0.78:
            col = CREAM_D                 # inner shadow under the rim
        return col
    disc(px, c, c, R, sh)
    return outline(im)


def td_broth(S=128):
    im = img(S); px = im.load(); c = S / 2
    R = S / 2 - 12

    def sh(dx, dy, t):
        col = GOLD
        if dx < -R * 0.2 and dy < -R * 0.2 and t < 0.7:
            col = GOLD_HI
        elif t > 0.8:
            col = GOLD_D
        return col
    disc(px, c, c, R, sh)
    return im


def td_noodles(S=128):
    im = img(S); px = im.load(); c = S / 2
    R = S / 2 - 14
    # wavy noodle strands across the nest
    for base in range(-int(R), int(R), 6):
        for x in range(int(c - R), int(c + R)):
            y = c + base + math.sin(x * 0.5) * 3
            if math.hypot(x - c, y - c) <= R:
                px[int(x), int(y)] = NOODLE
                if int(y) + 1 < S:
                    px[int(x), int(y) + 1] = NOODLE_D
    return im


def td_beef(S=128):
    im = img(S); px = im.load(); c = S / 2
    for ox, oy in ((-16, -6), (10, 8), (-2, 16)):
        for y in range(S):
            for x in range(S):
                dx = (x - (c + ox)) / 15.0
                dy = (y - (c + oy)) / 9.0
                d = dx * dx + dy * dy
                if d <= 1.0:
                    px[x, y] = BEEF_HI if (d < 0.4 and y < c + oy) else BEEF
    return im


def td_pot(liquid, hi, basket=False, S=64):
    im = img(S); px = im.load(); c = S / 2
    R = S / 2 - 3

    def sh(dx, dy, t):
        if t > 0.8:
            col = METAL
            if dx + dy < -R * 0.3:
                col = METAL_HI
            elif dx + dy > R * 0.3:
                col = METAL_D
            return col
        col = liquid
        if dx < 0 and dy < 0 and t < 0.6:
            col = hi
        return col
    disc(px, c, c, R, sh)
    if basket:
        # a noodle strainer ring dipped in
        for ang in range(0, 360, 6):
            a = math.radians(ang)
            x = c + math.cos(a) * (R - 8)
            y = c + math.sin(a) * (R - 8)
            px[int(x), int(y)] = METAL_D
    return outline(im)


def td_box(fill, hi, S=48):
    im = img(S); px = im.load(); c = S / 2
    R = S / 2 - 3
    # square-ish container with a rounded look
    for y in range(2, S - 2):
        for x in range(2, S - 2):
            edge = x <= 4 or y <= 4 or x >= S - 5 or y >= S - 5
            d = math.hypot(x - c, y - c)
            if edge and d < R + 3:
                px[x, y] = WOOD_D
            elif d < R - 1:
                col = fill
                if (x + y) % 7 == 0:
                    col = hi
                if x - c < 0 and y - c < 0 and d < R * 0.6:
                    col = hi
                px[x, y] = col
            elif d < R + 1:
                px[x, y] = WOOD
    return outline(im)


def main():
    save(td_bowl(), "td_bowl.png")
    save(td_broth(), "td_broth.png")
    save(td_noodles(), "td_noodles.png")
    save(td_beef(), "td_beef.png")
    save(td_pot(GOLD, GOLD_HI, False), "td_pot_soup.png")
    save(td_pot((210, 206, 188, 255), (234, 230, 214, 255), True), "td_pot_noodle.png")
    save(td_box(BEEF, BEEF_HI), "td_box_beef.png")
    save(td_box((143, 210, 78, 255), (176, 232, 110, 255)), "td_box_scallion.png")
    save(td_box((63, 143, 74, 255), (96, 178, 104, 255)), "td_box_cilantro.png")
    save(td_box((216, 58, 58, 255), (240, 96, 96, 255)), "td_box_chili.png")


if __name__ == "__main__":
    main()
