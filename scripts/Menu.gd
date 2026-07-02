extends Node2D
# =====================================================================
#  RAMEN-YA — MAIN MENU
#  新遊戲 (New Game) starts fresh; 繼續遊戲 (Continue) loads the save.
# =====================================================================

const W := 270
const H := 480

const START_RECT := Rect2(75, 372, 120, 40)

const COL_BG    := Color("231f28")
const COL_WHITE := Color("f4f0e6")
const COL_INK   := Color("1a1620")
const COL_YELLOW:= Color("f2c14e")
const COL_GREEN := Color("5fae5f")
const COL_GREY  := Color("4a3c54")
const COL_RED   := Color("c23b3b")
const COL_SOUP  := Color("e9b63a")   # yellow oily broth colour

var font: Font
var stall_tex: Texture2D
var logo_tex: Texture2D
var board_tex: Texture2D
var chef_tex: Texture2D
var mona_tex: Texture2D   # pixel Mona Lisa inside the bonus 挂画
var _splash := false   # when true, render just the counter scene (for the boot splash)

const VERSION := "0.0.1"
const CHEF_FW := 52
const CHEF_FH := 68
const CHEF_SEQ := [0, 1, 2, 3]
var anim := 0.0
var idx := 0
var blink := 0.0
var _garland_seed := 0.0   # randomised per menu visit so the flowers vary
var _board_pos := Vector2(135.0, 134.0)   # draggable price-board centre
var _note_pos := Vector2(220.0, 221.0)    # draggable version-note centre
var _flower_pos := Vector2(90.0, 130.0)   # draggable pink flower (left-third, mid-wall)
var _drag := ""                            # "", "flower" or "note"
var _drag_off := Vector2.ZERO
var _reg_taps := 0                          # consecutive register taps (secret reset)
var _confirm_reset := false                 # the reset-data dialog is open
# a decoration dropped into the 充電寶 machine is "stored"; tapping the machine
# rattles it and tosses a random stored one back onto the wall.
# "painting" is the bonus 挂画 — only exists once high_score > 1, starts stored.
var _stored := {"flower": false, "note": false, "painting": true}
var _painting_pos := Vector2(188.0, 118.0)   # bonus painting's wall position
var _reg_shake := 0.0                        # machine wobble timer after a tap
var _over_reg := false                       # a dragged decoration is hovering over the machine


func _ready() -> void:
	randomize()
	_garland_seed = randf() * 9999.0
	font = _make_font()
	if ResourceLoader.exists("res://assets/chef_sheet.png"):
		chef_tex = load("res://assets/chef_sheet.png")
	if ResourceLoader.exists("res://assets/env/cashier.png"):
		stall_tex = load("res://assets/env/cashier.png")
	elif ResourceLoader.exists("res://assets/env/ramen_stall.png"):
		stall_tex = load("res://assets/env/ramen_stall.png")
	if ResourceLoader.exists("res://assets/splash/logo_rounded.png"):
		logo_tex = load("res://assets/splash/logo_rounded.png")
	if ResourceLoader.exists("res://assets/env/board.png"):
		board_tex = load("res://assets/env/board.png")
	if ResourceLoader.exists("res://assets/env/mona.png"):
		mona_tex = load("res://assets/env/mona.png")
	if Game.has_save():
		Game.load_game()        # pre-load so the menu can show the saved coins
	if Game.has_layout:         # restore the player's saved wall arrangement
		_note_pos = Game.note_pos
		if Game.flower_pos != Vector2.ZERO:
			_flower_pos = Game.flower_pos
		_stored.flower = Game.flower_stored
		_stored.note = Game.note_stored
		_stored.painting = Game.painting_stored
		if Game.painting_pos != Vector2.ZERO:
			_painting_pos = Game.painting_pos
	set_process(true)


func _has_painting() -> bool:
	return Game.high_score > 1


# copy the current wall arrangement into the save
func _persist() -> void:
	Game.note_pos = _note_pos
	Game.flower_pos = _flower_pos
	Game.painting_pos = _painting_pos
	Game.flower_stored = _stored.flower
	Game.note_stored = _stored.note
	Game.painting_stored = _stored.painting
	Game.has_layout = true
	Game.save()


func _make_font() -> Font:
	if ResourceLoader.exists("res://assets/fonts/zpix.ttf"):
		var f = load("res://assets/fonts/zpix.ttf")
		if f is FontFile:
			f.antialiasing = TextServer.FONT_ANTIALIASING_NONE
			f.hinting = TextServer.HINTING_NONE
			f.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
		return f
	return ThemeDB.fallback_font


func _process(delta: float) -> void:
	blink += delta
	anim += delta
	if anim > 0.18:
		anim -= 0.18
		idx = (idx + 1) % CHEF_SEQ.size()
	if _reg_shake > 0.0:
		_reg_shake = max(0.0, _reg_shake - delta)
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var m: Vector2 = get_global_mouse_position() - _offset()
		if event.pressed:
			# the reset-data dialog intercepts all clicks while open
			if _confirm_reset:
				# only the dialog's own buttons close it (no dismiss-on-outside)
				if _reset_yes().has_point(m):
					Music.click()
					_do_reset()
					_confirm_reset = false
				elif _reset_no().has_point(m):
					Music.click()
					_confirm_reset = false
				queue_redraw()
				return
			# pick up a decoration to drag, else the start button.
			# a stored decoration lives inside the machine — can't be grabbed off the wall
			if _has_painting() and not _stored.painting and _painting_pos.distance_to(m) < 30.0:
				_drag = "painting"
				_drag_off = _painting_pos - m
				_reg_taps = 0
				Music.pick()
			elif not _stored.flower and _flower_pos.distance_to(m) < 22.0:
				_drag = "flower"
				_drag_off = _flower_pos - m
				_reg_taps = 0
				Music.pick()
			elif not _stored.note and _note_pos.distance_to(m) < 42.0:
				_drag = "note"
				_drag_off = _note_pos - m
				_reg_taps = 0
				Music.pick()
			elif START_RECT.has_point(m):
				_reg_taps = 0
				_start()
			elif _reg_rect().has_point(m):
				_tap_register()
			else:
				_reg_taps = 0
		else:
			if _drag != "":
				if _over_reg:
					_stored[_drag] = true          # dropped onto the machine → discard it in
				Music.drop()
				_persist()
			_drag = ""
			_over_reg = false
	elif event is InputEventMouseMotion and _drag != "":
		var np: Vector2 = (get_global_mouse_position() - _offset()) + _drag_off
		np.x = clamp(np.x, 24.0, float(W) - 24.0)
		np.y = clamp(np.y, 46.0, 252.0)   # keep it on the wall, above the counter
		if _drag == "flower":
			_flower_pos = np
		elif _drag == "note":
			_note_pos = np
		else:
			_painting_pos = np
		_over_reg = _reg_rect().has_point(np)   # hovering the machine → show 丟棄 hint
		queue_redraw()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_ENTER, KEY_SPACE]:
			_start()


func _offset() -> Vector2:
	var vp: Vector2 = get_viewport_rect().size
	return Vector2(floor(max(0.0, (vp.x - W) / 2.0)), floor(max(0.0, (vp.y - H) / 2.0)))


func _board_size() -> Vector2:
	return Vector2(108.0, 97.0)


func _board_rect() -> Rect2:
	var bs := _board_size()
	return Rect2(_board_pos - bs / 2.0, bs)


# register hit area (fixed) + reset-dialog button rects, all in content coords
func _reg_rect() -> Rect2:
	return Rect2(42.0, 220.0, 66.0, 62.0)


func _reset_no() -> Rect2:
	return Rect2(49.0, 214.0, 80.0, 28.0)


func _reset_yes() -> Rect2:
	return Rect2(141.0, 214.0, 80.0, 28.0)


func _do_reset() -> void:
	Game.reset_all()
	_note_pos = Vector2(220.0, 221.0)
	_flower_pos = Vector2(90.0, 130.0)
	_stored = {"flower": false, "note": false, "painting": true}   # decorations back to start


# tap the 充電寶 machine: it rattles, and tosses one random stored decoration
# back onto the wall. (Seven taps in a row still opens the secret reset dialog.)
func _tap_register() -> void:
	_reg_shake = 0.35
	Music.pick()
	var inside := []
	if _stored.flower:
		inside.append("flower")
	if _stored.note:
		inside.append("note")
	if _has_painting() and _stored.painting:
		inside.append("painting")
	if inside.size() > 0:
		var id: String = inside[randi() % inside.size()]
		_stored[id] = false
		var np := Vector2(randf_range(34.0, float(W) - 34.0), randf_range(58.0, 200.0))
		if id == "flower":
			_flower_pos = np
		elif id == "note":
			_note_pos = np
		else:
			_painting_pos = np
		Music.drop()
		_persist()
	_reg_taps += 1
	if _reg_taps >= 7:
		_reg_taps = 0
		_confirm_reset = true
	queue_redraw()


func _draw_reset_dialog() -> void:
	var p := Rect2(35.0, 158.0, 200.0, 96.0)
	draw_rect(p, Color("231f28"))
	draw_rect(p, COL_YELLOW, false, 2.0)
	_ctext("重置本地數據？", Vector2(135.0, 188.0), 14, COL_WHITE)
	_ctext("清空完成記錄與擺放", Vector2(135.0, 206.0), 9, Color(1, 1, 1, 0.7))
	_button(_reset_no(), "取消", COL_GREY, true)
	_button(_reset_yes(), "重置", COL_RED, true)


func _start() -> void:
	Music.click()
	get_tree().change_scene_to_file("res://scenes/Main.tscn")


# =====================================================================
func _draw() -> void:
	# fill the whole (possibly taller) screen so there are no black bars, then
	# centre the cover: top margin extends the noren green, bottom the counter wood
	var vp: Vector2 = get_viewport_rect().size
	var ox: float = floor(max(0.0, (vp.x - W) / 2.0))
	var oy: float = floor(max(0.0, (vp.y - H) / 2.0))
	var ct: float = oy + 280.0   # counter top
	# layered back-to-front: wall(1) → sticker(2) → board(10) → table(20)
	# → register(30) → garland(40); switch coord spaces between full-width
	# bands (viewport) and centred props (content) as needed.

	# z1 — wall (full-width) with diagonal light: bright centre, dark sides
	draw_rect(Rect2(0, 0, vp.x, vp.y), Color("e3cba0"))
	draw_rect(Rect2(0, oy + 215.0, vp.x, ct - (oy + 215.0)), Color("d8bd8e"))    # lower wall
	draw_rect(Rect2(0, oy + 215.0, vp.x, 1.0), Color("c8a874"))
	_draw_wall_light(vp, ct)

	draw_set_transform(Vector2(ox, oy), 0.0, Vector2.ONE)
	# z2 — version sticker (hidden while stored inside the machine)
	if not _stored.note:
		_draw_version_note()
	# z3 — bonus 挂画 (Mona Lisa), once unlocked and out of the machine
	if _has_painting() and not _stored.painting:
		_draw_painting()
	# z5 — draggable pink flower (hidden while stored inside the machine)
	if not _stored.flower:
		_draw_flower()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# z20 — wooden counter (full-width)
	draw_rect(Rect2(0, ct, vp.x, vp.y - ct), Color("a9743f"))
	draw_rect(Rect2(0, ct, vp.x, 6), Color("c08a4e"))
	draw_rect(Rect2(0, ct + 60.0, vp.x, 2), Color("8c5d30"))
	draw_rect(Rect2(0, ct + 120.0, vp.x, 2), Color("8c5d30"))

	# z30 — register (wobbles briefly after a tap)
	var shx := 0.0
	if _reg_shake > 0.0:
		shx = sin(Time.get_ticks_msec() * 0.045) * _reg_shake * 10.0
	draw_set_transform(Vector2(ox + shx, oy), 0.0, Vector2.ONE)
	if stall_tex != null:
		draw_texture_rect(stall_tex, Rect2(0, 0, W, H), false)
	if _machine_has_items():
		_draw_port_glow()          # one charging port glows blue while it holds a decoration
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# z35 — "丟棄" hint on the dragged decoration itself while it's over the machine
	if _drag != "" and _over_reg:
		draw_set_transform(Vector2(ox, oy), 0.0, Vector2.ONE)
		var dp: Vector2 = _flower_pos
		var dy: float = 22.0
		if _drag == "note":
			dp = _note_pos
			dy = 48.0
		elif _drag == "painting":
			dp = _painting_pos
			dy = 42.0
		_ctext("丟棄", dp - Vector2(0.0, dy), 12, COL_RED)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# shop name on top
	if _drag == "":
		# shop name at the upper golden ratio between the top safe area and the
		# table (0.382 down from the safe area = 0.618 up from the table)
		var st := _safe_top(vp)
		var ty := st + 0.382 * (ct - st)
		_ctext("拉麵怪奇物語", Vector2(vp.x / 2.0, ty), 28, COL_SOUP)

	# UI on top — start button + tally (hidden on splash / while dragging)
	draw_set_transform(Vector2(ox, oy), 0.0, Vector2.ONE)
	if not _splash and _drag == "":
		_button(START_RECT, "開 始", COL_GREEN, true)
		var hue: float = fmod(blink * 0.4, 1.0)
		var tally := Color.from_hsv(hue, 0.7, 1.0)
		_ctext("已完成  " + str(Game.high_score) + "  單", Vector2(135, 445), 10, tally)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# secret reset-data dialog on top of everything
	if _confirm_reset:
		draw_rect(Rect2(0, 0, vp.x, vp.y), Color(0, 0, 0, 0.55))   # dim
		draw_set_transform(Vector2(ox, oy), 0.0, Vector2.ONE)
		_draw_reset_dialog()
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# deterministic pseudo-random in [0,1) — stable per seed so the garland
# doesn't jitter every frame
func _hash(n: float) -> float:
	var f: float = sin(n * 12.9898) * 43758.5453
	return f - floor(f)


func _flower(c: Vector2, r: float, col: Color, rot := 0.0) -> void:
	for i in 5:
		var a := -PI / 2.0 + rot + float(i) * TAU / 5.0
		draw_circle(c + Vector2(cos(a), sin(a)) * r * 0.9, r * 0.62, col)
	draw_circle(c, r * 0.5, COL_YELLOW)


func _draw_flower() -> void:
	# a single draggable pink flower on the wall (z5)
	_flower(_flower_pos, 11.0, Color("e88aa0"), 0.0)


func _machine_has_items() -> bool:
	return _stored.flower or _stored.note or (_has_painting() and _stored.painting)


# bonus 挂画: a gold-framed pixel Mona Lisa hung on the wall (content space)
func _draw_painting() -> void:
	var c := _painting_pos
	var iw := 40.0
	var ih := 52.0
	var f := 5.0
	var ow := iw + f * 2.0
	var oh := ih + f * 2.0
	var x0 := c.x - ow / 2.0
	var y0 := c.y - oh / 2.0
	draw_rect(Rect2(x0 + 2.0, y0 + 3.0, ow, oh), Color(0, 0, 0, 0.18))     # shadow
	draw_rect(Rect2(x0, y0, ow, oh), Color("caa24e"))                       # gold frame
	draw_rect(Rect2(x0, y0, ow, oh), Color("7c5e22"), false, 1.0)
	draw_rect(Rect2(x0 + 3.0, y0 + 3.0, ow - 6.0, oh - 6.0), Color("6a5220"), false, 1.0)
	if mona_tex != null:
		draw_texture_rect(mona_tex, Rect2(c.x - iw / 2.0, c.y - ih / 2.0, iw, ih), false)
	else:
		draw_rect(Rect2(c.x - iw / 2.0, c.y - ih / 2.0, iw, ih), Color("4a4632"))
	draw_circle(Vector2(c.x, y0 - 3.0), 1.6, Color("3a3026"))               # hanging nail


# one charging port lights up blue while the machine holds a decoration
func _draw_port_glow() -> void:
	var a: float = 0.55 + 0.3 * sin(blink * 4.0)
	var px := 54.0
	var py := 232.0
	draw_circle(Vector2(px + 8.0, py + 6.0), 15.0, Color(0.3, 0.62, 1.0, 0.16 * a))
	draw_rect(Rect2(px, py, 16.0, 12.0), Color(0.35, 0.7, 1.0, 0.85 * a))
	draw_rect(Rect2(px, py, 16.0, 3.0), Color(0.75, 0.92, 1.0, 0.9 * a))


func _draw_wall_light(vp: Vector2, ct: float) -> void:
	# diagonal lighting on the wall: darken the two sides, a soft light beam
	# slanting down from the top centre
	var dark := Color(0.18, 0.11, 0.04, 0.26)
	var clear := Color(0.18, 0.11, 0.04, 0.0)
	var mL := vp.x * 0.40
	var mR := vp.x * 0.60
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(mL, 0), Vector2(mL, ct), Vector2(0, ct)]),
		PackedColorArray([dark, clear, clear, dark]))
	draw_polygon(PackedVector2Array([Vector2(mR, 0), Vector2(vp.x, 0), Vector2(vp.x, ct), Vector2(mR, ct)]),
		PackedColorArray([clear, dark, dark, clear]))
	# slanted light beam — brighter at the top, fading down
	var lit := Color(1.0, 0.97, 0.85, 0.14)
	var litc := Color(1.0, 0.97, 0.85, 0.0)
	draw_polygon(PackedVector2Array([
		Vector2(vp.x * 0.26, 0), Vector2(vp.x * 0.60, 0),
		Vector2(vp.x * 0.74, ct), Vector2(vp.x * 0.40, ct)]),
		PackedColorArray([lit, lit, litc, litc]))


func _safe_top(vp: Vector2) -> float:
	# top safe-area inset (notch) in viewport coords; 0 on desktop / web
	var ws := DisplayServer.window_get_size()
	if ws.y <= 0:
		return 0.0
	var st := float(DisplayServer.get_display_safe_area().position.y) * vp.y / float(ws.y)
	if OS.get_name() == "iOS":
		st = max(st, 44.0)
	return st


func _draw_version_note() -> void:
	# a white paper note taped on the wall (right side), tilted ~30° for a
	# casual crooked look: app logo + version number
	var pw := 62.0
	var ph := 74.0
	var cx := _note_pos.x
	var cy := _note_pos.y
	var off := _offset()
	draw_set_transform(off + Vector2(cx, cy), deg_to_rad(-30.0), Vector2.ONE)
	var hw := pw / 2.0
	var hh := ph / 2.0
	draw_rect(Rect2(-hw + 2.0, -hh + 3.0, pw, ph), Color(0, 0, 0, 0.12))   # soft shadow
	draw_rect(Rect2(-hw, -hh, pw, ph), Color("f6f2e8"))                    # paper
	draw_rect(Rect2(-hw, -hh, pw, ph), COL_INK, false, 1.0)               # outline
	# tape at the top corners
	var tape := Color(0.91, 0.89, 0.76, 0.6)
	draw_rect(Rect2(-hw - 4.0, -hh - 3.0, 18.0, 8.0), tape)
	draw_rect(Rect2(hw - 14.0, -hh - 3.0, 18.0, 8.0), tape)
	# app logo (iOS rounded-rect icon)
	if logo_tex != null:
		draw_texture_rect(logo_tex, Rect2(-20.0, -hh + 9.0, 40.0, 40.0), false)
	# version number, dark text
	_ctext("v" + VERSION, Vector2(0.0, -hh + 63.0), 12, COL_INK)
	draw_set_transform(off, 0.0, Vector2.ONE)   # restore content transform


func _button(r: Rect2, label: String, base: Color, enabled: bool) -> void:
	draw_rect(r, base if enabled else COL_GREY)
	draw_rect(Rect2(r.position, Vector2(r.size.x, 2)), Color(1, 1, 1, 0.2))
	draw_rect(r, COL_INK, false, 1.0)
	var col := COL_WHITE if enabled else Color(1, 1, 1, 0.5)
	_ctext(label, Vector2(r.position.x + r.size.x / 2, r.position.y + r.size.y / 2 + 5), 14, col)


func _draw_chef(center_bottom: Vector2, h: float) -> void:
	if chef_tex == null:
		return
	var col: int = CHEF_SEQ[idx]
	var src := Rect2(col * CHEF_FW, 0, CHEF_FW, CHEF_FH)   # row 0 = facing down
	var w := CHEF_FW / float(CHEF_FH) * h
	draw_texture_rect_region(chef_tex, Rect2(center_bottom.x - w / 2.0, center_bottom.y - h, w, h), src)


func _ctext(s: String, pos: Vector2, size: int, col: Color) -> void:
	var w: float = font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	# centre on the ink, not the advance box: the offset is just the last
	# CJK/full-width glyph's trailing advance gap (~size/4), independent of length;
	# ASCII-terminated strings (e.g. v0.0.1) need no correction
	var corr := 0.0
	if s.length() > 0 and s.unicode_at(s.length() - 1) >= 0x2000:
		corr = size * 0.25
	var ink: float = w - corr
	var p := Vector2(pos.x - ink * 0.5, pos.y)
	draw_string(font, p + Vector2(1, 1), s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, COL_INK)
	draw_string(font, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)
