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
    # sharp anime spikes across the top
    spikes = (f"L{cx-13} {top+5} L{cx-9} {top-6} L{cx-4} {top} L{cx} {top-8} "
              f"L{cx+4} {top-1} L{cx+8} {top-7} L{cx+12} {top-1} L{cx+13} {top+5}")
    if back:
        path = (f'<path d="M{cx-13} {top+5} {spikes} L{cx+13} {top+16} '
                f'Q{cx} {top+11} {cx-13} {top+16} Z" fill="{c}" stroke="{INK}" '
                f'stroke-width="2" stroke-linejoin="round"/>')
        return path
    # side-locks down the sides + a zigzag bang fringe above the eyes
    bangs = (f"L{cx+13} {top+18} L{cx+10} {top+11} L{cx+6} {top+9} L{cx+3} {top+12} "
             f"L{cx} {top+9} L{cx-3} {top+12} L{cx-6} {top+9} L{cx-10} {top+11} "
             f"L{cx-13} {top+18}")
    path = (f'<path d="M{cx-13} {top+5} {spikes} {bangs} Z" fill="{c}" '
            f'stroke="{INK}" stroke-width="2" stroke-linejoin="round"/>')
    shade = f'<path d="M{cx-8} {top+2} q8 3 16 0" fill="none" stroke="{HAIR_D}" stroke-width="1.3" stroke-linecap="round"/>'
    return path + shade


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
        # blush
        out.append(f'<ellipse cx="17.5" cy="{24+b}" rx="2" ry="1.3" fill="#f5a0a0" opacity="0.55"/>'
                   f'<ellipse cx="34.5" cy="{24+b}" rx="2" ry="1.3" fill="#f5a0a0" opacity="0.55"/>')
        # big anime eyes (iris + highlight)
        for ex in (21, 31):
            out.append(f'<ellipse cx="{ex}" cy="{21+b}" rx="2.9" ry="4" fill="#ffffff" stroke="{INK}" stroke-width="1.4"/>')
            out.append(f'<ellipse cx="{ex}" cy="{21.5+b}" rx="2.2" ry="3.2" fill="#3a6ea5"/>')
            out.append(f'<circle cx="{ex}" cy="{22+b}" r="1.3" fill="{EYE}"/>')
            out.append(f'<circle cx="{ex-0.8}" cy="{19.5+b}" r="1.1" fill="#ffffff"/>')
        # eyebrows
        out.append(f'<path d="M18 {15+b} q3 -1.4 5 0 M29 {15+b} q3 -1.4 5 0" fill="none" stroke="{INK}" stroke-width="1.3" stroke-linecap="round"/>')
        # small mouth
        out.append(f'<path d="M24.5 {27+b} q1.5 1.6 3 0" fill="none" stroke="{INK}" stroke-width="1.3" stroke-linecap="round"/>')
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
    out.append(f'<circle cx="15" cy="{22+b}" r="1.8" fill="{SKIN}" stroke="{INK}" stroke-width="1.4"/>')  # nose
    out.append(f'<ellipse cx="22.5" cy="{24+b}" rx="1.6" ry="1" fill="#f5a0a0" opacity="0.55"/>')  # blush
    # big anime eye (profile)
    out.append(f'<ellipse cx="21" cy="{21+b}" rx="2.6" ry="3.8" fill="#ffffff" stroke="{INK}" stroke-width="1.4"/>')
    out.append(f'<ellipse cx="21.4" cy="{21.5+b}" rx="1.9" ry="3" fill="#3a6ea5"/>')
    out.append(f'<circle cx="21.5" cy="{22+b}" r="1.2" fill="{EYE}"/>')
    out.append(f'<circle cx="20.6" cy="{19.5+b}" r="1" fill="#ffffff"/>')
    out.append(f'<path d="M18 {15+b} q3 -1.4 5 0" fill="none" stroke="{INK}" stroke-width="1.3" stroke-linecap="round"/>')  # brow
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
