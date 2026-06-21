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
# the ramen shop is the GROUND-FLOOR unit (底商) of a tall building.
# sprite is bottom-aligned to the footprint; SHOP_SIGN_Y is where Godot
# should draw the 拉麵 text (kept in sync with the awning valance below).
SHOP_SIGN_Y = 132


def shop():
    tower = (152, 152, 164, 255)
    tower_d = (120, 120, 134, 255)
    tower_hi = (178, 178, 190, 255)
    seam = (104, 104, 118, 255)
    win = (250, 218, 138, 255)
    win_off = (78, 92, 124, 255)
    win_fr = (58, 58, 68, 255)
    roof = (108, 108, 120, 255)
    roof_d = (82, 82, 94, 255)
    tank = (96, 96, 108, 255)
    awn = (200, 66, 66, 255)
    awn_w = (238, 232, 220, 255)
    awn_d = (150, 46, 46, 255)
    sign = (32, 26, 38, 255)
    wall = (206, 166, 110, 255)
    wall_d = (168, 130, 80, 255)
    glass = (96, 132, 144, 255)
    glass_lit = (250, 224, 150, 255)
    door = (78, 50, 30, 255)
    door_d = (44, 28, 18, 255)
    noren = (210, 72, 72, 255)
    W, H = 96, 176
    im = img(W, H)
    px = im.load()

    # ===== tower body (y 10..122) =====
    for y in range(10, 122):
        for x in range(3, W - 3):
            c = tower
            if x < 6:
                c = tower_hi
            elif x > W - 7:
                c = tower_d
            px[x, y] = c
    # parapet / flat roof
    for y in range(6, 12):
        for x in range(2, W - 2):
            px[x, y] = roof if y > 7 else roof_d
    # rooftop water tank
    for y in range(0, 7):
        for x in range(58, 74):
            px[x, y] = tank if y > 1 else roof_d

    # floors of windows, stacked upward
    wcols = [12, 41, 70]
    fy = 110
    fi = 0
    while fy > 16:
        for x in range(3, W - 3):            # floor slab line
            px[x, fy + 9] = seam
        for ci, wx in enumerate(wcols):
            lit = ((fi * 7 + ci * 5) % 3) != 0
            col = win if lit else win_off
            for y in range(fy, fy + 9):
                for x in range(wx, wx + 14):
                    if x == wx or x == wx + 13 or y == fy or y == fy + 8:
                        px[x, y] = win_fr
                    else:
                        px[x, y] = col
                px[wx + 6, y] = win_fr        # vertical mullion
        fy -= 20
        fi += 1

    # ===== ground-floor storefront (y 122..176) =====
    # awning: red/white stripes projecting over the shop front
    # (runs down to where the storefront wall begins — no transparent gap)
    for y in range(120, 136):
        for x in range(1, W - 1):
            c = awn if (x // 6) % 2 == 0 else awn_w
            if y >= 129:
                c = awn_d                     # valance shadow
            px[x, y] = c
    # dark sign plate on the valance (Godot draws 拉麵 here)
    for y in range(SHOP_SIGN_Y - 8, SHOP_SIGN_Y + 4):
        for x in range(32, 64):
            if 33 < x < 62 and SHOP_SIGN_Y - 7 < y < SHOP_SIGN_Y + 3:
                px[x, y] = sign
            else:
                px[x, y] = awn_d
    # storefront wall
    for y in range(136, H):
        for x in range(2, W - 2):
            px[x, y] = wall_d if y >= H - 2 else wall
    # display windows (warm glow), left & right of the door
    for wx0, wx1 in ((6, 38), (58, 90)):
        for y in range(140, 170):
            for x in range(wx0, wx1):
                if x == wx0 or x == wx1 - 1 or y == 140 or y == 169:
                    px[x, y] = win_fr
                else:
                    px[x, y] = glass_lit if y > 152 else glass
        for y in range(140, 170):
            px[(wx0 + wx1) // 2, y] = win_fr
    # entrance door + noren
    for y in range(150, H):
        for x in range(40, 56):
            px[x, y] = door_d if (x == 40 or x == 55 or y >= H - 2) else door
    for y in range(150, 158):
        for x in range(40, 56):
            if x != 47 and x != 48:
                px[x, y] = noren
    return im


def pavement():
    base = (178, 178, 186, 255)
    d = (150, 150, 160, 255)
    hi = (198, 198, 206, 255)
    seam = (132, 132, 142, 255)
    im = img()
    px = im.load()
    for y in range(S):
        for x in range(S):
            c = base
            v = nz(x, y, 71)
            if v > 0.85:
                c = hi
            elif v < 0.18:
                c = d
            if x == 0 or y == 0:
                c = seam                      # slab seams
            px[x, y] = c
    return im


def road():
    # a small cobblestone / flagstone street (no asphalt)
    mortar = (118, 110, 98, 255)
    shades = [(168, 158, 142, 255), (180, 170, 152, 255),
              (156, 146, 130, 255), (174, 162, 144, 255)]
    hi = (196, 186, 168, 255)
    sh = (132, 122, 108, 255)
    im = img()
    px = im.load()
    for y in range(S):
        row = y // 8
        ox = 4 if (row % 2) else 0          # offset every other course (running bond)
        for x in range(S):
            cellx = (x + ox) % 8
            celly = y % 8
            if cellx == 0 or celly == 0:    # mortar joints between stones
                px[x, y] = mortar
                continue
            sid = ((x + ox) // 8 * 3 + row * 7) % len(shades)
            c = shades[sid]
            if cellx <= 1 or celly <= 1:     # rounded top-left sheen
                c = hi
            elif cellx >= 6 or celly >= 6:   # bottom-right shade
                c = sh
            v = nz(x, y, 91)
            if v > 0.88:
                c = hi
            elif v < 0.12:
                c = sh
            px[x, y] = c
    return im


def gen_building(H, awn, awn_d, accent, tower, tower_hi, tower_d):
    """a generic store-front building of total height H (storefront = bottom 54px)."""
    W = 96
    win = (250, 218, 138, 255)
    win_off = (78, 92, 124, 255)
    win_fr = (58, 58, 68, 255)
    roof = (108, 108, 120, 255)
    roof_d = (82, 82, 94, 255)
    tank = (96, 96, 108, 255)
    awn_w = (238, 232, 220, 255)
    wall = (212, 202, 188, 255)
    wall_d = (178, 168, 154, 255)
    glass = (120, 150, 160, 255)
    glass_lit = (236, 232, 214, 255)
    door = (70, 70, 82, 255)
    door_d = (46, 46, 56, 255)
    store_top = H - 54
    im = img(W, H)
    px = im.load()
    # tower body
    for y in range(10, store_top + 2):
        for x in range(3, W - 3):
            c = tower
            if x < 6:
                c = tower_hi
            elif x > W - 7:
                c = tower_d
            px[x, y] = c
    # parapet + water tank
    for y in range(6, 12):
        for x in range(2, W - 2):
            px[x, y] = roof if y > 7 else roof_d
    for y in range(0, 7):
        for x in range(58, 74):
            px[x, y] = tank if y > 1 else roof_d
    # floors of windows
    wcols = [12, 41, 70]
    fy = store_top - 12
    fi = 0
    while fy > 16:
        for x in range(3, W - 3):
            px[x, fy + 9] = tower_d
        for ci, wx in enumerate(wcols):
            lit = ((fi * 7 + ci * 5) % 3) != 0
            col = win if lit else win_off
            for y in range(fy, fy + 9):
                for x in range(wx, wx + 14):
                    px[x, y] = win_fr if (x == wx or x == wx + 13 or y == fy or y == fy + 8) else col
                px[wx + 6, y] = win_fr
        fy -= 20
        fi += 1
    # awning
    ay = store_top
    for y in range(ay, ay + 12):
        for x in range(1, W - 1):
            c = awn if (x // 6) % 2 == 0 else awn_w
            if y >= ay + 9:
                c = awn_d
            px[x, y] = c
    # accent sign plate
    for y in range(ay + 1, ay + 9):
        for x in range(34, 62):
            px[x, y] = accent if (35 < x < 60) else awn_d
    # storefront wall (starts right where the awning ends — no gap)
    for y in range(ay + 12, H):
        for x in range(2, W - 2):
            px[x, y] = wall_d if y >= H - 2 else wall
    # display windows
    for wx0, wx1 in ((6, 38), (58, 90)):
        for y in range(ay + 18, H - 6):
            for x in range(wx0, wx1):
                if x == wx0 or x == wx1 - 1 or y == ay + 18 or y == H - 7:
                    px[x, y] = win_fr
                else:
                    px[x, y] = glass_lit if y > ay + 30 else glass
        for y in range(ay + 18, H - 6):
            px[(wx0 + wx1) // 2, y] = win_fr
    # glass door
    for y in range(ay + 22, H):
        for x in range(40, 56):
            px[x, y] = door_d if (x == 40 or x == 55 or y >= H - 2) else door
    for x in range(42, 54):
        px[x, ay + 30] = accent                 # door handle bar
    return im


def main():
    save(grass(False), "grass.png")
    save(grass(True), "grass2.png")
    save(path(), "path.png")
    save(sand(), "sand.png")
    save(water(), "water.png")
    save(tree(), "tree.png")
    save(shop(), "shop.png")
    save(pavement(), "pavement.png")
    save(road(), "road.png")
    # decorative neighbours along the commercial street
    save(gen_building(128, (74, 120, 198, 255), (52, 86, 150, 255), (120, 170, 230, 255),
                      (158, 150, 138, 255), (182, 174, 162, 255), (132, 124, 112, 255)), "bldg1.png")
    save(gen_building(150, (70, 160, 96, 255), (48, 120, 70, 255), (120, 210, 150, 255),
                      (150, 154, 160, 255), (178, 182, 188, 255), (122, 126, 132, 255)), "bldg2.png")
    save(gen_building(106, (224, 140, 56, 255), (180, 104, 40, 255), (248, 196, 120, 255),
                      (170, 160, 150, 255), (192, 184, 174, 255), (142, 132, 122, 255)), "bldg3.png")


if __name__ == "__main__":
    main()
