#!/usr/bin/env python3
"""Cartoon (SVG) app icon -> icon_1024.png + iOS sizes."""
import os
import cairosvg
from PIL import Image

OUT = os.path.dirname(os.path.abspath(__file__))
INK = "#241818"


def main():
    body = f'''
    <rect width="1024" height="1024" fill="#d6473f"/>
    <circle cx="512" cy="520" r="430" fill="#c23b35"/>
    <!-- steam -->
    <g fill="none" stroke="#ffffff" stroke-width="26" stroke-linecap="round" opacity="0.55">
      <path d="M430 300 q-50 -60 0 -120 q50 -60 0 -120"/>
      <path d="M610 300 q-50 -60 0 -120 q50 -60 0 -120"/></g>
    <!-- bowl -->
    <path d="M150 470 C150 300 874 300 874 470 C874 760 700 880 512 880 C324 880 150 760 150 470 Z"
          fill="#e85a52" stroke="{INK}" stroke-width="26" stroke-linejoin="round"/>
    <path d="M210 620 C330 760 694 760 814 620" fill="none" stroke="#3a6ea5" stroke-width="40" stroke-linecap="round"/>
    <ellipse cx="512" cy="460" rx="372" ry="120" fill="#f5837a" stroke="{INK}" stroke-width="26"/>
    <ellipse cx="512" cy="470" rx="305" ry="92" fill="#eaa43e"/>
    <path d="M207 474 a305 92 0 0 0 610 0 a305 92 0 0 1 -610 0" fill="#d18b2c"/>
    <g fill="none" stroke="#f4e3a0" stroke-width="20" stroke-linecap="round">
      <path d="M320 455 q95 50 190 0 q95 -50 185 0"/>
      <path d="M330 490 q95 45 185 0 q95 -45 170 0"/></g>
    <g stroke="#5e2c20" stroke-width="16">
      <ellipse cx="440" cy="455" rx="78" ry="44" fill="#a8503a"/></g>
    <ellipse cx="440" cy="455" rx="40" ry="20" fill="#c46b4f"/>
    '''
    svg = f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024">{body}</svg>'
    cairosvg.svg2png(bytestring=svg.encode(), write_to=os.path.join(OUT, "icon_1024.png"),
                     output_width=1024, output_height=1024)
    print("wrote icon_1024.png")
    src = Image.open(os.path.join(OUT, "icon_1024.png")).convert("RGB")
    sizes = {"iphone_120": 120, "iphone_180": 180, "ipad_76": 76, "ipad_152": 152,
             "ipad_167": 167, "spotlight_40": 40, "spotlight_80": 80, "settings_58": 58,
             "settings_87": 87, "notification_40": 40, "notification_60": 60}
    os.makedirs(os.path.join(OUT, "ios"), exist_ok=True)
    for name, s in sizes.items():
        src.resize((s, s), Image.LANCZOS).save(os.path.join(OUT, "ios", name + ".png"))
    print("wrote", len(sizes), "iOS icons")


if __name__ == "__main__":
    main()
