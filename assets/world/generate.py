#!/usr/bin/env python3
"""Procedurally generate the RAMEN-YA overworld pixel-art assets.

Ground tiles are 16x16 (tileable, opaque); trees and the shop building are
RGBA objects. Crisp under Godot's nearest filter. Regenerate with:

    python3 assets/world/generate.py
"""
from PIL import Image
import os

OUT = os.path.dirname(os.path.abspath(__file__))
S = 16


def nz(x, y, s=0):
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


def disc(px, x, y, cx, cy, rx, ry):
    nxv = (x - cx) / rx
    nyv = (y - cy) / ry
    return nxv * nxv + nyv * nyv


# --------------------------------------------------------------- grass
def grass(flowers=False):
    base = (78, 138, 60, 255)
    light = (96, 162, 74, 255)
    dark = (62, 114, 48, 255)
    blade = (118, 186, 90, 255)
    im = img()
    px = im.load()
    for y in range(S):
        for x in range(S):
            v = nz(x, y, 11)
            c = base
            if v > 0.86:
                c = light
            elif v < 0.14:
                c = dark
            if nz(x, y, 12) > 0.93:
                c = blade
            # soft darker clumps
            if nz(x // 4, y // 4, 13) > 0.8:
                c = lerp(c, dark, 0.4)
            px[x, y] = c
    if flowers:
        _flower(px, 5, 6, (240, 214, 84, 255), (250, 240, 170, 255))
        _flower(px, 11, 10, (226, 108, 156, 255), (250, 224, 236, 255))
    return im


def _flower(px, cx, cy, petal, core):
    for dx, dy in ((0, -1), (0, 1), (-1, 0), (1, 0)):
        px[cx + dx, cy + dy] = petal
    px[cx, cy] = core


# ---------------------------------------------------------------- path
def path():
    base = (176, 132, 86, 255)
    light = (196, 156, 108, 255)
    dark = (143, 104, 64, 255)
    stone = (120, 90, 56, 255)
    im = img()
    px = im.load()
    for y in range(S):
        for x in range(S):
            v = nz(x, y, 21)
            c = base
            if v > 0.85:
                c = light
            elif v < 0.2:
                c = dark
            if nz(x, y, 22) > 0.93:
                c = stone
            px[x, y] = c
    return im


# ---------------------------------------------------------------- sand
def sand():
    base = (220, 200, 138, 255)
    light = (236, 220, 164, 255)
    dark = (200, 176, 116, 255)
    im = img()
    px = im.load()
    for y in range(S):
        for x in range(S):
            v = nz(x, y, 41)
            c = base
            if v > 0.85:
                c = light
            elif v < 0.18:
                c = dark
            px[x, y] = c
    return im


# --------------------------------------------------------------- water
def water():
    base = (59, 109, 176, 255)
    hi = (92, 142, 210, 255)
    deep = (46, 86, 150, 255)
    foam = (170, 205, 235, 255)
    im = img()
    px = im.load()
    for y in range(S):
        for x in range(S):
            v = nz(x, y, 31)
            c = base
            if v < 0.2:
                c = deep
            if y in (3, 4) and nz(x, y, 32) > 0.45:
                c = hi
            if y in (10, 11) and nz(x, y, 33) > 0.5:
                c = hi
            if (y == 3 or y == 10) and nz(x, y, 34) > 0.8:
                c = foam
            px[x, y] = c
    return im


# ---------------------------------------------------------------- tree
def tree():
    trunk = (107, 74, 43, 255)
    trunk_d = (84, 56, 32, 255)
    leaf = (47, 122, 62, 255)
    leaf_d = (35, 96, 48, 255)
    leaf_hi = (78, 168, 92, 255)
    W, H = 28, 36
    im = img(W, H)
    px = im.load()
    # trunk
    for y in range(25, H):
        for x in range(12, 17):
            px[x, y] = trunk_d if x >= 15 else trunk
    # canopy: a main blob + a top bump
    cx, cy = 14, 14
    for y in range(0, 28):
        for x in range(0, W):
            d_main = disc(px, x, y, cx, cy, 13, 12)
            d_top = disc(px, x, y, cx, 8, 8, 7)
            d = min(d_main, d_top)
            if d <= 1.0:
                c = leaf
                if d > 0.78:
                    c = leaf_d                       # rim shade
                elif y < cy - 2 and x < cx + 2:
                    c = leaf_hi                      # sunlit upper-left
                elif y > cy + 3 or x > cx + 5:
                    c = leaf_d
                v = nz(x, y, 51)
                if v > 0.88:
                    c = leaf_hi
                elif v < 0.12:
                    c = leaf_d
                px[x, y] = c
    return im


# ---------------------------------------------------- shop building
def shop():
    wall = (200, 160, 106, 255)
    wall_d = (160, 124, 76, 255)
    wall_hi = (220, 184, 130, 255)
    roof = (198, 64, 64, 255)
    roof_d = (156, 46, 46, 255)
    roof_hi = (224, 96, 96, 255)
    door = (78, 50, 30, 255)
    door_d = (44, 28, 18, 255)
    noren = (210, 72, 72, 255)
    win = (250, 214, 130, 255)
    win_d = (120, 92, 50, 255)
    sign = (34, 28, 40, 255)
    sign_b = (96, 74, 46, 255)
    W, H = 96, 84
    im = img(W, H)
    px = im.load()

    # --- roof: a red hip roof, eaves overhanging the walls ---
    top_l, top_r, top_y = 30, 66, 10
    bot_l, bot_r, bot_y = 1, 95, 62
    for y in range(top_y, bot_y):
        t = (y - top_y) / float(bot_y - top_y)
        xl = int(round(lerp((top_l,), (bot_l,), t)[0]))
        xr = int(round(lerp((top_r,), (bot_r,), t)[0]))
        for x in range(xl, xr + 1):
            c = roof
            if (y - top_y) % 6 == 0:
                c = roof_d                            # tile courses
            if x <= xl + 1 or y < top_y + 2:
                c = roof_hi                           # left/top sheen
            elif x >= xr - 1:
                c = roof_d
            if y >= bot_y - 3:
                c = roof_d                            # eaves shadow
            px[x, y] = c

    # --- wall + door (bottom strip = footprint row 3) ---
    for y in range(64, H):
        for x in range(4, 92):
            c = wall
            if y == 64:
                c = wall_hi
            elif y >= H - 2:
                c = wall_d
            elif nz(x, y, 61) < 0.15:
                c = wall_d
            px[x, y] = c
    # windows
    for wx in (14, 70):
        for y in range(68, 78):
            for x in range(wx, wx + 12):
                px[x, y] = win if (4 < (x - wx) < 11 and 1 < (y - 68) < 9) else win_d
    # door (centred under the sign)
    for y in range(66, H):
        for x in range(40, 56):
            px[x, y] = door_d if (x == 40 or x == 55 or y >= H - 2) else door
    for y in range(66, 71):                            # noren over the doorway
        for x in range(40, 56):
            if x != 47 and x != 48:
                px[x, y] = noren

    # --- signboard at the top centre (text drawn by Godot over it) ---
    for y in range(2, 16):
        for x in range(33, 63):
            px[x, y] = sign_b if (x < 35 or x > 60 or y < 4 or y > 13) else sign
    return im


def main():
    save(grass(False), "grass.png")
    save(grass(True), "grass2.png")
    save(path(), "path.png")
    save(sand(), "sand.png")
    save(water(), "water.png")
    save(tree(), "tree.png")
    save(shop(), "shop.png")


if __name__ == "__main__":
    main()
