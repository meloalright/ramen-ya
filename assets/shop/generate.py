#!/usr/bin/env python3
"""Procedurally generate the RAMEN-YA shop-interior pixel-art tileset.

All tiles are authored at native 16x16 (objects use RGBA alpha) so they stay
crisp under Godot's nearest-neighbour filter. Re-run to regenerate:

    python3 assets/shop/generate.py
"""
from PIL import Image
import os

OUT = os.path.dirname(os.path.abspath(__file__))
S = 16


def nz(x, y, s=0):
    """deterministic value noise in [0,1)."""
    h = (x * 73856093) ^ (y * 19349663) ^ (s * 83492791)
    h &= 0xFFFFFFFF
    return ((h * 2654435761) & 0xFFFFFFFF) / 0xFFFFFFFF


def lerp(a, b, t):
    return tuple(int(round(a[i] + (b[i] - a[i]) * t)) for i in range(len(a)))


def img(w=S, h=S):
    return Image.new("RGBA", (w, h), (0, 0, 0, 0))


def save(im, name):
    im.save(os.path.join(OUT, name))
    print("wrote", name, im.size)


# ---------------------------------------------------------------- floor
def floor():
    base = (138, 92, 50, 255)
    light = (164, 114, 66, 255)
    dark = (112, 72, 38, 255)
    seam = (84, 52, 26, 255)
    knot = (96, 60, 30, 255)
    im = img()
    px = im.load()
    for y in range(S):
        for x in range(S):
            v = nz(x, y, 1)
            c = base
            r = y % 8
            if r == 0:
                c = seam
            elif r == 1:
                c = light if v > 0.45 else base
            elif r == 7:
                c = dark
            else:
                if v > 0.84:
                    c = light
                elif v < 0.16:
                    c = dark
            # occasional vertical board joint
            if x == (4 if (y // 8) % 2 == 0 else 12) and r != 0:
                c = lerp(c, seam, 0.5)
            # a knot
            if (x, y) in ((11, 3), (5, 11)):
                c = knot
            px[x, y] = c
    return im


# ----------------------------------------------------------------- wall
def wall():
    base = (58, 42, 28, 255)
    light = (80, 60, 40, 255)
    dark = (40, 28, 18, 255)
    cap = (104, 78, 48, 255)
    cap_d = (66, 46, 28, 255)
    im = img()
    px = im.load()
    for y in range(S):
        for x in range(S):
            v = nz(x, y, 2)
            if y < 3:
                c = cap if y < 2 else cap_d        # wainscot rail on top
            else:
                c = base
                if x % 8 == 0:
                    c = dark                       # vertical panel groove
                elif x % 8 == 1:
                    c = light
                elif v > 0.86:
                    c = light
                elif v < 0.14:
                    c = dark
            px[x, y] = c
    return im


# -------------------------------------------------------------- counter
def counter():
    base = (208, 164, 98, 255)
    light = (234, 198, 134, 255)
    dark = (170, 126, 68, 255)
    edge = (120, 84, 44, 255)
    edge_d = (92, 62, 32, 255)
    im = img()
    px = im.load()
    for y in range(S):
        for x in range(S):
            v = nz(x, y, 3)
            if y <= 1:
                c = light                          # polished highlight
            elif y >= 13:
                c = edge if y == 13 else edge_d    # front lip / apron
            else:
                c = base
                if v > 0.82:
                    c = light
                elif v < 0.18:
                    c = dark
            px[x, y] = c
    return im


# ------------------------------------------------------ kitchen / stove
def kitchen():
    wall_c = (52, 46, 58, 255)
    metal = (120, 118, 132, 255)
    metal_d = (74, 70, 84, 255)
    inset = (40, 36, 48, 255)
    ring = (210, 110, 40, 255)
    hot = (248, 200, 90, 255)
    im = img()
    px = im.load()
    for y in range(S):
        for x in range(S):
            if y < 4:
                c = wall_c                         # tiled back wall
                if (x + y) % 4 == 0:
                    c = lerp(wall_c, metal_d, 0.4)
            else:
                # steel stove top with a dark inset pan well
                c = metal if y == 4 else metal_d
                if 2 <= x <= 13 and 6 <= y <= 14:
                    c = inset
                # burner flame
                dx, dy = x - 8, y - 10
                d2 = dx * dx + dy * dy
                if d2 <= 9:
                    c = hot if d2 <= 2 else ring
            px[x, y] = c
    return im


# ----------------------------------------------------------- table top
def table():
    base = (150, 98, 52, 255)
    light = (182, 128, 74, 255)
    dark = (110, 68, 34, 255)
    rim = (200, 146, 88, 255)
    im = img()
    px = im.load()
    for y in range(S):
        for x in range(S):
            if y < 2:
                continue                            # transparent gap above table
            v = nz(x, y, 4)
            if y == 2:
                c = rim                             # bright front-lit rim
            elif y >= 14:
                c = dark                            # shadowed front edge
            else:
                c = base
                if v > 0.84:
                    c = light
                elif v < 0.16:
                    c = dark
            px[x, y] = c
    # soft contact shadow stripe at the very bottom
    for x in range(1, S - 1):
        r, g, b, a = px[x, S - 1]
        px[x, S - 1] = (r, g, b, 255)
    return im


# --------------------------------------------------------------- chair
def chair():
    seat = (122, 74, 40, 255)
    seat_hi = (154, 100, 56, 255)
    seat_lo = (92, 54, 28, 255)
    leg = (72, 44, 22, 255)
    im = img()
    px = im.load()
    # round seat
    cx, cy, rx, ry = 8, 7, 5, 3
    for y in range(S):
        for x in range(S):
            nxv = (x - cx) / rx
            nyv = (y - cy) / ry
            if nxv * nxv + nyv * nyv <= 1.0:
                c = seat
                if y <= cy - 1:
                    c = seat_hi
                elif y >= cy + 2:
                    c = seat_lo
                px[x, y] = c
    # backrest
    for y in range(2, 5):
        for x in range(6, 11):
            px[x, y] = seat_lo
    # legs
    for lx in (5, 10):
        for y in range(10, 14):
            px[lx, y] = leg
            px[lx + 1, y] = leg
    return im


# ---------------------------------------------------------------- bowl
def bowl():
    body = (238, 234, 222, 255)
    body_sh = (206, 198, 182, 255)
    rim = (198, 62, 62, 255)
    broth = (198, 130, 62, 255)
    noodle = (240, 226, 178, 255)
    egg = (246, 198, 98, 255)
    egg_y = (224, 132, 60, 255)
    nori = (38, 60, 48, 255)
    negi = (122, 202, 92, 255)
    steam = (255, 255, 255, 120)
    im = img()
    px = im.load()
    cx, cy, rx, ry = 8, 9, 6, 4
    for y in range(S):
        for x in range(S):
            nxv = (x - cx) / rx
            nyv = (y - cy) / ry
            if nxv * nxv + nyv * nyv <= 1.0:
                c = body
                if y <= cy - 2:
                    c = broth                       # broth surface
                elif y >= cy + 2:
                    c = body_sh
                px[x, y] = c
    # rim
    for x in range(cx - rx, cx + rx + 1):
        if 0 <= x < S:
            px[x, cy - ry] = rim
            px[x, cy - ry + 1] = rim
    # toppings on the broth
    for x in range(5, 9):
        px[x, cy - 2] = noodle
    px[10, cy - 2] = egg
    px[11, cy - 2] = egg_y
    px[6, cy - 1] = nori
    px[8, cy - 1] = negi
    # steam
    px[6, 1] = steam
    px[7, 2] = steam
    px[9, 1] = steam
    px[10, 3] = steam
    return im


# ----------------------------------------------------------- exit door
def door():
    frame = (70, 46, 26, 255)
    frame_hi = (98, 68, 40, 255)
    opening = (26, 20, 16, 255)
    noren = (198, 62, 62, 255)
    noren_d = (152, 42, 42, 255)
    sign = (244, 240, 230, 255)
    im = img()
    px = im.load()
    for y in range(S):
        for x in range(S):
            if x <= 1 or x >= S - 2:
                px[x, y] = frame_hi if x <= 1 else frame
            else:
                px[x, y] = opening
    # red noren curtain across the top, split in the middle
    for y in range(1, 8):
        for x in range(2, S - 2):
            if x == 8:
                continue                            # split gap
            px[x, y] = noren if y < 6 else noren_d
    for x in range(4, 7):
        px[x, 3] = sign                             # tiny sign mark
    return im


# ------------------------------------------------------ paper lantern
def lantern():
    red = (206, 52, 52, 255)
    red_d = (150, 32, 32, 255)
    red_hi = (236, 96, 96, 255)
    cap = (38, 28, 22, 255)
    glow = (250, 212, 124, 255)
    im = img()
    px = im.load()
    cx, rx, ry = 8, 5, 6
    cy = 9
    for y in range(S):
        for x in range(S):
            nxv = (x - cx) / rx
            nyv = (y - cy) / ry
            if nxv * nxv + nyv * nyv <= 1.0:
                c = red
                if x <= cx - 2:
                    c = red_hi
                elif x >= cx + 2:
                    c = red_d
                if x == cx:
                    c = glow                        # lit centre seam
                px[x, y] = c
    # caps + string
    for x in range(cx - 2, cx + 3):
        px[x, cy - ry] = cap
        px[x, cy + ry] = cap
    px[cx, 0] = cap
    px[cx, 1] = cap
    return im


def main():
    save(floor(), "floor.png")
    save(wall(), "wall.png")
    save(counter(), "counter.png")
    save(kitchen(), "kitchen.png")
    save(table(), "table.png")
    save(chair(), "chair.png")
    save(bowl(), "bowl.png")
    save(door(), "door.png")
    save(lantern(), "lantern.png")


if __name__ == "__main__":
    main()
