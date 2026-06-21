extends Node2D
# =====================================================================
#  RAMEN-YA  /  らーめん屋
#  A self-contained 2D pixel-art ramen-shop management demo.
#  All graphics are drawn procedurally (no external art assets), so the
#  project exports cleanly to Web / HTML5.
# =====================================================================

# ---- screen ---------------------------------------------------------
const W := 480
const H := 270

# ---- game states ----------------------------------------------------
enum State { TITLE, PLAY, OVER }
var state: int = State.TITLE

# ---- palette --------------------------------------------------------
const COL_BG       := Color("231f28")
const COL_WOOD     := Color("6b4a2b")
const COL_WOOD_D   := Color("4d3320")
const COL_COUNTER  := Color("c89b6a")
const COL_WHITE    := Color("f4f0e6")
const COL_INK      := Color("1a1620")
const COL_RED      := Color("d94f4f")
const COL_GREEN    := Color("5fae5f")
const COL_YELLOW   := Color("f2c14e")
const COL_PANEL    := Color("33293a")
const COL_PANEL_HI := Color("4a3c54")
const COL_BOWL     := Color("e7e3d8")
const COL_BOWL_RIM := Color("c23b3b")

# broth colors
const BROTH := {
	"shoyu": Color("7a4a22"),
	"miso":  Color("c47a2e"),
}
const BROTH_NAME := { "shoyu": "醤油 Shoyu", "miso": "味噌 Miso" }

# topping colors / short labels
const TOP := {
	"egg":    { "col": Color("f2a64e"), "lbl": "玉" },
	"nori":   { "col": Color("2f4a3a"), "lbl": "海" },
	"chashu": { "col": Color("d98a8a"), "lbl": "焼" },
	"negi":   { "col": Color("8fd24e"), "lbl": "葱" },
}
const TOP_KEYS := ["egg", "nori", "chashu", "negi"]

# ---- font -----------------------------------------------------------
var font: Font

# ---- gameplay state -------------------------------------------------
var money: int = 0
var served: int = 0
var reputation: int = 3
var day_time: float = 120.0          # length of one business day (sec)

var customers: Array = []            # one entry per seat (or null)
const SEATS := 3
var seat_x := [80, 240, 400]
var selected_seat: int = 0

var spawn_timer: float = 1.0
var spawn_interval: float = 4.0

# current bowl being assembled
var bowl := { "noodles": false, "broth": "", "toppings": [] }

var float_texts: Array = []          # {pos, text, col, ttl}
var buttons: Array = []              # {id, rect, label, kind}
var flash: float = 0.0               # screen feedback timer
var flash_col: Color = COL_GREEN


func _ready() -> void:
	randomize()
	font = ThemeDB.fallback_font
	_build_buttons()
	set_process(true)


# =====================================================================
#  BUTTON LAYOUT
# =====================================================================
func _build_buttons() -> void:
	buttons.clear()
	var w := 76
	var h := 22
	# row 1 : base + first topping
	_add_btn("noodles", 6,   198, w, h, "麺 Noodle", "ing")
	_add_btn("shoyu",   86,  198, w, h, "醤油",       "ing")
	_add_btn("miso",    166, 198, w, h, "味噌",       "ing")
	_add_btn("egg",     246, 198, w, h, "玉子 Egg",   "ing")
	# row 2 : toppings
	_add_btn("nori",    6,   224, w, h, "海苔",       "ing")
	_add_btn("chashu",  86,  224, w, h, "叉焼",       "ing")
	_add_btn("negi",    166, 224, w, h, "葱 Negi",    "ing")
	# actions
	_add_btn("serve",   336, 198, 138, 22, "出す SERVE", "serve")
	_add_btn("clear",   336, 224, 138, 22, "捨てる CLEAR", "clear")


func _add_btn(id: String, x: int, y: int, w: int, h: int, label: String, kind: String) -> void:
	buttons.append({
		"id": id,
		"rect": Rect2(x, y, w, h),
		"label": label,
		"kind": kind,
	})


# =====================================================================
#  GAME LOOP
# =====================================================================
func _process(delta: float) -> void:
	if flash > 0.0:
		flash = max(0.0, flash - delta)

	# advance float texts
	for ft in float_texts:
		ft.pos.y -= 18.0 * delta
		ft.ttl -= delta
	float_texts = float_texts.filter(func(t): return t.ttl > 0.0)

	if state == State.PLAY:
		_update_play(delta)

	queue_redraw()


func _update_play(delta: float) -> void:
	day_time -= delta
	if day_time <= 0.0:
		day_time = 0.0
		_end_game()
		return

	# spawn customers into empty seats
	spawn_timer -= delta
	if spawn_timer <= 0.0:
		_try_spawn()
		# ramp up difficulty as the day goes on
		spawn_interval = max(2.0, 4.0 - served * 0.12)
		spawn_timer = spawn_interval

	# tick patience
	for i in SEATS:
		var c = customers[i]
		if c == null:
			continue
		c.patience -= delta
		if c.patience <= 0.0:
			# customer leaves angry
			_spawn_float(Vector2(seat_x[i], 70), "怒 ANGRY!", COL_RED)
			customers[i] = null
			reputation -= 1
			flash = 0.25
			flash_col = COL_RED
			if reputation <= 0:
				_end_game()
				return


func _try_spawn() -> void:
	var empty := []
	for i in SEATS:
		if customers[i] == null:
			empty.append(i)
	if empty.is_empty():
		return
	var seat: int = empty[randi() % empty.size()]
	customers[seat] = _make_order()
	# auto-select if nothing selected/occupied
	if customers[selected_seat] == null:
		selected_seat = seat


func _make_order() -> Dictionary:
	var broth: String = ["shoyu", "miso"][randi() % 2]
	var pool := TOP_KEYS.duplicate()
	pool.shuffle()
	var n := 1 + randi() % 3            # 1..3 toppings
	var tops := []
	for i in n:
		tops.append(pool[i])
	tops.sort()
	var pat := 20.0
	return {
		"broth": broth,
		"toppings": tops,
		"patience": pat,
		"max_patience": pat,
		"face": randi() % 4,
	}


# =====================================================================
#  INPUT
# =====================================================================
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_click(get_global_mouse_position())
	elif event is InputEventKey and event.pressed and not event.echo:
		_handle_key(event.keycode)


func _handle_key(key: int) -> void:
	if state == State.TITLE and (key == KEY_SPACE or key == KEY_ENTER):
		_start_game()
	elif state == State.OVER and (key == KEY_R or key == KEY_SPACE or key == KEY_ENTER):
		_start_game()


func _handle_click(p: Vector2) -> void:
	if state == State.TITLE:
		_start_game()
		return
	if state == State.OVER:
		_start_game()
		return

	# seat selection
	for i in SEATS:
		var r := Rect2(seat_x[i] - 70, 24, 140, 126)
		if r.has_point(p) and customers[i] != null:
			selected_seat = i
			return

	# buttons
	for b in buttons:
		if b.rect.has_point(p):
			_press_button(b.id, b.kind)
			return


func _press_button(id: String, kind: String) -> void:
	match kind:
		"ing":
			_add_ingredient(id)
		"clear":
			bowl = { "noodles": false, "broth": "", "toppings": [] }
		"serve":
			_serve()


func _add_ingredient(id: String) -> void:
	if id == "noodles":
		bowl.noodles = true
	elif id == "shoyu" or id == "miso":
		bowl.broth = id
	else:
		# topping — toggle, no duplicates
		if bowl.toppings.has(id):
			bowl.toppings.erase(id)
		else:
			bowl.toppings.append(id)
			bowl.toppings.sort()


func _serve() -> void:
	var c = customers[selected_seat]
	if c == null:
		_spawn_float(Vector2(240, 150), "no customer", COL_YELLOW)
		return
	if not bowl.noodles or bowl.broth == "":
		_spawn_float(Vector2(240, 150), "未完成 incomplete!", COL_YELLOW)
		return

	var ok: bool = (bowl.broth == c.broth) and _same(bowl.toppings, c.toppings)
	if ok:
		var tip: int = 60 + int(round(c.patience / c.max_patience * 60.0)) + 10 * c.toppings.size()
		money += tip
		served += 1
		_spawn_float(Vector2(seat_x[selected_seat], 60), "+" + str(tip), COL_GREEN)
		flash = 0.2
		flash_col = COL_GREEN
	else:
		money = max(0, money - 30)
		reputation -= 1
		_spawn_float(Vector2(seat_x[selected_seat], 60), "違う！ wrong  -30", COL_RED)
		flash = 0.25
		flash_col = COL_RED

	customers[selected_seat] = null
	bowl = { "noodles": false, "broth": "", "toppings": [] }
	if reputation <= 0:
		_end_game()


func _same(a: Array, b: Array) -> bool:
	if a.size() != b.size():
		return false
	for x in a:
		if not b.has(x):
			return false
	return true


# =====================================================================
#  STATE TRANSITIONS
# =====================================================================
func _start_game() -> void:
	state = State.PLAY
	money = 0
	served = 0
	reputation = 3
	day_time = 120.0
	spawn_timer = 0.8
	spawn_interval = 4.0
	selected_seat = 0
	customers = [null, null, null]
	bowl = { "noodles": false, "broth": "", "toppings": [] }
	float_texts.clear()


func _end_game() -> void:
	state = State.OVER


func _spawn_float(pos: Vector2, text: String, col: Color) -> void:
	float_texts.append({ "pos": pos, "text": text, "col": col, "ttl": 1.4 })


# =====================================================================
#  DRAWING
# =====================================================================
func _draw() -> void:
	draw_rect(Rect2(0, 0, W, H), COL_BG)
	match state:
		State.TITLE:
			_draw_title()
		State.PLAY:
			_draw_play()
		State.OVER:
			_draw_play()      # keep scene behind
			_draw_over()

	# flash overlay
	if flash > 0.0:
		var a := flash * 0.5
		draw_rect(Rect2(0, 0, W, H), Color(flash_col.r, flash_col.g, flash_col.b, a))

	# floating texts (always on top)
	for ft in float_texts:
		_text(ft.text, ft.pos + Vector2(1, 1), 10, COL_INK, HORIZONTAL_ALIGNMENT_CENTER)
		_text(ft.text, ft.pos, 10, ft.col, HORIZONTAL_ALIGNMENT_CENTER)


func _draw_title() -> void:
	# backdrop
	draw_rect(Rect2(0, 150, W, 120), COL_WOOD_D)
	draw_rect(Rect2(0, 150, W, 8), COL_COUNTER)
	# noren / banner
	draw_rect(Rect2(120, 40, 240, 70), COL_BOWL_RIM)
	draw_rect(Rect2(120, 40, 240, 10), Color("a02a2a"))
	_text("らーめん", Vector2(240, 92), 40, COL_WHITE, HORIZONTAL_ALIGNMENT_CENTER)

	_text("R A M E N - Y A", Vector2(240, 145), 22, COL_YELLOW, HORIZONTAL_ALIGNMENT_CENTER)
	_text("2D Pixel Ramen-Shop Manager  (DEMO)", Vector2(240, 172), 11, COL_WHITE, HORIZONTAL_ALIGNMENT_CENTER)

	# a couple of decorative bowls
	_draw_bowl(Vector2(70, 200), "shoyu", ["egg", "nori"], 1.6)
	_draw_bowl(Vector2(390, 200), "miso", ["chashu", "negi"], 1.6)

	if int(day_time * 2.0) % 2 == 0 or true:
		_text("[ CLICK or press SPACE to start ]", Vector2(240, 235), 12,
			COL_GREEN if (Time_blink()) else COL_WHITE, HORIZONTAL_ALIGNMENT_CENTER)


func Time_blink() -> bool:
	# cheap blink driven by float_texts-independent timer using engine time
	return int(Engine.get_frames_drawn() / 30) % 2 == 0


func _draw_play() -> void:
	# --- counter / kitchen backdrop ---
	draw_rect(Rect2(0, 24, W, 126), COL_WOOD)
	draw_rect(Rect2(0, 150, W, 4), COL_COUNTER)        # counter top edge
	draw_rect(Rect2(0, 154, W, 42), COL_PANEL)         # kitchen band
	draw_rect(Rect2(0, 196, W, 74), COL_PANEL_HI)      # control panel bg

	# --- seats / customers ---
	for i in SEATS:
		_draw_seat(i)

	# --- selected bowl-building area ---
	_draw_build_area()

	# --- buttons ---
	for b in buttons:
		_draw_button(b)

	# --- top HUD ---
	_draw_hud()


func _draw_hud() -> void:
	draw_rect(Rect2(0, 0, W, 22), COL_INK)
	_text("￥ " + str(money), Vector2(8, 16), 13, COL_YELLOW)
	_text("Served: " + str(served), Vector2(150, 16), 11, COL_WHITE)

	# reputation hearts
	_text("Rep:", Vector2(250, 16), 11, COL_WHITE)
	for i in 3:
		var c := COL_RED if i < reputation else Color("44333a")
		draw_rect(Rect2(286 + i * 14, 5, 11, 11), c)

	# day timer bar
	_text("Day", Vector2(338, 16), 10, COL_WHITE)
	var bw := 110
	draw_rect(Rect2(362, 6, bw, 10), COL_PANEL)
	var frac: float = clamp(day_time / 120.0, 0.0, 1.0)
	draw_rect(Rect2(362, 6, int(bw * frac), 10), COL_GREEN)


func _draw_seat(i: int) -> void:
	var cx: int = seat_x[i]
	# selection highlight
	if i == selected_seat and customers[i] != null:
		draw_rect(Rect2(cx - 72, 26, 144, 124), Color(1, 1, 1, 0.08))
		draw_rect(Rect2(cx - 72, 26, 144, 2), COL_YELLOW)

	var c = customers[i]
	if c == null:
		_text("空席", Vector2(cx, 95), 11, Color(1, 1, 1, 0.25), HORIZONTAL_ALIGNMENT_CENTER)
		return

	# --- customer body (simple pixel figure) ---
	_draw_customer(Vector2(cx, 96), c.face)

	# --- patience bar ---
	var pw := 90
	var px: int = cx - pw / 2
	draw_rect(Rect2(px, 140, pw, 6), COL_INK)
	var pf: float = clamp(c.patience / c.max_patience, 0.0, 1.0)
	var pcol := COL_GREEN
	if pf < 0.5: pcol = COL_YELLOW
	if pf < 0.25: pcol = COL_RED
	draw_rect(Rect2(px, 140, int(pw * pf), 6), pcol)

	# --- order speech bubble ---
	_draw_order_bubble(Vector2(cx, 30), c)


func _draw_order_bubble(top_left_center: Vector2, c: Dictionary) -> void:
	var bx := int(top_left_center.x) - 64
	var by := 27
	var bw := 128
	var bh := 36
	draw_rect(Rect2(bx, by, bw, bh), COL_WHITE)
	draw_rect(Rect2(bx, by, bw, 2), COL_INK)
	draw_rect(Rect2(bx, by + bh, bw, 2), COL_INK)
	# little tail
	draw_rect(Rect2(int(top_left_center.x) - 4, by + bh, 8, 6), COL_WHITE)

	# broth swatch
	draw_rect(Rect2(bx + 6, by + 8, 20, 20), BROTH[c.broth])
	draw_rect(Rect2(bx + 6, by + 8, 20, 3), Color(1, 1, 1, 0.25))
	_text(BROTH_NAME[c.broth].substr(0, 2), Vector2(bx + 16, by + 24), 9, COL_WHITE, HORIZONTAL_ALIGNMENT_CENTER)

	# topping icons
	var ix := bx + 34
	for t in c.toppings:
		draw_rect(Rect2(ix, by + 10, 16, 16), TOP[t].col)
		draw_rect(Rect2(ix, by + 10, 16, 16), COL_INK, false, 1.0)
		_text(TOP[t].lbl, Vector2(ix + 8, by + 23), 9, COL_WHITE, HORIZONTAL_ALIGNMENT_CENTER)
		ix += 20


func _draw_customer(center: Vector2, face: int) -> void:
	var skin: Color = [Color("e8b98c"), Color("c98a5a"), Color("f0cba0"), Color("d9a06a")][face % 4]
	var cloth: Color = [Color("4e6fae"), Color("ae4e6f"), Color("4eae8a"), Color("9a6fae")][face % 4]
	var cx := center.x
	var cy := center.y
	# body
	draw_rect(Rect2(cx - 16, cy + 8, 32, 30), cloth)
	# head
	draw_rect(Rect2(cx - 12, cy - 16, 24, 24), skin)
	# hair
	draw_rect(Rect2(cx - 13, cy - 18, 26, 7), COL_INK)
	# eyes
	draw_rect(Rect2(cx - 7, cy - 6, 3, 4), COL_INK)
	draw_rect(Rect2(cx + 4, cy - 6, 3, 4), COL_INK)
	# mouth
	draw_rect(Rect2(cx - 3, cy + 2, 6, 2), Color("7a3b3b"))


func _draw_build_area() -> void:
	# label
	_text("Seat #" + str(selected_seat + 1) + " — building:", Vector2(8, 168), 10, COL_WHITE)
	# the bowl preview
	_draw_bowl(Vector2(248, 176), bowl.broth, bowl.toppings, 1.3)
	# noodles indicator
	var nood_col := COL_YELLOW if bowl.noodles else Color(1, 1, 1, 0.2)
	_text("麺", Vector2(300, 182), 12, nood_col)
	_text(("noodles OK" if bowl.noodles else "no noodles"), Vector2(312, 182), 9, nood_col)


# draws a ramen bowl with given broth key ("" = empty) and toppings list
func _draw_bowl(center: Vector2, broth: String, toppings: Array, s: float) -> void:
	var cx := center.x
	var cy := center.y
	var w := 46.0 * s
	var h := 22.0 * s
	# rim
	draw_rect(Rect2(cx - w / 2 - 2, cy - h / 2 - 2, w + 4, 6), COL_BOWL_RIM)
	# bowl body (trapezoid-ish using two rects)
	draw_rect(Rect2(cx - w / 2, cy - h / 2, w, h), COL_BOWL)
	draw_rect(Rect2(cx - w / 2 + 4, cy + h / 2, w - 8, 5), COL_BOWL_RIM)
	# broth
	if broth != "":
		draw_rect(Rect2(cx - w / 2 + 4, cy - h / 2 + 3, w - 8, h - 8), BROTH[broth])
		# noodles hint lines
		for n in 4:
			draw_rect(Rect2(cx - w / 2 + 8 + n * (w - 16) / 4.0, cy - h / 2 + 5, 2, h - 12), Color("f2e3b0"))
	# toppings sit on top
	var tx := cx - (toppings.size() - 1) * 9 * s / 2.0
	for t in toppings:
		draw_rect(Rect2(tx - 6 * s, cy - 4 * s, 12 * s, 10 * s), TOP[t].col)
		draw_rect(Rect2(tx - 6 * s, cy - 4 * s, 12 * s, 10 * s), COL_INK, false, 1.0)
		tx += 14 * s


func _draw_button(b: Dictionary) -> void:
	var r: Rect2 = b.rect
	var base := COL_PANEL
	var active := false
	if b.kind == "serve":
		base = COL_GREEN
	elif b.kind == "clear":
		base = COL_RED
	elif b.kind == "ing":
		# show pressed/active for current bowl contents
		if (b.id == "noodles" and bowl.noodles) \
			or (b.id == bowl.broth) \
			or bowl.toppings.has(b.id):
			active = true
	var col := base
	if active:
		col = COL_PANEL_HI

	draw_rect(r, col)
	draw_rect(Rect2(r.position, Vector2(r.size.x, 2)), Color(1, 1, 1, 0.18))
	draw_rect(r, COL_INK, false, 1.0)
	if active:
		draw_rect(r, COL_YELLOW, false, 2.0)

	# small color swatch for ingredient buttons
	if b.kind == "ing":
		var sw := COL_YELLOW
		if b.id == "shoyu" or b.id == "miso":
			sw = BROTH[b.id]
		elif TOP.has(b.id):
			sw = TOP[b.id].col
		draw_rect(Rect2(r.position.x + 4, r.position.y + 5, 12, 12), sw)
		draw_rect(Rect2(r.position.x + 4, r.position.y + 5, 12, 12), COL_INK, false, 1.0)

	var tx := r.position.x + (22 if b.kind == "ing" else 0)
	var ty := r.position.y + r.size.y / 2 + 4
	var align := HORIZONTAL_ALIGNMENT_LEFT
	var pos := Vector2(tx + 4, ty)
	if b.kind != "ing":
		align = HORIZONTAL_ALIGNMENT_CENTER
		pos = Vector2(r.position.x + r.size.x / 2, ty)
	_text(b.label, pos, 10, COL_WHITE, align)


func _draw_over() -> void:
	draw_rect(Rect2(0, 0, W, H), Color(0, 0, 0, 0.7))
	var won := reputation > 0
	var title := "閉店 — DAY COMPLETE!" if won else "GAME OVER"
	_text(title, Vector2(240, 90), 24, (COL_GREEN if won else COL_RED), HORIZONTAL_ALIGNMENT_CENTER)
	_text("Earnings:  ￥ " + str(money), Vector2(240, 130), 16, COL_YELLOW, HORIZONTAL_ALIGNMENT_CENTER)
	_text("Bowls served:  " + str(served), Vector2(240, 156), 13, COL_WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	_text("[ CLICK or press R to play again ]", Vector2(240, 205), 12, COL_WHITE, HORIZONTAL_ALIGNMENT_CENTER)


# ---- text helper ----------------------------------------------------
func _text(s: String, pos: Vector2, size: int, col: Color, align := HORIZONTAL_ALIGNMENT_LEFT) -> void:
	draw_string(font, pos, s, align, -1, size, col)
