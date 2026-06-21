#!/usr/bin/env python3
"""Anime (日漫) hero walk spritesheet -> chef_sheet.png (208x204, 52x68 cells).
Less chibi: smaller egg-shaped head with a pointed chin, slim elongated body,
big tall anime eyes, flowing spiky hair. Rows: 0 front, 1 side-left, 2 back.
"""
import os
import io
import cairosvg
from PIL import Image

OUT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "chef_sheet.png"))
FW, FH = 52, 68
INK = "#2a2230"
SKIN, SKIN_D = "#f6cea6", "#e3ad84"
HAIR, HAIR_D = "#eef1f7", "#c9d2e2"
SHIRT = "#ffffff"
SHORT = "#39406e"
SHOE = "#f4f6fa"
EYE = "#241c30"
IRIS = "#3f7bbd"
BLUSH = "#f5a0a0"
CX = 26

PHASES = [dict(leg=0, arm=0, bob=0), dict(leg=1, arm=1, bob=-1),
          dict(leg=0, arm=0, bob=0), dict(leg=-1, arm=-1, bob=-1)]


def to_png(body):
    body = f'<g transform="translate(0,3)">{body}</g>'   # sit a touch lower so hair fits
    data = cairosvg.svg2png(
        bytestring=f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {FW} {FH}">{body}</svg>'.encode(),
        output_width=FW, output_height=FH)
    return Image.open(io.BytesIO(data)).convert("RGBA")


def hair(top, back=False):
    cx = CX
    spikes = (f"L{cx-9} {top+4} L{cx-6} {top-4} L{cx-3} {top} L{cx} {top-5} "
              f"L{cx+3} {top-1} L{cx+6} {top-4} L{cx+9} {top+4}")
    if back:
        return (f'<path d="M{cx-9} {top+4} {spikes} L{cx+9} {top+14} '
                f'Q{cx} {top+10} {cx-9} {top+14} Z" fill="{HAIR}" stroke="{INK}" '
                f'stroke-width="1.6" stroke-linejoin="round"/>')
    # lighter bangs: short side-locks + a tidy fringe above the eyes
    bangs = (f"L{cx+9} {top+13} L{cx+6} {top+9} L{cx+3} {top+11} L{cx} {top+8} "
             f"L{cx-3} {top+11} L{cx-6} {top+9} L{cx-9} {top+13}")
    path = (f'<path d="M{cx-9} {top+4} {spikes} {bangs} Z" fill="{HAIR}" '
            f'stroke="{INK}" stroke-width="1.6" stroke-linejoin="round"/>')
    shade = f'<path d="M{cx-6} {top+1} q6 2.5 12 0" fill="none" stroke="{HAIR_D}" stroke-width="1.1" stroke-linecap="round"/>'
    return path + shade


def legs(out, s, b):
    lY, rY = 60 + s, 60 - s
    out.append(f'<rect x="21" y="48" width="4.6" height="{lY-48}" fill="{SKIN}" stroke="{INK}" stroke-width="1.6"/>')
    out.append(f'<rect x="26.4" y="48" width="4.6" height="{rY-48}" fill="{SKIN}" stroke="{INK}" stroke-width="1.6"/>')
    out.append(f'<rect x="19" y="{lY-2}" width="9" height="5" rx="2.3" fill="{SHOE}" stroke="{INK}" stroke-width="1.6"/>')
    out.append(f'<rect x="24" y="{rY-2}" width="9" height="5" rx="2.3" fill="{SHOE}" stroke="{INK}" stroke-width="1.6"/>')
    out.append(f'<rect x="18" y="{42+b}" width="16" height="9" rx="2.5" fill="{SHORT}" stroke="{INK}" stroke-width="1.9"/>')


def front(ph, back=False):
    b, s, a = ph["bob"], ph["leg"] * 2, ph["arm"] * 2
    cx = CX
    out = []
    legs(out, s, b)
    # arms (slim)
    out.append(f'<rect x="14.5" y="{27+b+a}" width="4.2" height="14" rx="2.1" fill="{SHIRT}" stroke="{INK}" stroke-width="1.7"/>')
    out.append(f'<rect x="33.3" y="{27+b-a}" width="4.2" height="14" rx="2.1" fill="{SHIRT}" stroke="{INK}" stroke-width="1.7"/>')
    out.append(f'<circle cx="16.6" cy="{41+b+a}" r="2.1" fill="{SKIN}" stroke="{INK}" stroke-width="1.4"/>')
    out.append(f'<circle cx="35.4" cy="{41+b-a}" r="2.1" fill="{SKIN}" stroke="{INK}" stroke-width="1.4"/>')
    # slim torso
    out.append(f'<path d="M18 {28+b} Q18 {25+b} 22 {25+b} H30 Q34 {25+b} 34 {28+b} V43 H18 Z" fill="{SHIRT}" stroke="{INK}" stroke-width="1.9"/>')
    out.append(f'<rect x="23.6" y="{22+b}" width="4.8" height="4" fill="{SKIN}" stroke="{INK}" stroke-width="1.5"/>')
    # egg head with pointed chin
    ht = 3 + b
    out.append(f'<path d="M{cx-8} {ht+6} Q{cx-9} {ht} {cx} {ht} Q{cx+9} {ht} {cx+8} {ht+6} '
               f'Q{cx+7} {ht+15} {cx} {ht+19} Q{cx-7} {ht+15} {cx-8} {ht+6} Z" '
               f'fill="{SKIN}" stroke="{INK}" stroke-width="1.9"/>')
    if not back:
        out.append(f'<ellipse cx="{cx-6}" cy="{ht+14}" rx="1.7" ry="1.1" fill="{BLUSH}" opacity="0.6"/>'
                   f'<ellipse cx="{cx+6}" cy="{ht+14}" rx="1.7" ry="1.1" fill="{BLUSH}" opacity="0.6"/>')
        for ex in (cx - 4, cx + 4):
            out.append(f'<path d="M{ex-2.4} {ht+11} Q{ex} {ht+9} {ex+2.4} {ht+11} '
                       f'L{ex+2.2} {ht+15} Q{ex} {ht+16.5} {ex-2.2} {ht+15} Z" fill="#ffffff" stroke="{INK}" stroke-width="1.2"/>')
            out.append(f'<ellipse cx="{ex}" cy="{ht+13}" rx="1.9" ry="3" fill="{IRIS}"/>')
            out.append(f'<circle cx="{ex}" cy="{ht+13.5}" r="1.1" fill="{EYE}"/>')
            out.append(f'<circle cx="{ex-0.7}" cy="{ht+11.5}" r="0.9" fill="#ffffff"/>')
        out.append(f'<path d="M{cx-6} {ht+8} q2.5 -1.2 4.5 0 M{cx+1.5} {ht+8} q2.5 -1.2 4.5 0" '
                   f'fill="none" stroke="{INK}" stroke-width="1.1" stroke-linecap="round"/>')
        out.append(f'<path d="M{cx-1} {ht+17.5} q1 1 2 0" fill="none" stroke="{INK}" stroke-width="1.1" stroke-linecap="round"/>')
    out.append(hair(ht, back))
    return "".join(out)


def side(ph):
    b, dx, a = ph["bob"], ph["leg"] * 3, ph["arm"] * 3
    cx = CX
    out = []
    # legs (front/back stride)
    out.append(f'<rect x="{24-dx}" y="48" width="4.6" height="12" fill="{SKIN_D}" stroke="{INK}" stroke-width="1.6"/>')
    out.append(f'<rect x="{21-dx}" y="58" width="9" height="5" rx="2.3" fill="{HAIR_D}" stroke="{INK}" stroke-width="1.6"/>')
    out.append(f'<rect x="{23+dx}" y="48" width="4.6" height="12" fill="{SKIN}" stroke="{INK}" stroke-width="1.6"/>')
    out.append(f'<rect x="{20+dx}" y="58" width="10" height="5" rx="2.3" fill="{SHOE}" stroke="{INK}" stroke-width="1.6"/>')
    out.append(f'<rect x="21" y="{42+b}" width="11" height="9" rx="2.5" fill="{SHORT}" stroke="{INK}" stroke-width="1.9"/>')
    out.append(f'<path d="M22 {28+b} Q22 {25+b} 26 {25+b} Q31 {25+b} 31 {28+b} V43 H22 Z" fill="{SHIRT}" stroke="{INK}" stroke-width="1.9"/>')
    out.append(f'<rect x="{24+a}" y="{28+b}" width="4.4" height="13" rx="2.1" fill="{SHIRT}" stroke="{INK}" stroke-width="1.7"/>')
    out.append(f'<circle cx="{26.2+a}" cy="{41+b}" r="2.1" fill="{SKIN}" stroke="{INK}" stroke-width="1.4"/>')
    # head (egg, facing left)
    ht = 3 + b
    out.append(f'<path d="M{cx-9} {ht+8} Q{cx-9} {ht} {cx} {ht} Q{cx+8} {ht} {cx+8} {ht+7} '
               f'Q{cx+7} {ht+15} {cx-1} {ht+19} Q{cx-9} {ht+16} {cx-9} {ht+8} Z" '
               f'fill="{SKIN}" stroke="{INK}" stroke-width="1.9"/>')
    out.append(f'<circle cx="{cx-9}" cy="{ht+12}" r="1.6" fill="{SKIN}" stroke="{INK}" stroke-width="1.3"/>')  # nose
    out.append(f'<ellipse cx="{cx-1}" cy="{ht+15}" rx="1.5" ry="1" fill="{BLUSH}" opacity="0.6"/>')
    ex = cx - 4
    out.append(f'<path d="M{ex-2.2} {ht+11} Q{ex} {ht+9} {ex+2.2} {ht+11} L{ex+2} {ht+15} Q{ex} {ht+16.5} {ex-2} {ht+15} Z" fill="#ffffff" stroke="{INK}" stroke-width="1.2"/>')
    out.append(f'<ellipse cx="{ex+0.2}" cy="{ht+13}" rx="1.8" ry="3" fill="{IRIS}"/>')
    out.append(f'<circle cx="{ex+0.3}" cy="{ht+13.5}" r="1.1" fill="{EYE}"/>')
    out.append(f'<circle cx="{ex-0.5}" cy="{ht+11.5}" r="0.9" fill="#ffffff"/>')
    out.append(f'<path d="M{ex-2.5} {ht+8} q2.5 -1.2 4.5 0" fill="none" stroke="{INK}" stroke-width="1.1" stroke-linecap="round"/>')
    out.append(hair(ht, False))
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
