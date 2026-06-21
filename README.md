# 🍜 RAMEN-YA / らーめん屋

A small **2D pixel-art ramen-shop management** game **DEMO**, built with **Godot 4.x**.
All graphics are drawn procedurally in code (no external art assets), so the project is
tiny and exports cleanly to the **Web (HTML5)**.

![pixel ramen](icon.svg)

## 🎮 How to play

You run the counter of a ramen shop. Customers sit down and order a bowl shown in their
speech bubble (a **broth** + some **toppings**). Build the matching bowl and serve it
before their patience runs out.

| Action | Control |
|---|---|
| Start / restart | `SPACE` / `Enter` / click |
| Select a customer | click their seat |
| Add ingredient | click an ingredient button (toppings toggle on/off) |
| Serve current bowl | **出す SERVE** button |
| Trash current bowl | **捨てる CLEAR** button |

**Rules**
- A valid bowl needs **noodles (麺)** + one **broth** (醤油 Shoyu / 味噌 Miso).
- Toppings must **exactly match** the order: 玉子 Egg / 海苔 Nori / 叉焼 Chashu / 葱 Negi.
- Correct serve → tip (bigger the faster you serve). Wrong serve → −￥30 & −1 reputation.
- A customer whose patience hits zero leaves angry → −1 reputation.
- Lose all 3 reputation **or** survive the 120-second day to end the shift.

## 📂 Project layout

```
ramen-ya/
├── project.godot          # engine config (GL Compatibility renderer — best for Web)
├── export_presets.cfg     # ready-made "Web" export preset → build/index.html
├── icon.svg
├── scenes/Main.tscn       # main scene
├── scripts/Main.gd        # entire game (state machine + pixel rendering)
└── build/                 # web export output goes here
```

## ▶️ Run it (editor)

1. Install **Godot 4.3+** (standard, not .NET): https://godotengine.org/download
2. Open Godot → **Import** → select `project.godot` in this folder.
3. Press **F5** (Play).

## 🌐 Export to Web (HTML5)

### Option A — from the editor
1. First time only: **Editor → Manage Export Templates → Download and Install**
   (matches your Godot version).
2. **Project → Export…** → the **Web** preset is already configured →
   **Export Project** → save as `build/index.html`.

### Option B — command line (headless)
```bash
# from the project folder, with export templates installed
godot --headless --export-release "Web" build/index.html
```

### Serve the export locally
Browsers won't run the game from `file://` (and it needs cross-origin isolation headers),
so serve it over HTTP:

```bash
cd build
python3 -m http.server 8000
# open http://localhost:8000
```

> The export preset already enables **cross-origin isolation headers** for PWA hosting.
> If you self-host elsewhere, make sure the server sends:
> `Cross-Origin-Opener-Policy: same-origin` and
> `Cross-Origin-Embedder-Policy: require-corp`
> (Godot ships `coi-serviceworker` to help when you can't set headers — or just use
> `python3 -m http.server` locally for testing).

## 🛠️ Tech notes
- Renderer: **GL Compatibility** (OpenGL ES 3 / WebGL2) — the most reliable choice for Web.
- Display: 480×270 base canvas, `canvas_items` stretch with `keep` aspect → crisp pixels.
- Single-file game logic lives in `scripts/Main.gd`.

---
Demo scaffold — extend it with new recipes, day/night cycles, upgrades, sound, etc. 🍜
