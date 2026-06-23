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


# supersample: rasterise at SSx the design size so curves stay crisp when the
# 270-wide canvas is scaled up ~4x on high-DPI phones (textures downscale, not up)
SS = 4


def render(name, w, h, body):
    svg = f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}">{body}</svg>'
    cairosvg.svg2png(bytestring=svg.encode(), write_to=os.path.join(OUT, name + ".png"),
                     output_width=w * SS, output_height=h * SS)
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
    <ellipse cx="64" cy="50" rx="48" ry="36" fill="#e9b63a"/>
    <path d="M16 54 a48 36 0 0 0 96 0 a48 36 0 0 1 -96 0" fill="#cf9a28"/>
    <ellipse cx="48" cy="40" rx="16" ry="8" fill="#f6cf5a" opacity="0.7"/>
    <g fill="#f8d566">
      <ellipse cx="82" cy="44" rx="6" ry="3.2" opacity="0.6"/>
      <ellipse cx="62" cy="60" rx="4.5" ry="2.4" opacity="0.55"/>
      <ellipse cx="92" cy="56" rx="3.5" ry="2" opacity="0.5"/>
      <ellipse cx="44" cy="56" rx="3" ry="1.8" opacity="0.5"/></g>'''
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
     <ellipse cx="78" cy="58" rx="19" ry="11" fill="#a8503a"/></g>
    <ellipse cx="50" cy="46" rx="10" ry="5" fill="#c46b4f"/>
    <ellipse cx="78" cy="58" rx="9" ry="4" fill="#c46b4f"/>'''
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
        <stop offset="0" stop-color="#7a4324"/>
        <stop offset="0.32" stop-color="#e6a868"/>
        <stop offset="0.62" stop-color="#c17c42"/>
        <stop offset="1" stop-color="#6b3a1e"/>
      </linearGradient>
    </defs>
    <!-- smooth copper cylinder body, plain undecorated walls -->
    <path d="M5 30 L5 112 A48 16 0 0 0 101 112 L101 30 A48 22 0 0 1 5 30 Z"
          fill="url(#cy_{name})" stroke="{INK}" stroke-width="2.8" stroke-linejoin="round"/>
    <!-- thin copper rim, liquid filling right up to it (no inner-wall depth) -->
    <ellipse cx="53" cy="30" rx="48" ry="22" fill="#d2914f" stroke="{INK}" stroke-width="2.8"/>
    <ellipse cx="53" cy="30" rx="44" ry="19" fill="{liquid}"/>
    <path d="M9 30 a44 19 0 0 0 88 0 a44 19 0 0 1 -88 0" fill="{liquid_d}"/>
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
        dot = "#a82c2c" if chunky == "chili" else c[1]   # chili = darker flecks
        import_dots = ""
        for cx, cy in ((14, 15), (24, 13), (33, 18), (18, 22), (28, 23)):
            import_dots += f'<circle cx="{cx}" cy="{cy}" r="3.4" fill="{dot}"/>'
        bits = import_dots
    body = f'''
    <path d="M4 18 C4 10 44 10 44 18 C44 34 38 40 24 40 C10 40 4 34 4 18 Z"
          fill="#6b4a2e" stroke="{INK}" stroke-width="4" stroke-linejoin="round"/>
    <ellipse cx="24" cy="18" rx="20" ry="13" fill="{fill}" stroke="{INK}" stroke-width="4"/>
    <path d="M4 20 a20 13 0 0 0 40 0 a20 13 0 0 1 -40 0" fill="{fill_d}"/>
    {bits}'''
    render(name, 48, 48, body)


def ladle():
    # side view: a deep scoop of broth with a long handle angled up
    body = f'''
    <path d="M31 40 L43 4" stroke="{INK}" stroke-width="6.5" stroke-linecap="round"/>
    <path d="M31 40 L43 4" stroke="#c9c4b4" stroke-width="3.6" stroke-linecap="round"/>
    <path d="M31.5 38 L43 5" stroke="#e6e2d6" stroke-width="1" stroke-linecap="round" opacity="0.7"/>
    <path d="M8 40 Q8 62 23 62 Q38 62 38 40 Z" fill="#c9c4b4" stroke="{INK}" stroke-width="3.5" stroke-linejoin="round"/>
    <path d="M30 46 Q32 56 24 60" fill="none" stroke="#aca695" stroke-width="2.5" opacity="0.55"/>
    <ellipse cx="23" cy="40" rx="15" ry="4.6" fill="#c9c4b4" stroke="{INK}" stroke-width="2.4"/>
    <ellipse cx="23" cy="40" rx="13.4" ry="4.1" fill="#e9b63a" stroke="{INK}" stroke-width="1.6"/>
    <ellipse cx="21.5" cy="39.3" rx="6" ry="1.5" fill="#f6cf5a"/>'''
    render("td_pot_soup", 48, 64, body)


def noodle_clump():
    # side view: long chopsticks at an angle, long white noodle strands dangling
    body = f'''
    <line x1="9" y1="50" x2="44" y2="6" stroke="{INK}" stroke-width="6.5" stroke-linecap="round"/>
    <line x1="9" y1="50" x2="44" y2="6" stroke="#c98f54" stroke-width="3.8" stroke-linecap="round"/>
    <line x1="15" y1="54" x2="48" y2="12" stroke="{INK}" stroke-width="6.5" stroke-linecap="round"/>
    <line x1="15" y1="54" x2="48" y2="12" stroke="#b97f44" stroke-width="3.8" stroke-linecap="round"/>
    <g fill="none" stroke="#f2efe6" stroke-width="3" stroke-linecap="round">
      <path d="M9 49 q-4 22 0 44"/><path d="M14 51 q-2 24 2 42"/>
      <path d="M19 52 q3 22 -1 41"/><path d="M24 51 q4 20 1 38"/></g>
    <g fill="none" stroke="#d3cdbd" stroke-width="1.2" stroke-linecap="round">
      <path d="M14 51 q-2 24 2 42"/><path d="M19 52 q3 22 -1 41"/></g>'''
    render("td_pot_noodle", 48, 100, body)


def bowl_pot(name, fill, fill_d):
    # a wide ceramic bowl (same style as the topping trays) of broth / water
    body = f'''
    <path d="M6 20 C6 8 110 8 110 20 C110 40 98 48 58 48 C18 48 6 40 6 20 Z"
          fill="#6b4a2e" stroke="{INK}" stroke-width="4.5" stroke-linejoin="round"/>
    <ellipse cx="58" cy="20" rx="52" ry="14" fill="{fill}" stroke="{INK}" stroke-width="4.5"/>
    <path d="M6 22 a52 14 0 0 0 104 0 a52 14 0 0 1 -104 0" fill="{fill_d}"/>'''
    render(name, 116, 50, body)


def main():
    bowl_empty(); broth(); noodles(); beef(); ladle(); noodle_clump()
    bowl_pot("td_bowl_soup", "#e9b63a", "#cf9a28")
    bowl_pot("td_bowl_noodle", "#e3e9ea", "#c4cfd0")
    vat("td_vat_soup", "#e9b63a", "#cf9a28", "#f6cf5a", False)
    vat("td_vat_noodle", "#ece8dc", "#d6d1c0", "#f8f5ee", False)   # 白汤 (noodles appear only while cooking)
    tray("td_box_beef", "#b06246", "#8a4a33", "beef")
    tray("td_box_scallion", "#8fd25a", "#6fb244", "scallion")
    tray("td_box_cilantro", "#4e9e58", "#3a7a42", "cilantro")
    tray("td_box_chili", "#e05050", "#b83a3a", "chili")


if __name__ == "__main__":
    main()
