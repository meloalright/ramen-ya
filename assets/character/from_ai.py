#!/usr/bin/env python3
"""Slice the AI-generated walk sheet (ai_source.jpg) into chef_sheet.png.

The AI sheet is a 4x4 grid on a black background.  Rows:
  0 = facing DOWN (front), 1 = facing UP (back), 2 = LEFT, 3 = RIGHT.
We build the game sheet as DOWN / SIDE-left / UP (right is mirrored in code).
Each cell is cropped around its grid centre, the black background removed by
flood-fill from the borders, then the character is bbox-cropped and scaled.
"""
from PIL import Image, ImageFilter
from collections import deque
import numpy as np
import os

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, "ai_source.jpg")
OUT = os.path.normpath(os.path.join(HERE, "..", "chef_sheet.png"))

# 4x4 grid centres (detected from the 1254x1254 sheet)
COL_C = [248, 508, 752, 1002]
ROW_C = [156, 467, 770, 1064]
CELL_W, CELL_H = 212, 284      # region cropped around each centre
TH = 80                        # brightness (r+g+b) below this = black background

FW, FH = 52, 68                # output frame cell (near on-screen size)
CHAR_H = 64                    # scale each character to this height


def cut(im, bright, r, c):
    cx0 = COL_C[c] - CELL_W // 2
    cy0 = ROW_C[r] - CELL_H // 2
    cell = im.crop((cx0, cy0, cx0 + CELL_W, cy0 + CELL_H)).convert("RGBA")
    b = bright[cy0:cy0 + CELL_H, cx0:cx0 + CELL_W]
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
    w, h = cell.size
    nw = max(1, round(w * CHAR_H / h))
    cell = cell.resize((nw, CHAR_H), Image.LANCZOS)
    cell = cell.filter(ImageFilter.UnsharpMask(radius=1.0, percent=35, threshold=3))
    frame = Image.new("RGBA", (FW, FH), (0, 0, 0, 0))
    frame.alpha_composite(cell, ((FW - nw) // 2, FH - CHAR_H))
    return frame


def main():
    im = Image.open(SRC).convert("RGB")
    bright = np.asarray(im).astype(int).sum(2)
    # game sheet rows: 0=DOWN, 1=SIDE-left, 2=UP
    sheet = Image.new("RGBA", (FW * 4, FH * 3), (0, 0, 0, 0))
    for c in range(4):
        sheet.alpha_composite(cut(im, bright, 0, c), (c * FW, 0 * FH))   # DOWN ← row0
        sheet.alpha_composite(cut(im, bright, 2, c), (c * FW, 1 * FH))   # LEFT ← row2
        sheet.alpha_composite(cut(im, bright, 1, c), (c * FW, 2 * FH))   # UP   ← row1
    sheet.save(OUT)
    print("wrote", OUT, sheet.size)


if __name__ == "__main__":
    main()
