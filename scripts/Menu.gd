extends Node2D
# =====================================================================
#  RAMEN-YA — MAIN MENU
#  新遊戲 (New Game) starts fresh; 繼續遊戲 (Continue) loads the save.
# =====================================================================

const W := 480
const H := 270

const NEW_RECT := Rect2(170, 132, 140, 28)
const CONT_RECT := Rect2(170, 170, 140, 28)

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
	if ResourceLoader.exists("res://assets/env/ramen_stall.png"):
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
		_click(get_global_mouse_position())
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ENTER or event.keycode == KEY_SPACE:
			_new_game()
		elif event.keycode == KEY_C and Game.has_save():
			_continue()


func _click(p: Vector2) -> void:
	if NEW_RECT.has_point(p):
		_new_game()
	elif CONT_RECT.has_point(p) and Game.has_save():
		_continue()


func _new_game() -> void:
	Game.new_game()
	get_tree().change_scene_to_file("res://scenes/World.tscn")


func _continue() -> void:
	Game.load_game()
	get_tree().change_scene_to_file("res://scenes/World.tscn")


# =====================================================================
func _draw() -> void:
	draw_rect(Rect2(0, 0, W, H), COL_BG)
	# stall art as a faint full-width backdrop
	if stall_tex != null:
		var sw := float(W)
		var sh := sw * stall_tex.get_height() / float(stall_tex.get_width())
		draw_texture_rect(stall_tex, Rect2(0, (H - sh) / 2.0, sw, sh), false, Color(1, 1, 1, 0.4))
	draw_rect(Rect2(0, 0, W, H), Color(0.07, 0.06, 0.09, 0.62))

	# title
	_ctext("拉 麵 屋", Vector2(240, 64), 30, COL_YELLOW)
	_ctext("2D 卡通拉麵 RPG", Vector2(240, 92), 11, COL_WHITE)

	# walking chef on the left
	_draw_chef(Vector2(78, 232), 92)

	# buttons
	_button(NEW_RECT, "新遊戲", COL_GREEN, true)
	var has := Game.has_save()
	_button(CONT_RECT, "繼續遊戲", COL_YELLOW if has else COL_GREY, has)
	if has:
		_ctext("存檔金幣 ￥" + str(Game.coins), Vector2(240, 212), 9, COL_WHITE)
	else:
		_ctext("（尚無存檔）", Vector2(240, 212), 9, Color(1, 1, 1, 0.55))

	_ctext("點擊選擇 ・ Enter 新遊戲 ・ C 繼續", Vector2(240, 258), 9,
		COL_GREEN if int(blink * 2.0) % 2 == 0 else COL_WHITE)


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
	draw_string(font, pos + Vector2(1, 1), s, HORIZONTAL_ALIGNMENT_CENTER, -1, size, COL_INK)
	draw_string(font, pos, s, HORIZONTAL_ALIGNMENT_CENTER, -1, size, col)
