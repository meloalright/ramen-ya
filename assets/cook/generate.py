#!/usr/bin/env python3
"""Refined round pixel-art bowls/pots for the cooking counter.

Round ceramic ramen bowls (elliptical rim, red rim + white body, layered
contents) and stainless pots. RGBA, native pixel res, crisp under Godot's
nearest filter. Regenerate with:

    python3 assets/cook/generate.py
"""
from PIL import Image
import math
import os

OUT = os.path.dirname(os.path.abspath(__file__))

# ---- palette --------------------------------------------------------
CREAM    = (238, 232, 220, 255)
CREAM_D  = (202, 194, 178, 255)
CREAM_HI = (250, 246, 236, 255)
RED      = (200, 66, 66, 255)
RED_HI   = (228, 100, 100, 255)
RED_D    = (150, 46, 46, 255)
GOLD     = (208, 150, 66, 255)
GOLD_HI  = (232, 184, 100, 255)
GOLD_D   = (174, 120, 50, 255)
NOODLE   = (244, 228, 168, 255)
NOODLE_D = (212, 192, 128, 255)
BEEF     = (170, 82, 64, 255)
BEEF_HI  = (202, 112, 90, 255)
BEEF_D   = (120, 54, 44, 255)
SCAL     = (143, 210, 78, 255)
SCAL_HI  = (176, 232, 110, 255)
CIL      = (63, 143, 74, 255)
CIL_HI   = (96, 178, 104, 255)
CHILI    = (216, 58, 58, 255)
CHILI_HI = (240, 96, 96, 255)
METAL    = (122, 126, 136, 255)
METAL_D  = (82, 86, 96, 255)
METAL_HI = (170, 174, 184, 255)
OUTLINE  = (38, 30, 30, 255)


def img(w, h):
    return Image.new("RGBA", (w, h), (0, 0, 0, 0))


def save(im, name):
    im.save(os.path.join(OUT, name))
    print("wrote", name, im.size)


def ed(x, y, cx, cy, rx, ry):
    return ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2


def outline(im):
    """add a 1px dark outline around the opaque silhouette."""
    px = im.load()
    w, h = im.size
    src = im.copy().load()
    for y in range(h):
        for x in range(w):
            if src[x, y][3] != 0:
                continue
            near = False
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < w and 0 <= ny < h and src[nx, ny][3] == 255 \
                        and src[nx, ny] != OUTLINE:
                    near = True
                    break
            if near:
                px[x, y] = OUTLINE
    return im


# =====================================================================
#  BIG ASSEMBLY BOWL  (90x56) + content overlays on the same canvas
# =====================================================================
BW, BH, BCX = 90, 56, 45
RIM = (BCX, 18, 42, 12)        # cx, cy, rx, ry
INT = (BCX, 19, 35, 8)
LOW = (BCX, 20, 42, 33)
FILL = (BCX, 19, 32, 7)        # where contents live


def bowl_big():
    im = img(BW, BH)
    px = im.load()
    for y in range(BH):
        for x in range(BW):
            di = ed(x, y, *INT)
            dr = ed(x, y, *RIM)
            dl = ed(x, y, *LOW)
            if di <= 1.0:
                c = CREAM
                if y < 18:
                    c = CREAM_D
                elif y > 22:
                    c = CREAM_HI
            elif dr <= 1.0:
                c = RED
                if y < 15:
                    c = RED_HI
                elif y > 21:
                    c = RED_D
                if y <= 16 and x % 6 == 0:
                    c = CREAM                    # rim ticks (雷紋 hint)
            elif dl <= 1.0 and y > 16:
                c = CREAM
                if x < BCX - 8:
                    c = CREAM_HI
                elif x > BCX + 10:
                    c = CREAM_D
                if y >= 48:
                    c = RED_D                    # red foot ring
                elif y >= 45:
                    c = CREAM_D
            else:
                continue
            px[x, y] = c
    return outline(im)


def _fill_layer(draw):
    im = img(BW, BH)
    draw(im.load())
    return im


def b_broth():
    def d(px):
        for y in range(BH):
            for x in range(BW):
                if ed(x, y, *FILL) <= 1.0:
                    c = GOLD
                    if y < 18:
                        c = GOLD_D
                    elif ed(x, y, BCX - 8, 18, 14, 5) < 1.0:
                        c = GOLD_HI
                    px[x, y] = c
    return _fill_layer(d)


def b_noodles():
    def d(px):
        for x in range(BW):
            for base in (16, 19, 21):
                y = base + int(round(1.4 * math.sin(x * 0.55)))
                if ed(x, y, *FILL) <= 0.92:
                    px[x, y] = NOODLE
                    if y + 1 < BH and ed(x, y + 1, *FILL) <= 0.92:
                        px[x, y + 1] = NOODLE_D
    return _fill_layer(d)


def _blob(px, cx, cy, rx, ry, col, hi):
    for y in range(BH):
        for x in range(BW):
            dd = ed(x, y, cx, cy, rx, ry)
            if dd <= 1.0:
                px[x, y] = hi if (dd < 0.45 and y <= cy) else col


def b_beef():
    def d(px):
        _blob(px, BCX - 13, 18, 8, 4, BEEF, BEEF_HI)
        _blob(px, BCX - 1, 20, 8, 4, BEEF, BEEF_HI)
        for x, y in ((BCX - 16, 18), (BCX - 5, 19)):
            px[x, y] = BEEF_D
    return _fill_layer(d)


def _scatter(col, hi, spots):
    def d(px):
        for (x, y) in spots:
            if ed(x, y, *FILL) <= 0.95:
                px[x, y] = col
                px[x + 1, y] = hi
                px[x, y + 1] = hi
    return _fill_layer(d)


def b_scallion():
    return _scatter(SCAL, SCAL_HI, [(54, 16), (60, 20), (66, 17), (49, 21), (58, 23), (64, 14)])


def b_cilantro():
    return _scatter(CIL, CIL_HI, [(52, 22), (57, 15), (63, 22), (68, 18), (47, 17), (61, 18)])


def b_chili():
    return _scatter(CHILI, CHILI_HI, [(50, 15), (56, 18), (62, 16), (67, 21), (53, 23), (45, 20)])


# =====================================================================
#  SMALL STATION BOWL (30x20)
# =====================================================================
def sbowl(fill, fill_hi):
    W, H, cx = 30, 20, 15
    rim = (cx, 9, 14, 6)
    inn = (cx, 10, 11, 4)
    low = (cx, 10, 14, 10)
    im = img(W, H)
    px = im.load()
    for y in range(H):
        for x in range(W):
            di = ed(x, y, *inn)
            dr = ed(x, y, *rim)
            dl = ed(x, y, *low)
            if di <= 1.0:
                c = fill_hi if (di < 0.5 and y <= 10) else fill
            elif dr <= 1.0:
                c = RED
                if y < 7:
                    c = RED_HI
                elif y > 11:
                    c = RED_D
            elif dl <= 1.0 and y > 8:
                c = CREAM
                if x < cx - 5:
                    c = CREAM_HI
                elif x > cx + 6:
                    c = CREAM_D
                if y >= 17:
                    c = RED_D
            else:
                continue
            px[x, y] = c
    return outline(im)


# =====================================================================
#  POT (32x26)
# =====================================================================
def pot(liquid, liquid_hi, basket=False):
    W, H, cx = 32, 26, 16
    rim = (cx, 8, 14, 5)
    inn = (cx, 8, 11, 3.4)
    im = img(W, H)
    px = im.load()
    for y in range(H):
        for x in range(W):
            di = ed(x, y, *inn)
            dr = ed(x, y, *rim)
            # body silhouette: straight-ish walls with a rounded base
            in_body = (8 <= y <= 23) and ed(x, min(y, 18), cx, 12, 13.5, 12) <= 1.0
            if di <= 1.0:
                c = liquid
                if y < 8:
                    c = tuple(int(v * 0.8) for v in liquid[:3]) + (255,)
                elif di < 0.5 and x <= cx:
                    c = liquid_hi
            elif dr <= 1.0:
                c = METAL
                if y < 7:
                    c = METAL_HI
                elif y > 9:
                    c = METAL_D
            elif in_body:
                c = METAL
                if x < cx - 7:
                    c = METAL_HI
                elif x > cx + 6:
                    c = METAL_D
                if y > 19:
                    c = METAL_D
            else:
                continue
            px[x, y] = c
    # handles
    for hy in (10, 11):
        px[1, hy] = METAL_D
        px[2, hy] = METAL
        px[W - 2, hy] = METAL_D
        px[W - 3, hy] = METAL
    if basket:
        # a noodle strainer dipped in, handle going up-right
        for y in range(5, 10):
            for x in range(cx - 6, cx + 4):
                if ed(x, y, cx - 1, 8, 7, 3) <= 1.0 and ed(x, y, cx - 1, 8, 6, 2.2) >= 1.0:
                    px[x, y] = METAL_D
        for i in range(6):
            px[cx + 4 + i, 7 - i] = METAL_HI if i % 2 else METAL
    return outline(im)


# =====================================================================
#  MINI BOWL for the order bubble (18x11)
# =====================================================================
def bowl_mini():
    W, H, cx = 18, 11, 9
    rim = (cx, 5, 8, 3.4)
    inn = (cx, 5, 6, 2.2)
    low = (cx, 5, 8, 6)
    im = img(W, H)
    px = im.load()
    for y in range(H):
        for x in range(W):
            di = ed(x, y, *inn)
            dr = ed(x, y, *rim)
            dl = ed(x, y, *low)
            if di <= 1.0:
                c = GOLD if y >= 5 else GOLD_D
            elif dr <= 1.0:
                c = RED if y <= 5 else RED_D
            elif dl <= 1.0 and y > 4:
                c = CREAM if x < cx + 4 else CREAM_D
            else:
                continue
            px[x, y] = c
    return outline(im)


def main():
    save(bowl_big(), "bowl_big.png")
    save(b_broth(), "b_broth.png")
    save(b_noodles(), "b_noodles.png")
    save(b_beef(), "b_beef.png")
    save(b_scallion(), "b_scallion.png")
    save(b_cilantro(), "b_cilantro.png")
    save(b_chili(), "b_chili.png")
    save(sbowl(BEEF, BEEF_HI), "sbowl_beef.png")
    save(sbowl(SCAL, SCAL_HI), "sbowl_scallion.png")
    save(sbowl(CIL, CIL_HI), "sbowl_cilantro.png")
    save(sbowl(CHILI, CHILI_HI), "sbowl_chili.png")
    save(pot(GOLD, GOLD_HI, False), "pot_soup.png")
    save(pot((210, 206, 188, 255), (234, 230, 214, 255), True), "pot_noodle.png")
    save(bowl_mini(), "bowl_mini.png")


if __name__ == "__main__":
    main()
