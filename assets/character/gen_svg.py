#!/usr/bin/env python3
"""Cartoon (SVG) hero walk spritesheet -> chef_sheet.png (208x204, 52x68 cells).
Rows: 0 front (DOWN), 1 side-left (SIDE), 2 back (UP). 4 walk frames each.
"""
import os
import io
import cairosvg
from PIL import Image

OUT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "chef_sheet.png"))
FW, FH = 52, 68
INK = "#28201c"
SKIN, SKIN_D = "#f4c9a0", "#e0ac82"
HAIR, HAIR_D = "#eef1f7", "#cdd5e3"
SHIRT, SHIRT_D = "#ffffff", "#dde2ea"
SHORT = "#39406e"
SHOE = "#f4f6fa"
EYE = "#2a2636"

PHASES = [dict(leg=0, arm=0, bob=0), dict(leg=1, arm=1, bob=-1),
          dict(leg=0, arm=0, bob=0), dict(leg=-1, arm=-1, bob=-1)]


def to_png(body):
    data = cairosvg.svg2png(
        bytestring=f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {FW} {FH}">{body}</svg>'.encode(),
        output_width=FW, output_height=FH)
    return Image.open(io.BytesIO(data)).convert("RGBA")


def hair(cx, top, back=False):
    c = HAIR
    # one organic jagged spiky shape (varied heights = tousled, not a crown)
    jag = (f"L{cx-13} {top+3} L{cx-9} {top-3} L{cx-5} {top+1} L{cx-1} {top-5} "
           f"L{cx+3} {top-1} L{cx+7} {top-4} L{cx+11} {top} L{cx+13} {top+4}")
    bottom = top + 14 if back else top + 9
    mid = top + 9 if back else top + 5
    return (f'<path d="M{cx-13} {top+8} {jag} L{cx+13} {bottom} '
            f'Q{cx} {mid} {cx-13} {top+8} Z" fill="{c}" stroke="{INK}" '
            f'stroke-width="2" stroke-linejoin="round"/>'
            f'<path d="M{cx-9} {top+4} q9 4 18 0" fill="none" stroke="{HAIR_D}" stroke-width="1.6" stroke-linecap="round"/>')


def front(ph, back=False):
    b = ph["bob"]
    s = ph["leg"] * 2
    a = ph["arm"] * 2
    cx = 26
    legL_h, legR_h = 7 + s, 7 - s
    out = []
    # legs + shoes
    out.append(f'<rect x="19" y="52" width="6" height="{legL_h}" fill="{SKIN}" stroke="{INK}" stroke-width="2"/>')
    out.append(f'<rect x="27" y="52" width="6" height="{legR_h}" fill="{SKIN}" stroke="{INK}" stroke-width="2"/>')
    out.append(f'<rect x="17" y="{52+legL_h-1}" width="10" height="6" rx="2.5" fill="{SHOE}" stroke="{INK}" stroke-width="2"/>')
    out.append(f'<rect x="25" y="{52+legR_h-1}" width="10" height="6" rx="2.5" fill="{SHOE}" stroke="{INK}" stroke-width="2"/>')
    # shorts
    out.append(f'<rect x="16" y="{44+b}" width="20" height="11" rx="3" fill="{SHORT}" stroke="{INK}" stroke-width="2.4"/>')
    # arms
    out.append(f'<rect x="12" y="{30+b+a}" width="6" height="14" rx="3" fill="{SHIRT}" stroke="{INK}" stroke-width="2.2"/>')
    out.append(f'<rect x="34" y="{30+b-a}" width="6" height="14" rx="3" fill="{SHIRT}" stroke="{INK}" stroke-width="2.2"/>')
    out.append(f'<circle cx="15" cy="{44+b+a}" r="2.6" fill="{SKIN}" stroke="{INK}" stroke-width="1.6"/>')
    out.append(f'<circle cx="37" cy="{44+b-a}" r="2.6" fill="{SKIN}" stroke="{INK}" stroke-width="1.6"/>')
    # torso
    out.append(f'<rect x="15" y="{30+b}" width="22" height="18" rx="5" fill="{SHIRT}" stroke="{INK}" stroke-width="2.4"/>')
    # head
    out.append(f'<rect x="13" y="{8+b}" width="26" height="24" rx="11" fill="{SKIN}" stroke="{INK}" stroke-width="2.4"/>')
    if not back:
        out.append(f'<circle cx="21" cy="{20+b}" r="2.4" fill="{EYE}"/><circle cx="31" cy="{20+b}" r="2.4" fill="{EYE}"/>')
        out.append(f'<path d="M23 {26+b} q3 3 6 0" fill="none" stroke="{INK}" stroke-width="1.8" stroke-linecap="round"/>')
    out.append(hair(cx, 8 + b, back))
    return "".join(out)


def side(ph):
    b = ph["bob"]
    dx = ph["leg"] * 3
    a = ph["arm"] * 3
    cx = 26
    out = []
    # back leg
    out.append(f'<rect x="{24-dx}" y="52" width="6" height="8" fill="{SKIN_D}" stroke="{INK}" stroke-width="2"/>')
    out.append(f'<rect x="{21-dx}" y="59" width="11" height="6" rx="2.5" fill="{HAIR_D}" stroke="{INK}" stroke-width="2"/>')
    # front leg
    out.append(f'<rect x="{23+dx}" y="52" width="6" height="8" fill="{SKIN}" stroke="{INK}" stroke-width="2"/>')
    out.append(f'<rect x="{20+dx}" y="59" width="12" height="6" rx="2.5" fill="{SHOE}" stroke="{INK}" stroke-width="2"/>')
    # shorts
    out.append(f'<rect x="20" y="{44+b}" width="13" height="11" rx="3" fill="{SHORT}" stroke="{INK}" stroke-width="2.4"/>')
    # torso
    out.append(f'<rect x="20" y="{30+b}" width="13" height="18" rx="5" fill="{SHIRT}" stroke="{INK}" stroke-width="2.4"/>')
    # swinging arm
    out.append(f'<rect x="{24+a}" y="{31+b}" width="6" height="13" rx="3" fill="{SHIRT}" stroke="{INK}" stroke-width="2.2"/>')
    out.append(f'<circle cx="{27+a}" cy="{44+b}" r="2.6" fill="{SKIN}" stroke="{INK}" stroke-width="1.6"/>')
    # head (facing left)
    out.append(f'<rect x="16" y="{8+b}" width="22" height="24" rx="11" fill="{SKIN}" stroke="{INK}" stroke-width="2.4"/>')
    out.append(f'<circle cx="15" cy="{21+b}" r="2.2" fill="{SKIN}" stroke="{INK}" stroke-width="1.6"/>')  # nose
    out.append(f'<circle cx="22" cy="{20+b}" r="2.4" fill="{EYE}"/>')
    out.append(hair(cx, 8 + b, False))
    return "".join(out)


def main():
    sheet = Image.new("RGBA", (FW * 4, FH * 3), (0, 0, 0, 0))
    for c in range(4):
        sheet.alpha_composite(to_png(front(PHASES[c], back=False)), (c * FW, 0))
        sheet.alpha_composite(to_png(side(PHASES[c])), (c * FW, FH))
        sheet.alpha_composite(to_png(front(PHASES[c], back=True)), (c * FW, FH * 2))
    sheet.save(OUT)
    print("wrote", OUT, sheet.size)


if __name__ == "__main__":
    main()
