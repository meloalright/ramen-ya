extends Node2D
# =====================================================================
#  RAMEN-YA  /  らーめん屋  —  OPEN WORLD
#  A small Stardew-Valley-style overworld: walk the chef freely around a
#  procedurally-drawn tile map, with a follow-camera and collisions.
#  Walk up to the ramen shop and press [E] to enter the cooking minigame
#  (the original single-screen game, scenes/Main.tscn).
#
#  Everything is drawn procedurally in _draw() in WORLD coordinates; the
#  Camera2D child scrolls/zooms it, so no external tileset assets are
#  needed and it still exports cleanly to Web / HTML5.
# =====================================================================

# ---- tile grid ------------------------------------------------------
const TILE := 16
const MAP_W := 56            # tiles
const MAP_H := 40

# tile ids
enum {
	T_GRASS,        # 0  walkable
	T_GRASS2,       # 1  walkable (flowery)
	T_PATH,         # 2  walkable (dirt road)
	T_SAND,         # 3  walkable
	T_WATER,        # 4  blocked
	T_TREE,         # 5  blocked (trunk); canopy drawn above
	T_WALL,         # 6  blocked (shop wall)
	T_ROOF,         # 7  blocked (shop roof)
	T_DOOR,         # 8  walkable — shop entrance trigger
	T_ROAD,         # 9  walkable (asphalt street)
	T_PAVE,         # 10 walkable (sidewalk)
	T_BLD,          # 11 blocked (a neighbour building's footprint)
}

var map: Array = []           # MAP_H rows of MAP_W ints
var door_cell := Vector2i(-1, -1)     # ramen shop entrance
var tower_cell := Vector2i(-1, -1)    # 紫金大廈 entrance
var buildings: Array = []     # {x, ft, tex, kind} — storefronts along the street

# ---- palette --------------------------------------------------------
const C_GRASS    := Color("4e8a3c")
const C_GRASS_D  := Color("3f7331")
const C_GRASS_HI := Color("5fa049")
const C_FLOWER_A := Color("e7d24e")
const C_FLOWER_B := Color("e06b9a")
const C_PATH     := Color("b08456")
const C_PATH_D   := Color("8f6840")
const C_SAND     := Color("dcc88a")
const C_WATER    := Color("3b6db0")
const C_WATER_HI := Color("5a8bd0")
const C_TRUNK    := Color("6b4a2b")
const C_LEAF     := Color("2f7a3e")
const C_LEAF_D   := Color("236030")
const C_LEAF_HI  := Color("46a256")
const C_WALL     := Color("c8a06a")
const C_WALL_D   := Color("a07c4c")
const C_ROOF     := Color("c23b3b")
const C_ROOF_D   := Color("9a2e2e")
const C_DOOR     := Color("5a3a22")
const C_INK      := Color("1a1620")
const C_WHITE    := Color("f4f0e6")
const C_YELLOW   := Color("f2c14e")

# ---- player ---------------------------------------------------------
var player_pos := Vector2(0, 0)       # world px (feet anchor)
var player_vel := Vector2.ZERO
const PLAYER_SPEED := 78.0
const PLAYER_H := 26.0                 # draw height (px)
const FEET_W := 11.0                   # collision box at the feet
const FEET_H := 7.0
var facing := 0                        # 0 down, 1 left, 2 right, 3 up
var moving := false
var anim_t := 0.0
var anim_i := 0
const STEP_SEQ := [0, 1, 2, 3]         # column cycle while walking

# chef spritesheet (3 cols x 3 rows)  rows: 0 down, 1 side(left), 2 up
var chef_tex: Texture2D
const CHEF_FW := 52
const CHEF_FH := 68
const ROW_DOWN := 0
const ROW_SIDE := 1
const ROW_UP := 2

# ---- camera ---------------------------------------------------------
@onready var cam: Camera2D = $Camera

# ---- interaction ----------------------------------------------------
var near_door := false       # near the ramen shop door
var near_tower := false      # near the 紫金大廈 gate
var font: Font
var hint_blink := 0.0

# ---- generated overworld tileset (assets/world/*.png) --------------
var wtex := {}

# ---- click / touch to move -----------------------------------------
var move_target := Vector2.ZERO
var has_target := false
var pending_enter := ""        # "" | "shop" | "tower" — enter on arrival


# =====================================================================
func _ready() -> void:
	font = _make_font()
	if ResourceLoader.exists("res://assets/chef_sheet.png"):
		chef_tex = load("res://assets/chef_sheet.png")
	_load_world_tiles()
	_build_map()
	# spawn: saved position (Continue) or just south of the shop door (new)
	if Game.has_pos:
		player_pos = Game.world_pos
	elif door_cell.x >= 0:
		player_pos = Vector2(door_cell.x * TILE + TILE / 2.0, (door_cell.y + 3) * TILE)
	else:
		player_pos = Vector2(MAP_W * TILE / 2.0, MAP_H * TILE / 2.0)
	_setup_camera()
	set_process(true)


func _setup_camera() -> void:
	cam.zoom = Vector2(2.5, 2.5)
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 8.0
	# clamp camera to the map so we never show outside the world
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = MAP_W * TILE
	cam.limit_bottom = MAP_H * TILE
	cam.position = player_pos
	cam.reset_smoothing()


# crisp pixel Traditional-Chinese font (Zpix), antialiasing off
func _make_font() -> Font:
	if ResourceLoader.exists("res://assets/fonts/zpix.ttf"):
		var f = load("res://assets/fonts/zpix.ttf")
		if f is FontFile:
			f.antialiasing = TextServer.FONT_ANTIALIASING_NONE
			f.hinting = TextServer.HINTING_NONE
			f.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
		return f
	return ThemeDB.fallback_font


func _load_world_tiles() -> void:
	for key in ["grass", "grass2", "path", "sand", "water", "tree", "shop",
			"pavement", "road", "bldg1", "bldg2", "bldg3", "tower_ext"]:
		var p := "res://assets/world/%s.png" % key
		if ResourceLoader.exists(p):
			wtex[key] = load(p)


# =====================================================================
#  MAP GENERATION  (deterministic — fixed seed)
# =====================================================================
func _build_map() -> void:
	seed(20260621)
	map = []
	for y in MAP_H:
		var row := []
		for x in MAP_W:
			row.append(T_GRASS2 if randi() % 8 == 0 else T_GRASS)
		map.append(row)

	# --- the commercial street: a horizontal road with sidewalks ---
	var street_y := 22                       # top row of the cobbled street
	for y in range(street_y, street_y + 4):  # cobblestones
		for x in MAP_W:
			map[y][x] = T_ROAD
	for y in range(street_y - 3, street_y):  # north sidewalk
		for x in MAP_W:
			map[y][x] = T_PAVE
	for y in range(street_y + 4, street_y + 6):  # south sidewalk
		for x in MAP_W:
			map[y][x] = T_PAVE

	# --- a row of storefronts along the north side ---
	buildings.clear()
	var ft := street_y - 7                   # footprint top (4 rows tall)
	var slots := [2, 11, 20, 29, 38, 47]
	var variants := ["bldg1", "bldg2", "bldg3", "bldg2", "bldg3", "bldg1"]
	var ramen_slot := 2
	var tower_slot := 3                       # the 紫金大廈, right of the ramen shop
	for i in slots.size():
		var sx: int = slots[i]
		for yy in range(ft, ft + 4):
			for xx in range(sx, sx + 6):
				if xx < MAP_W and yy < MAP_H:
					map[yy][xx] = T_BLD
		var dx := sx + 3
		var dy := ft + 3
		if i == ramen_slot:
			map[dy][dx] = T_DOOR
			door_cell = Vector2i(dx, dy)
			buildings.append({"x": sx, "ft": ft, "tex": "shop", "kind": "ramen"})
		elif i == tower_slot:
			map[dy][dx] = T_DOOR
			tower_cell = Vector2i(dx, dy)
			buildings.append({"x": sx, "ft": ft, "tex": "tower_ext", "kind": "tower"})
		else:
			buildings.append({"x": sx, "ft": ft, "tex": variants[i], "kind": "deco"})

	# --- street trees: one in each gap between storefronts (right by the kerb) ---
	for i in range(slots.size() - 1):
		var ax: int = slots[i] + 7
		if ax < MAP_W and map[ft + 3][ax] == T_GRASS:
			map[ft + 3][ax] = T_TREE
	# --- a leafy row lining the far (south) side of the street ---
	for x in range(4, MAP_W - 2, 5):
		if map[street_y + 6][x] == T_GRASS:
			map[street_y + 6][x] = T_TREE
	# --- scattered background trees for depth ---
	for i in 16:
		var tx: int = randi() % MAP_W
		var ty: int = street_y + 9 + randi() % int(max(1, MAP_H - street_y - 11))
		if ty < MAP_H - 1 and map[ty][tx] == T_GRASS:
			map[ty][tx] = T_TREE


func _shop_door_front() -> Vector2:
	return Vector2(door_cell.x * TILE + TILE / 2.0, (door_cell.y + 3) * TILE)


# =====================================================================
#  COLLISION
# =====================================================================
func _tile_at(wx: float, wy: float) -> int:
	var tx := int(floor(wx / TILE))
	var ty := int(floor(wy / TILE))
	if tx < 0 or ty < 0 or tx >= MAP_W or ty >= MAP_H:
		return T_WALL        # treat out-of-bounds as solid
	return map[ty][tx]


func _blocked(tile: int) -> bool:
	return tile == T_WATER or tile == T_TREE or tile == T_WALL or tile == T_ROOF or tile == T_BLD


# can the feet-box centered at (cx, feet_y) occupy this spot?
func _can_stand(cx: float, feet_y: float) -> bool:
	var x0 := cx - FEET_W / 2.0
	var x1 := cx + FEET_W / 2.0
	var y0 := feet_y - FEET_H
	var y1 := feet_y
	for px in [x0, x1]:
		for py in [y0, y1]:
			if _blocked(_tile_at(px, py)):
				return false
	return true


# =====================================================================
#  LOOP
# =====================================================================
func _process(delta: float) -> void:
	hint_blink += delta

	# --- input vector (WASD + arrows) ---
	var dir := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
		dir.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
		dir.x += 1.0
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
		dir.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
		dir.y += 1.0

	# keyboard takes over; otherwise steer toward a clicked/tapped target
	if dir != Vector2.ZERO:
		has_target = false
		pending_enter = ""
	elif has_target:
		var to: Vector2 = move_target - player_pos
		if to.length() <= 2.5:
			has_target = false
		else:
			dir = to.normalized()

	var prev := player_pos
	moving = dir != Vector2.ZERO
	if moving:
		dir = dir.normalized()
		# face the dominant axis
		# deadband: only switch facing when one axis clearly dominates, so
		# near-diagonal / near-target jitter doesn't flicker the sprite
		if abs(dir.x) - abs(dir.y) > 0.34:
			facing = 1 if dir.x < 0.0 else 2
		elif abs(dir.y) - abs(dir.x) > 0.34:
			facing = 3 if dir.y < 0.0 else 0

	# --- move with axis-separated collision (slide along walls) ---
	var step := dir * PLAYER_SPEED * delta
	var nx := player_pos.x + step.x
	if _can_stand(nx, player_pos.y):
		player_pos.x = nx
	var ny := player_pos.y + step.y
	if _can_stand(player_pos.x, ny):
		player_pos.y = ny

	# keep inside the world bounds
	player_pos.x = clamp(player_pos.x, FEET_W, MAP_W * TILE - FEET_W)
	player_pos.y = clamp(player_pos.y, FEET_H + 2, MAP_H * TILE - 2)

	# click-move that hit a wall and made no progress → drop the target
	if has_target and dir != Vector2.ZERO and player_pos.distance_to(prev) < 0.05:
		has_target = false
		pending_enter = ""

	# --- walk animation ---
	if moving:
		anim_t += delta
		if anim_t > 0.16:
			anim_t -= 0.16
			anim_i = (anim_i + 1) % STEP_SEQ.size()
	else:
		anim_i = 0
		anim_t = 0.0

	# --- camera follow ---
	cam.position = player_pos

	# --- entrance proximity ---
	near_door = door_cell.x >= 0 and player_pos.distance_to(_cell_front(door_cell)) < 26.0
	near_tower = tower_cell.x >= 0 and player_pos.distance_to(_cell_front(tower_cell)) < 26.0

	# walked up to an entrance after tapping it → step inside
	if pending_enter == "shop" and near_door:
		_enter_shop()
		return
	if pending_enter == "tower" and near_tower:
		_enter_tower()
		return

	queue_redraw()


func _cell_front(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * TILE + TILE / 2.0, cell.y * TILE + TILE)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E:
			if near_door:
				_enter_shop()
			elif near_tower:
				_enter_tower()
		elif event.keycode == KEY_ESCAPE:
			Game.remember_pos(player_pos)
			get_tree().change_scene_to_file("res://scenes/Menu.tscn")
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# (touch is delivered as a mouse button too — emulate_mouse_from_touch)
		_on_pointer(get_global_mouse_position())


func _on_pointer(world_pos: Vector2) -> void:
	# tapping an entrance walks there and enters (great for touch / mouse-only)
	if door_cell.x >= 0 and _cell_rect(door_cell).has_point(world_pos):
		if near_door: _enter_shop()
		else: _walk_to_enter(door_cell, "shop")
		return
	if tower_cell.x >= 0 and _cell_rect(tower_cell).has_point(world_pos):
		if near_tower: _enter_tower()
		else: _walk_to_enter(tower_cell, "tower")
		return
	# otherwise just walk toward the tapped point
	move_target = world_pos
	has_target = true
	pending_enter = ""


func _walk_to_enter(cell: Vector2i, what: String) -> void:
	move_target = _cell_front(cell)
	has_target = true
	pending_enter = what


func _cell_rect(cell: Vector2i) -> Rect2:
	return Rect2(cell.x * TILE, cell.y * TILE, TILE, TILE)


func _enter_shop() -> void:
	Game.remember_pos(player_pos)
	get_tree().change_scene_to_file("res://scenes/Shop.tscn")


func _enter_tower() -> void:
	Game.remember_pos(player_pos)
	get_tree().change_scene_to_file("res://scenes/Tower.tscn")


# =====================================================================
#  DRAWING  (world coordinates; camera handles scroll/zoom)
# =====================================================================
func _draw() -> void:
	# only draw tiles roughly within the camera view for a little perf
	var view := _visible_tile_rect()
	# ground pass
	for ty in range(view.position.y, view.end.y):
		for tx in range(view.position.x, view.end.x):
			_draw_ground_tile(tx, ty)
	# object pass (trees, buildings, player) sorted by Y so things overlap right
	var objs: Array = []
	for ty in range(view.position.y, view.end.y):
		for tx in range(view.position.x, view.end.x):
			var t: int = map[ty][tx]
			if t == T_TREE:
				objs.append({"y": ty * TILE + TILE, "kind": "tree", "x": tx, "ty": ty})
	# storefront buildings, each anchored at its base row
	for b in buildings:
		objs.append({"y": (int(b.ft) + 4) * TILE, "kind": "bld", "b": b})
	# player
	objs.append({"y": player_pos.y, "kind": "player"})
	objs.sort_custom(func(a, b): return a.y < b.y)
	for o in objs:
		match o.kind:
			"tree":
				_draw_tree(o.x, o.ty)
			"bld":
				_draw_building(o.b)
			"player":
				_draw_player()

	# click/tap destination marker
	if has_target:
		_draw_target_marker()

	# entrance hint above the player's head
	if near_door:
		_draw_hint("[E] 進店")
	elif near_tower:
		_draw_hint("[E] 進入")

	# screen-space HUD pinned to the top-left of the view
	var vtl: Vector2 = cam.position - get_viewport_rect().size / (2.0 * cam.zoom)
	draw_rect(Rect2(vtl.x + 4, vtl.y + 4, 62, 16), Color(0, 0, 0, 0.55))
	_wtext("￥ " + str(Game.coins), vtl + Vector2(9, 16), 9, C_YELLOW)
	_wtext("[ESC] 菜單", vtl + Vector2(get_viewport_rect().size.x / cam.zoom.x - 50, 16), 8, Color(1, 1, 1, 0.7))


func _visible_tile_rect() -> Rect2i:
	var vsize := get_viewport_rect().size / cam.zoom
	var tl: Vector2 = cam.position - vsize / 2.0
	var x0: int = max(0, int(floor(tl.x / TILE)) - 1)
	var y0: int = max(0, int(floor(tl.y / TILE)) - 1)
	var x1: int = min(MAP_W, int(ceil((tl.x + vsize.x) / TILE)) + 2)
	var y1: int = min(MAP_H, int(ceil((tl.y + vsize.y) / TILE)) + 2)
	return Rect2i(x0, y0, x1 - x0, y1 - y0)


# deterministic pseudo-random 0..1 per tile (for stable detailing)
func _tnoise(x: int, y: int, salt: int) -> float:
	var n := (x * 374761393 + y * 668265263 + salt * 1442695040) & 0x7fffffff
	n = (n ^ (n >> 13)) * 1274126177
	return float((n & 0xffff)) / 65535.0


func _draw_ground_tile(tx: int, ty: int) -> void:
	var t: int = map[ty][tx]
	var px := tx * TILE
	var py := ty * TILE
	var nm := "grass"
	match t:
		T_WATER: nm = "water"
		T_PATH:  nm = "path"
		T_SAND:  nm = "sand"
		T_GRASS2: nm = "grass2"
		T_ROAD:  nm = "road"
		T_PAVE:  nm = "pavement"
		T_DOOR:  nm = "pavement"   # ground under the ramen door
		_: nm = "grass"
	if wtex.has(nm):
		draw_texture_rect(wtex[nm], Rect2(px, py, TILE, TILE), false)
	else:
		_draw_ground_fallback(tx, ty)


func _draw_ground_fallback(tx: int, ty: int) -> void:
	var t: int = map[ty][tx]
	var px := tx * TILE
	var py := ty * TILE
	var r := Rect2(px, py, TILE, TILE)
	match t:
		T_WATER:
			draw_rect(r, C_WATER)
			if _tnoise(tx, ty, 3) > 0.55:
				var wy := py + 4 + int(_tnoise(tx, ty, 9) * 7)
				draw_rect(Rect2(px + 3, wy, 7, 1), C_WATER_HI)
		T_PATH:
			draw_rect(r, C_PATH)
			if _tnoise(tx, ty, 5) > 0.6:
				draw_rect(Rect2(px + int(_tnoise(tx, ty, 1) * 11), py + int(_tnoise(tx, ty, 2) * 11), 2, 2), C_PATH_D)
		T_SAND:
			draw_rect(r, C_SAND)
		_:
			# grass (and the ground under trees / flowery grass)
			draw_rect(r, C_GRASS)
			# subtle blade speckles
			if _tnoise(tx, ty, 7) > 0.5:
				draw_rect(Rect2(px + 2, py + 9, 2, 3), C_GRASS_D)
			if _tnoise(tx, ty, 4) > 0.62:
				draw_rect(Rect2(px + 10, py + 4, 2, 3), C_GRASS_HI)
			if t == T_GRASS2:
				var fc := C_FLOWER_A if _tnoise(tx, ty, 8) > 0.5 else C_FLOWER_B
				draw_rect(Rect2(px + 6, py + 7, 3, 3), fc)


func _draw_tree(tx: int, ty: int) -> void:
	var px := tx * TILE + TILE / 2.0
	var base := ty * TILE + TILE
	if wtex.has("tree"):
		var t: Texture2D = wtex["tree"]
		var tw := t.get_width()
		var th := t.get_height()
		# soft shadow at the trunk base
		draw_rect(Rect2(px - 7, base - 3, 14, 4), Color(0, 0, 0, 0.18))
		draw_texture_rect(t, Rect2(px - tw / 2.0, base - th, tw, th), false)
		return
	# fallback: stacked blobs
	draw_rect(Rect2(px - 2, base - 9, 4, 9), C_TRUNK)
	draw_rect(Rect2(px - 11, base - 30, 22, 16), C_LEAF_D)
	draw_rect(Rect2(px - 9, base - 33, 18, 16), C_LEAF)
	draw_rect(Rect2(px - 6, base - 36, 12, 12), C_LEAF_HI)
	draw_rect(Rect2(px - 4, base - 30, 3, 3), C_LEAF_HI)
	draw_rect(Rect2(px + 3, base - 24, 3, 3), C_LEAF_HI)


func _draw_building(b: Dictionary) -> void:
	var sx: int = b.x
	var ft: int = b.ft
	var bottom := (ft + 4) * TILE                 # footprint bottom edge (px)
	if wtex.has(b.tex):
		var s: Texture2D = wtex[b.tex]
		var ox := sx * TILE
		var oy := bottom - s.get_height()         # bottom-aligned
		draw_texture_rect(s, Rect2(ox, oy, s.get_width(), s.get_height()), false)
		var mid := ox + s.get_width() / 2.0
		if b.kind == "ramen":
			_wtext("拉麵", Vector2(mid, oy + 134), 9, C_WHITE, HORIZONTAL_ALIGNMENT_CENTER)
		elif b.kind == "tower":
			_wtext("紫金", Vector2(mid, oy + 130), 9, C_YELLOW, HORIZONTAL_ALIGNMENT_CENTER)
		return
	# fallback box
	draw_rect(Rect2(sx * TILE, ft * TILE, 6 * TILE, 4 * TILE), C_WALL)


func _draw_player() -> void:
	var w := CHEF_FW / float(CHEF_FH) * PLAYER_H
	var dst := Rect2(player_pos.x - w / 2.0, player_pos.y - PLAYER_H, w, PLAYER_H)
	# soft shadow at the feet
	draw_rect(Rect2(player_pos.x - 6, player_pos.y - 2, 12, 4), Color(0, 0, 0, 0.22))
	if chef_tex == null:
		draw_rect(dst, C_YELLOW)
		return
	var row := ROW_DOWN
	var flip := false
	match facing:
		0: row = ROW_DOWN
		3: row = ROW_UP
		1: row = ROW_SIDE          # side art faces LEFT
		2: row = ROW_SIDE; flip = true
	var col: int = STEP_SEQ[anim_i] if moving else 0
	var src := Rect2(col * CHEF_FW, row * CHEF_FH, CHEF_FW, CHEF_FH)
	if flip:
		# mirror via a transform (clean per-frame sampling, no boundary bleed)
		var cx := dst.position.x + dst.size.x / 2.0
		draw_set_transform(Vector2(cx * 2.0, 0.0), 0.0, Vector2(-1.0, 1.0))
		draw_texture_rect_region(chef_tex, dst, src)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	else:
		draw_texture_rect_region(chef_tex, dst, src)


func _draw_hint(label: String) -> void:
	var hx := player_pos.x
	var hy := player_pos.y - PLAYER_H - 8
	if int(hint_blink * 2.0) % 2 == 0:
		var fs := 8
		var tw: float = font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_rect(Rect2(hx - tw / 2.0 - 4, hy - fs, tw + 8, fs + 4), Color(0, 0, 0, 0.72))
		_wtext(label, Vector2(hx, hy), fs, C_YELLOW, HORIZONTAL_ALIGNMENT_CENTER)


func _draw_target_marker() -> void:
	var a: float = 0.4 + 0.35 * sin(hint_blink * 8.0)
	var col := Color(1, 1, 0.4, a)
	draw_arc(move_target, 5.0, 0.0, TAU, 18, col, 1.2)
	draw_line(move_target - Vector2(3, 0), move_target + Vector2(3, 0), col, 1.0)
	draw_line(move_target - Vector2(0, 3), move_target + Vector2(0, 3), col, 1.0)


func _wtext(s: String, pos: Vector2, size: int, col: Color, align := HORIZONTAL_ALIGNMENT_LEFT) -> void:
	draw_string(font, pos + Vector2(0.6, 0.6), s, align, -1, size, C_INK)
	draw_string(font, pos, s, align, -1, size, col)
