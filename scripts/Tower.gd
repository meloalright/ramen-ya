extends Node2D
# =====================================================================
#  RAMEN-YA — 紫金大廈: a PORTRAIT vertical-scrolling shooter.
#  Play field is a tall central column; the tower shaft and the monsters
#  scroll DOWNWARD. You stay at the bottom: move left/right and fire
#  shockwaves upward, dodging the bullets the monsters aim back at you.
# =====================================================================
const W := 480
const H := 270

# central portrait column (the actual play field); side panels hold the UI
const CX_L := 140.0
const CX_R := 340.0

const INK      := Color("241830")
const C_BG     := Color("2a1f44")
const C_PANEL  := Color("160f26")
const C_GOLD   := Color("e7b84e")
const C_WHITE  := Color("f4f0e6")
const C_YELLOW := Color("f2c14e")
const C_RED    := Color("e2533f")
const C_MON    := Color("9a5ee0")
const C_MON_HI := Color("c79bf0")
const C_WAVE   := Color("6fe0ff")
const C_EBALL  := Color("ff5f9e")

# player
const PLAYER_Y := 242.0
const PMIN_X := 156.0
const PMAX_X := 324.0
const PLAYER_SPEED := 150.0
const HP_MAX := 3
const INVULN := 1.1
var player_x := 240.0
var hp := HP_MAX
var invuln := 0.0

# shooting
const SHOOT_DT := 0.26
const SHOT_SPEED := 240.0
var shot_cd := 0.0
var shots: Array = []          # {x, y, w}

# enemies (descend the shaft)
const ENEMY_HP := 2
const EBALL_SPEED := 118.0
var enemies: Array = []        # {pos, x0, vy, weave, hp, fire, bob, hurt}
var eballs: Array = []         # {pos, vel}
var spawn_cd := 0.7
var spawn_dt := 1.5
var enemy_vy := 30.0
var defeated := 0

# destructible obstacles: block both shockwaves and bullets, hurt you on
# contact, and break after a few taps.
const OBST_HP := 3
const OBST_HW := 17.0
const OBST_HH := 13.0
var obstacles: Array = []      # {pos, vy, hp, hurt}
var obst_cd := 2.2

# 大招 · 沸腾巨浪: charge by defeating enemies, then sweep the whole shaft
const ULT_MAX := 8
var ult_charge := 0
var ult_active := false
var ult_wave_y := 0.0
var flash := 0.0
var puffs: Array = []          # {pos, ttl}
var bg_y := 0.0

var game_over := false
var font: Font
var chef_tex: Texture2D
var sfx: AudioStreamPlayer
const CHEF_FW := 52
const CHEF_FH := 68
var anim := 0.0
var anim_i := 0
var t := 0.0
var touch_pts := {}

const LEFT_RECT  := Rect2(16, 200, 52, 52)
const RIGHT_RECT := Rect2(72, 200, 52, 52)
const SHOOT_RECT := Rect2(396, 194, 70, 60)
const ULT_RECT   := Rect2(16, 130, 108, 52)
const BACK_RECT  := Rect2(W - 50, 4, 46, 16)

@onready var cam: Camera2D = $Camera


func _ready() -> void:
	randomize()
	font = _make_font()
	if ResourceLoader.exists("res://assets/chef_sheet.png"):
		chef_tex = load("res://assets/chef_sheet.png")
	sfx = AudioStreamPlayer.new()
	sfx.bus = "Master"
	sfx.volume_db = -4.0
	add_child(sfx)
	if ResourceLoader.exists("res://assets/audio/hit.wav"):
		sfx.stream = load("res://assets/audio/hit.wav")
	cam.zoom = Vector2.ONE
	cam.position = Vector2(W / 2.0, H / 2.0)
	cam.position_smoothing_enabled = false
	cam.make_current()
	cam.reset_smoothing()
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


# ---- input ----------------------------------------------------------
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			var wp: Vector2 = get_canvas_transform().affine_inverse() * event.position
			touch_pts[event.index] = wp
			_on_press(wp)
		else:
			touch_pts.erase(event.index)
	elif event is InputEventScreenDrag:
		var wp: Vector2 = get_canvas_transform().affine_inverse() * event.position
		touch_pts[event.index] = wp
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE or event.keycode == KEY_M:
			_exit()
		elif game_over and event.keycode in [KEY_R, KEY_SPACE, KEY_ENTER]:
			_restart()
		elif event.keycode in [KEY_E, KEY_SHIFT, KEY_Q]:
			_fire_ult()


func _on_press(p: Vector2) -> void:
	if BACK_RECT.has_point(p):
		_exit()
		return
	if game_over:
		_restart()
		return
	if ULT_RECT.has_point(p) and ult_charge >= ULT_MAX and not ult_active:
		_fire_ult()
		return
	# tap an obstacle (in the play column) to chip it — a few taps breaks it
	for o in obstacles:
		if o.hp > 0 and abs(p.x - o.pos.x) < OBST_HW + 3.0 and abs(p.y - o.pos.y) < OBST_HH + 3.0:
			o.hp -= 1
			o.hurt = 0.12
			_sfx()
			if o.hp <= 0:
				puffs.append({"pos": o.pos, "ttl": 0.4})
			break


func _touch_in(r: Rect2) -> bool:
	for k in touch_pts:
		if r.has_point(touch_pts[k]):
			return true
	return false


# ---- update ---------------------------------------------------------
func _process(delta: float) -> void:
	t += delta
	anim += delta
	if anim > 0.16:
		anim -= 0.16
		anim_i = (anim_i + 1) % 4
	bg_y = fmod(bg_y + 74.0 * delta, 40.0)
	if flash > 0.0:
		flash = max(0.0, flash - delta * 1.4)
	for p in puffs:
		p.ttl -= delta
	puffs = puffs.filter(func(p): return p.ttl > 0.0)

	if game_over:
		queue_redraw()
		return

	if invuln > 0.0:
		invuln -= delta

	# 大招 sweep: a boiling surge rises and wipes everything in its wake
	if ult_active:
		ult_wave_y -= 560.0 * delta
		eballs.clear()
		for e in enemies:
			if e.hp > 0 and e.pos.y >= ult_wave_y:
				defeated += 1
				puffs.append({"pos": e.pos, "ttl": 0.4})
				e.hp = 0
		for o in obstacles:
			if o.hp > 0 and o.pos.y >= ult_wave_y:
				puffs.append({"pos": o.pos, "ttl": 0.4})
				o.hp = 0
		if ult_wave_y < -32.0:
			ult_active = false

	# movement (within the column)
	var lp := Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT) or _touch_in(LEFT_RECT)
	var rp := Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT) or _touch_in(RIGHT_RECT)
	var sp := Input.is_physical_key_pressed(KEY_SPACE) or Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP) or _touch_in(SHOOT_RECT)
	var dir := (1.0 if rp else 0.0) - (1.0 if lp else 0.0)
	player_x = clamp(player_x + dir * PLAYER_SPEED * delta, PMIN_X, PMAX_X)

	# shoot shockwaves upward
	shot_cd = max(0.0, shot_cd - delta)
	if sp and shot_cd <= 0.0:
		shots.append({"x": player_x, "y": PLAYER_Y - 16.0, "w": 9.0})
		shot_cd = SHOOT_DT
	for s in shots:
		s.y -= SHOT_SPEED * delta
		s.w = min(30.0, s.w + 42.0 * delta)

	# spawn enemies at the top of the shaft (ramping up)
	spawn_cd -= delta
	if spawn_cd <= 0.0:
		_spawn_enemy()
		spawn_dt = max(0.65, spawn_dt - 0.02)
		enemy_vy = min(58.0, enemy_vy + 0.6)
		spawn_cd = spawn_dt

	# spawn obstacles (less often)
	obst_cd -= delta
	if obst_cd <= 0.0:
		obstacles.append({"pos": Vector2(randf_range(CX_L + 26.0, CX_R - 26.0), -16.0),
			"vy": enemy_vy * 0.95, "hp": OBST_HP, "hurt": 0.0})
		obst_cd = randf_range(2.8, 4.6)

	# obstacles descend; crashing into the player hurts
	for o in obstacles:
		o.pos.y += o.vy * delta
		if o.hurt > 0.0:
			o.hurt -= delta
		if invuln <= 0.0 and o.hp > 0 and abs(o.pos.x - player_x) < OBST_HW + 6.0 and abs(o.pos.y - PLAYER_Y) < OBST_HH + 10.0:
			hp -= 1
			invuln = INVULN
			o.hurt = 0.12
			_sfx()
			if hp <= 0:
				game_over = true
	obstacles = obstacles.filter(func(o): return o.hp > 0 and o.pos.y < H + 24.0)

	# enemies descend, weave and fire
	for e in enemies:
		e.pos.y += e.vy * delta
		e.pos.x = clamp(e.x0 + sin(t * 1.4 + e.bob) * e.weave, CX_L + 14.0, CX_R - 14.0)
		if e.hurt > 0.0:
			e.hurt -= delta
		e.fire -= delta
		if e.fire <= 0.0 and e.pos.y > 8.0 and e.pos.y < PLAYER_Y - 24.0:
			var aim: Vector2 = (Vector2(player_x, PLAYER_Y) - e.pos).normalized()
			eballs.append({"pos": e.pos + Vector2(0, 10), "vel": Vector2(aim.x * 52.0, EBALL_SPEED)})
			e.fire = randf_range(1.4, 2.8)
		# crash into the player
		if invuln <= 0.0 and e.hp > 0 and e.pos.distance_to(Vector2(player_x, PLAYER_Y)) < 17.0:
			hp -= 1
			invuln = INVULN
			e.hp = 0
			puffs.append({"pos": e.pos, "ttl": 0.4})
			_sfx()
			if hp <= 0:
				game_over = true

	# shockwaves: blocked by obstacles (absorbed), otherwise damage enemies
	for s in shots:
		var blocked := false
		for o in obstacles:
			if o.hp > 0 and abs(o.pos.x - s.x) < OBST_HW + s.w * 0.5 and abs(o.pos.y - s.y) < OBST_HH + 6.0:
				s.y = -999.0
				blocked = true
				break
		if blocked:
			continue
		for e in enemies:
			if e.hp > 0 and abs(e.pos.x - s.x) < s.w * 0.6 + 4.0 and abs(e.pos.y - s.y) < 12.0:
				e.hp -= 1
				e.hurt = 0.14
				s.y = -999.0
				if e.hp <= 0:
					defeated += 1
					ult_charge = min(ULT_MAX, ult_charge + 1)
					puffs.append({"pos": e.pos, "ttl": 0.4})
					_sfx()
				break
	shots = shots.filter(func(s): return s.y > -24.0)
	enemies = enemies.filter(func(e): return e.hp > 0 and e.pos.y < H + 22.0)

	# enemy bullets: blocked by obstacles (cover), else hit the player
	for b in eballs:
		b.pos += b.vel * delta
		for o in obstacles:
			if o.hp > 0 and abs(b.pos.x - o.pos.x) < OBST_HW + 4.0 and abs(b.pos.y - o.pos.y) < OBST_HH + 4.0:
				b.pos.y = 9999.0
				break
		if invuln <= 0.0 and abs(b.pos.x - player_x) < 11.0 and abs(b.pos.y - PLAYER_Y) < 14.0:
			hp -= 1
			invuln = INVULN
			b.pos.y = 9999.0
			_sfx()
			if hp <= 0:
				game_over = true
	eballs = eballs.filter(func(b): return b.pos.y < H + 12.0 and b.pos.x > CX_L - 14.0 and b.pos.x < CX_R + 14.0)

	queue_redraw()


func _spawn_enemy() -> void:
	var ex := randf_range(CX_L + 24.0, CX_R - 24.0)
	enemies.append({"pos": Vector2(ex, -14.0), "x0": ex, "vy": enemy_vy + randf_range(-4.0, 12.0),
		"weave": randf_range(6.0, 22.0), "hp": ENEMY_HP, "fire": randf_range(0.6, 1.6),
		"bob": randf() * TAU, "hurt": 0.0})


func _restart() -> void:
	hp = HP_MAX
	invuln = 0.0
	player_x = 240.0
	enemies.clear(); eballs.clear(); shots.clear(); puffs.clear(); obstacles.clear()
	defeated = 0
	spawn_dt = 1.5
	enemy_vy = 30.0
	spawn_cd = 0.7
	obst_cd = 2.2
	ult_charge = 0
	ult_active = false
	flash = 0.0
	game_over = false


func _fire_ult() -> void:
	if ult_active or ult_charge < ULT_MAX:
		return
	ult_active = true
	ult_wave_y = H + 12.0
	ult_charge = 0
	flash = 0.6
	_sfx()


func _sfx() -> void:
	if sfx and sfx.stream:
		sfx.play()


func _exit() -> void:
	get_tree().change_scene_to_file("res://scenes/World.tscn")


# ---- draw -----------------------------------------------------------
func _draw() -> void:
	# scrolling tower shaft inside the column
	draw_rect(Rect2(CX_L, 0, CX_R - CX_L, H), C_BG)
	var y := bg_y - 40.0
	while y < H:
		draw_rect(Rect2(CX_L, y, CX_R - CX_L, 2), Color(1, 1, 1, 0.05))
		draw_rect(Rect2(CX_L + 40, y + 18, 2, 22), Color(1, 1, 1, 0.04))
		draw_rect(Rect2(CX_R - 42, y + 18, 2, 22), Color(1, 1, 1, 0.04))
		y += 40.0

	# side panels (tower walls) + gold trim along the column
	draw_rect(Rect2(0, 0, CX_L, H), C_PANEL)
	draw_rect(Rect2(CX_R, 0, W - CX_R, H), C_PANEL)
	draw_rect(Rect2(CX_L - 3, 0, 3, H), C_GOLD)
	draw_rect(Rect2(CX_R, 0, 3, H), C_GOLD)

	for e in enemies:
		_draw_monster(e)
	for o in obstacles:
		_draw_obstacle(o)
	for b in eballs:
		draw_circle(b.pos, 6.0, INK)
		draw_circle(b.pos, 5.0, C_EBALL)
		draw_circle(b.pos + Vector2(-1.4, -1.4), 1.6, Color(1, 1, 1, 0.85))
	for s in shots:
		_draw_wave(s)
	_draw_player()
	for p in puffs:
		var a: float = clamp(p.ttl / 0.4, 0.0, 1.0)
		draw_arc(p.pos, (1.0 - a) * 18.0 + 4.0, 0.0, TAU, 18, Color(1, 1, 1, a * 0.6), 2.5)

	if ult_active:
		var wy := ult_wave_y
		draw_rect(Rect2(CX_L, wy, CX_R - CX_L, H - wy + 12.0), Color(0.42, 0.9, 1.0, 0.16))
		draw_rect(Rect2(CX_L, wy - 3.0, CX_R - CX_L, 9.0), C_WAVE)
		draw_rect(Rect2(CX_L, wy - 5.0, CX_R - CX_L, 2.0), Color(1, 1, 1, 0.95))
		var bx := CX_L + 18.0
		while bx < CX_R:
			draw_arc(Vector2(bx, wy + 7.0), 15.0, PI * 1.1, PI * 1.9, 12, Color(1, 1, 1, 0.85), 3.0)
			bx += 38.0
	if flash > 0.0:
		draw_rect(Rect2(0, 0, W, H), Color(1, 1, 1, flash * 0.55))

	_draw_hud()
	_draw_buttons()
	if game_over:
		_draw_over()


func _draw_wave(s: Dictionary) -> void:
	var c := Vector2(s.x, s.y + 5.0)
	draw_arc(c, s.w, PI * 1.12, PI * 1.88, 18, C_WAVE, 4.0)
	draw_arc(c, s.w, PI * 1.12, PI * 1.88, 18, Color(1, 1, 1, 0.9), 1.8)
	draw_arc(c, s.w * 0.6, PI * 1.2, PI * 1.8, 12, C_WAVE.lightened(0.2), 2.0)


func _draw_monster(e: Dictionary) -> void:
	var p: Vector2 = e.pos
	var col: Color = C_MON_HI if e.hurt > 0.0 else C_MON
	draw_circle(p, 14.0, INK)
	draw_circle(p, 12.0, col)
	draw_colored_polygon(PackedVector2Array([p + Vector2(-9, -7), p + Vector2(-12, -15), p + Vector2(-4, -9)]), INK)
	draw_colored_polygon(PackedVector2Array([p + Vector2(9, -7), p + Vector2(12, -15), p + Vector2(4, -9)]), INK)
	draw_circle(p + Vector2(-4.5, -1), 3.4, C_WHITE)
	draw_circle(p + Vector2(4.5, -1), 3.4, C_WHITE)
	draw_circle(p + Vector2(-4.5, 1), 1.7, INK)
	draw_circle(p + Vector2(4.5, 1), 1.7, INK)
	draw_line(p + Vector2(-4, 6), p + Vector2(4, 6), INK, 1.6)
	for i in range(int(e.hp)):
		draw_rect(Rect2(p.x - 5 + i * 5, p.y - 20, 3, 2), C_YELLOW)


func _draw_obstacle(o: Dictionary) -> void:
	var p: Vector2 = o.pos
	var col: Color = Color("a8946a") if o.hurt > 0.0 else Color("857252")
	draw_rect(Rect2(p.x - OBST_HW, p.y - OBST_HH, OBST_HW * 2, OBST_HH * 2), INK)
	draw_rect(Rect2(p.x - OBST_HW + 2, p.y - OBST_HH + 2, OBST_HW * 2 - 4, OBST_HH * 2 - 4), col)
	draw_rect(Rect2(p.x - OBST_HW + 2, p.y - OBST_HH + 2, OBST_HW * 2 - 4, 3), Color(1, 1, 1, 0.18))
	# cracks grow as it takes taps
	var dmg := OBST_HP - int(o.hp)
	if dmg >= 1:
		draw_line(p + Vector2(-8, -9), p + Vector2(0, 3), INK, 1.6)
		draw_line(p + Vector2(0, 3), p + Vector2(-4, 10), INK, 1.6)
	if dmg >= 2:
		draw_line(p + Vector2(9, -8), p + Vector2(1, 0), INK, 1.6)
		draw_line(p + Vector2(1, 0), p + Vector2(8, 9), INK, 1.6)


func _draw_player() -> void:
	if invuln > 0.0 and int(t * 18.0) % 2 == 0:
		return
	draw_rect(Rect2(player_x - 9, PLAYER_Y + 1, 18, 4), Color(0, 0, 0, 0.2))
	if chef_tex != null:
		var h := 32.0
		var w := CHEF_FW / float(CHEF_FH) * h
		var col: int = anim_i
		var src := Rect2(col * CHEF_FW, 0, CHEF_FW, CHEF_FH)
		draw_texture_rect_region(chef_tex, Rect2(player_x - w / 2.0, PLAYER_Y - h, w, h), src)
	else:
		draw_circle(Vector2(player_x, PLAYER_Y - 10), 9, C_WHITE)


func _draw_hud() -> void:
	for i in range(HP_MAX):
		_draw_heart(Vector2(14 + i * 16, 14), i < hp)
	_text("擊退 " + str(defeated), Vector2(W / 2.0, 16), 10, C_WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	draw_rect(BACK_RECT, Color(0, 0, 0, 0.4))
	draw_rect(BACK_RECT, C_WHITE, false, 1.0)
	_text("離開", Vector2(BACK_RECT.position.x + 23, BACK_RECT.position.y + 12), 9, C_WHITE, HORIZONTAL_ALIGNMENT_CENTER)


func _draw_heart(c: Vector2, full: bool) -> void:
	var col := C_RED if full else Color(0.3, 0.2, 0.3)
	draw_circle(c + Vector2(-2.4, -1), 3.0, col)
	draw_circle(c + Vector2(2.4, -1), 3.0, col)
	draw_colored_polygon(PackedVector2Array([c + Vector2(-5, 0), c + Vector2(5, 0), c + Vector2(0, 6)]), col)


func _draw_buttons() -> void:
	# 大招 button + charge gauge (left panel, above the move buttons)
	var ready := ult_charge >= ULT_MAX
	draw_rect(ULT_RECT, Color(0.95, 0.55, 0.2, 0.5 if ready else 0.18))
	if not ready:
		var f := ult_charge / float(ULT_MAX)
		draw_rect(Rect2(ULT_RECT.position, Vector2(ULT_RECT.size.x * f, ULT_RECT.size.y)), Color(0.95, 0.6, 0.3, 0.4))
	var lit := ready and int(t * 4.0) % 2 == 0
	draw_rect(ULT_RECT, C_YELLOW if lit else Color(1, 1, 1, 0.55), false, 2.5 if lit else 1.5)
	var label := "大招！" if ready else "大招 %d/%d" % [ult_charge, ULT_MAX]
	_text(label, ULT_RECT.get_center() + Vector2(0, 4), 11 if ready else 9,
		C_WHITE if ready else Color(1, 1, 1, 0.7), HORIZONTAL_ALIGNMENT_CENTER)

	_btn(LEFT_RECT, _touch_in(LEFT_RECT) or Input.is_physical_key_pressed(KEY_LEFT) or Input.is_physical_key_pressed(KEY_A))
	var lc := LEFT_RECT.get_center()
	draw_colored_polygon(PackedVector2Array([lc + Vector2(7, -9), lc + Vector2(7, 9), lc + Vector2(-9, 0)]), C_WHITE)
	_btn(RIGHT_RECT, _touch_in(RIGHT_RECT) or Input.is_physical_key_pressed(KEY_RIGHT) or Input.is_physical_key_pressed(KEY_D))
	var rc := RIGHT_RECT.get_center()
	draw_colored_polygon(PackedVector2Array([rc + Vector2(-7, -9), rc + Vector2(-7, 9), rc + Vector2(9, 0)]), C_WHITE)
	var shooting := _touch_in(SHOOT_RECT) or Input.is_physical_key_pressed(KEY_SPACE)
	_btn(SHOOT_RECT, shooting, C_WAVE)
	var sc := SHOOT_RECT.get_center()
	draw_arc(sc, 14, PI * 1.15, PI * 1.85, 14, C_WHITE, 3.0)
	draw_arc(sc, 9, PI * 1.2, PI * 1.8, 12, C_WHITE, 2.0)


func _btn(r: Rect2, pressed: bool, base := Color(1, 1, 1, 1)) -> void:
	var fill := Color(base.r, base.g, base.b, 0.5 if pressed else 0.2)
	draw_rect(r, fill)
	draw_rect(r, Color(1, 1, 1, 0.7), false, 1.5)


func _draw_over() -> void:
	draw_rect(Rect2(0, 0, W, H), Color(0.06, 0.04, 0.09, 0.72))
	_text("被打倒了…", Vector2(W / 2.0, 116), 18, C_RED, HORIZONTAL_ALIGNMENT_CENTER)
	_text("擊退了 " + str(defeated) + " 隻", Vector2(W / 2.0, 140), 11, C_WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	_text("點擊重來  ·  ESC 離開", Vector2(W / 2.0, 162), 10,
		C_YELLOW if int(t * 2.0) % 2 == 0 else C_WHITE, HORIZONTAL_ALIGNMENT_CENTER)


func _text(s: String, pos: Vector2, size: int, col: Color, align := HORIZONTAL_ALIGNMENT_LEFT) -> void:
	draw_string(font, pos + Vector2(1, 1), s, align, -1, size, INK)
	draw_string(font, pos, s, align, -1, size, col)
