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

var font: Font
var stall_tex: Texture2D
var chef_tex: Texture2D
var _splash := false   # when true, render just the counter scene (for the boot splash)
const CHEF_FW := 52
const CHEF_FH := 68
const CHEF_SEQ := [0, 1, 2, 3]
var anim := 0.0
var idx := 0
var blink := 0.0


func _ready() -> void:
	font = _make_font()
	if ResourceLoader.exists("res://assets/chef_sheet.png"):
		chef_tex = load("res://assets/chef_sheet.png")
	if ResourceLoader.exists("res://assets/env/cashier.png"):
		stall_tex = load("res://assets/env/cashier.png")
	elif ResourceLoader.exists("res://assets/env/ramen_stall.png"):
		stall_tex = load("res://assets/env/ramen_stall.png")
	if Game.has_save():
		Game.load_game()        # pre-load so the menu can show the saved coins
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
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if START_RECT.has_point(get_global_mouse_position() - _offset()):
			_start()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_ENTER, KEY_SPACE]:
			_start()


func _offset() -> Vector2:
	var vp: Vector2 = get_viewport_rect().size
	return Vector2(floor(max(0.0, (vp.x - W) / 2.0)), floor(max(0.0, (vp.y - H) / 2.0)))


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
	var nb: float = oy + 58.0    # noren bottom
	var ct: float = oy + 280.0   # counter top
	# --- shop background drawn full-width so it extends to any screen size ---
	draw_rect(Rect2(0, 0, vp.x, vp.y), Color("e3cba0"))                          # wall
	draw_rect(Rect2(0, oy + 215.0, vp.x, ct - (oy + 215.0)), Color("d8bd8e"))    # lower wall
	draw_rect(Rect2(0, oy + 215.0, vp.x, 1.0), Color("c8a874"))
	# noren curtain with slats
	draw_rect(Rect2(0, 0, vp.x, nb), Color("3f8f6a"))
	var sx: float = 0.0
	while sx < vp.x:
		draw_rect(Rect2(sx, oy + 8.0, 2, nb - (oy + 8.0)), COL_INK)
		sx += 28.0
	draw_rect(Rect2(0, nb - 2.0, vp.x, 2), COL_INK)
	# wooden counter that extends infinitely wide
	draw_rect(Rect2(0, ct, vp.x, vp.y - ct), Color("a9743f"))
	draw_rect(Rect2(0, ct, vp.x, 6), Color("c08a4e"))
	draw_rect(Rect2(0, ct + 60.0, vp.x, 2), Color("8c5d30"))
	draw_rect(Rect2(0, ct + 120.0, vp.x, 2), Color("8c5d30"))
	draw_set_transform(Vector2(ox, oy), 0.0, Vector2.ONE)

	# centred props (lanterns / board / register / cat) overlaid on the bands
	if stall_tex != null:
		draw_texture_rect(stall_tex, Rect2(0, 0, W, H), false)

	# shop name on the noren
	_ctext("拉麵怪奇物語", Vector2(135, 40), 22, COL_YELLOW)

	# start button (hidden when rendering the splash)
	if not _splash:
		_button(START_RECT, "開 始", COL_GREEN, true)
		# completed-orders tally, blinking white
		var pulse: float = 0.5 + 0.5 * sin(blink * 5.0)
		var tally := Color(0.5, 0.5, 0.5).lerp(COL_WHITE, pulse)
		_ctext("已完成  " + str(Game.high_score) + "  單", Vector2(135, 445), 10, tally)

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


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
	var ink: float = w - s.length() * max(1.0, round(size / 8.0))
	var p := Vector2(pos.x - ink * 0.5, pos.y)
	draw_string(font, p + Vector2(1, 1), s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, COL_INK)
	draw_string(font, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)
