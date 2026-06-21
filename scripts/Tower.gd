extends Node2D
# =====================================================================
#  紫金大廈  —  PURPLE-GOLD TOWER (a little action room)
#  Walk in through the open gate. Small monsters (小怪) roam the hall;
#  click one to attack it — two hits defeats it. Leave by the door.
# =====================================================================

const TILE := 16
const MAP_W := 16
const MAP_H := 24

enum { FLOOR, WALL, PILLAR, DOOR }
var map: Array = []
var door_cell := Vector2i(-1, -1)

# ---- palette --------------------------------------------------------
const C_FLOOR    := Color("3a2e4a")
const C_FLOOR_D  := Color("2e2440")
const C_FLOOR_HI := Color("463858")
const C_WALL     := Color("241c30")
const C_WALL_HI  := Color("3a2e4a")
const C_GOLD     := Color("d2aa4c")
const C_GOLD_D   := Color("a8842e")
const C_DOOR     := Color("141018")
const C_INK      := Color("141018")
const C_WHITE    := Color("f4f0e6")
const C_YELLOW   := Color("f2c14e")
const C_RED      := Color("d94f4f")
const C_MON      := Color("8a4ec8")
const C_MON_D    := Color("6a36a0")
const C_MON_HI   := Color("a86ee0")
const C_MON_EYE  := Color("f2e24e")

# ---- player ---------------------------------------------------------
var player_pos := Vector2.ZERO
const PLAYER_SPEED := 74.0
const PLAYER_H := 26.0
const FEET_W := 11.0
const FEET_H := 7.0
var facing := 3
var moving := false
var anim_t := 0.0
var anim_i := 0
const STEP_SEQ := [0, 1, 0, 2]

var chef_tex: Texture2D
const CHEF_FW := 200
const CHEF_FH := 301
const ROW_DOWN := 0
const ROW_SIDE := 1
const ROW_UP := 2

# ---- click / touch --------------------------------------------------
var move_target := Vector2.ZERO
var has_target := false
var exit_on_arrive := false

# ---- monsters -------------------------------------------------------
var monsters: Array = []        # {pos, hp, alive, hurt, bob, dead_t}
var defeated := 0
const MON_HP := 2

var near_exit := false
var font: Font
var blink := 0.0

@onready var cam: Camera2D = $Camera


func _ready() -> void:
	randomize()
	font = _make_font()
	if ResourceLoader.exists("res://assets/chef_sheet.png"):
		chef_tex = load("res://assets/chef_sheet.png")
	_build_room()
	_spawn_monsters(6)
	player_pos = Vector2(door_cell.x * TILE + TILE / 2.0, (door_cell.y - 1) * TILE + 12)
	facing = 3
	_setup_camera()
	set_process(true)


func _make_font() -> Font:
	if ResourceLoader.exists("res://assets/fonts/zpix.ttf"):
		var f = load("res://assets/fonts/zpix.ttf")
		if f is FontFile:
			f.antialiasing = TextServer.FONT_ANTIALIASING_NONE
			f.hinting = TextServer.HINTING_NONE
			f.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
		return f
	return ThemeDB.fallback_font


func _setup_camera() -> void:
	var room := Vector2(MAP_W * TILE, MAP_H * TILE)
	var vp := get_viewport_rect().size
	var z: float = min(vp.x / room.x, vp.y / room.y) * 0.995
	cam.zoom = Vector2(z, z)
	cam.position_smoothing_enabled = false
	cam.position = room / 2.0
	cam.reset_smoothing()


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
	# a few pillars for character
	for p in [Vector2i(4, 7), Vector2i(11, 7), Vector2i(4, 15), Vector2i(11, 15)]:
		map[p.y][p.x] = PILLAR
	# exit door at the bottom
	var dx := MAP_W / 2
	map[MAP_H - 1][dx] = DOOR
	door_cell = Vector2i(dx, MAP_H - 1)


func _spawn_monsters(n: int) -> void:
	monsters.clear()
	var cells := []
	for y in range(3, MAP_H - 4):
		for x in range(2, MAP_W - 2):
			if map[y][x] == FLOOR:
				cells.append(Vector2i(x, y))
	cells.shuffle()
	for i in min(n, cells.size()):
		var c: Vector2i = cells[i]
		monsters.append({
			"pos": Vector2(c.x * TILE + TILE / 2.0, c.y * TILE + TILE / 2.0),
			"hp": MON_HP, "alive": true, "hurt": 0.0, "bob": randf() * TAU, "dead_t": 0.0,
		})


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
	return t == WALL or t == PILLAR


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
		exit_on_arrive = false
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
		if abs(dir.x) > abs(dir.y):
			facing = 1 if dir.x < 0.0 else 2
		else:
			facing = 3 if dir.y < 0.0 else 0
	var step := dir * PLAYER_SPEED * delta
	if _can_stand(player_pos.x + step.x, player_pos.y):
		player_pos.x += step.x
	if _can_stand(player_pos.x, player_pos.y + step.y):
		player_pos.y += step.y
	if has_target and dir != Vector2.ZERO and player_pos.distance_to(prev) < 0.05:
		has_target = false
		exit_on_arrive = false

	if moving:
		anim_t += delta
		if anim_t > 0.16:
			anim_t -= 0.16
			anim_i = (anim_i + 1) % STEP_SEQ.size()
	else:
		anim_i = 0
		anim_t = 0.0

	# monster timers
	for m in monsters:
		m.bob += delta * 3.0
		if m.hurt > 0.0:
			m.hurt = max(0.0, m.hurt - delta)
		if not m.alive and m.dead_t > 0.0:
			m.dead_t = max(0.0, m.dead_t - delta)
	monsters = monsters.filter(func(m): return m.alive or m.dead_t > 0.0)

	# exit proximity
	var dcenter := Vector2(door_cell.x * TILE + TILE / 2.0, door_cell.y * TILE)
	near_exit = player_pos.distance_to(dcenter) < 22.0
	if exit_on_arrive and near_exit:
		_exit()
		return

	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE or event.keycode == KEY_M or (event.keycode == KEY_E and near_exit):
			_exit()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_pointer(get_global_mouse_position())


func _on_pointer(p: Vector2) -> void:
	# attack a monster if one was clicked
	for m in monsters:
		if m.alive and p.distance_to(m.pos) < 13.0:
			_attack(m)
			return
	# tap the exit door
	if door_cell.x >= 0 and Rect2(door_cell.x * TILE, (door_cell.y - 1) * TILE, TILE, TILE * 2).has_point(p):
		if near_exit:
			_exit()
		else:
			move_target = Vector2(door_cell.x * TILE + TILE / 2.0, (door_cell.y - 1) * TILE + 12)
			has_target = true
			exit_on_arrive = true
		return
	# otherwise walk
	move_target = p
	has_target = true
	exit_on_arrive = false


func _attack(m: Dictionary) -> void:
	m.hp -= 1
	m.hurt = 0.22
	# knock the monster a little away from the player
	var kb: Vector2 = (m.pos - player_pos)
	if kb.length() > 0.1:
		m.pos += kb.normalized() * 3.0
	if m.hp <= 0:
		m.alive = false
		m.dead_t = 0.4
		defeated += 1


func _exit() -> void:
	get_tree().change_scene_to_file("res://scenes/World.tscn")


# =====================================================================
#  DRAWING
# =====================================================================
func _draw() -> void:
	for ty in MAP_H:
		for tx in MAP_W:
			_draw_ground(tx, ty)

	# Y-sorted: pillars, monsters, player
	var objs: Array = []
	for ty in MAP_H:
		for tx in MAP_W:
			if map[ty][tx] == PILLAR:
				objs.append({"y": ty * TILE + TILE, "kind": "pillar", "x": tx, "ty": ty})
	for m in monsters:
		objs.append({"y": m.pos.y + 8, "kind": "mon", "m": m})
	objs.append({"y": player_pos.y, "kind": "player"})
	objs.sort_custom(func(a, b): return a.y < b.y)
	for o in objs:
		match o.kind:
			"pillar": _draw_pillar(o.x, o.ty)
			"mon": _draw_monster(o.m)
			"player": _draw_player()

	if has_target:
		_draw_target()
	if near_exit:
		_draw_prompt("[E] 離開")

	_draw_hud()


func _draw_ground(tx: int, ty: int) -> void:
	var px := tx * TILE
	var py := ty * TILE
	var r := Rect2(px, py, TILE, TILE)
	match map[ty][tx]:
		WALL:
			draw_rect(r, C_WALL)
			draw_rect(Rect2(px, py, TILE, 3), C_WALL_HI)
			if ty == 0:
				draw_rect(Rect2(px, py + TILE - 2, TILE, 2), C_GOLD_D)   # gold cornice
		DOOR:
			draw_rect(r, C_WALL)
			draw_rect(Rect2(px + 2, py + 1, TILE - 4, TILE - 1), C_DOOR)
			draw_rect(Rect2(px + 1, py, TILE - 2, 2), C_GOLD_D)
		_:
			draw_rect(r, C_FLOOR)
			if (tx + ty) % 2 == 0:
				draw_rect(Rect2(px, py, TILE, TILE), C_FLOOR_D)
			draw_rect(Rect2(px, py, TILE, 1), C_FLOOR_HI)
			# faint gold inlay grid
			if tx % 4 == 0 and ty % 4 == 0:
				draw_rect(Rect2(px + TILE - 2, py + TILE - 2, 2, 2), C_GOLD_D)


func _draw_pillar(tx: int, ty: int) -> void:
	var px := tx * TILE
	var py := ty * TILE
	draw_rect(Rect2(px + 2, py - 8, TILE - 4, TILE + 8), C_WALL)
	draw_rect(Rect2(px + 2, py - 8, TILE - 4, 3), C_GOLD_D)       # gold capital
	draw_rect(Rect2(px + 2, py + TILE - 3, TILE - 4, 3), C_GOLD_D)
	draw_rect(Rect2(px + 3, py - 6, 2, TILE + 4), C_WALL_HI)


func _draw_monster(m: Dictionary) -> void:
	var bobf := sin(m.bob) * 1.5
	var cx: float = m.pos.x
	var cy: float = m.pos.y + bobf
	if not m.alive:
		# poof: expanding fading ring
		var t: float = 1.0 - m.dead_t / 0.4
		var rad: float = 4.0 + t * 10.0
		draw_arc(Vector2(cx, cy), rad, 0.0, TAU, 16, Color(0.66, 0.4, 0.85, 1.0 - t), 2.0)
		return
	var body := C_MON
	var bd := C_MON_D
	if m.hurt > 0.0 and int(m.hurt * 40) % 2 == 0:
		body = C_WHITE
		bd = C_WHITE
	# shadow
	draw_rect(Rect2(cx - 7, m.pos.y + 8, 14, 3), Color(0, 0, 0, 0.22))
	# body (blob)
	draw_rect(Rect2(cx - 8, cy - 6, 16, 14), body)
	draw_rect(Rect2(cx - 6, cy - 8, 12, 4), body)
	draw_rect(Rect2(cx - 8, cy - 6, 16, 2), C_MON_HI if body != C_WHITE else C_WHITE)
	draw_rect(Rect2(cx - 8, cy + 5, 16, 3), bd)
	# horns
	draw_rect(Rect2(cx - 7, cy - 11, 2, 4), bd)
	draw_rect(Rect2(cx + 5, cy - 11, 2, 4), bd)
	# eyes
	draw_rect(Rect2(cx - 5, cy - 4, 3, 4), C_MON_EYE)
	draw_rect(Rect2(cx + 2, cy - 4, 3, 4), C_MON_EYE)
	draw_rect(Rect2(cx - 4, cy - 3, 1, 2), C_INK)
	draw_rect(Rect2(cx + 3, cy - 3, 1, 2), C_INK)
	# little fangs
	draw_rect(Rect2(cx - 3, cy + 2, 2, 2), C_WHITE)
	draw_rect(Rect2(cx + 1, cy + 2, 2, 2), C_WHITE)
	# hp pips above
	for i in MON_HP:
		var col := C_RED if i < m.hp else Color(0.3, 0.2, 0.3)
		draw_rect(Rect2(cx - 5 + i * 6, cy - 16, 4, 3), col)


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
		src.position.x += CHEF_FW
		src.size.x = -CHEF_FW
	draw_texture_rect_region(chef_tex, dst, src)


func _draw_hud() -> void:
	var w := MAP_W * TILE
	draw_rect(Rect2(0, 0, w, 16), Color(0.08, 0.06, 0.12, 0.92))
	draw_rect(Rect2(0, 15, w, 1), C_GOLD_D)
	_wtext("紫金大廈", Vector2(w / 2.0, 11), 9, C_YELLOW, HORIZONTAL_ALIGNMENT_CENTER)
	_wtext("擊倒 " + str(defeated), Vector2(6, 11), 8, C_WHITE)
	var alive := 0
	for m in monsters:
		if m.alive:
			alive += 1
	if alive == 0:
		_wtext("全部擊倒！", Vector2(w / 2.0, 30), 10, C_YELLOW, HORIZONTAL_ALIGNMENT_CENTER)


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


func _wtext(s: String, pos: Vector2, size: int, col: Color, align := HORIZONTAL_ALIGNMENT_LEFT) -> void:
	draw_string(font, pos + Vector2(0.6, 0.6), s, align, -1, size, C_INK)
	draw_string(font, pos, s, align, -1, size, col)
