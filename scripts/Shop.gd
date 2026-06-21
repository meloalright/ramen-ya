extends Node2D
# =====================================================================
#  RAMEN-YA — SHOP INTERIOR  /  店内
#  A walkable rectangular room: wooden floor, dining tables + chairs,
#  and a service counter (档口) along the back. Walk around freely;
#  step up to the COUNTER to start cooking, or to the DOOR to leave.
#
#  Same procedural / code-drawn style as the overworld (World.gd):
#  fixed camera framing the whole room, click/tap or WASD to move.
# =====================================================================

const TILE := 16
const MAP_W := 11            # tiles (incl. walls) — narrow
const MAP_H := 20            # short, cosy room

enum { FLOOR, WALL, KITCHEN, COUNTER, TABLE, CHAIR, DOOR }

var map: Array = []
var counter_zone: Rect2          # floor strip right in front of the counter
var door_cell := Vector2i(-1, -1)

# decorative seated customers (no interaction, just to look busy)
var seated := {}                 # chair Vector2i -> face int
var bowl_tables := {}            # table Vector2i -> true (a ramen bowl sits here)

# remembers where to drop the player when (re)entering this scene
static var entry := "door"       # "door" (from overworld) | "counter" (from cooking)

# ---- palette --------------------------------------------------------
const C_FLOOR    := Color("7a5230")
const C_FLOOR_D  := Color("6a4628")
const C_FLOOR_HI := Color("8a5f38")
const C_WALL     := Color("3a2a1c")
const C_WALL_HI  := Color("4d3826")
const C_KITCHEN  := Color("4b4550")
const C_STOVE    := Color("2a2630")
const C_BURNER   := Color("e0792e")
const C_COUNTER  := Color("c89b6a")
const C_COUNTER_D:= Color("a07c4c")
const C_TABLE    := Color("8a5a32")
const C_TABLE_HI := Color("a76f3f")
const C_CHAIR    := Color("5a3a22")
const C_DOOR     := Color("c23b3b")
const C_INK      := Color("1a1620")
const C_WHITE    := Color("f4f0e6")
const C_YELLOW   := Color("f2c14e")
const C_BOWL     := Color("e7e3d8")

# ---- player (shared with the overworld) -----------------------------
var player_pos := Vector2.ZERO
const PLAYER_SPEED := 70.0
const PLAYER_H := 26.0
const FEET_W := 11.0
const FEET_H := 7.0
var facing := 3                  # start facing up (toward the counter)
var moving := false
var anim_t := 0.0
var anim_i := 0
const STEP_SEQ := [0, 1, 2, 3]

var chef_tex: Texture2D
const CHEF_FW := 52
const CHEF_FH := 68
const ROW_DOWN := 0
const ROW_SIDE := 1
const ROW_UP := 2

# ---- click / touch to move ------------------------------------------
var move_target := Vector2.ZERO
var has_target := false
enum { ACT_NONE, ACT_COOK, ACT_EXIT }
var pending := ACT_NONE

# ---- interaction ----------------------------------------------------
var near_counter := false
var near_exit := false
var font: Font
var blink := 0.0

@onready var cam: Camera2D = $Camera

# generated pixel-art tileset (assets/shop/*.png); empty → procedural fallback
var tex := {}
const GROUND_NAME := {
	FLOOR: "floor", WALL: "wall", COUNTER: "counter",
	KITCHEN: "kitchen", DOOR: "door", TABLE: "floor", CHAIR: "floor",
}


# =====================================================================
func _ready() -> void:
	font = _make_font()
	if ResourceLoader.exists("res://assets/chef_sheet.png"):
		chef_tex = load("res://assets/chef_sheet.png")
	_load_tileset()
	_build_room()
	# spawn point depends on how we got here
	if entry == "counter":
		player_pos = Vector2(MAP_W * TILE / 2.0, 5 * TILE - 2)
		facing = 3
	else:
		player_pos = Vector2(door_cell.x * TILE + TILE / 2.0, (door_cell.y - 1) * TILE + 13)
		facing = 3
	entry = "door"              # default for the next overworld entry
	_setup_camera()
	set_process(true)


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


func _load_tileset() -> void:
	for key in ["floor", "wall", "counter", "kitchen", "table", "chair", "bowl", "door", "lantern"]:
		var p := "res://assets/shop/%s.png" % key
		if ResourceLoader.exists(p):
			tex[key] = load(p)


func _setup_camera() -> void:
	# narrow room: zoom so the WIDTH fills the screen, then scroll vertically
	var room := Vector2(MAP_W * TILE, MAP_H * TILE)
	var vp := get_viewport_rect().size
	var z: float = vp.x / room.x
	cam.zoom = Vector2(z, z)
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 9.0
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = int(room.x)
	cam.limit_bottom = int(room.y)
	cam.position = player_pos
	cam.reset_smoothing()


# =====================================================================
#  ROOM LAYOUT
# =====================================================================
func _build_room() -> void:
	map = []
	for y in MAP_H:
		var row := []
		for x in MAP_W:
			if x == 0 or y == 0 or x == MAP_W - 1 or y == MAP_H - 1:
				row.append(WALL)
			else:
				row.append(FLOOR)
		map.append(row)

	# kitchen back-bench + counter front along the top
	for x in range(1, MAP_W - 1):
		map[1][x] = KITCHEN
		map[2][x] = COUNTER
	counter_zone = Rect2(TILE, 3 * TILE, (MAP_W - 2) * TILE, 2 * TILE)

	# exit door in the bottom wall, centered
	var dx := MAP_W / 2
	map[MAP_H - 1][dx] = DOOR
	door_cell = Vector2i(dx, MAP_H - 1)

	# booths down both walls (clear central aisle), some with seated diners
	seed(771)
	seated.clear()
	bowl_tables.clear()
	for ry in [6, 10, 14]:
		_make_booth(ry, 1, 2, 3)                              # left
		_make_booth(ry, MAP_W - 2, MAP_W - 3, MAP_W - 4)     # right


func _make_booth(ry: int, t_outer: int, t_inner: int, chair_x: int) -> void:
	# some booths are a long two-seat table (spanning an extra row)
	var two_seat: bool = randi() % 100 < 40
	var rows := [ry]
	if two_seat:
		rows.append(ry + 1)
	for r in rows:
		map[r][t_outer] = TABLE
		map[r][t_inner] = TABLE
		map[r][chair_x] = CHAIR
	# seat diners → bowl on the table in front of each
	if randi() % 100 < 60:
		seated[Vector2i(chair_x, ry)] = randi() % 4
		bowl_tables[Vector2i(t_inner, ry)] = true
		# a companion on the second seat most of the time
		if two_seat and randi() % 100 < 75:
			seated[Vector2i(chair_x, ry + 1)] = randi() % 4
			bowl_tables[Vector2i(t_inner, ry + 1)] = true


# =====================================================================
#  COLLISION
# =====================================================================
func _tile_at(wx: float, wy: float) -> int:
	var tx := int(floor(wx / TILE))
	var ty := int(floor(wy / TILE))
	if tx < 0 or ty < 0 or tx >= MAP_W or ty >= MAP_H:
		return WALL
	return map[ty][tx]


func _blocked(t: int) -> bool:
	return t == WALL or t == KITCHEN or t == COUNTER or t == TABLE or t == CHAIR


func _can_stand(cx: float, feet_y: float) -> bool:
	for px in [cx - FEET_W / 2.0, cx + FEET_W / 2.0]:
		for py in [feet_y - FEET_H, feet_y]:
			if _blocked(_tile_at(px, py)):
				return false
	return true


# =====================================================================
#  LOOP
# =====================================================================
func _process(delta: float) -> void:
	blink += delta

	var dir := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
		dir.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
		dir.x += 1.0
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
		dir.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
		dir.y += 1.0

	if dir != Vector2.ZERO:
		has_target = false
		pending = ACT_NONE
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
		# deadband: only switch facing when one axis clearly dominates, so
		# near-diagonal / near-target jitter doesn't flicker the sprite
		if abs(dir.x) - abs(dir.y) > 0.34:
			facing = 1 if dir.x < 0.0 else 2
		elif abs(dir.y) - abs(dir.x) > 0.34:
			facing = 3 if dir.y < 0.0 else 0

	var step := dir * PLAYER_SPEED * delta
	if _can_stand(player_pos.x + step.x, player_pos.y):
		player_pos.x += step.x
	if _can_stand(player_pos.x, player_pos.y + step.y):
		player_pos.y += step.y

	if has_target and dir != Vector2.ZERO and player_pos.distance_to(prev) < 0.05:
		has_target = false
		pending = ACT_NONE

	if moving:
		anim_t += delta
		if anim_t > 0.16:
			anim_t -= 0.16
			anim_i = (anim_i + 1) % STEP_SEQ.size()
	else:
		anim_i = 0
		anim_t = 0.0

	# camera follows the player up/down the room
	cam.position = player_pos

	# interaction zones
	near_counter = counter_zone.has_point(player_pos)
	var dcenter := Vector2(door_cell.x * TILE + TILE / 2.0, door_cell.y * TILE)
	near_exit = player_pos.distance_to(dcenter) < 24.0

	# auto-trigger a pending click action on arrival
	if pending == ACT_COOK and near_counter:
		_cook()
		return
	if pending == ACT_EXIT and near_exit:
		_exit()
		return

	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E:
			if near_counter:
				_cook()
			elif near_exit:
				_exit()
		elif event.keycode == KEY_ESCAPE or event.keycode == KEY_M:
			_exit()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_pointer(get_global_mouse_position())


func _on_pointer(p: Vector2) -> void:
	# tap the counter band → walk up to it and start cooking
	if p.y < 3 * TILE and p.x > TILE and p.x < (MAP_W - 1) * TILE:
		if near_counter:
			_cook()
		else:
			move_target = Vector2(clamp(p.x, 2 * TILE, (MAP_W - 2) * TILE), 4 * TILE - 2)
			has_target = true
			pending = ACT_COOK
		return
	# tap the door → walk to it and leave
	if door_cell.x >= 0 and Rect2(door_cell.x * TILE, (door_cell.y - 1) * TILE, TILE, TILE * 2).has_point(p):
		if near_exit:
			_exit()
		else:
			move_target = Vector2(door_cell.x * TILE + TILE / 2.0, (door_cell.y - 1) * TILE + 12)
			has_target = true
			pending = ACT_EXIT
		return
	# otherwise walk toward the tapped point
	move_target = p
	has_target = true
	pending = ACT_NONE


func _cook() -> void:
	entry = "counter"
	get_tree().change_scene_to_file("res://scenes/Main.tscn")


func _exit() -> void:
	get_tree().change_scene_to_file("res://scenes/World.tscn")


# =====================================================================
#  DRAWING
# =====================================================================
func _draw() -> void:
	# floor + static tiles (counter/kitchen/walls/door)
	for ty in MAP_H:
		for tx in MAP_W:
			_draw_ground(tx, ty)

	# Y-sorted objects: furniture + player so overlaps look right
	var objs: Array = []
	for ty in MAP_H:
		for tx in MAP_W:
			var t: int = map[ty][tx]
			if t == TABLE or t == CHAIR:
				objs.append({"y": ty * TILE + TILE, "kind": t, "x": tx, "ty": ty})
	objs.append({"y": player_pos.y, "kind": -1})
	objs.sort_custom(func(a, b): return a.y < b.y)
	for o in objs:
		if o.kind == TABLE:
			_draw_table(o.x, o.ty)
		elif o.kind == CHAIR:
			_draw_chair(o.x, o.ty)
		else:
			_draw_player()

	# interaction prompts
	if near_counter:
		_draw_prompt("[E] 煮拉麵")
	elif near_exit:
		_draw_prompt("[E] 離開")

	if has_target:
		_draw_target()


func _draw_ground(tx: int, ty: int) -> void:
	var px := tx * TILE
	var py := ty * TILE
	var t: int = map[ty][tx]
	var nm: String = GROUND_NAME.get(t, "floor")
	if tex.has(nm):
		draw_texture_rect(tex[nm], Rect2(px, py, TILE, TILE), false)
	else:
		_draw_ground_fallback(tx, ty)
	# dressing: bowls along the counter, lanterns hung on the kitchen wall
	if t == COUNTER and tx % 3 == 1 and tex.has("bowl"):
		draw_texture_rect(tex["bowl"], Rect2(px, py - 2, TILE, TILE), false)
	if t == KITCHEN and (tx == 3 or tx == 7) and tex.has("lantern"):
		draw_texture_rect(tex["lantern"], Rect2(px, py - 5, TILE, TILE), false)


func _draw_ground_fallback(tx: int, ty: int) -> void:
	var px := tx * TILE
	var py := ty * TILE
	var r := Rect2(px, py, TILE, TILE)
	var t: int = map[ty][tx]
	match t:
		WALL:
			draw_rect(r, C_WALL)
			draw_rect(Rect2(px, py, TILE, 3), C_WALL_HI)
		KITCHEN:
			draw_rect(r, C_KITCHEN)
			# stove top with burners
			draw_rect(Rect2(px + 1, py + 5, TILE - 2, TILE - 6), C_STOVE)
			if (tx % 2) == 0:
				draw_rect(Rect2(px + 5, py + 8, 6, 5), C_BURNER)
		COUNTER:
			draw_rect(r, C_COUNTER)
			draw_rect(Rect2(px, py, TILE, 3), Color(1, 1, 1, 0.18))
			draw_rect(Rect2(px, py + TILE - 3, TILE, 3), C_COUNTER_D)
			# a few bowls lined up on the counter
			if (tx % 3) == 1:
				draw_rect(Rect2(px + 4, py + 4, 8, 5), C_BOWL)
				draw_rect(Rect2(px + 4, py + 4, 8, 2), C_DOOR)
		DOOR:
			draw_rect(r, C_WALL)
			draw_rect(Rect2(px + 2, py + 1, TILE - 4, TILE - 1), C_DOOR)
			draw_rect(Rect2(px + 2, py + 1, TILE - 4, 4), C_INK)
		_:
			# wooden floor with plank lines
			draw_rect(r, C_FLOOR)
			draw_rect(Rect2(px, py, TILE, 1), C_FLOOR_HI)
			draw_rect(Rect2(px, py + TILE - 1, TILE, 1), C_FLOOR_D)
			if (tx + ty) % 2 == 0:
				draw_rect(Rect2(px + TILE - 1, py, 1, TILE), C_FLOOR_D)


func _draw_table(tx: int, ty: int) -> void:
	var px := tx * TILE
	var py := ty * TILE
	var has_bowl: bool = bowl_tables.has(Vector2i(tx, ty))
	if tex.has("table"):
		draw_texture_rect(tex["table"], Rect2(px, py, TILE, TILE), false)
		if has_bowl and tex.has("bowl"):
			draw_texture_rect(tex["bowl"], Rect2(px, py - 3, TILE, TILE), false)
	else:
		draw_rect(Rect2(px, py + 3, TILE, TILE - 4), C_TABLE)
		draw_rect(Rect2(px, py + 3, TILE, 3), C_TABLE_HI)
		if has_bowl:
			draw_rect(Rect2(px + 4, py + 6, 9, 5), C_BOWL)
			draw_rect(Rect2(px + 4, py + 6, 9, 2), C_DOOR)


func _draw_chair(tx: int, ty: int) -> void:
	var px := tx * TILE
	var py := ty * TILE
	if tex.has("chair"):
		draw_texture_rect(tex["chair"], Rect2(px, py, TILE, TILE), false)
	else:
		draw_rect(Rect2(px + 3, py + 6, TILE - 6, TILE - 8), C_CHAIR)
		draw_rect(Rect2(px + 3, py + 4, TILE - 6, 3), C_TABLE_HI)
	# a seated diner on this chair?
	var cell := Vector2i(tx, ty)
	if seated.has(cell):
		_draw_diner(tx, ty, int(seated[cell]))


func _draw_diner(tx: int, ty: int, face: int) -> void:
	var skins := [Color("e8b98c"), Color("c98a5a"), Color("f0cba0"), Color("d9a06a")]
	var cloths := [Color("4e6fae"), Color("ae4e6f"), Color("4eae8a"), Color("9a6fae")]
	var skin: Color = skins[face % 4]
	var cloth: Color = cloths[face % 4]
	var cx := tx * TILE + TILE / 2.0
	var cy := ty * TILE + TILE / 2.0
	var left := tx < MAP_W / 2          # diner faces their table (toward the wall)
	# body + head sitting at the table
	draw_rect(Rect2(cx - 6, cy - 1, 12, 11), cloth)
	draw_rect(Rect2(cx - 6, cy - 1, 12, 2), Color(1, 1, 1, 0.12))
	draw_rect(Rect2(cx - 5, cy - 11, 10, 11), skin)
	draw_rect(Rect2(cx - 6, cy - 12, 12, 4), C_INK)
	# eyes toward the facing side
	if left:
		draw_rect(Rect2(cx - 5, cy - 6, 2, 2), C_INK)
		draw_rect(Rect2(cx - 1, cy - 6, 2, 2), C_INK)
	else:
		draw_rect(Rect2(cx - 1, cy - 6, 2, 2), C_INK)
		draw_rect(Rect2(cx + 3, cy - 6, 2, 2), C_INK)


func _draw_player() -> void:
	var w := CHEF_FW / float(CHEF_FH) * PLAYER_H
	var dst := Rect2(player_pos.x - w / 2.0, player_pos.y - PLAYER_H, w, PLAYER_H)
	draw_rect(Rect2(player_pos.x - 6, player_pos.y - 2, 12, 4), Color(0, 0, 0, 0.22))
	if chef_tex == null:
		draw_rect(dst, C_YELLOW)
		return
	var row := ROW_DOWN
	var flip := false
	match facing:
		0: row = ROW_DOWN
		3: row = ROW_UP
		1: row = ROW_SIDE
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


func _draw_prompt(label: String) -> void:
	if int(blink * 2.0) % 2 != 0:
		return
	var hx := player_pos.x
	var hy := player_pos.y - PLAYER_H - 6
	var fs := 8
	var tw: float = font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	draw_rect(Rect2(hx - tw / 2.0 - 4, hy - fs, tw + 8, fs + 4), Color(0, 0, 0, 0.72))
	_wtext(label, Vector2(hx, hy), fs, C_YELLOW, HORIZONTAL_ALIGNMENT_CENTER)


func _draw_target() -> void:
	var a: float = 0.4 + 0.35 * sin(blink * 8.0)
	var col := Color(1, 1, 0.4, a)
	draw_arc(move_target, 5.0, 0.0, TAU, 18, col, 1.2)
	draw_line(move_target - Vector2(3, 0), move_target + Vector2(3, 0), col, 1.0)
	draw_line(move_target - Vector2(0, 3), move_target + Vector2(0, 3), col, 1.0)


func _wtext(s: String, pos: Vector2, size: int, col: Color, align := HORIZONTAL_ALIGNMENT_LEFT) -> void:
	draw_string(font, pos + Vector2(0.6, 0.6), s, align, -1, size, C_INK)
	draw_string(font, pos, s, align, -1, size, col)
