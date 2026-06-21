extends Node2D
# =====================================================================
#  升級商店 — spend coins on upgrades that make cooking pay off more.
#  Closes the core loop: earn → spend → cook better → earn more.
# =====================================================================

const W := 480
const H := 270

const COL_BG    := Color("241c2a")
const COL_PANEL := Color("33293a")
const COL_PANEL_HI := Color("443754")
const COL_WHITE := Color("f4f0e6")
const COL_INK   := Color("1a1620")
const COL_YELLOW:= Color("f2c14e")
const COL_GREEN := Color("5fae5f")
const COL_RED   := Color("d94f4f")
const COL_GREY  := Color("564a60")
const COL_PIP   := Color("f2c14e")
const COL_PIP_OFF := Color("4a3c54")

const UPGRADES := [
	{ "key": "tip", "name": "小費加成", "eff": "每級小費 +15%" },
	{ "key": "patience", "name": "客人耐心", "eff": "每級耐心 +5 秒" },
	{ "key": "day", "name": "營業時間", "eff": "每級營業 +20 秒" },
]
const ROWS := [Rect2(18, 58, 444, 54), Rect2(18, 120, 444, 54), Rect2(18, 182, 444, 54)]
const EXIT_RECT := Rect2(W - 84, 6, 76, 18)

var font: Font
var flash_row := -1
var flash_t := 0.0
var flash_ok := false


func _ready() -> void:
	font = _make_font()
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
	if flash_t > 0.0:
		flash_t = max(0.0, flash_t - delta)
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE or event.keycode == KEY_M:
			_exit()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_click(get_global_mouse_position())


func _click(p: Vector2) -> void:
	if EXIT_RECT.has_point(p):
		_exit()
		return
	for i in UPGRADES.size():
		if ROWS[i].has_point(p):
			_try_buy(i)
			return


func _try_buy(i: int) -> void:
	flash_row = i
	flash_t = 0.4
	flash_ok = Game.buy_upgrade(UPGRADES[i].key)


func _exit() -> void:
	get_tree().change_scene_to_file("res://scenes/World.tscn")


# =====================================================================
func _draw() -> void:
	draw_rect(Rect2(0, 0, W, H), COL_BG)
	draw_rect(Rect2(0, 0, W, 30), COL_INK)
	_text("升級商店", Vector2(W / 2.0, 21), 16, COL_YELLOW, HORIZONTAL_ALIGNMENT_CENTER)
	_text("￥ " + str(Game.coins), Vector2(12, 21), 13, COL_YELLOW)
	# exit
	draw_rect(EXIT_RECT, Color(0, 0, 0, 0.5))
	draw_rect(EXIT_RECT, COL_YELLOW, false, 1.0)
	_text("← 離開", Vector2(EXIT_RECT.position.x + EXIT_RECT.size.x / 2, EXIT_RECT.position.y + 13),
		9, COL_WHITE, HORIZONTAL_ALIGNMENT_CENTER)

	for i in UPGRADES.size():
		_draw_row(i)

	_text("點擊一行購買 ・ ESC 離開", Vector2(W / 2.0, 258), 9, Color(1, 1, 1, 0.7), HORIZONTAL_ALIGNMENT_CENTER)


func _draw_row(i: int) -> void:
	var u: Dictionary = UPGRADES[i]
	var r: Rect2 = ROWS[i]
	var lvl: int = Game.up_level(u.key)
	var maxed: bool = lvl >= Game.UP_MAX
	var cost: int = Game.up_cost(u.key)
	var afford: bool = Game.coins >= cost

	var base := COL_PANEL
	if flash_row == i and flash_t > 0.0:
		base = COL_GREEN if flash_ok else COL_RED
	draw_rect(r, base)
	draw_rect(Rect2(r.position, Vector2(r.size.x, 2)), Color(1, 1, 1, 0.12))
	draw_rect(r, COL_INK, false, 1.0)

	var x := r.position.x + 10
	var y := r.position.y
	_text(u.name, Vector2(x, y + 20), 14, COL_WHITE)
	_text(u.eff, Vector2(x, y + 40), 9, Color(1, 1, 1, 0.7))

	# level pips
	for p in Game.UP_MAX:
		var px := r.position.x + 150 + p * 14
		draw_rect(Rect2(px, y + 11, 11, 11), COL_PIP if p < lvl else COL_PIP_OFF)
		draw_rect(Rect2(px, y + 11, 11, 11), COL_INK, false, 1.0)
	_text("Lv " + str(lvl) + "/" + str(Game.UP_MAX), Vector2(r.position.x + 150, y + 44), 9, COL_WHITE)

	# cost / buy state on the right
	var bx := r.position.x + r.size.x - 96
	var brect := Rect2(bx, y + 12, 86, 30)
	if maxed:
		draw_rect(brect, COL_GREY)
		_text("已滿級", Vector2(bx + 43, y + 31), 11, COL_WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	else:
		draw_rect(brect, COL_GREEN if afford else COL_GREY)
		draw_rect(brect, COL_INK, false, 1.0)
		_text("￥" + str(cost), Vector2(bx + 43, y + 26), 12,
			COL_WHITE if afford else Color(1, 0.8, 0.8, 0.9), HORIZONTAL_ALIGNMENT_CENTER)
		_text("購買" if afford else "金幣不足", Vector2(bx + 43, y + 38), 8,
			COL_INK if afford else COL_RED, HORIZONTAL_ALIGNMENT_CENTER)


func _text(s: String, pos: Vector2, size: int, col: Color, align := HORIZONTAL_ALIGNMENT_LEFT) -> void:
	draw_string(font, pos + Vector2(0.7, 0.7), s, align, -1, size, COL_INK)
	draw_string(font, pos, s, align, -1, size, col)
