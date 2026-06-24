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
	if Game.has_save():
		Game.load_game()        # pre-load so the menu can show the saved coins
	if Game.has_layout:         # restore the player's saved wall arrangement
		_note_pos = Game.note_pos
		if Game.flower_pos != Vector2.ZERO:
			_flower_pos = Game.flower_pos
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


func _process(delta: float) -> void:
	blink += delta
	anim += delta
	if anim > 0.18:
		anim -= 0.18
		idx = (idx + 1) % CHEF_SEQ.size()
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
			# pick up the flower / sticker to drag, else the start button
			if _flower_pos.distance_to(m) < 22.0:
				_drag = "flower"
				_drag_off = _flower_pos - m
				_reg_taps = 0
				Music.pick()
			elif _note_pos.distance_to(m) < 42.0:
				_drag = "note"
				_drag_off = _note_pos - m
				_reg_taps = 0
				Music.pick()
			elif START_RECT.has_point(m):
				_reg_taps = 0
				_start()
			elif _reg_rect().has_point(m):
				# secret: 7 taps in a row on the register → reset-data dialog
				_reg_taps += 1
				if _reg_taps >= 7:
					_reg_taps = 0
					_confirm_reset = true
					queue_redraw()
			else:
				_reg_taps = 0
		else:
			if _drag != "":
				Game.save_layout(_note_pos, _flower_pos)   # persist the arrangement
				Music.drop()
			_drag = ""
	elif event is InputEventMouseMotion and _drag != "":
		var np: Vector2 = (get_global_mouse_position() - _offset()) + _drag_off
		np.x = clamp(np.x, 24.0, float(W) - 24.0)
		np.y = clamp(np.y, 46.0, 252.0)   # keep it on the wall, above the counter
		if _drag == "flower":
			_flower_pos = np
		else:
			_note_pos = np
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

	# z1 — wall (full-width)
	draw_rect(Rect2(0, 0, vp.x, vp.y), Color("e3cba0"))
	draw_rect(Rect2(0, oy + 215.0, vp.x, ct - (oy + 215.0)), Color("d8bd8e"))    # lower wall
	draw_rect(Rect2(0, oy + 215.0, vp.x, 1.0), Color("c8a874"))

	draw_set_transform(Vector2(ox, oy), 0.0, Vector2.ONE)
	# z2 — version sticker
	_draw_version_note()
	# z5 — draggable pink flower
	_draw_flower()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# z20 — wooden counter (full-width)
	draw_rect(Rect2(0, ct, vp.x, vp.y - ct), Color("a9743f"))
	draw_rect(Rect2(0, ct, vp.x, 6), Color("c08a4e"))
	draw_rect(Rect2(0, ct + 60.0, vp.x, 2), Color("8c5d30"))
	draw_rect(Rect2(0, ct + 120.0, vp.x, 2), Color("8c5d30"))

	draw_set_transform(Vector2(ox, oy), 0.0, Vector2.ONE)
	# z30 — register
	if stall_tex != null:
		draw_texture_rect(stall_tex, Rect2(0, 0, W, H), false)
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
