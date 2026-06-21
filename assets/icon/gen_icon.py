#!/usr/bin/env python3
"""Generate the iOS / app icon (opaque 1024x1024) — a bowl of ramen."""
from PIL import Image
import math
import os

OUT = os.path.dirname(os.path.abspath(__file__))
S = 1024

BG_TOP   = (214, 92, 70)      # warm red
BG_BOT   = (168, 60, 52)
RIMCOL   = (206, 70, 70)
RIM_HI   = (228, 104, 104)
RIM_D    = (158, 50, 50)
CREAM    = (236, 228, 214)
CREAM_D  = (200, 190, 174)
GOLD     = (214, 156, 70)
GOLD_HI  = (236, 186, 100)
GOLD_D   = (180, 124, 52)
NOODLE   = (246, 230, 172)
NOODLE_D = (214, 194, 132)
BEEF     = (172, 84, 66)
BEEF_HI  = (204, 114, 92)
GREEN    = (146, 212, 80)
REDCHILI = (220, 60, 60)
INK      = (40, 30, 30)


def main():
    im = Image.new("RGB", (S, S), BG_TOP)
    px = im.load()
    # vertical warm gradient background
    for y in range(S):
        f = y / S
        c = tuple(int(BG_TOP[i] * (1 - f) + BG_BOT[i] * f) for i in range(3))
        for x in range(S):
            px[x, y] = c

    cx = S / 2.0
    oy = S * 0.46
    rx = S * 0.36
    ry = rx * 0.78
    ry2 = ry + S * 0.16          # front wall depth

    def put(x, y, col):
        if 0 <= x < S and 0 <= y < S:
            px[int(x), int(y)] = col

    # bowl: opening ellipse + front wall
    for y in range(int(oy - ry - 4), int(oy + ry2 + 4)):
        for x in range(int(cx - rx - 4), int(cx + rx + 4)):
            dx = x - cx
            dy = y - oy
            t = math.sqrt((dx / rx) ** 2 + (dy / ry) ** 2)
            if t <= 1.0:
                if t > 0.9:
                    col = RIMCOL
                    if dx < 0 and dy < 0:
                        col = RIM_HI
                    elif dy > 0:
                        col = RIM_D
                    put(x, y, col)
                else:
                    # broth surface
                    col = GOLD
                    if dx < 0 and dy < 0 and t < 0.6:
                        col = GOLD_HI
                    elif t > 0.84:
                        col = GOLD_D
                    put(x, y, col)
            elif dy > 0 and (dx / rx) ** 2 + (dy / ry2) ** 2 <= 1.0:
                put(x, y, CREAM_D if dy / ry2 > 0.6 else CREAM)

    # noodle nest
    nrx, nry = rx * 0.82, ry * 0.82
    for base in range(-int(nry), int(nry), int(S * 0.022)):
        for x in range(int(cx - nrx), int(cx + nrx)):
            y = oy + base + math.sin(x * 0.05) * S * 0.018
            if ((x - cx) / nrx) ** 2 + ((y - oy) / nry) ** 2 <= 1.0:
                for k in range(int(S * 0.012)):
                    put(x, y + k, NOODLE if k < S * 0.008 else NOODLE_D)

    # beef slices
    for ox, oyy, r in ((-0.10, -0.02, 0.11), (0.07, 0.05, 0.10)):
        bcx, bcy = cx + ox * S, oy + oyy * S
        brx, bry = r * S, r * S * 0.62
        for y in range(int(bcy - bry), int(bcy + bry)):
            for x in range(int(bcx - brx), int(bcx + brx)):
                d = ((x - bcx) / brx) ** 2 + ((y - bcy) / bry) ** 2
                if d <= 1.0:
                    put(x, y, BEEF_HI if (d < 0.4 and y < bcy) else BEEF)

    # scallion + chili specks
    import random
    random.seed(7)
    for _ in range(70):
        a = random.uniform(0, 2 * math.pi)
        rr = random.uniform(0, 0.9)
        x = cx + math.cos(a) * nrx * rr
        y = oy + math.sin(a) * nry * rr
        col = GREEN if random.random() < 0.6 else REDCHILI
        s = int(S * 0.014)
        for yy in range(s):
            for xx in range(s):
                put(x + xx, y + yy, col)

    # chopsticks resting across the bowl
    for i in range(2):
        x0 = cx - rx * 0.2 + i * S * 0.05
        for s in range(int(S * 0.5)):
            xx = x0 + s * 0.55
            yy = oy - ry * 0.7 - s * 0.62
            w = int(S * 0.020)
            for a in range(w):
                for b in range(w):
                    put(xx + a, yy + b, (224, 196, 150))

    im.save(os.path.join(OUT, "icon_1024.png"))
    print("wrote icon_1024.png")


if __name__ == "__main__":
    main()
