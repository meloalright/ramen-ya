#!/usr/bin/env python3
"""Cartoon (SVG) ramen-stall backdrop for the title / menu (ramen_stall.png)."""
import os
import cairosvg

OUT = os.path.dirname(os.path.abspath(__file__))
INK = "#28201c"
W, H = 768, 512


def main():
    body = f'''
    <!-- wall -->
    <rect width="{W}" height="{H}" fill="#e7d2ab"/>
    <rect y="300" width="{W}" height="212" fill="#d8c099"/>
    <g stroke="#c9b083" stroke-width="2"><path d="M0 300 H{W} M128 300 V512 M384 300 V512 M640 300 V512 M256 406 H512"/></g>
    <!-- green noren across the top -->
    <rect x="0" y="0" width="{W}" height="120" fill="#3f8f6a" stroke="{INK}" stroke-width="4"/>
    <g stroke="{INK}" stroke-width="3.3">
      <path d="M110 120 V40 M220 120 V40 M330 120 V40 M440 120 V40 M550 120 V40 M660 120 V40"/></g>
    <!-- hanging lanterns -->
    <g>
      <path d="M120 0 V60" stroke="{INK}" stroke-width="3.3"/>
      <ellipse cx="120" cy="150" rx="42" ry="56" fill="#e2533f" stroke="{INK}" stroke-width="4"/>
      <path d="M88 150 h64" stroke="{INK}" stroke-width="2.6" opacity="0.5"/>
      <path d="M648 0 V60" stroke="{INK}" stroke-width="3.3"/>
      <ellipse cx="648" cy="150" rx="42" ry="56" fill="#e2533f" stroke="{INK}" stroke-width="4"/>
      <path d="M616 150 h64" stroke="{INK}" stroke-width="2.6" opacity="0.5"/></g>
    <!-- big steaming stock pot -->
    <g fill="none" stroke="#ffffff" stroke-width="7.3" stroke-linecap="round" opacity="0.6">
      <path d="M250 250 q-26 -34 0 -68 q26 -34 0 -68"/>
      <path d="M320 250 q26 -34 0 -68 q-26 -34 0 -68"/></g>
    <ellipse cx="290" cy="330" rx="118" ry="92" fill="#8d9099" stroke="{INK}" stroke-width="5.3"/>
    <ellipse cx="290" cy="300" rx="110" ry="60" fill="#a6694a" stroke="{INK}" stroke-width="5.3"/>
    <ellipse cx="290" cy="300" rx="92" ry="46" fill="#eaa43e"/>
    <path d="M198 300 a92 46 0 0 0 184 0 a92 46 0 0 1 -184 0" fill="#d18b2c"/>
    <!-- a couple of ramen bowls on the right -->
    {bowl(560,300)}{bowl(660,330,0.8)}
    <!-- wooden counter -->
    <rect x="0" y="430" width="{W}" height="82" fill="#a9743f" stroke="{INK}" stroke-width="5.3"/>
    <rect x="0" y="430" width="{W}" height="14" fill="#c08a4e"/>
    '''
    svg = f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}">{body}</svg>'
    cairosvg.svg2png(bytestring=svg.encode(), write_to=os.path.join(OUT, "ramen_stall.png"),
                     output_width=W, output_height=H)
    print("wrote ramen_stall.png", (W, H))


def bowl(cx, cy, s=1.0):
    rx, ry = 60 * s, 30 * s
    return f'''<g>
    <path d="M{cx-rx} {cy} C{cx-rx} {cy-rx*0.7} {cx+rx} {cy-rx*0.7} {cx+rx} {cy} C{cx+rx} {cy+ry*1.6} {cx-rx} {cy+ry*1.6} {cx-rx} {cy} Z"
          fill="#dc4a44" stroke="{INK}" stroke-width="4.6"/>
    <ellipse cx="{cx}" cy="{cy}" rx="{rx}" ry="{ry}" fill="#ec6a60" stroke="{INK}" stroke-width="4.6"/>
    <ellipse cx="{cx}" cy="{cy}" rx="{rx*0.78}" ry="{ry*0.72}" fill="#eaa43e"/>
    </g>'''


def register(cx, by):
    # a shared power-bank rental kiosk standing with its base on the counter (y=by)
    slots = ""
    for r in range(3):
        for c in range(2):
            sx = cx - 44 + c * 48
            sy = by - 100 + r * 30
            slots += (
                f'<rect x="{sx}" y="{sy}" width="40" height="24" rx="3" fill="#c99f30"/>'
                f'<rect x="{sx+4}" y="{sy+4}" width="32" height="16" rx="2" fill="#f8edc0" stroke="{INK}" stroke-width="2"/>'
            )
    return f'''<g>
    <!-- all-yellow power-bank dispenser (no screen / banner) -->
    <rect x="{cx-58}" y="{by-116}" width="116" height="116" rx="12" fill="#f0bf45" stroke="{INK}" stroke-width="4"/>
    {slots}
    <!-- base -->
    <rect x="{cx-62}" y="{by-10}" width="124" height="12" rx="4" fill="#d2a233" stroke="{INK}" stroke-width="4"/>
    </g>'''


def lucky_cat(cx, by):
    # a maneki-neko sitting on the counter top (y=by)
    return f'''<g>
    <path d="M{cx-36} {by} C{cx-44} {by-78} {cx-26} {by-86} {cx} {by-86} C{cx+26} {by-86} {cx+44} {by-78} {cx+36} {by} Z" fill="#ffffff" stroke="{INK}" stroke-width="4"/>
    <ellipse cx="{cx}" cy="{by-24}" rx="22" ry="14" fill="#f2c14e" stroke="{INK}" stroke-width="3.3"/>
    <path d="M{cx-9} {by-24} h18" stroke="{INK}" stroke-width="2"/>
    <path d="M{cx-34} {by-122} l-8 -24 l26 13 Z" fill="#ffffff" stroke="{INK}" stroke-width="3.3"/>
    <path d="M{cx+34} {by-122} l8 -24 l-26 13 Z" fill="#ffffff" stroke="{INK}" stroke-width="3.3"/>
    <path d="M{cx-29} {by-127} l-4 -12 l13 7 Z" fill="#f4a6a6"/>
    <path d="M{cx+29} {by-127} l4 -12 l-13 7 Z" fill="#f4a6a6"/>
    <circle cx="{cx}" cy="{by-104}" r="37" fill="#ffffff" stroke="{INK}" stroke-width="4"/>
    <!-- raised beckoning paw (maneki-neko waving) -->
    <path d="M{cx+18} {by-46} Q{cx+52} {by-72} {cx+46} {by-108}" fill="none" stroke="{INK}" stroke-width="22" stroke-linecap="round"/>
    <path d="M{cx+18} {by-46} Q{cx+52} {by-72} {cx+46} {by-108}" fill="none" stroke="#ffffff" stroke-width="15" stroke-linecap="round"/>
    <circle cx="{cx+47}" cy="{by-114}" r="12.5" fill="#ffffff" stroke="{INK}" stroke-width="3.5"/>
    <path d="M{cx+41} {by-113} q6 5 12 0" fill="none" stroke="{INK}" stroke-width="1.8" opacity="0.55"/>
    <path d="M{cx-25} {by-80} Q{cx} {by-69} {cx+25} {by-80}" fill="none" stroke="#e23b3b" stroke-width="4.6"/>
    <circle cx="{cx}" cy="{by-73}" r="6" fill="#f2c14e" stroke="{INK}" stroke-width="2"/>
    <ellipse cx="{cx-14}" cy="{by-107}" rx="3.5" ry="5" fill="{INK}"/>
    <ellipse cx="{cx+14}" cy="{by-107}" rx="3.5" ry="5" fill="{INK}"/>
    <path d="M{cx-4} {by-97} q4 4 8 0" fill="none" stroke="{INK}" stroke-width="2"/>
    <g stroke="{INK}" stroke-width="2"><path d="M{cx-17} {by-99} h-13 M{cx+17} {by-99} h13 M{cx-17} {by-93} h-12 M{cx+17} {by-93} h12"/></g>
    </g>'''


def lantern(cx):
    # a Chinese red lantern (大紅燈籠): gold caps, ribbed red body, tassel
    cy, rx, ry = 128, 42, 46
    g = "#edb93f"
    return f'''<g>
    <path d="M{cx} 0 V{cy-ry-3}" stroke="{INK}" stroke-width="3"/>
    <rect x="{cx-15}" y="{cy-ry-9}" width="30" height="11" rx="3" fill="{g}" stroke="{INK}" stroke-width="3"/>
    <ellipse cx="{cx}" cy="{cy}" rx="{rx}" ry="{ry}" fill="#d8352f" stroke="{INK}" stroke-width="3.5"/>
    <g fill="none" stroke="#a52219" stroke-width="3" opacity="0.85">
      <path d="M{cx-23} {cy-38} Q{cx-33} {cy} {cx-23} {cy+38}"/>
      <path d="M{cx} {cy-ry} V{cy+ry}"/>
      <path d="M{cx+23} {cy-38} Q{cx+33} {cy} {cx+23} {cy+38}"/></g>
    <rect x="{cx-13}" y="{cy+ry-3}" width="26" height="10" rx="3" fill="{g}" stroke="{INK}" stroke-width="3"/>
    <path d="M{cx} {cy+ry+7} v9" stroke="#cf9a2c" stroke-width="4"/>
    <g stroke="{g}" stroke-width="3" stroke-linecap="round">
      <path d="M{cx} {cy+ry+15} l-6 22 M{cx} {cy+ry+15} v24 M{cx} {cy+ry+15} l6 22"/></g>
    </g>'''


def board():
    # the price board as its own sprite so the menu can drag it around the wall
    rows = ""
    for i, col in enumerate(["#b5582f", "#5f8f4a", "#3f7bbd", "#b5582f"]):
        y = 214 + i * 34
        w = [78, 62, 84, 58][i]
        rows += (f'<rect x="200" y="{y}" width="{w}" height="15" rx="3" fill="{col}"/>'
                 f'<rect x="300" y="{y}" width="46" height="15" rx="3" fill="#cba978"/>')
    body = f'''
    <rect x="170" y="178" width="200" height="178" rx="10" fill="#5a3b26" stroke="{INK}" stroke-width="4.6"/>
    <rect x="186" y="194" width="168" height="146" rx="4" fill="#f0e6cf"/>
    {rows}'''
    vw, vh = 216, 194
    svg = f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="162 170 {vw} {vh}">{body}</svg>'
    cairosvg.svg2png(bytestring=svg.encode(), write_to=os.path.join(OUT, "board.png"),
                     output_width=vw * 4, output_height=vh * 4)
    print("wrote board.png", (vw * 4, vh * 4))


def cups(cx, by):
    # a stack of nested paper cups on the counter (base at y=by)
    top_w, bot_w, h = 19, 14, 86
    rims = ""
    for i in range(1, 6):
        f = i / 6.0
        yy = (by - h) + f * h
        wd = top_w + (bot_w - top_w) * f
        rims += (f'<path d="M{cx-wd} {yy} q {wd} 5 {2*wd} 0" fill="none" '
                 f'stroke="{INK}" stroke-width="2.4" opacity="0.8"/>')
    return f'''<g>
    <path d="M{cx-top_w} {by-h} L{cx-bot_w} {by} L{cx+bot_w} {by} L{cx+top_w} {by-h} Z"
          fill="#f4f0e6" stroke="{INK}" stroke-width="4" stroke-linejoin="round"/>
    <path d="M{cx+top_w-7} {by-h} L{cx+bot_w-5} {by} L{cx+bot_w} {by} L{cx+top_w} {by-h} Z" fill="#e0d9c6"/>
    {rims}
    <ellipse cx="{cx}" cy="{by-h}" rx="{top_w}" ry="5.5" fill="#efe9d8" stroke="{INK}" stroke-width="4"/>
    <ellipse cx="{cx}" cy="{by-h}" rx="{top_w-5}" ry="3" fill="#cfc7b0"/>
    </g>'''


def cashier():
    # register + a stack of cups (the board is a separate, draggable sprite)
    W2, H2 = 540, 960
    cy = 560                       # counter top
    body = f'''{register(150, cy)}{cups(248, cy)}'''
    SS = 2
    svg = f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W2} {H2}">{body}</svg>'
    cairosvg.svg2png(bytestring=svg.encode(), write_to=os.path.join(OUT, "cashier.png"),
                     output_width=W2 * SS, output_height=H2 * SS)
    print("wrote cashier.png (register only)", (W2 * SS, H2 * SS))


if __name__ == "__main__":
    main()
    board()
    cashier()
