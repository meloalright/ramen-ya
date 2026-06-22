#!/usr/bin/env python3
"""Cartoon (American/Western) cook sprites, hand-drawn as SVG -> PNG.

Keeps the SAME geometry the game expects so the layered bowl + vats + trays
line up:
  td_bowl   128, opening ellipse at (64,50) rx52 ry40 (3/4 tilt, wall below)
  td_broth/td_noodles/td_beef 128, contents inside that opening
  td_vat_*  88,  opening at (44,36)  (VAT_OPEN_Y=36 in Main.gd)
  td_box_*  48,  ingredient tray
Bold black outlines, flat vibrant colours, soft cel shading, chunky shapes.
"""
import os
import cairosvg

OUT = os.path.dirname(os.path.abspath(__file__))
INK = "#241818"


def render(name, w, h, body):
    svg = f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}">{body}</svg>'
    cairosvg.svg2png(bytestring=svg.encode(), write_to=os.path.join(OUT, name + ".png"),
                     output_width=w, output_height=h)
    print("wrote", name)


# ---- the assembly bowl (layers) -------------------------------------
def bowl_empty():
    body = f'''
    <path d="M12 50 C12 27 116 27 116 50 C116 95 96 112 64 112 C32 112 12 95 12 50 Z"
          fill="#dc4a44" stroke="{INK}" stroke-width="5" stroke-linejoin="round"/>
    <path d="M64 112 C32 112 12 95 12 50 C20 90 40 104 64 106 Z" fill="#b83a35" opacity="0.55"/>
    <path d="M22 78 C40 100 88 100 106 78" fill="none" stroke="#3a6ea5" stroke-width="6" stroke-linecap="round"/>
    <ellipse cx="64" cy="50" rx="52" ry="40" fill="#ec6a60" stroke="{INK}" stroke-width="5"/>
    <ellipse cx="64" cy="52" rx="44" ry="33" fill="#efe6d4"/>
    <path d="M22 56 a44 33 0 0 0 84 0 a44 33 0 0 1 -84 0" fill="#dccdb4" opacity="0.7"/>'''
    render("td_bowl", 128, 128, body)


def broth():
    body = '''
    <ellipse cx="64" cy="50" rx="48" ry="36" fill="#eaa43e"/>
    <path d="M16 54 a48 36 0 0 0 96 0 a48 36 0 0 1 -96 0" fill="#d18b2c"/>
    <ellipse cx="48" cy="40" rx="16" ry="8" fill="#f2bd5c" opacity="0.7"/>'''
    render("td_broth", 128, 128, body)


def noodles():
    body = '''
    <g fill="none" stroke="#f4e3a0" stroke-width="6" stroke-linecap="round">
     <path d="M26 46 q20 14 40 0 q20 -14 38 0"/>
     <path d="M28 56 q20 14 40 0 q20 -14 36 0"/>
     <path d="M34 66 q18 12 38 0 q18 -12 32 0"/></g>'''
    render("td_noodles", 128, 128, body)


def beef():
    body = f'''
    <g stroke="#5e2c20" stroke-width="5">
     <ellipse cx="50" cy="46" rx="20" ry="12" fill="#a8503a"/>
     <ellipse cx="50" cy="46" rx="10" ry="5" fill="#c46b4f"/>
     <ellipse cx="78" cy="58" rx="19" ry="11" fill="#a8503a"/>
     <ellipse cx="78" cy="58" rx="9" ry="4" fill="#c46b4f"/></g>'''
    render("td_beef", 128, 128, body)


# ---- big vats (大缸) -------------------------------------------------
def vat(name, liquid, liquid_d, hi, basket):
    # a tall square metal pot, 3/4 overhead — taller than the bowl; the base
    # runs off behind the action buttons. liquid surface sits at y=32.
    extra = ""
    if basket:
        extra = f'<ellipse cx="62" cy="30" rx="12" ry="8" fill="#cfcab4" stroke="{INK}" stroke-width="2.5"/>'
    else:
        extra = f'<ellipse cx="38" cy="24" rx="9" ry="4" fill="{hi}" opacity="0.6"/>'
    body = f'''
    <defs>
      <linearGradient id="cy_{name}" x1="0" y1="0" x2="1" y2="0">
        <stop offset="0" stop-color="#79818a"/>
        <stop offset="0.32" stop-color="#c4cace"/>
        <stop offset="0.62" stop-color="#a6aeb6"/>
        <stop offset="1" stop-color="#6b737b"/>
      </linearGradient>
    </defs>
    <!-- smooth cylinder body, plain undecorated walls -->
    <path d="M5 30 L5 112 A48 16 0 0 0 101 112 L101 30 A48 22 0 0 1 5 30 Z"
          fill="url(#cy_{name})" stroke="{INK}" stroke-width="4.5" stroke-linejoin="round"/>
    <!-- round rim + liquid surface (fuller 3/4 oval) -->
    <ellipse cx="53" cy="30" rx="48" ry="22" fill="#c4cad0" stroke="{INK}" stroke-width="4.5"/>
    <ellipse cx="53" cy="30" rx="40" ry="17" fill="#888f97"/>
    <ellipse cx="53" cy="30" rx="36" ry="15" fill="{liquid}"/>
    <path d="M17 30 a36 15 0 0 0 72 0 a36 15 0 0 1 -72 0" fill="{liquid_d}"/>
    {extra}'''
    render(name, 106, 132, body)


# ---- ingredient trays -----------------------------------------------
def tray(name, fill, fill_d, chunky):
    bits = ""
    cols = {"beef": ["#a8503a", "#c46b4f"], "scallion": ["#7ec24a", "#a6e070"],
            "cilantro": ["#3f8f4a", "#5fae5f"], "chili": ["#e23b3b", "#f06a6a"]}
    c = cols[chunky]
    if chunky == "beef":
        bits = f'<g stroke="#5e2c20" stroke-width="2"><ellipse cx="18" cy="17" rx="9" ry="5" fill="{c[0]}"/><ellipse cx="30" cy="22" rx="9" ry="5" fill="{c[0]}"/></g>'
    else:
        import_dots = ""
        for cx, cy in ((14, 15), (24, 13), (33, 18), (18, 22), (28, 23)):
            import_dots += f'<circle cx="{cx}" cy="{cy}" r="3.4" fill="{c[1]}" stroke="{c[0]}" stroke-width="1.5"/>'
        bits = import_dots
    body = f'''
    <path d="M4 18 C4 10 44 10 44 18 C44 34 38 40 24 40 C10 40 4 34 4 18 Z"
          fill="#6b4a2e" stroke="{INK}" stroke-width="4" stroke-linejoin="round"/>
    <ellipse cx="24" cy="18" rx="20" ry="13" fill="{fill}" stroke="{INK}" stroke-width="4"/>
    <path d="M4 20 a20 13 0 0 0 40 0 a20 13 0 0 1 -40 0" fill="{fill_d}"/>
    {bits}'''
    render(name, 48, 48, body)


def ladle():
    body = f'''
    <rect x="22" y="2" width="5" height="30" rx="2.5" fill="#9a6a3a" stroke="{INK}" stroke-width="3"/>
    <path d="M6 34 a18 12 0 0 0 36 0 Z" fill="#cfcab4" stroke="{INK}" stroke-width="3.5"/>
    <ellipse cx="24" cy="34" rx="16" ry="6" fill="#eaa43e" stroke="{INK}" stroke-width="3"/>'''
    render("td_pot_soup", 48, 48, body)


def noodle_clump():
    body = f'''
    <ellipse cx="24" cy="26" rx="20" ry="16" fill="#f0dd92" stroke="{INK}" stroke-width="3.5"/>
    <g fill="none" stroke="#d7bf68" stroke-width="2.4" stroke-linecap="round">
     <path d="M8 22 q16 10 32 0"/><path d="M8 28 q16 10 32 0"/><path d="M10 34 q14 8 28 0"/></g>'''
    render("td_pot_noodle", 48, 48, body)


def main():
    bowl_empty(); broth(); noodles(); beef(); ladle(); noodle_clump()
    vat("td_vat_soup", "#eaa43e", "#d18b2c", "#f2bd5c", False)
    vat("td_vat_noodle", "#ece8dc", "#d6d1c0", "#f8f5ee", False)   # 白汤 (noodles appear only while cooking)
    tray("td_box_beef", "#b06246", "#8a4a33", "beef")
    tray("td_box_scallion", "#8fd25a", "#6fb244", "scallion")
    tray("td_box_cilantro", "#4e9e58", "#3a7a42", "cilantro")
    tray("td_box_chili", "#e05050", "#b83a3a", "chili")


if __name__ == "__main__":
    main()
