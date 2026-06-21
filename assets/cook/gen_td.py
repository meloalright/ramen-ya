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


# slightly-tilted overhead: the opening is an ellipse high in the canvas,
# the bowl's front wall is visible below it.  Opening centre = (64, 50).
CX = 64.0
OY = 50.0
RX = 52.0
RY = 40.0
WALL = 22.0          # how much of the outer front wall shows
CERAMIC   = (232, 224, 210, 255)
CERAMIC_D = (196, 186, 170, 255)


def td_bowl(S=128):
    im = img(S); px = im.load()
    ry2 = RY + WALL
    for y in range(S):
        for x in range(S):
            dx = x - CX
            dy = y - OY
            t = math.sqrt((dx / RX) ** 2 + (dy / RY) ** 2)
            if t <= 1.0:                                  # the opening
                if t > 0.84:                              # rim ring
                    col = RED
                    if dx < 0 and dy < 0:
                        col = RED_HI
                    elif dy > 0:
                        col = RED_D                       # front lip in shadow
                    px[x, y] = col
                else:
                    px[x, y] = CREAM_D if t > 0.72 else CREAM
            elif dy > 0 and (dx / RX) ** 2 + (dy / ry2) ** 2 <= 1.0:
                # front outer wall (the "side" of the bowl)
                shade = dy / ry2
                px[x, y] = CERAMIC_D if shade > 0.62 else CERAMIC
    return outline(im)


def td_broth(S=128):
    im = img(S); px = im.load()
    rx, ry = RX - 4, RY - 4
    for y in range(S):
        for x in range(S):
            dx = x - CX
            dy = y - OY
            t = (dx / rx) ** 2 + (dy / ry) ** 2
            if t <= 1.0:
                col = GOLD
                if dx < 0 and dy < 0 and t < 0.6:
                    col = GOLD_HI
                elif t > 0.82:
                    col = GOLD_D
                px[x, y] = col
    return im


def td_noodles(S=128):
    im = img(S); px = im.load()
    rx, ry = RX - 6, RY - 6
    for base in range(-int(ry), int(ry), 5):
        for x in range(int(CX - rx), int(CX + rx)):
            y = OY + base + math.sin(x * 0.5) * 2.5
            if ((x - CX) / rx) ** 2 + ((y - OY) / ry) ** 2 <= 1.0:
                px[int(x), int(y)] = NOODLE
                if int(y) + 1 < S:
                    px[int(x), int(y) + 1] = NOODLE_D
    return im


def td_beef(S=128):
    im = img(S); px = im.load()
    for ox, oy in ((-14, -4), (9, 5), (-2, 12)):
        for y in range(S):
            for x in range(S):
                dx = (x - (CX + ox)) / 13.0
                dy = (y - (OY + oy)) / 8.0
                d = dx * dx + dy * dy
                if d <= 1.0:
                    px[x, y] = BEEF_HI if (d < 0.4 and y < OY + oy) else BEEF
    return im


def td_pot(liquid, hi, basket=False, S=64):
    # slight 3/4 tilt: elliptical mouth high up, metal wall showing below
    im = img(S); px = im.load()
    cx = S / 2.0; oy = 26.0; rx = 29.0; ry = 22.0; ry2 = ry + 13.0
    for y in range(S):
        for x in range(S):
            dx = x - cx; dy = y - oy
            t = math.sqrt((dx / rx) ** 2 + (dy / ry) ** 2)
            if t <= 1.0:
                if t > 0.82:                          # metal rim
                    col = METAL
                    if dx < 0 and dy < 0:
                        col = METAL_HI
                    elif dy > 0:
                        col = METAL_D
                    px[x, y] = col
                else:
                    col = liquid
                    if dx < 0 and dy < 0 and t < 0.6:
                        col = hi
                    px[x, y] = col
            elif dy > 0 and (dx / rx) ** 2 + (dy / ry2) ** 2 <= 1.0:
                px[x, y] = METAL_D if dy / ry2 > 0.55 else METAL
    # side handles at rim height
    for sgn in (-1, 1):
        hx = int(cx + sgn * (rx + 1))
        for yy in range(int(oy - 3), int(oy + 3)):
            if 0 <= hx < S and 0 <= yy < S:
                px[hx, yy] = METAL_D
    if basket:
        for ang in range(0, 360, 8):
            a = math.radians(ang)
            bx = int(cx + math.cos(a) * (rx - 8))
            by = int(oy + math.sin(a) * (ry - 6))
            if 0 <= bx < S and 0 <= by < S:
                px[bx, by] = METAL_D
    return outline(im)


def td_pot_big(S=116):
    # one big boiling pot: golden broth (湯) on the left, a noodle basket (麵)
    # on the right — both bubbling away in the same pot.
    im = img(S); px = im.load()
    cx = S / 2.0; oy = 46.0; rx = 54.0; ry = 42.0; ry2 = ry + 20.0
    for y in range(S):
        for x in range(S):
            dx = x - cx; dy = y - oy
            t = math.sqrt((dx / rx) ** 2 + (dy / ry) ** 2)
            if t <= 1.0:
                if t > 0.86:                              # metal rim
                    col = METAL
                    if dx < 0 and dy < 0:
                        col = METAL_HI
                    elif dy > 0:
                        col = METAL_D
                    px[x, y] = col
                else:
                    col = GOLD                            # broth
                    if dx < 0 and dy < 0 and t < 0.6:
                        col = GOLD_HI
                    elif t > 0.82:
                        col = GOLD_D
                    px[x, y] = col
            elif dy > 0 and (dx / rx) ** 2 + (dy / ry2) ** 2 <= 1.0:
                px[x, y] = METAL_D if dy / ry2 > 0.55 else METAL
    # noodle basket on the right half
    bx, by, br = cx + 22, oy + 1, 19.0
    for y in range(int(by - br - 1), int(by + br + 1)):
        for x in range(int(bx - br - 1), int(bx + br + 1)):
            d = math.hypot((x - bx), (y - by) / 0.82)
            if d <= br:
                if d > br - 2.0:
                    px[int(x), int(y)] = METAL_D          # basket rim
                else:
                    px[int(x), int(y)] = NOODLE if (int(y) % 3) else NOODLE_D
    # bubbles on the broth (left half)
    for cxx, cyy, r in ((cx - 26, oy - 4, 4), (cx - 16, oy + 9, 3),
                        (cx - 30, oy + 8, 3), (cx - 10, oy - 8, 3)):
        for y in range(int(cyy - r), int(cyy + r)):
            for x in range(int(cxx - r), int(cxx + r)):
                if math.hypot(x - cxx, y - cyy) <= r:
                    px[int(x), int(y)] = GOLD_HI
    # side handles
    for sgn in (-1, 1):
        hx = int(cx + sgn * (rx + 1))
        for yy in range(int(oy - 3), int(oy + 4)):
            if 0 <= hx < S and 0 <= yy < S:
                px[hx, yy] = METAL_D
    return outline(im)


def td_box(fill, hi, S=48):
    # slight 3/4 tilt: elliptical mouth, wood wall showing below
    im = img(S); px = im.load()
    cx = S / 2.0; oy = 19.0; rx = 20.0; ry = 15.0; ry2 = ry + 10.0
    for y in range(S):
        for x in range(S):
            dx = x - cx; dy = y - oy
            t = math.sqrt((dx / rx) ** 2 + (dy / ry) ** 2)
            if t <= 1.0:
                if t > 0.8:                           # wood rim
                    px[x, y] = WOOD_D if dy > 0 else WOOD
                else:
                    col = fill
                    if dx < 0 and dy < 0 and t < 0.6:
                        col = hi
                    elif (x + y) % 7 == 0:
                        col = hi
                    px[x, y] = col
            elif dy > 0 and (dx / rx) ** 2 + (dy / ry2) ** 2 <= 1.0:
                px[x, y] = WOOD_D if dy / ry2 > 0.5 else WOOD
    return outline(im)


def main():
    save(td_bowl(), "td_bowl.png")
    save(td_broth(), "td_broth.png")
    save(td_noodles(), "td_noodles.png")
    save(td_beef(), "td_beef.png")
    save(td_pot(GOLD, GOLD_HI, False), "td_pot_soup.png")
    save(td_pot((210, 206, 188, 255), (234, 230, 214, 255), True), "td_pot_noodle.png")
    save(td_pot_big(), "td_pot_big.png")
    save(td_box(BEEF, BEEF_HI), "td_box_beef.png")
    save(td_box((143, 210, 78, 255), (176, 232, 110, 255)), "td_box_scallion.png")
    save(td_box((63, 143, 74, 255), (96, 178, 104, 255)), "td_box_cilantro.png")
    save(td_box((216, 58, 58, 255), (240, 96, 96, 255)), "td_box_chili.png")


if __name__ == "__main__":
    main()
