#!/usr/bin/env python3
"""Cartoon (SVG) overworld assets: ground tiles, tree, buildings."""
import os
import cairosvg

OUT = os.path.dirname(os.path.abspath(__file__))
INK = "#28201c"


def render(name, w, h, body, ow=None, oh=None):
    svg = f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}">{body}</svg>'
    cairosvg.svg2png(bytestring=svg.encode(), write_to=os.path.join(OUT, name + ".png"),
                     output_width=ow or w, output_height=oh or h)
    print("wrote", name)


# ---- 16x16 ground tiles (flat cartoon, tile-friendly) ----------------
def tile(name, base, marks=""):
    render(name, 16, 16, f'<rect width="16" height="16" fill="{base}"/>{marks}')


def tiles():
    tile("grass", "#6fae3a",
         '<g stroke="#5d9830" stroke-width="1.4" stroke-linecap="round">'
         '<path d="M3 13 v-4 M7 14 v-5 M11 12 v-4 M14 14 v-4 M5 6 v-3 M10 5 v-3"/></g>')
    tile("grass2", "#74b53e",
         '<circle cx="4" cy="5" r="1.6" fill="#fff1a0"/><circle cx="11" cy="9" r="1.6" fill="#ffb3c8"/>'
         '<circle cx="13" cy="3" r="1.4" fill="#fff1a0"/><circle cx="6" cy="12" r="1.4" fill="#fff"/>')
    tile("path", "#b98a52",
         '<g fill="#a2753f"><circle cx="4" cy="5" r="1.5"/><circle cx="11" cy="4" r="1.3"/>'
         '<circle cx="8" cy="10" r="1.6"/><circle cx="13" cy="12" r="1.3"/><circle cx="3" cy="12" r="1.2"/></g>')
    tile("sand", "#e6cf95",
         '<g fill="#d3b878"><circle cx="5" cy="6" r="1"/><circle cx="11" cy="9" r="1"/>'
         '<circle cx="8" cy="13" r="1"/><circle cx="13" cy="3" r="1"/></g>')
    tile("water", "#56b6c0",
         '<g fill="none" stroke="#bfe9ec" stroke-width="1.3" stroke-linecap="round">'
         '<path d="M2 5 q3 -2 6 0 q3 2 6 0"/><path d="M2 11 q3 -2 6 0 q3 2 6 0"/></g>')
    tile("pavement", "#b7b3ad",
         '<g stroke="#8f8b85" stroke-width="1.2"><path d="M0 8 h16 M8 0 v8 M4 8 v8 M12 8 v8"/></g>')
    tile("road", "#9a948c",
         '<g fill="#88827a" stroke="#6f6960" stroke-width="0.8">'
         '<circle cx="4" cy="4" r="3"/><circle cx="12" cy="5" r="3"/>'
         '<circle cx="3" cy="12" r="3"/><circle cx="11" cy="12" r="3"/><circle cx="8" cy="9" r="2.4"/></g>')


# ---- tree ------------------------------------------------------------
def tree():
    body = f'''
    <rect x="18" y="30" width="8" height="14" rx="3" fill="#8a5a32" stroke="{INK}" stroke-width="3"/>
    <circle cx="22" cy="20" r="18" fill="#5ba33a" stroke="{INK}" stroke-width="3"/>
    <circle cx="13" cy="24" r="11" fill="#5ba33a" stroke="{INK}" stroke-width="3"/>
    <circle cx="31" cy="24" r="11" fill="#5ba33a" stroke="{INK}" stroke-width="3"/>
    <circle cx="22" cy="20" r="18" fill="#5ba33a"/>
    <circle cx="13" cy="24" r="11" fill="#5ba33a"/><circle cx="31" cy="24" r="11" fill="#5ba33a"/>
    <path d="M16 12 a14 14 0 0 1 14 2" fill="none" stroke="#79c356" stroke-width="4" stroke-linecap="round"/>'''
    render("tree", 44, 46, body)


# ---- buildings (96 wide, door centred at bottom) ---------------------
def shop():
    body = f'''
    <rect x="6" y="30" width="84" height="54" fill="#a9743f" stroke="{INK}" stroke-width="3.5"/>
    <rect x="6" y="30" width="84" height="54" fill="none" stroke="#8a5a30" stroke-width="1" stroke-dasharray="2 6"/>
    <!-- roof -->
    <path d="M0 34 L14 14 H82 L96 34 Z" fill="#3f6b54" stroke="{INK}" stroke-width="3.5" stroke-linejoin="round"/>
    <path d="M0 34 H96" stroke="{INK}" stroke-width="3.5"/>
    <!-- noren curtain -->
    <path d="M30 34 h36 v14 h-36 z" fill="#3f8f6a" stroke="{INK}" stroke-width="2.5"/>
    <g stroke="{INK}" stroke-width="2"><path d="M42 34 v14 M54 34 v14"/></g>
    <!-- door -->
    <rect x="38" y="58" width="20" height="26" fill="#7a5230" stroke="{INK}" stroke-width="3"/>
    <path d="M48 58 v26" stroke="{INK}" stroke-width="2"/>
    <!-- windows -->
    <rect x="12" y="54" width="18" height="16" rx="2" fill="#ffd98a" stroke="{INK}" stroke-width="3"/>
    <rect x="66" y="54" width="18" height="16" rx="2" fill="#ffd98a" stroke="{INK}" stroke-width="3"/>
    <!-- lanterns -->
    <g><circle cx="14" cy="40" r="6" fill="#e2533f" stroke="{INK}" stroke-width="2.5"/>
       <circle cx="82" cy="40" r="6" fill="#e2533f" stroke="{INK}" stroke-width="2.5"/></g>'''
    render("shop", 96, 84, body)


def tower():
    rows = ""
    for ry in range(34, 120, 18):
        for rx in (16, 40, 64):
            rows += f'<rect x="{rx}" y="{ry}" width="16" height="12" rx="1.5" fill="#ffcf5e" stroke="{INK}" stroke-width="2"/>'
    body = f'''
    <rect x="8" y="20" width="80" height="130" fill="#6a4a96" stroke="{INK}" stroke-width="4"/>
    <path d="M8 20 H88 L80 6 H16 Z" fill="#caa24a" stroke="{INK}" stroke-width="4" stroke-linejoin="round"/>
    {rows}
    <!-- open gate -->
    <rect x="34" y="120" width="28" height="30" fill="#1c1622" stroke="{INK}" stroke-width="4"/>
    <path d="M48 120 v30" stroke="#3a3346" stroke-width="2"/>
    <rect x="8" y="146" width="80" height="6" fill="#caa24a" stroke="{INK}" stroke-width="3"/>'''
    render("tower_ext", 96, 152, body)


def rowhouse(name, h, wall, roof, awn):
    floors = ""
    y = 30
    while y < h - 34:
        for rx in (16, 44, 72):
            floors += f'<rect x="{rx-2}" y="{y}" width="16" height="14" rx="1.5" fill="#ffcf6a" stroke="{INK}" stroke-width="2.5"/>'
        y += 24
    body = f'''
    <rect x="6" y="22" width="84" height="{h-22}" fill="{wall}" stroke="{INK}" stroke-width="3.5"/>
    <path d="M2 26 L12 8 H84 L94 26 Z" fill="{roof}" stroke="{INK}" stroke-width="3.5" stroke-linejoin="round"/>
    {floors}
    <!-- ground-floor shopfront with awning -->
    <rect x="10" y="{h-34}" width="76" height="34" fill="#6a4a30" stroke="{INK}" stroke-width="3"/>
    <path d="M8 {h-34} h80 v8 h-80 z" fill="{awn}" stroke="{INK}" stroke-width="2.5"/>
    <g stroke="{INK}" stroke-width="1.6"><path d="M24 {h-34} v8 M40 {h-34} v8 M56 {h-34} v8 M72 {h-34} v8"/></g>
    <rect x="40" y="{h-26}" width="18" height="26" fill="#8a5a30" stroke="{INK}" stroke-width="3"/>
    <rect x="14" y="{h-26}" width="20" height="16" fill="#ffd98a" stroke="{INK}" stroke-width="3"/>
    <rect x="62" y="{h-26}" width="20" height="16" fill="#ffd98a" stroke="{INK}" stroke-width="3"/>'''
    render(name, 96, h, body)


def main():
    tiles(); tree(); shop(); tower()
    rowhouse("bldg1", 140, "#c9a06a", "#5a8f6a", "#d2533f")
    rowhouse("bldg2", 152, "#cfc6b8", "#5a7fa0", "#3f8f6a")
    rowhouse("bldg3", 130, "#b5703f", "#7a4a30", "#caa24a")


if __name__ == "__main__":
    main()
