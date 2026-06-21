#!/usr/bin/env python3
"""Slice the AI-generated walk sheet (ai_source.jpg) into chef_sheet.png.

The AI sheet is 4 columns (walk frames) x 3 rows, but only drew:
  row0 = facing DOWN, row1 = facing LEFT (side), row2 = (another left).
So we build the game sheet as DOWN / SIDE-left / UP, reusing the front
frames for UP (the AI gave no back view). Background (black) is removed by
flood-fill from each cell's border, preserving dark hair/eyes inside.
"""
from PIL import Image, ImageFilter
from collections import deque
import numpy as np
import os

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, "ai_source.jpg")
OUT = os.path.normpath(os.path.join(HERE, "..", "chef_sheet.png"))

# source grid: 4x4 cells.  AI rows: 0=DOWN, 1=UP(back), 2=LEFT, 3=RIGHT
X0, Y0, CW, CH = 81, 40, 159, 179
TH = 78                       # brightness (r+g+b) below this = black background

# keep the frames near the on-screen size (avoids a blurry shrink-then-upscale)
FW, FH = 52, 68               # output frame cell
CHAR_H = 64                   # scale each character to this height


def cut(im, bright, r, c):
    cx, cy = X0 + c * CW, Y0 + r * CH
    cell = im.crop((cx, cy, cx + CW, cy + CH)).convert("RGBA")
    b = bright[cy:cy + CH, cx:cx + CW]
    H, W = b.shape
    bg = np.zeros((H, W), bool)
    dq = deque()
    for x in range(W):
        for yy in (0, H - 1):
            if b[yy, x] < TH and not bg[yy, x]:
                bg[yy, x] = True; dq.append((yy, x))
    for y in range(H):
        for xx in (0, W - 1):
            if b[y, xx] < TH and not bg[y, xx]:
                bg[y, xx] = True; dq.append((y, xx))
    while dq:
        y, x = dq.popleft()
        for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            ny, nx = y + dy, x + dx
            if 0 <= ny < H and 0 <= nx < W and not bg[ny, nx] and b[ny, nx] < TH:
                bg[ny, nx] = True; dq.append((ny, nx))
    alpha = np.where(bg, 0, 255).astype("uint8")
    cell.putalpha(Image.fromarray(alpha, "L"))
    bb = cell.getbbox()
    cell = cell.crop(bb)
    # scale to CHAR_H, center horizontally, feet at the bottom of FWxFH
    w, h = cell.size
    nw = max(1, round(w * CHAR_H / h))
    cell = cell.resize((nw, CHAR_H), Image.LANCZOS)
    cell = cell.filter(ImageFilter.UnsharpMask(radius=1.2, percent=110, threshold=2))
    frame = Image.new("RGBA", (FW, FH), (0, 0, 0, 0))
    frame.alpha_composite(cell, ((FW - nw) // 2, FH - CHAR_H))
    return frame


def main():
    im = Image.open(SRC).convert("RGB")
    bright = np.asarray(im).astype(int).sum(2)
    # game sheet rows: 0=DOWN, 1=SIDE-left, 2=UP — right is mirrored in code
    sheet = Image.new("RGBA", (FW * 4, FH * 3), (0, 0, 0, 0))
    for c in range(4):
        sheet.alpha_composite(cut(im, bright, 0, c), (c * FW, 0 * FH))   # DOWN  ← AI row0
        sheet.alpha_composite(cut(im, bright, 2, c), (c * FW, 1 * FH))   # LEFT  ← AI row2
        sheet.alpha_composite(cut(im, bright, 1, c), (c * FW, 2 * FH))   # UP    ← AI row1 (back)
    sheet.save(OUT)
    print("wrote", OUT, sheet.size)


if __name__ == "__main__":
    main()
