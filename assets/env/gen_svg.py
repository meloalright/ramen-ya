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
    # a cash register sitting with its base on the counter top (y=by)
    return f'''<g>
    <rect x="{cx-60}" y="{by-98}" width="120" height="98" rx="8" fill="#cf6b4e" stroke="{INK}" stroke-width="4"/>
    <rect x="{cx-60}" y="{by-98}" width="120" height="16" rx="8" fill="#e08a6c"/>
    <!-- display housing + screen -->
    <rect x="{cx-44}" y="{by-142}" width="88" height="48" rx="6" fill="#6f4230" stroke="{INK}" stroke-width="4"/>
    <rect x="{cx-34}" y="{by-134}" width="68" height="32" rx="3" fill="#bfe6c8"/>
    <g fill="#2e6b3f"><rect x="{cx-25}" y="{by-126}" width="8" height="16"/><rect x="{cx-11}" y="{by-126}" width="8" height="16"/><rect x="{cx+3}" y="{by-126}" width="8" height="16"/><rect x="{cx+17}" y="{by-126}" width="8" height="16"/></g>
    <!-- keypad -->
    <g fill="#f0d9a0" stroke="{INK}" stroke-width="2">
      <rect x="{cx-42}" y="{by-72}" width="22" height="19" rx="3"/><rect x="{cx-12}" y="{by-72}" width="22" height="19" rx="3"/><rect x="{cx+18}" y="{by-72}" width="22" height="19" rx="3"/>
      <rect x="{cx-42}" y="{by-47}" width="22" height="19" rx="3"/><rect x="{cx-12}" y="{by-47}" width="22" height="19" rx="3"/><rect x="{cx+18}" y="{by-47}" width="22" height="19" rx="3"/>
    </g>
    <!-- drawer line + handle -->
    <rect x="{cx-60}" y="{by-24}" width="120" height="4" fill="{INK}"/>
    <rect x="{cx-15}" y="{by-18}" width="30" height="9" rx="3" fill="#6f4230" stroke="{INK}" stroke-width="2"/>
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


def cashier():
    W2, H2 = 540, 960
    cy = 560                       # counter top
    rows = ""
    for i, col in enumerate(["#b5582f", "#5f8f4a", "#3f7bbd", "#b5582f"]):
        y = 214 + i * 34
        w = [78, 62, 84, 58][i]
        rows += (f'<rect x="200" y="{y}" width="{w}" height="15" rx="3" fill="{col}"/>'
                 f'<rect x="300" y="{y}" width="46" height="15" rx="3" fill="#cba978"/>')
    # props only on a TRANSPARENT background — the noren / wall / counter bands
    # are drawn procedurally full-width in Menu.gd so they extend to any width.
    body = f'''
    <!-- menu / price board mounted flat on the wall (no hanging cords) -->
    <rect x="170" y="178" width="200" height="178" rx="10" fill="#5a3b26" stroke="{INK}" stroke-width="4.6"/>
    <rect x="186" y="194" width="168" height="146" rx="4" fill="#f0e6cf"/>
    {rows}
    {register(150, cy)}
    '''
    svg = f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W2} {H2}">{body}</svg>'
    cairosvg.svg2png(bytestring=svg.encode(), write_to=os.path.join(OUT, "cashier.png"),
                     output_width=W2, output_height=H2)
    print("wrote cashier.png (props only)", (W2, H2))


if __name__ == "__main__":
    main()
    cashier()
