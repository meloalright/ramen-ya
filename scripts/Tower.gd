extends Node2D
# =====================================================================
#  RAMEN-YA — 紫金大廈: a horizontal-move VERTICAL SHOOTER.
#  Move left/right (on-screen buttons or A/D/←/→), hold SHOOT (button or
#  Space/W/↑) to fire shockwaves upward. Dodge the monsters' shots.
# =====================================================================
const W := 480
const H := 270

const INK      := Color("241830")
const C_BG     := Color("241a38")
const C_GOLD   := Color("e7b84e")
const C_WHITE  := Color("f4f0e6")
const C_YELLOW := Color("f2c14e")
const C_RED    := Color("e2533f")
const C_MON    := Color("9a5ee0")
const C_MON_HI := Color("c79bf0")
const C_MON_EYE:= Color("ffe24e")
const C_WAVE   := Color("6fe0ff")
const C_EBALL  := Color("ff5f9e")

# player
const PLAYER_Y := 206.0
const PMIN_X := 26.0
const PMAX_X := 454.0
const PLAYER_SPEED := 168.0
const HP_MAX := 3
const INVULN := 1.1
var player_x := 240.0
var hp := HP_MAX
var invuln := 0.0

# shooting
const SHOOT_DT := 0.26
const SHOT_SPEED := 235.0
var shot_cd := 0.0
var shots: Array = []          # {x, y, w}

# enemies
const ENEMY_HP := 2
const EBALL_SPEED := 120.0
var enemies: Array = []        # {pos, base_y, vx, hp, fire, bob, hurt}
var eballs: Array = []         # {pos, vel}
var spawn_cd := 0.8
var spawn_dt := 1.7
var defeated := 0
var puffs: Array = []          # {pos, ttl}
var bg_dashes: Array = []

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

const LEFT_RECT  := Rect2(12, 226, 52, 40)
const RIGHT_RECT := Rect2(70, 226, 52, 40)
const SHOOT_RECT := Rect2(398, 222, 70, 44)
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
	for i in range(28):
		bg_dashes.append(Vector2(randf() * W, randf() * H))
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


func _on_press(p: Vector2) -> void:
	if BACK_RECT.has_point(p):
		_exit()
	elif game_over:
		_restart()


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
	for d in bg_dashes:
		d.y += 64.0 * delta
		if d.y > H:
			d.y -= H
			d.x = randf() * W
	for p in puffs:
		p.ttl -= delta
	puffs = puffs.filter(func(p): return p.ttl > 0.0)

	if game_over:
		queue_redraw()
		return

	if invuln > 0.0:
		invuln -= delta

	# movement
	var lp := Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT) or _touch_in(LEFT_RECT)
	var rp := Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT) or _touch_in(RIGHT_RECT)
	var sp := Input.is_physical_key_pressed(KEY_SPACE) or Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP) or _touch_in(SHOOT_RECT)
	var dir := (1.0 if rp else 0.0) - (1.0 if lp else 0.0)
	player_x = clamp(player_x + dir * PLAYER_SPEED * delta, PMIN_X, PMAX_X)

	# shooting (hold to auto-fire shockwaves)
	shot_cd = max(0.0, shot_cd - delta)
	if sp and shot_cd <= 0.0:
		shots.append({"x": player_x, "y": PLAYER_Y - 16.0, "w": 9.0})
		shot_cd = SHOOT_DT
	for s in shots:
		s.y -= SHOT_SPEED * delta
		s.w = min(32.0, s.w + 42.0 * delta)

	# spawn enemies (slowly ramping up)
	spawn_cd -= delta
	if spawn_cd <= 0.0:
		_spawn_enemy()
		spawn_dt = max(0.7, spawn_dt - 0.03)
		spawn_cd = spawn_dt

	# enemies move / bob / fire
	for e in enemies:
		e.pos.x += e.vx * delta
		if e.pos.x < 26.0:
			e.pos.x = 26.0
			e.vx = abs(e.vx)
		elif e.pos.x > W - 26.0:
			e.pos.x = W - 26.0
			e.vx = -abs(e.vx)
		e.pos.y = e.base_y + sin(t * 1.7 + e.bob) * 6.0
		if e.hurt > 0.0:
			e.hurt -= delta
		e.fire -= delta
		if e.fire <= 0.0:
			var aim: Vector2 = (Vector2(player_x, PLAYER_Y) - e.pos).normalized()
			eballs.append({"pos": e.pos + Vector2(0, 10), "vel": Vector2(aim.x * 46.0, EBALL_SPEED)})
			e.fire = randf_range(1.3, 2.6)

	# shockwaves vs enemies
	for s in shots:
		for e in enemies:
			if e.hp > 0 and abs(e.pos.x - s.x) < s.w * 0.6 + 4.0 and abs(e.pos.y - s.y) < 12.0:
				e.hp -= 1
				e.hurt = 0.14
				s.y = -999.0
				if e.hp <= 0:
					defeated += 1
					puffs.append({"pos": e.pos, "ttl": 0.4})
					_sfx()
				break
	shots = shots.filter(func(s): return s.y > -24.0)
	enemies = enemies.filter(func(e): return e.hp > 0)

	# enemy shots vs player
	for b in eballs:
		b.pos += b.vel * delta
		if invuln <= 0.0 and abs(b.pos.x - player_x) < 11.0 and abs(b.pos.y - PLAYER_Y) < 14.0:
			hp -= 1
			invuln = INVULN
			b.pos.y = 9999.0
			_sfx()
			if hp <= 0:
				game_over = true
	eballs = eballs.filter(func(b): return b.pos.y < H + 12.0 and b.pos.x > -12.0 and b.pos.x < W + 12.0)

	queue_redraw()


func _spawn_enemy() -> void:
	var by := randf_range(34.0, 100.0)
	var spd := randf_range(28.0, 52.0) * (1.0 if randf() < 0.5 else -1.0)
	enemies.append({"pos": Vector2(randf_range(40.0, W - 40.0), by), "base_y": by,
		"vx": spd, "hp": ENEMY_HP, "fire": randf_range(0.8, 2.0), "bob": randf() * TAU, "hurt": 0.0})


func _restart() -> void:
	hp = HP_MAX
	invuln = 0.0
	player_x = 240.0
	enemies.clear(); eballs.clear(); shots.clear(); puffs.clear()
	defeated = 0
	spawn_dt = 1.7
	spawn_cd = 0.8
	game_over = false


func _sfx() -> void:
	if sfx and sfx.stream:
		sfx.play()


func _exit() -> void:
	get_tree().change_scene_to_file("res://scenes/World.tscn")


# ---- draw -----------------------------------------------------------
func _draw() -> void:
	draw_rect(Rect2(0, 0, W, H), C_BG)
	for d in bg_dashes:
		draw_rect(Rect2(d.x, d.y, 2, 9), Color(1, 1, 1, 0.06))
	draw_rect(Rect2(0, 0, W, 5), C_GOLD)
	draw_rect(Rect2(0, H - 5, W, 5), C_GOLD)

	for e in enemies:
		_draw_monster(e)
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
	draw_circle(p + Vector2(-4.5, 0), 1.7, INK)
	draw_circle(p + Vector2(4.5, 0), 1.7, INK)
	draw_line(p + Vector2(-4, 6), p + Vector2(4, 6), INK, 1.6)
	for i in range(int(e.hp)):
		draw_rect(Rect2(p.x - 5 + i * 5, p.y - 20, 3, 2), C_YELLOW)


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
	_btn(LEFT_RECT, _touch_in(LEFT_RECT) or Input.is_physical_key_pressed(KEY_LEFT) or Input.is_physical_key_pressed(KEY_A))
	var lc := LEFT_RECT.get_center()
	draw_colored_polygon(PackedVector2Array([lc + Vector2(6, -8), lc + Vector2(6, 8), lc + Vector2(-8, 0)]), C_WHITE)
	_btn(RIGHT_RECT, _touch_in(RIGHT_RECT) or Input.is_physical_key_pressed(KEY_RIGHT) or Input.is_physical_key_pressed(KEY_D))
	var rc := RIGHT_RECT.get_center()
	draw_colored_polygon(PackedVector2Array([rc + Vector2(-6, -8), rc + Vector2(-6, 8), rc + Vector2(8, 0)]), C_WHITE)
	var shooting := _touch_in(SHOOT_RECT) or Input.is_physical_key_pressed(KEY_SPACE)
	_btn(SHOOT_RECT, shooting, C_WAVE)
	var sc := SHOOT_RECT.get_center()
	draw_arc(sc, 13, PI * 1.15, PI * 1.85, 14, C_WHITE, 3.0)
	draw_arc(sc, 8, PI * 1.2, PI * 1.8, 12, C_WHITE, 2.0)


func _btn(r: Rect2, pressed: bool, base := Color(1, 1, 1, 1)) -> void:
	var fill := Color(base.r, base.g, base.b, 0.5 if pressed else 0.22)
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
