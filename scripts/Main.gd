extends Node2D
# =====================================================================
#  RAMEN-YA  —  COUNTER / 档口  (cooking minigame, redesigned)
#
#  Assemble a bowl of beef ramen with a "pick up → put down" flow:
#  click a station to lift an ingredient, then click the assembly bowl
#  to drop it in.  Base = 湯 + 麵 + 牛肉 (always).  The customer only
#  cares whether to add 蔥花 / 香菜 / 辣椒.  Match their order and serve.
# =====================================================================

# ---- screen ---------------------------------------------------------
const W := 480
const H := 270

# on-screen "back to shop" button (also bound to ESC / M)
const BACK_RECT := Rect2(W - 58, 25, 54, 16)

# action buttons
const CLEAR_RECT := Rect2(148, 247, 88, 18)
const SERVE_RECT := Rect2(244, 247, 88, 18)

# the assembly bowl (click target to drop a held ingredient)
const BOWL_RECT := Rect2(196, 112, 88, 56)

# ---- game states ----------------------------------------------------
enum State { TITLE, PLAY, OVER }
var state: int = State.TITLE

# ---- palette --------------------------------------------------------
const COL_BG       := Color("231f28")
const COL_WALL     := Color("3a2c2e")
const COL_WALL_HI  := Color("4d3a3a")
const COL_COUNTER  := Color("c89b6a")
const COL_COUNTER_D:= Color("a07c4c")
const COL_WHITE    := Color("f4f0e6")
const COL_INK      := Color("1a1620")
const COL_RED      := Color("d94f4f")
const COL_GREEN    := Color("5fae5f")
const COL_YELLOW   := Color("f2c14e")
const COL_PANEL    := Color("33293a")
const COL_PANEL_HI := Color("4a3c54")
const COL_BOWL     := Color("e7e3d8")
const COL_BOWL_RIM := Color("c23b3b")
const COL_POT      := Color("4a4652")
const COL_POT_D    := Color("332f3a")

# ingredient colors
const C_SOUP    := Color("cf9a44")   # golden broth
const C_NOODLE  := Color("f0e0a8")
const C_BEEF    := Color("a8503c")
const C_BEEF_HI := Color("c46a52")

# the three optional toppings the customer may ask for
const TOPPING := {
	"scallion": { "name": "蔥花", "col": Color("8fd24e") },
	"cilantro": { "name": "香菜", "col": Color("3f8f4a") },
	"chili":    { "name": "辣椒", "col": Color("d83a3a") },
}
const TOP_ORDER := ["scallion", "cilantro", "chili"]

# ---- font -----------------------------------------------------------
var font: Font

# ---- gameplay state -------------------------------------------------
var money: int = 0
var served: int = 0
var reputation: int = 3
var day_time: float = 120.0
var day_len: float = 120.0

const SEATS := 3
var seat_x := [96, 240, 384]
var customers: Array = []
var selected_seat: int = 0

var spawn_timer: float = 1.0
var spawn_interval: float = 4.0

# the bowl being assembled + what we're currently holding
var bowl := {}
var held: String = ""              # "" or soup/noodles/beef/scallion/cilantro/chili
var held_q := ""                   # quality of held noodles: raw / ok / over
var bowl_nq := ""                  # noodle quality placed in the bowl
var mouse_pos := Vector2(W / 2.0, H / 2.0)

# 麵鍋 cooking: you must boil a portion and lift it at the right moment
var noodle_state := "empty"        # empty / cooking
var noodle_t := 0.0
const COOK_READY := 3.0            # perfect window opens
const COOK_OVER := 4.8             # ... and closes (after this it's overcooked)

# 湯: ladle a few scoops to fill the bowl (broth rises as you pour)
var soup_fill := 0.0
const SOUP_LADLE := 0.34           # ~3 ladles to fill

# 撒料: shake a topping over the bowl — where & how much is up to you
var sprinkles: Array = []          # {type, pos}
var dragging := false
var last_sprinkle := Vector2(-999, -999)
var sprinkle_cd := 0.0
const SPRINKLE_MAX := 16           # per topping
const SPRINKLE_C := Vector2(240, 130)
const SPRINKLE_RX := 34.0
const SPRINKLE_RY := 10.0

# stations: {item, name, rect, cx}
var stations: Array = []

# refined round-bowl sprites (assets/cook/*.png); empty → procedural fallback
var ctex := {}

# cooking SFX players + steam particles (juice)
var sfx := {}
var steam: Array = []              # {pos, vx, ttl, ph}
var steam_t := 0.0

var float_texts: Array = []
var flash: float = 0.0
var flash_col: Color = COL_GREEN

# ---- chef sprite (title screen only) --------------------------------
var chef_tex: Texture2D
const CHEF_FW := 52
const CHEF_FH := 68
const CHEF_SEQ := [0, 1, 2, 3]
var chef_anim: float = 0.0
var chef_idx: int = 0
var stall_tex: Texture2D


func _ready() -> void:
	randomize()
	font = _make_font()
	if ResourceLoader.exists("res://assets/chef_sheet.png"):
		chef_tex = load("res://assets/chef_sheet.png")
	if ResourceLoader.exists("res://assets/env/ramen_stall.png"):
		stall_tex = load("res://assets/env/ramen_stall.png")
	_build_stations()
	_load_cook()
	_load_sfx()
	_reset_bowl()
	set_process(true)


func _load_sfx() -> void:
	for k in ["pick", "plop", "pour", "boil", "serve", "no"]:
		var p := "res://assets/audio/%s.wav" % k
		if ResourceLoader.exists(p):
			var pl := AudioStreamPlayer.new()
			pl.stream = load(p)
			pl.bus = "Master"
			pl.volume_db = -5.0
			add_child(pl)
			sfx[k] = pl


func _sfx(k: String) -> void:
	if sfx.has(k):
		sfx[k].play()


func _load_cook() -> void:
	for key in ["bowl_big", "b_broth", "b_noodles", "b_beef", "b_scallion", "b_cilantro",
			"b_chili", "sbowl_beef", "sbowl_scallion", "sbowl_cilantro", "sbowl_chili",
			"pot_soup", "pot_noodle", "bowl_mini"]:
		var p := "res://assets/cook/%s.png" % key
		if ResourceLoader.exists(p):
			ctex[key] = load(p)


func _item_sprite(item: String) -> String:
	match item:
		"soup": return "pot_soup"
		"noodles": return "pot_noodle"
		"beef": return "sbowl_beef"
		"scallion": return "sbowl_scallion"
		"cilantro": return "sbowl_cilantro"
		"chili": return "sbowl_chili"
	return ""


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


func _build_stations() -> void:
	stations.clear()
	var defs := [
		["soup", "湯鍋"], ["noodles", "麵鍋"], ["beef", "牛肉片"],
		["scallion", "蔥花"], ["cilantro", "香菜"], ["chili", "辣椒"],
	]
	var centers := [52, 128, 204, 280, 356, 432]
	var ww := 64
	var hh := 46
	for i in defs.size():
		stations.append({
			"item": defs[i][0],
			"name": defs[i][1],
			"rect": Rect2(centers[i] - ww / 2.0, 178, ww, hh),
			"cx": centers[i],
		})


func _reset_bowl() -> void:
	bowl = {
		"soup": false, "noodles": false, "beef": false,
		"scallion": false, "cilantro": false, "chili": false,
	}
	held = ""
	held_q = ""
	bowl_nq = ""
	soup_fill = 0.0
	sprinkles.clear()
	last_sprinkle = Vector2(-999, -999)


# =====================================================================
#  GAME LOOP
# =====================================================================
func _process(delta: float) -> void:
	if flash > 0.0:
		flash = max(0.0, flash - delta)

	if noodle_state == "cooking":
		noodle_t = min(8.0, noodle_t + delta)
	if sprinkle_cd > 0.0:
		sprinkle_cd = max(0.0, sprinkle_cd - delta)

	# rising steam from hot things (juice)
	for p in steam:
		p.pos.y -= 16.0 * delta
		p.pos.x += sin(p.ph + p.ttl * 6.0) * 8.0 * delta
		p.ttl -= delta
	steam = steam.filter(func(s): return s.ttl > 0.0)
	if state == State.PLAY:
		steam_t -= delta
		if steam_t <= 0.0:
			steam_t = 0.16
			if _base_ok() or soup_fill > 0.0 or bowl.noodles:
				_puff(240, 120)                       # the assembled bowl
			_puff(52, 166)                            # 湯鍋
			if noodle_state == "cooking":
				_puff(128, 166)                       # 麵鍋 while boiling

	chef_anim += delta
	if chef_anim > 0.22:
		chef_anim -= 0.22
		chef_idx = (chef_idx + 1) % CHEF_SEQ.size()

	for ft in float_texts:
		ft.pos.y -= 18.0 * delta
		ft.ttl -= delta
	float_texts = float_texts.filter(func(t): return t.ttl > 0.0)

	mouse_pos = get_global_mouse_position()

	if state == State.PLAY:
		_update_play(delta)

	queue_redraw()


func _update_play(delta: float) -> void:
	# relaxed craft: customers keep coming, no day timer, no fail state
	spawn_timer -= delta
	if spawn_timer <= 0.0:
		_try_spawn()
		spawn_timer = 5.0

	for i in SEATS:
		var c = customers[i]
		if c == null:
			continue
		c.patience -= delta
		if c.patience <= 0.0:
			# they wander off on their own — no penalty, just make room
			_spawn_float(Vector2(seat_x[i], 70), "先走啦～", COL_YELLOW)
			customers[i] = null


func _try_spawn() -> void:
	var empty := []
	for i in SEATS:
		if customers[i] == null:
			empty.append(i)
	if empty.is_empty():
		return
	var seat: int = empty[randi() % empty.size()]
	customers[seat] = _make_order()
	if customers[selected_seat] == null:
		selected_seat = seat


func _make_order() -> Dictionary:
	var wants := {}
	for k in TOP_ORDER:
		wants[k] = (randi() % 2 == 0)
	var pat := 45.0          # generous — no rush, it's about doing it well
	return { "wants": wants, "patience": pat, "max_patience": pat, "face": randi() % 4 }


# =====================================================================
#  INPUT
# =====================================================================
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			dragging = true
			_handle_click(get_global_mouse_position())
		else:
			dragging = false
	elif event is InputEventMouseMotion and dragging:
		# drag a topping over the bowl to keep sprinkling
		var mp := get_global_mouse_position()
		if state == State.PLAY and held in TOP_ORDER and BOWL_RECT.has_point(mp):
			_sprinkle(mp)
	elif event is InputEventKey and event.pressed and not event.echo:
		_handle_key(event.keycode)


func _handle_key(key: int) -> void:
	if key == KEY_ESCAPE or key == KEY_M:
		get_tree().change_scene_to_file("res://scenes/Shop.tscn")
		return
	if state == State.TITLE and (key == KEY_SPACE or key == KEY_ENTER):
		_start_game()
	elif state == State.OVER and (key == KEY_R or key == KEY_SPACE or key == KEY_ENTER):
		_start_game()


func _handle_click(p: Vector2) -> void:
	if BACK_RECT.has_point(p):
		get_tree().change_scene_to_file("res://scenes/Shop.tscn")
		return
	if state == State.TITLE or state == State.OVER:
		_start_game()
		return

	# seat selection
	for i in SEATS:
		if Rect2(seat_x[i] - 40, 24, 80, 80).has_point(p) and customers[i] != null:
			selected_seat = i
			return

	# action buttons
	if SERVE_RECT.has_point(p):
		_serve()
		return
	if CLEAR_RECT.has_point(p):
		_reset_bowl()
		_spawn_float(Vector2(240, 150), "倒掉了", COL_YELLOW)
		return

	# over the assembly bowl: sprinkle a topping, or drop an ingredient
	if BOWL_RECT.has_point(p):
		if held in TOP_ORDER:
			_sprinkle(p)
		else:
			_place_into_bowl()
		return

	# pick up from a station (麵鍋 is special — you cook then lift)
	for s in stations:
		if s.rect.has_point(p):
			if s.item == "noodles":
				_noodle_pot_click(s.cx)
			else:
				held = s.item
				held_q = ""
				_sfx("pick")
			return


func _noodle_pot_click(cx: float) -> void:
	if held == "noodles":
		return
	if held != "":
		_spawn_float(Vector2(cx, 168), "手上拿著東西", COL_YELLOW)
		return
	if noodle_state == "empty":
		noodle_state = "cooking"
		noodle_t = 0.0
		_sfx("boil")
		_spawn_float(Vector2(cx, 168), "下麵煮！", COL_GREEN)
	else:
		# lift the noodles — quality depends on the timing
		held = "noodles"
		held_q = _noodle_quality()
		noodle_state = "empty"
		noodle_t = 0.0
		_sfx("pick")
		var msg := "剛剛好！" if held_q == "ok" else ("還太生" if held_q == "raw" else "煮過頭")
		_spawn_float(Vector2(cx, 156), "提起 " + msg, COL_GREEN if held_q == "ok" else COL_YELLOW)


func _noodle_quality() -> String:
	if noodle_t < COOK_READY:
		return "raw"
	if noodle_t <= COOK_OVER:
		return "ok"
	return "over"


func _sprinkle(p: Vector2) -> void:
	if not (held in TOP_ORDER):
		return
	if p.distance_to(last_sprinkle) < 5.0:      # spread out on drags
		return
	var cnt := 0
	for s in sprinkles:
		if s.type == held:
			cnt += 1
	if cnt >= SPRINKLE_MAX:
		return
	last_sprinkle = p
	# clamp onto the broth-surface ellipse
	var d: Vector2 = p - SPRINKLE_C
	var e := Vector2(d.x / SPRINKLE_RX, d.y / SPRINKLE_RY)
	if e.length() > 1.0:
		d = e.normalized() * Vector2(SPRINKLE_RX, SPRINKLE_RY)
	var pos: Vector2 = SPRINKLE_C + d + Vector2(randf_range(-2, 2), randf_range(-1.5, 1.5))
	sprinkles.append({"type": held, "pos": pos})
	bowl[held] = true
	if sprinkle_cd <= 0.0:
		_sfx("pick")
		sprinkle_cd = 0.09


func _place_into_bowl() -> void:
	if held == "":
		_spawn_float(Vector2(240, 150), "先點材料提起", COL_YELLOW)
		return
	if held == "soup":
		if soup_fill >= 1.05:
			_spawn_float(Vector2(240, 128), "湯要溢出來了", COL_YELLOW)
		else:
			soup_fill = min(1.1, soup_fill + SOUP_LADLE)
			_sfx("pour")
			_spawn_float(Vector2(240, 128), "湯滿了！" if soup_fill >= 0.9 else "+1 勺", COL_GREEN)
		held = ""
		held_q = ""
		return
	if bowl[held]:
		_spawn_float(Vector2(240, 130), "已經放過了", COL_YELLOW)
	else:
		bowl[held] = true
		if held == "noodles":
			bowl_nq = held_q
		_sfx("plop")
		var label := _item_name(held)
		_spawn_float(Vector2(240, 126), "放入 " + label, COL_GREEN)
	held = ""
	held_q = ""


func _serve() -> void:
	var c = customers[selected_seat]
	if c == null:
		_spawn_float(Vector2(240, 150), "沒有客人", COL_YELLOW)
		_sfx("no")
		return
	if not _base_ok():
		_spawn_float(Vector2(240, 150), "還沒做好！", COL_YELLOW)
		_sfx("no")
		return

	if not _matches(c):
		# wrong toppings — let the player try again, no penalty
		_spawn_float(Vector2(seat_x[selected_seat], 60), "配料不對…", COL_YELLOW)
		_sfx("no")
		flash = 0.18
		flash_col = COL_YELLOW
		return

	# served! the bowl's quality is judged on the noodles' doneness
	served += 1
	var sx: int = seat_x[selected_seat]
	if bowl_nq == "ok":
		_spawn_float(Vector2(sx, 56), "完美的一碗！★", COL_GREEN)
	elif bowl_nq == "raw":
		_spawn_float(Vector2(sx, 56), "好吃，但麵有點生", COL_YELLOW)
	else:
		_spawn_float(Vector2(sx, 56), "好吃,下次麵別煮太久", COL_YELLOW)
	_sfx("serve")
	flash = 0.2
	flash_col = COL_GREEN
	customers[selected_seat] = null
	_reset_bowl()


func _base_ok() -> bool:
	return soup_fill >= 0.9 and bowl.noodles and bowl.beef


func _matches(c: Dictionary) -> bool:
	if not _base_ok():
		return false
	for k in TOP_ORDER:
		if bool(bowl[k]) != bool(c.wants[k]):
			return false
	return true


func _item_name(item: String) -> String:
	match item:
		"soup": return "湯"
		"noodles": return "麵"
		"beef": return "牛肉"
		_: return TOPPING[item].name


# =====================================================================
#  STATE TRANSITIONS
# =====================================================================
func _start_game() -> void:
	state = State.PLAY
	served = 0
	spawn_timer = 0.8
	selected_seat = 0
	customers = [null, null, null]
	noodle_state = "empty"
	noodle_t = 0.0
	_reset_bowl()
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
			_draw_play()
			_draw_over()

	_draw_back_button()

	if flash > 0.0:
		draw_rect(Rect2(0, 0, W, H), Color(flash_col.r, flash_col.g, flash_col.b, flash * 0.5))

	for ft in float_texts:
		_text(ft.text, ft.pos + Vector2(1, 1), 10, COL_INK, HORIZONTAL_ALIGNMENT_CENTER)
		_text(ft.text, ft.pos, 10, ft.col, HORIZONTAL_ALIGNMENT_CENTER)


func _draw_title() -> void:
	if stall_tex != null:
		var sw := 472.0
		var sh := sw * stall_tex.get_height() / float(stall_tex.get_width())
		draw_texture_rect(stall_tex, Rect2((W - sw) / 2.0, 4, sw, sh), false)
	_draw_chef(Vector2(64, 262), 118)
	draw_rect(Rect2(0, 224, W, 46), Color(0.07, 0.06, 0.09, 0.8))
	_title_text("拉 麵 屋", Vector2(244, 242), 20, COL_YELLOW)
	_title_text("2D 像素拉麵店  試玩版", Vector2(242, 256), 10, COL_WHITE)
	_title_text("[ 點擊或空白鍵 開始 ]   [ ESC 返回店內 ]", Vector2(242, 267), 9,
		COL_GREEN if _blink() else COL_WHITE)


func _draw_play() -> void:
	# kitchen wall + wooden counter
	draw_rect(Rect2(0, 22, W, 90), COL_WALL)
	draw_rect(Rect2(0, 22, W, 3), COL_WALL_HI)
	draw_rect(Rect2(0, 112, W, H - 112), COL_COUNTER)
	draw_rect(Rect2(0, 112, W, 3), Color(1, 1, 1, 0.18))
	draw_rect(Rect2(0, 168, W, 2), COL_COUNTER_D)

	# customers behind the counter
	for i in SEATS:
		_draw_seat(i)

	# stations on the counter
	for s in stations:
		_draw_station(s)

	# assembly bowl
	_draw_assembly(Vector2(240, 140))
	_text("組裝中", Vector2(240, 106), 9, COL_WHITE, HORIZONTAL_ALIGNMENT_CENTER)

	# rising steam
	for p in steam:
		var a: float = clamp(p.ttl, 0.0, 1.0) * 0.42
		draw_rect(Rect2(p.pos.x - 2, p.pos.y - 2, 4, 4), Color(1, 1, 1, a))

	# action buttons
	_draw_button(CLEAR_RECT, "倒掉", COL_RED)
	_draw_button(SERVE_RECT, "上菜", COL_GREEN)

	_draw_hud()

	# held ingredient follows the cursor
	if held != "":
		_draw_held(mouse_pos)


func _puff(x: float, y: float) -> void:
	steam.append({"pos": Vector2(x + randf_range(-5, 5), y), "vx": 0.0,
		"ttl": 0.9 + randf() * 0.4, "ph": randf() * TAU})


func _draw_hud() -> void:
	draw_rect(Rect2(0, 0, W, 22), COL_INK)
	_text("拉麵屋 · 親手做一碗", Vector2(8, 16), 11, COL_YELLOW)
	_text("今日已做 " + str(served) + " 碗", Vector2(W - 130, 16), 11, COL_WHITE)


func _draw_seat(i: int) -> void:
	var cx: int = seat_x[i]
	var c = customers[i]
	if c == null:
		return
	if i == selected_seat:
		draw_rect(Rect2(cx - 40, 24, 80, 80), Color(1, 1, 1, 0.10))
		draw_rect(Rect2(cx - 26, 100, 52, 3), COL_YELLOW)

	_draw_customer(Vector2(cx, 86), c.face)

	# patience bar
	var pw := 70
	var px: int = cx - pw / 2
	draw_rect(Rect2(px, 102, pw, 5), COL_INK)
	var pf: float = clamp(c.patience / c.max_patience, 0.0, 1.0)
	var pcol := COL_GREEN
	if pf < 0.5: pcol = COL_YELLOW
	if pf < 0.25: pcol = COL_RED
	draw_rect(Rect2(px, 102, int(pw * pf), 5), pcol)

	_draw_order_bubble(Vector2(cx, 30), c)


func _draw_order_bubble(anchor: Vector2, c: Dictionary) -> void:
	var wants := []
	for k in TOP_ORDER:
		if c.wants[k]:
			wants.append(k)
	var bw := 92
	var bx := int(anchor.x) - bw / 2
	var by := int(anchor.y)
	draw_rect(Rect2(bx, by, bw, 30), COL_WHITE)
	draw_rect(Rect2(bx, by, bw, 30), COL_INK, false, 1.0)
	draw_rect(Rect2(int(anchor.x) - 3, by + 30, 6, 5), COL_WHITE)
	# beef-ramen base icon
	if ctex.has("bowl_mini"):
		var mb: Texture2D = ctex["bowl_mini"]
		draw_texture_rect(mb, Rect2(bx + 13 - mb.get_width() / 2.0, by + 15 - mb.get_height() / 2.0,
			mb.get_width(), mb.get_height()), false)
	else:
		_mini_bowl(Vector2(bx + 13, by + 15))
	_text("牛肉麵", Vector2(bx + 24, by + 11), 8, COL_INK)
	# wanted toppings (or 原味)
	if wants.is_empty():
		_text("原味", Vector2(bx + 40, by + 24), 9, COL_INK)
	else:
		var ix := bx + 24
		for k in wants:
			draw_rect(Rect2(ix, by + 17, 9, 9), TOPPING[k].col)
			draw_rect(Rect2(ix, by + 17, 9, 9), COL_INK, false, 1.0)
			ix += 12


func _mini_bowl(center: Vector2) -> void:
	var cx := center.x
	var cy := center.y
	draw_rect(Rect2(cx - 8, cy - 3, 16, 7), COL_BOWL)
	draw_rect(Rect2(cx - 8, cy - 4, 16, 2), COL_BOWL_RIM)
	draw_rect(Rect2(cx - 6, cy - 2, 12, 3), C_SOUP)


func _draw_customer(center: Vector2, face: int) -> void:
	var skin: Color = [Color("e8b98c"), Color("c98a5a"), Color("f0cba0"), Color("d9a06a")][face % 4]
	var cloth: Color = [Color("4e6fae"), Color("ae4e6f"), Color("4eae8a"), Color("9a6fae")][face % 4]
	var cx := center.x
	var cy := center.y
	draw_rect(Rect2(cx - 14, cy + 6, 28, 22), cloth)
	draw_rect(Rect2(cx - 10, cy - 14, 20, 20), skin)
	draw_rect(Rect2(cx - 11, cy - 16, 22, 6), COL_INK)
	draw_rect(Rect2(cx - 6, cy - 5, 3, 3), COL_INK)
	draw_rect(Rect2(cx + 3, cy - 5, 3, 3), COL_INK)
	draw_rect(Rect2(cx - 3, cy + 1, 6, 2), Color("7a3b3b"))


# --- stations --------------------------------------------------------
func _draw_station(s: Dictionary) -> void:
	var r: Rect2 = s.rect
	var cx: float = s.cx
	var picked: bool = held == s.item
	# tray slot
	draw_rect(r, COL_PANEL)
	draw_rect(r, COL_INK, false, 1.0)
	if picked:
		draw_rect(r, COL_YELLOW, false, 2.0)
	var top := r.position.y + 6
	var spr := _item_sprite(s.item)
	if ctex.has(spr):
		var t: Texture2D = ctex[spr]
		draw_texture_rect(t, Rect2(cx - t.get_width() / 2.0, top, t.get_width(), t.get_height()), false)
	else:
		match s.item:
			"soup":
				_draw_pot(Vector2(cx, top + 14), C_SOUP, true)
			"noodles":
				_draw_pot(Vector2(cx, top + 14), Color("d8d2c0"), true)
				draw_rect(Rect2(cx - 6, top + 6, 12, 9), Color("caa45a"))
				draw_rect(Rect2(cx - 6, top + 6, 12, 9), COL_INK, false, 1.0)
			"beef":
				_draw_ing_bowl(Vector2(cx, top + 14), C_BEEF, C_BEEF_HI)
			_:
				_draw_ing_bowl(Vector2(cx, top + 14), TOPPING[s.item].col, TOPPING[s.item].col.lightened(0.25))
	# 麵鍋 boil gauge — green window = the moment to lift
	if s.item == "noodles" and noodle_state == "cooking":
		var gx := r.position.x + 6
		var gw := r.size.x - 12
		var gy := r.position.y + 2
		draw_rect(Rect2(gx, gy, gw, 5), COL_INK)
		# ready window band
		var rx0 := gx + gw * (COOK_READY / 8.0)
		var rx1 := gx + gw * (COOK_OVER / 8.0)
		draw_rect(Rect2(rx0, gy, rx1 - rx0, 5), Color(0.37, 0.68, 0.37, 0.5))
		var frac: float = clamp(noodle_t / 8.0, 0.0, 1.0)
		var gc := COL_YELLOW
		if noodle_t >= COOK_READY and noodle_t <= COOK_OVER:
			gc = COL_GREEN
		elif noodle_t > COOK_OVER:
			gc = COL_RED
		draw_rect(Rect2(gx, gy, gw * frac, 5), gc)
		if noodle_t >= COOK_READY and int(flash * 0 + Engine.get_frames_drawn() / 12) % 2 == 0:
			_text("提起!", Vector2(cx, r.position.y + 30), 9,
				COL_GREEN if noodle_t <= COOK_OVER else COL_RED, HORIZONTAL_ALIGNMENT_CENTER)
	_text(s.name, Vector2(cx, r.position.y + r.size.y - 3), 9, COL_WHITE, HORIZONTAL_ALIGNMENT_CENTER)


func _draw_pot(center: Vector2, liquid: Color, steam: bool) -> void:
	var cx := center.x
	var cy := center.y
	draw_rect(Rect2(cx - 13, cy - 7, 26, 16), COL_POT)
	draw_rect(Rect2(cx - 13, cy - 7, 26, 3), COL_POT_D)
	draw_rect(Rect2(cx - 11, cy - 6, 22, 6), liquid)            # liquid surface
	# handles
	draw_rect(Rect2(cx - 16, cy - 4, 3, 4), COL_POT_D)
	draw_rect(Rect2(cx + 13, cy - 4, 3, 4), COL_POT_D)
	if steam and _blink():
		draw_rect(Rect2(cx - 5, cy - 12, 2, 4), Color(1, 1, 1, 0.5))
		draw_rect(Rect2(cx + 3, cy - 13, 2, 4), Color(1, 1, 1, 0.4))


func _draw_ing_bowl(center: Vector2, col: Color, hi: Color) -> void:
	var cx := center.x
	var cy := center.y
	draw_rect(Rect2(cx - 12, cy - 6, 24, 14), COL_BOWL)
	draw_rect(Rect2(cx - 12, cy - 7, 24, 3), COL_BOWL_RIM)
	draw_rect(Rect2(cx - 9, cy - 4, 18, 9), col)
	# little chunks for texture
	draw_rect(Rect2(cx - 6, cy - 2, 4, 3), hi)
	draw_rect(Rect2(cx + 2, cy, 4, 3), hi)


# --- assembly bowl ---------------------------------------------------
func _draw_assembly(center: Vector2) -> void:
	# highlight when holding something to drop
	if held != "":
		draw_rect(BOWL_RECT, Color(1, 1, 0.4, 0.12))
		draw_rect(BOWL_RECT, COL_YELLOW, false, 1.0)

	if ctex.has("bowl_big"):
		var big: Texture2D = ctex["bowl_big"]
		var o := Vector2(center.x - big.get_width() / 2.0, center.y - big.get_height() / 2.0)
		var dst := Rect2(o, Vector2(big.get_width(), big.get_height()))
		draw_texture_rect(big, dst, false)
		if soup_fill > 0.0 and ctex.has("b_broth"):
			# broth rises as you ladle (reveal the bottom of the broth band)
			var bt: Texture2D = ctex["b_broth"]
			var band_top := 12.0
			var band_bot := 27.0
			var shown: float = (band_bot - band_top) * clamp(soup_fill, 0.0, 1.0)
			var sy: float = band_bot - shown
			draw_texture_rect_region(bt, Rect2(o.x, o.y + sy, bt.get_width(), shown),
				Rect2(0, sy, bt.get_width(), shown))
		if bowl.noodles and ctex.has("b_noodles"):
			draw_texture_rect(ctex["b_noodles"], dst, false)
		if bowl.beef and ctex.has("b_beef"):
			draw_texture_rect(ctex["b_beef"], dst, false)
		# toppings appear exactly where you sprinkled them
		for sp in sprinkles:
			var scol: Color = TOPPING[sp.type].col
			draw_rect(Rect2(sp.pos.x - 1, sp.pos.y - 1, 3, 3), scol)
			draw_rect(Rect2(sp.pos.x - 1, sp.pos.y - 1, 3, 1), scol.lightened(0.25))
		return

	var cx := center.x
	var cy := center.y
	var w := 80.0
	var h := 38.0
	# bowl
	draw_rect(Rect2(cx - w / 2 - 3, cy - h / 2 - 3, w + 6, 8), COL_BOWL_RIM)
	draw_rect(Rect2(cx - w / 2, cy - h / 2, w, h), COL_BOWL)
	draw_rect(Rect2(cx - w / 2 + 6, cy + h / 2, w - 12, 6), COL_BOWL_RIM)
	# contents
	if soup_fill > 0.0:
		draw_rect(Rect2(cx - w / 2 + 5, cy - h / 2 + 4, w - 10, int((h - 10) * clamp(soup_fill, 0, 1))), C_SOUP)
	if bowl.noodles:
		for n in 6:
			draw_rect(Rect2(cx - w / 2 + 10 + n * (w - 20) / 6.0, cy - h / 2 + 6, 3, h - 16), C_NOODLE)
	if bowl.beef:
		draw_rect(Rect2(cx - 26, cy - 6, 14, 9), C_BEEF)
		draw_rect(Rect2(cx - 24, cy - 4, 6, 3), C_BEEF_HI)
		draw_rect(Rect2(cx - 8, cy - 7, 14, 9), C_BEEF)
		draw_rect(Rect2(cx - 6, cy - 5, 6, 3), C_BEEF_HI)
	# toppings sprinkled on top
	var tcx := cx + 6
	for k in TOP_ORDER:
		if bowl[k]:
			for d in 5:
				var ox := tcx + (d % 3) * 6 - 6
				var oy := cy - 6 + int(d / 3) * 6
				draw_rect(Rect2(ox, oy, 3, 3), TOPPING[k].col)
			tcx += 22


# --- held ingredient on the cursor -----------------------------------
func _draw_held(p: Vector2) -> void:
	var label := _item_name(held)
	var spr := _item_sprite(held)
	if ctex.has(spr):
		var t: Texture2D = ctex[spr]
		draw_texture_rect(t, Rect2(p.x - t.get_width() / 2.0, p.y - t.get_height() / 2.0,
			t.get_width(), t.get_height()), false)
	else:
		var col := C_SOUP
		match held:
			"soup": col = C_SOUP
			"noodles": col = C_NOODLE
			"beef": col = C_BEEF
			_: col = TOPPING[held].col
		draw_rect(Rect2(p.x - 9, p.y - 9, 18, 12), COL_BOWL)
		draw_rect(Rect2(p.x - 9, p.y - 10, 18, 3), COL_BOWL_RIM)
		draw_rect(Rect2(p.x - 6, p.y - 7, 12, 7), col)
	# label tag
	var tw: float = font.get_string_size("提起 " + label, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
	draw_rect(Rect2(p.x - tw / 2 - 3, p.y + 5, tw + 6, 11), Color(0, 0, 0, 0.72))
	_text("提起 " + label, Vector2(p.x, p.y + 14), 8, COL_YELLOW, HORIZONTAL_ALIGNMENT_CENTER)


# --- buttons ---------------------------------------------------------
func _draw_button(r: Rect2, label: String, base: Color) -> void:
	draw_rect(r, base)
	draw_rect(Rect2(r.position, Vector2(r.size.x, 2)), Color(1, 1, 1, 0.2))
	draw_rect(r, COL_INK, false, 1.0)
	_text(label, Vector2(r.position.x + r.size.x / 2, r.position.y + r.size.y / 2 + 4),
		11, COL_WHITE, HORIZONTAL_ALIGNMENT_CENTER)


func _draw_back_button() -> void:
	draw_rect(BACK_RECT, Color(0, 0, 0, 0.6))
	draw_rect(BACK_RECT, COL_YELLOW, false, 1.0)
	_text("← 店內", Vector2(BACK_RECT.position.x + BACK_RECT.size.x / 2, BACK_RECT.position.y + 12),
		9, COL_WHITE, HORIZONTAL_ALIGNMENT_CENTER)


func _draw_over() -> void:
	draw_rect(Rect2(0, 0, W, H), Color(0, 0, 0, 0.7))
	var won := reputation > 0
	var title := "打烊—今日結束！" if won else "遊戲結束"
	_text(title, Vector2(240, 90), 22, (COL_GREEN if won else COL_RED), HORIZONTAL_ALIGNMENT_CENTER)
	_text("今日收入  ￥" + str(money), Vector2(240, 130), 15, COL_YELLOW, HORIZONTAL_ALIGNMENT_CENTER)
	_text("賣出拉麵  " + str(served), Vector2(240, 156), 12, COL_WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	_text("[ 點擊或按 R 再玩一次 ]", Vector2(240, 205), 12, COL_WHITE, HORIZONTAL_ALIGNMENT_CENTER)


func _draw_chef(center_bottom: Vector2, h: float) -> void:
	if chef_tex == null:
		return
	var col: int = CHEF_SEQ[chef_idx]
	var src := Rect2(col * CHEF_FW, 0, CHEF_FW, CHEF_FH)
	var w := CHEF_FW / float(CHEF_FH) * h
	draw_texture_rect_region(chef_tex, Rect2(center_bottom.x - w / 2.0, center_bottom.y - h, w, h), src)


func _title_text(s: String, pos: Vector2, size: int, col: Color) -> void:
	_text(s, pos + Vector2(1, 1), size, COL_INK, HORIZONTAL_ALIGNMENT_CENTER)
	_text(s, pos, size, col, HORIZONTAL_ALIGNMENT_CENTER)


func _blink() -> bool:
	return int(Engine.get_frames_drawn() / 30) % 2 == 0


func _text(s: String, pos: Vector2, size: int, col: Color, align := HORIZONTAL_ALIGNMENT_LEFT) -> void:
	draw_string(font, pos, s, align, -1, size, col)
