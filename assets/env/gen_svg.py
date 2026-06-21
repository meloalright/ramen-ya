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
    <g stroke="#c9b083" stroke-width="3"><path d="M0 300 H{W} M128 300 V512 M384 300 V512 M640 300 V512 M256 406 H512"/></g>
    <!-- green noren across the top -->
    <rect x="0" y="0" width="{W}" height="120" fill="#3f8f6a" stroke="{INK}" stroke-width="6"/>
    <g stroke="{INK}" stroke-width="5">
      <path d="M110 120 V40 M220 120 V40 M330 120 V40 M440 120 V40 M550 120 V40 M660 120 V40"/></g>
    <!-- hanging lanterns -->
    <g>
      <path d="M120 0 V60" stroke="{INK}" stroke-width="5"/>
      <ellipse cx="120" cy="150" rx="42" ry="56" fill="#e2533f" stroke="{INK}" stroke-width="6"/>
      <path d="M88 150 h64" stroke="{INK}" stroke-width="4" opacity="0.5"/>
      <path d="M648 0 V60" stroke="{INK}" stroke-width="5"/>
      <ellipse cx="648" cy="150" rx="42" ry="56" fill="#e2533f" stroke="{INK}" stroke-width="6"/>
      <path d="M616 150 h64" stroke="{INK}" stroke-width="4" opacity="0.5"/></g>
    <!-- big steaming stock pot -->
    <g fill="none" stroke="#ffffff" stroke-width="11" stroke-linecap="round" opacity="0.6">
      <path d="M250 250 q-26 -34 0 -68 q26 -34 0 -68"/>
      <path d="M320 250 q26 -34 0 -68 q-26 -34 0 -68"/></g>
    <ellipse cx="290" cy="330" rx="118" ry="92" fill="#8d9099" stroke="{INK}" stroke-width="8"/>
    <ellipse cx="290" cy="300" rx="110" ry="60" fill="#a6694a" stroke="{INK}" stroke-width="8"/>
    <ellipse cx="290" cy="300" rx="92" ry="46" fill="#eaa43e"/>
    <path d="M198 300 a92 46 0 0 0 184 0 a92 46 0 0 1 -184 0" fill="#d18b2c"/>
    <!-- a couple of ramen bowls on the right -->
    {bowl(560,300)}{bowl(660,330,0.8)}
    <!-- wooden counter -->
    <rect x="0" y="430" width="{W}" height="82" fill="#a9743f" stroke="{INK}" stroke-width="8"/>
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
          fill="#dc4a44" stroke="{INK}" stroke-width="7"/>
    <ellipse cx="{cx}" cy="{cy}" rx="{rx}" ry="{ry}" fill="#ec6a60" stroke="{INK}" stroke-width="7"/>
    <ellipse cx="{cx}" cy="{cy}" rx="{rx*0.78}" ry="{ry*0.72}" fill="#eaa43e"/>
    </g>'''


if __name__ == "__main__":
    main()
