# 拉麵屋 · 素材 AI 生成提示词包

> 用法:每张**单独生成**,把**原始整图发我(不要自己裁切/缩放)**,我来切片、抠底、缩放、导入。
> 每个提示词都先加下面这段【统一风格】,保证整套素材一致。

## 【统一风格】(粘在每个提示词开头)
```
cozy detailed 16-bit pixel art, warm cozy Chinese ramen-shop theme,
soft directional lighting, clean readable shapes, limited warm palette,
crisp pixels, no text, no letters, no logos, no watermark, no UI, no grid lines
```

## 【通用规则】
- **要抠图的**(角色 / 物件 / 建筑 / 道具):**纯黑 `#000000` 背景**,主体居中、四周留空,**不要地面阴影**。
- **整张背景图**(档口/场景):正常作画,铺满画面。
- 尽量大尺寸生成(1024² 或更大),我会降采样到游戏像素尺寸。

---

## 1. 主角 · 行走精灵(1 张)
对应 `chef_sheet.png`
```
<统一风格>
A single character walk sprite sheet on a pure solid BLACK (#000000) background.
Character: a cool young guy with spiky WHITE/silver hair, plain WHITE t-shirt,
navy shorts, white sneakers, friendly face.
Layout: a strict 4x4 grid, every cell the SAME size, character centered with even
margin and the SAME feet baseline in every cell.
Row 1 = facing the viewer (front).  Row 2 = facing away (back).
Row 3 = side profile facing LEFT.    Row 4 = side profile facing RIGHT.
Each row is a 4-frame walking cycle (legs/arms swing). Full body head-to-feet.
No grid lines, no ground shadow. ~1024x1024.
```

## 2. 档口做面物件合集(1 张 atlas)
对应 `td_*`(碗/大缸/料盒/手持)
```
<统一风格>
A neat sprite atlas of top-down (slightly tilted 3/4 overhead) ramen-kitchen
objects, each object centered in its own cell, evenly spaced on a pure BLACK
(#000000) background. Objects, left-to-right, top-to-bottom:
1) a big ramen BOWL seen from above: golden broth, a nest of noodles, sliced beef on top;
2) a big glazed dark-brown earthenware VAT full of golden bubbling broth (soup vat);
3) a big glazed earthenware VAT with clear water and a round metal noodle basket (noodle vat);
4) a ladle/scoop holding broth;
5) a clump of cooked noodles;
6) a small square metal tray of chopped green scallion;
7) a small square metal tray of dark-green cilantro;
8) a small square metal tray of sliced beef;
9) a small square metal tray of red chili.
Consistent lighting, clean outlines, generous spacing between items, no grid lines.
```

## 3. 建筑(各 1 张,纯黑底,整栋居中)
对应 `world/`
- **拉麵店 `shop`**
```
<统一风格>
A single small Chinese ramen-shop storefront building, front 3/4 view, full
building centered on pure BLACK (#000000) background with margin. Wooden facade,
green noren curtain over the door, a hanging sign, two warm lanterns, glowing
windows. Cozy, inviting. No ground, no shadow.
```
- **紫金大廈 `tower_ext`**(竖高)
```
<统一风格>
A tall imposing purple-and-gold Chinese office tower, front view, the WHOLE tower
visible and centered on pure BLACK (#000000) background, taller than wide. An open
black gate at the base. Slightly mysterious. No ground, no shadow.
```
- **普通临街楼 `bldg1/2/3`**(生成 3 个变体)
```
<统一风格>
A mid-rise Chinese commercial-street building, front 3/4 view, centered on pure
BLACK (#000000) background. Shops on the ground floor, windows above. Make 3
distinct variants (different colors/heights). No ground, no shadow.
```

## 4. 道具 / 自然(纯黑底)
- **树 `tree`**
```
<统一风格>
A single small stylized street tree, centered on pure BLACK (#000000) background,
lush round canopy, short trunk. No ground, no shadow.
```

## 5. 店内 tiles(1 张 tileset,可选)
对应 `shop/`(floor/wall/counter/kitchen/door/table/chair/lantern/bowl)
```
<统一风格>
A top-down interior tileset grid for a cozy ramen-shop room: wooden FLOOR tile,
plaster WALL tile, service COUNTER tile, KITCHEN/stove tile, wooden DOOR tile,
square TABLE (top-down), CHAIR (top-down), hanging LANTERN, a small ramen BOWL.
Each on its own cell, evenly spaced, pure BLACK (#000000) background, top-down view,
seamless-friendly. No grid lines.
```

## 6. 地块 tiles(⚠️ 建议保留程序化)
`grass/path/road/water/sand/pavement` —— AI 很难画**无缝拼接**的地砖,接缝会很明显。
**建议**:这 7 个 16×16 地块继续用现有 `world/generate.py` 程序生成;若坚持 AI,需要标 “seamless tileable texture, edges wrap perfectly”,且大概率要我手工修接缝。

## 7. App 图标(1 张,可重做)
对应 `icon/`
```
<统一风格, 但要 opaque 背景>
A polished iOS app icon: a single bowl of ramen, bold and centered, warm red
background, no text. Clean, recognizable at small size. Opaque (no transparency),
1024x1024 square.
```

---

## 生成顺序建议(从影响最大到最小)
1. 档口背景(已换 ✅) → 2. 主角精灵 → 3. 档口做面物件 → 4. 拉面店 + 紫金大廈 → 5. 树/普通楼 → 6. 店内 tiles → 7. App 图标 → (地块按需)

---

# 地面 / 地块 · 可平铺纹理(seamless tiles)
> ⚠️ 关键:**无缝拼接**。每个都**单独**生成一张正方形纹理,我会降采样到 16×16 并检查接缝(有缝我手修)。
> 每个提示词同样先加【统一风格】,再加下面这段【平铺约束】:

## 【平铺约束】(粘在每个地块提示词)
```
a SEAMLESS TILEABLE top-down ground texture, the pattern repeats perfectly and
the edges wrap on all four sides (no visible seam when tiled), uniform flat
lighting, no objects, no props, no shadows, fills the entire square frame,
512x512.
```

## 室外地块（对应 `world/`）
- **草地 `grass`**
```
<统一风格> <平铺约束>
lush short green grass, subtle blade texture, gentle color variation.
```
- **草地·花点 `grass2`**
```
<统一风格> <平铺约束>
green grass with a few tiny scattered flowers, slightly lighter than plain grass.
```
- **泥土小路 `path`**
```
<统一风格> <平铺约束>
packed dirt / fine gravel path, warm earthy brown, small pebbles.
```
- **沙地 `sand`**
```
<统一风格> <平铺约束>
fine pale sand, soft granular texture.
```
- **水面 `water`**
```
<统一风格> <平铺约束>
calm shallow water, gentle ripples, soft teal-blue, subtle highlights.
```
- **人行道石板 `pavement`**
```
<统一风格> <平铺约束>
neat light-grey stone paving slabs, clean grout lines, walkable sidewalk.
```
- **石板街道 `road`**
```
<统一风格> <平铺约束>
old cobblestone street, rounded grey stones with mortar gaps, slightly worn.
```

## 室内地面 / 墙面（对应 `shop/`）
- **木地板 `floor`**
```
<统一风格> <平铺约束>
warm wooden plank floor, top-down, cozy ramen-shop interior.
```
- **墙面 `wall`**
```
<统一风格> <平铺约束>
plain plaster interior wall with a thin lower wood wainscot line, warm neutral tone.
```

> 备选(更省事):把以上 9 个做成**一张 3x3 的网格大图**,每格一个材质——但**每一格自身必须无缝**(不是格子之间无缝)。单张分开生成通常拼接更干净。
