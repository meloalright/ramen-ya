#!/usr/bin/env python3
"""Cartoon (SVG) shop-interior assets, sized to what Shop.gd draws."""
import os
import cairosvg

OUT = os.path.dirname(os.path.abspath(__file__))
INK = "#28201c"


def render(name, w, h, body):
    svg = f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}">{body}</svg>'
    cairosvg.svg2png(bytestring=svg.encode(), write_to=os.path.join(OUT, name + ".png"),
                     output_width=w, output_height=h)
    print("wrote", name)


def main():
    # 16x16 floor / wall tiles
    render("floor", 16, 16,
           '<rect width="16" height="16" fill="#a9743f"/>'
           '<g stroke="#8a5a30" stroke-width="1"><path d="M0 5 h16 M0 11 h16 M8 0 v5 M3 11 v5 M12 11 v5"/></g>')
    render("wall", 16, 16,
           '<rect width="16" height="16" fill="#d8c7a6"/>'
           '<g fill="#cbb892"><circle cx="4" cy="5" r="1"/><circle cx="11" cy="9" r="1"/><circle cx="8" cy="13" r="1"/></g>')

    # service counter top (repeats horizontally; plain wood edges)
    render("counter", 54, 26, f'''
    <rect x="0" y="8" width="54" height="18" fill="#a9743f" stroke="{INK}" stroke-width="2.5"/>
    <rect x="0" y="6" width="54" height="6" fill="#c08a4e" stroke="{INK}" stroke-width="2.5"/>
    <rect x="20" y="0" width="8" height="10" rx="2" fill="#8a5a30" stroke="{INK}" stroke-width="2"/>
    <g stroke="#caa45a" stroke-width="1.4"><path d="M22 1 v8 M24 1 v8 M26 1 v8"/></g>
    <ellipse cx="40" cy="6" rx="5" ry="3" fill="#e2533f" stroke="{INK}" stroke-width="2"/>''')

    # stove (repeats; plain metal edges)
    render("kitchen", 48, 37, f'''
    <rect x="0" y="10" width="48" height="27" rx="2" fill="#8d9099" stroke="{INK}" stroke-width="2.5"/>
    <rect x="3" y="13" width="42" height="14" rx="2" fill="#3a3640" stroke="{INK}" stroke-width="2"/>
    <ellipse cx="14" cy="14" rx="9" ry="5" fill="#b9bcc6" stroke="{INK}" stroke-width="2.5"/>
    <ellipse cx="14" cy="13" rx="5" ry="2.6" fill="#8d9099"/>
    <circle cx="34" cy="20" r="5" fill="#e0792e" stroke="{INK}" stroke-width="2"/>''')

    # table (top-down)
    render("table", 26, 28, f'''
    <rect x="3" y="4" width="20" height="22" rx="4" fill="#a9743f" stroke="{INK}" stroke-width="2.5"/>
    <rect x="3" y="4" width="20" height="6" rx="3" fill="#c08a4e"/>
    <rect x="11" y="14" width="4" height="4" rx="1" fill="#8a5a30"/>''')

    # chair (backrest + seat)
    render("chair", 16, 26, f'''
    <rect x="3" y="2" width="10" height="9" rx="2" fill="#8a5a32" stroke="{INK}" stroke-width="2.2"/>
    <rect x="2" y="10" width="12" height="9" rx="2" fill="#a9743f" stroke="{INK}" stroke-width="2.2"/>''')

    # hanging lantern
    render("lantern", 13, 28, f'''
    <path d="M6.5 0 v6" stroke="{INK}" stroke-width="2"/>
    <ellipse cx="6.5" cy="16" rx="6" ry="9" fill="#e2533f" stroke="{INK}" stroke-width="2.2"/>
    <path d="M2 16 h9" stroke="{INK}" stroke-width="1.4" opacity="0.5"/>
    <rect x="5" y="24" width="3" height="3" fill="#caa24a"/>''')

    # small ramen bowl
    render("bowl", 16, 15, f'''
    <path d="M2 6 C2 2 14 2 14 6 C14 11 11 13 8 13 C5 13 2 11 2 6 Z" fill="#dc4a44" stroke="{INK}" stroke-width="2"/>
    <ellipse cx="8" cy="6" rx="6" ry="3" fill="#eaa43e" stroke="{INK}" stroke-width="2"/>''')

    # door
    render("door", 20, 20, f'''
    <rect x="2" y="1" width="16" height="19" rx="1.5" fill="#8a5a30" stroke="{INK}" stroke-width="2.5"/>
    <path d="M10 1 v19" stroke="{INK}" stroke-width="1.6"/>
    <circle cx="7" cy="11" r="1.4" fill="#caa24a"/><circle cx="13" cy="11" r="1.4" fill="#caa24a"/>''')


if __name__ == "__main__":
    main()
