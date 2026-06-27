extends Node2D
# =====================================================================
#  RAMEN-YA  —  COUNTER / 档口  (cooking minigame, redesigned)
#
#  Assemble a bowl of beef ramen with a "pick up → put down" flow:
#  click a station to lift an ingredient, then click the assembly bowl
#  to drop it in.  Base = 湯 + 麵 + 牛肉 (always).  The customer only
#  cares whether to add 蔥花 / 香菜 / 辣椒.  Match their order and serve.
# =====================================================================

# ---- screen (portrait) ----------------------------------------------
const W := 270
const H := 480

# on-screen "back to menu" button (also bound to ESC / M)
const BACK_RECT := Rect2(4, 4, 48, 15)

# action buttons + victory buttons are anchored to the live screen — see
# _clear_rect()/_serve_rect()/_menu_rect()/_next_rect()

# the assembly bowl (slightly-tilted overhead) — click target to add / sprinkle.
const BOWL_C := Vector2(135, 152)
const BOWL_OPEN := Vector2(135, 138)    # = BOWL_C + (0, -14)
const BOWL_RX := 50.0                  # opening (sprinkle) radii
const BOWL_RY := 38.0
const BOWL_HIT_RX := 56.0              # generous click radii (incl. rim)
const BOWL_HIT_RY := 44.0

# big pans: the sprite's liquid surface sits VAT_OPEN_Y down from its top
const VAT_OPEN_Y := 30.0

# ---- game states ----------------------------------------------------
enum State { TITLE, PLAY, OVER }
var state: int = State.TITLE

# ---- palette --------------------------------------------------------
const COL_BG       := Color("231f28")
const COL_WALL     := Color("3a2c2e")
const COL_WALL_HI  := Color("4d3a3a")
const COL_COUNTER  := Color("c89b6a")
const COL_COUNTER_D:= Color("a07c4c")
const COL_WOOD     := Color("a9794a")
const COL_WOOD_D   := Color("946a3f")
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
const C_SOUP    := Color("e9b63a")   # yellow oily broth
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

# one order at a time + last result
var order: Dictionary = {}
var stars: int = 0
var spawn_interval: float = 4.0

# the bowl being assembled + what we're currently holding
var bowl := {}
var held: String = ""              # "" or soup/noodles/beef/scallion/cilantro/chili
var held_q := ""                   # quality of held noodles: raw / ok / over
var bowl_nq := ""                  # noodle quality placed in the bowl
var mouse_pos := Vector2(W / 2.0, H / 2.0)
var _ox := 0.0        # horizontal offset that centres the 270-wide column
var _oy := 0.0        # vertical content offset (= top safe-area inset)
var _vw := float(W)
var _vh := float(H)   # live viewport size
var _safe_t := 0.0    # iOS safe-area insets in logical px (notch / home indicator)
var _safe_b := 0.0


func _compute_layout() -> void:
	var vp: Vector2 = get_viewport_rect().size
	_vw = vp.x
	_vh = vp.y
	_ox = floor(max(0.0, (vp.x - W) / 2.0))
	_safe_t = 0.0
	_safe_b = 0.0
	var ws := DisplayServer.window_get_size()
	if ws.y > 0:
		var sa := DisplayServer.get_display_safe_area()
		var sc := _vh / float(ws.y)
		_safe_t = max(0.0, float(sa.position.y)) * sc
		_safe_b = max(0.0, float(ws.y - sa.position.y - sa.size.y)) * sc
	# on iOS, guarantee an inset even if the safe-area API reports nothing,
	# so the top labels clear the notch / Dynamic Island and the buttons the
	# home indicator
	if OS.get_name() == "iOS":
		_safe_t = max(_safe_t, 38.0)
		_safe_b = max(_safe_b, 30.0)
	_safe_t = min(_safe_t, _vh * 0.2)
	_safe_b = min(_safe_b, _vh * 0.2)
	_oy = _safe_t
	# the two steam patches sit low on the page, just above the action button
	if stations.size() >= 2:
		var sy: float = _avail() - 104.0
		stations[0]["center"] = Vector2(75, sy)
		stations[0]["rect"] = Rect2(17, sy - 30, 116, 72)
		stations[1]["center"] = Vector2(195, sy)
		stations[1]["rect"] = Rect2(137, sy - 30, 116, 72)


# usable content height between the safe-area insets
func _avail() -> float: return _vh - _safe_t - _safe_b

# one action button at the bottom, shown only when it's relevant:
#   上菜 once the bowl matches the order, 倒掉 once it's unrecoverably ruined
func _action_rect() -> Rect2: return Rect2(69, _avail() - 48.0, 132, 30)
func _can_serve() -> bool: return not order.is_empty() and _matches(order)
func _is_ruined() -> bool:
	if order.is_empty():
		return false
	for t in TOP_ORDER:
		if bool(bowl[t]) and not bool(order.wants[t]):   # a topping was sprinkled that the order didn't want
			return true
	return false
func _vic_top() -> float: return floor((_avail() - 250.0) / 2.0)
func _menu_rect() -> Rect2: return Rect2(36, _vic_top() + 188.0, 92, 30)
func _next_rect() -> Rect2: return Rect2(142, _vic_top() + 188.0, 92, 30)

# 麵鍋 cooking: you must boil a portion and lift it at the right moment
var noodle_state := "empty"        # empty / cooking
var noodle_t := 0.0
const COOK_READY := 3.0            # perfect window opens
const COOK_OVER := 4.8             # ... and closes (after this it's overcooked)

# 湯: one ladle fills the bowl
var soup_fill := 0.0
const SOUP_LADLE := 1.0            # a single scoop is enough

# 撒料: shake a topping over the bowl — where & how much is up to you
var sprinkles: Array = []          # {type, pos}
var last_sprinkle := Vector2(-999, -999)
var sprinkle_cd := 0.0
const SPRINKLE_MAX := 18            # per topping

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
	served = 0
	_start_game()              # straight into making the one order
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
			"pot_soup", "pot_noodle", "bowl_mini",
			"td_bowl", "td_broth", "td_noodles", "td_beef", "td_pot_soup", "td_pot_noodle",
			"td_vat_soup", "td_vat_noodle", "td_bowl_soup", "td_bowl_noodle",
			"td_box_beef", "td_box_scallion", "td_box_cilantro", "td_box_chili"]:
		var p := "res://assets/cook/%s.png" % key
		if ResourceLoader.exists(p):
			ctex[key] = load(p)


func _item_sprite(item: String) -> String:
	match item:
		"soup": return "td_pot_soup"
		"noodles": return "td_pot_noodle"
		"beef": return "td_box_beef"
		"scallion": return "td_box_scallion"
		"cilantro": return "td_box_cilantro"
		"chili": return "td_box_chili"
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
	# portrait: two big vats (大缸) side by side under the bowl; toppings in a row below.
	stations.clear()
	# the pots are off-screen below — only two steam patches show; click to take
	stations.append({"item": "soup", "name": "湯", "center": Vector2(75, 352), "r": 32,
		"rect": Rect2(22, 300, 106, 100), "cx": 75})
	stations.append({"item": "noodles", "name": "麵", "center": Vector2(195, 352), "r": 32,
		"rect": Rect2(142, 300, 106, 100), "cx": 195})
	var defs := [
		["beef", "牛肉", Vector2(45, 250), 22],
		["scallion", "蔥花", Vector2(105, 250), 22],
		["cilantro", "香菜", Vector2(165, 250), 22],
		["chili", "辣椒", Vector2(225, 250), 22],
	]
	for d in defs:
		var c: Vector2 = d[2]
		var r: int = d[3]
		stations.append({
			"item": d[0], "name": d[1], "center": c, "r": r,
			"rect": Rect2(c.x - r, c.y - r, r * 2, r * 2),
			"cx": c.x,
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
			var ss0: Vector2 = stations[0].center     # 湯 steam (left)
			var ss1: Vector2 = stations[1].center     # 麵 steam (right)
			_puff(ss0.x - 11, ss0.y - 2)
			_puff(ss0.x + 11, ss0.y - 2)
			_puff(ss1.x - 11, ss1.y - 2)
			_puff(ss1.x + 11, ss1.y - 2)
			if soup_fill > 0.0 or bowl.noodles or _base_ok():
				_puff(BOWL_OPEN.x, BOWL_OPEN.y - 8)   # the bowl, once it holds hot broth/noodles

	chef_anim += delta
	if chef_anim > 0.22:
		chef_anim -= 0.22
		chef_idx = (chef_idx + 1) % CHEF_SEQ.size()

	for ft in float_texts:
		ft.pos.y -= 18.0 * delta
		ft.ttl -= delta
	float_texts = float_texts.filter(func(t): return t.ttl > 0.0)

	_compute_layout()
	mouse_pos = get_global_mouse_position() - Vector2(_ox, _oy)

	if state == State.PLAY:
		_update_play(delta)

	queue_redraw()


func _update_play(_delta: float) -> void:
	pass  # single-order craft: nothing to tick; making the bowl is all in _process


func _update_play_legacy(delta: float) -> void:
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
	return { "wants": wants }


# =====================================================================
#  INPUT
# =====================================================================
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		# tap only — every action is a discrete click (no drag-and-drop)
		if event.pressed:
			_handle_click(get_global_mouse_position() - Vector2(_ox, _oy))
	elif event is InputEventKey and event.pressed and not event.echo:
		_handle_key(event.keycode)


func _handle_key(key: int) -> void:
	if key == KEY_ESCAPE or key == KEY_M:
		get_tree().change_scene_to_file("res://scenes/Menu.tscn")
		return
	if state == State.OVER and (key == KEY_R or key == KEY_SPACE or key == KEY_ENTER):
		_start_game()


func _handle_click(p: Vector2) -> void:
	# the victory overlay is modal — the back button is covered and inert there
	if state != State.OVER and BACK_RECT.has_point(p):
		Music.click()
		get_tree().change_scene_to_file("res://scenes/Menu.tscn")
		return
	if state == State.OVER:
		# only the two buttons act — no dismiss/restart on outside taps
		if _menu_rect().has_point(p):
			Music.click()
			get_tree().change_scene_to_file("res://scenes/Menu.tscn")
		elif _next_rect().has_point(p):
			Music.click()
			_start_game()      # 再來一單
		return

	# action buttons
	if _action_rect().has_point(p):
		if _can_serve():
			Music.click()
			_serve()
			return
		if _is_ruined():
			Music.click()
			_reset_bowl()
			_spawn_float(BOWL_C, "倒掉了", COL_YELLOW)
			return

	# over the bowl: sprinkle a topping, or drop an ingredient
	if _in_bowl(p):
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
			elif held == s.item:
				_put_down()                     # click the same station to put it back
			else:
				held = s.item
				held_q = ""
				_sfx("pick")
			return

	# clicked empty counter — put down whatever you're holding
	if held != "":
		_put_down()


func _put_down() -> void:
	if held == "":
		return
	_sfx("plop")
	_spawn_float(mouse_pos, "放下了", COL_YELLOW)
	held = ""
	held_q = ""


func _noodle_pot_click(cx: float) -> void:
	if held == "noodles":
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
	# clamp onto the elliptical broth surface
	var d: Vector2 = p - BOWL_OPEN
	var e := Vector2(d.x / BOWL_RX, d.y / BOWL_RY)
	if e.length() > 1.0:
		d = e.normalized() * Vector2(BOWL_RX, BOWL_RY)
	var pos: Vector2 = BOWL_OPEN + d + Vector2(randf_range(-2, 2), randf_range(-2, 2))
	sprinkles.append({"type": held, "pos": pos})
	bowl[held] = true
	if sprinkle_cd <= 0.0:
		_sfx("pick")
		sprinkle_cd = 0.09


func _place_into_bowl() -> void:
	if held == "":
		_spawn_float(Vector2(135,150), "先點材料提起", COL_YELLOW)
		return
	if held == "soup":
		if soup_fill >= 0.9:
			_spawn_float(Vector2(135,128), "湯夠了", COL_YELLOW)
		else:
			soup_fill = 1.0                       # one ladle fills the bowl
			_sfx("pour")
			_spawn_float(Vector2(135,128), "下湯！", COL_GREEN)
		held = ""
		held_q = ""
		return
	if bowl[held]:
		_spawn_float(Vector2(135,130), "已經放過了", COL_YELLOW)
	else:
		bowl[held] = true
		if held == "noodles":
			bowl_nq = held_q
			_sfx("boil")          # the boiling/cooking sound as the noodles go in
		else:
			_sfx("plop")
		var label := _item_name(held)
		_spawn_float(Vector2(135,126), "放入 " + label, COL_GREEN)
	held = ""
	held_q = ""


func _serve() -> void:
	if order.is_empty():
		return
	if not _base_ok():
		_spawn_float(Vector2(135,150), "還沒做好！", COL_YELLOW)
		_sfx("no")
		return
	if not _matches(order):
		_spawn_float(Vector2(135,60), "配料不對…", COL_YELLOW)
		_sfx("no")
		flash = 0.18
		flash_col = COL_YELLOW
		return

	# success → victory! stars from the noodles' doneness
	served += 1
	stars = 3 if bowl_nq == "ok" else 2
	_sfx("serve")
	flash = 0.25
	flash_col = COL_GREEN
	state = State.OVER          # victory / results screen (keeps the finished bowl on show)
	var g = get_node_or_null("/root/Game")
	if g:
		g.high_score += 1       # persisted "completed orders" total
		g.save()


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
	order = _make_order()
	stars = 0
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
	# fill the whole (possibly taller) screen so there are no black bars, then
	# centre the 480-tall canvas: top margin reads as the dark HUD strip, the
	# bottom margin as more counter.
	_compute_layout()
	# the prep table extends to fill the whole screen, whatever its size
	draw_rect(Rect2(0, 0, _vw, _vh), COL_WOOD)
	for ty in range(0, int(_vh), 12):
		draw_rect(Rect2(0, ty, _vw, 1), COL_WOOD_D)
	draw_set_transform(Vector2(_ox, _oy), 0.0, Vector2.ONE)

	draw_rect(Rect2(0, 0, W, H), COL_BG)
	match state:
		State.TITLE:
			_draw_title()
		State.PLAY:
			_draw_play()
		State.OVER:
			_draw_play()
			_draw_over()

	# back button hides under the victory overlay
	if state != State.OVER:
		_draw_back_button()

	if flash > 0.0:
		draw_rect(Rect2(0, 0, W, H), Color(flash_col.r, flash_col.g, flash_col.b, flash * 0.5))

	for ft in float_texts:
		_text(ft.text, ft.pos + Vector2(1, 1), 10, COL_INK, HORIZONTAL_ALIGNMENT_CENTER)
		_text(ft.text, ft.pos, 10, ft.col, HORIZONTAL_ALIGNMENT_CENTER)

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_title() -> void:
	if stall_tex != null:
		# fit the whole counter into the area above the title bar
		var sh := 218.0
		var sw := sh * stall_tex.get_width() / float(stall_tex.get_height())
		draw_texture_rect(stall_tex, Rect2((W - sw) / 2.0, 4, sw, sh), false)
	_draw_chef(Vector2(64, 262), 118)
	draw_rect(Rect2(0, 224, W, 46), Color(0.07, 0.06, 0.09, 0.8))
	_title_text("拉 麵 屋", Vector2(244, 242), 20, COL_YELLOW)
	_title_text("2D 卡通拉麵店  試玩版", Vector2(242, 256), 10, COL_WHITE)
	_title_text("[ 點擊或空白鍵 開始 ]   [ ESC 返回店內 ]", Vector2(242, 267), 9,
		COL_GREEN if _blink() else COL_WHITE)


func _draw_play() -> void:
	# top-down wooden prep counter
	draw_rect(Rect2(0, 0, W, H), COL_WOOD)
	for y in range(0, H, 12):
		draw_rect(Rect2(0, y, W, 1), COL_WOOD_D)

	# the single order ticket, pinned at the top
	_draw_order_ticket()

	# raised little wooden platforms the bowl & toppings sit on
	_draw_riser(Rect2(62, 170, 146, 56), 11.0)     # under the bowl (closer to square)
	_draw_riser(Rect2(14, 240, 242, 30), 10.0)     # toppings — right below the bowl's stand

	# the bowl (top-down) in the middle of the counter
	_draw_assembly(BOWL_C)

	# vats & ingredient boxes
	for s in stations:
		_draw_station(s)

	# rising steam
	for p in steam:
		var a: float = clamp(p.ttl, 0.0, 1.0) * 0.42
		draw_rect(Rect2(p.pos.x - 2, p.pos.y - 2, 4, 4), Color(1, 1, 1, a))

	# action buttons
	# the action button only appears when it matters
	if _can_serve():
		_draw_button(_action_rect(), "完成", COL_GREEN)
	elif _is_ruined():
		_draw_button(_action_rect(), "倒掉", COL_RED)

	_draw_hud()

	# held ingredient follows the cursor
	if held != "":
		_draw_held(mouse_pos)


func _draw_riser(r: Rect2, depth: float) -> void:
	var top := Color("c79355")
	var top_hi := Color("dcab69")
	var side := Color("7c5128")
	var seam := Color("a9743f")
	# front thickness (the "height")
	draw_rect(Rect2(r.position.x, r.position.y + r.size.y - 2, r.size.x, depth + 2), side)
	# top surface
	draw_rect(r, top)
	draw_rect(Rect2(r.position.x, r.position.y, r.size.x, 2), top_hi)
	# plank seams running front-to-back
	for i in range(1, 4):
		var sx := r.position.x + r.size.x * i / 4.0
		draw_rect(Rect2(sx, r.position.y + 1, 1, r.size.y - 1), seam)
	# ink outline of the whole block
	draw_rect(Rect2(r.position.x, r.position.y, r.size.x, r.size.y + depth), COL_INK, false, 1.5)


func _puff(x: float, y: float) -> void:
	steam.append({"pos": Vector2(x + randf_range(-5, 5), y), "vx": 0.0,
		"ttl": 0.9 + randf() * 0.4, "ph": randf() * TAU})


func _draw_hud() -> void:
	# no top bar — this-round count sits top-right on the back button's centre
	# line; hidden until at least one bowl is done this round
	if served >= 1:
		var s := "本輪 " + str(served) + " 單"
		var sz := 11
		var cy: float = BACK_RECT.position.y + BACK_RECT.size.y / 2.0
		var by: float = cy + (font.get_ascent(sz) - font.get_descent(sz)) / 2.0
		_text(s, Vector2(W - 7, by + 1), sz, COL_INK, HORIZONTAL_ALIGNMENT_RIGHT)
		_text(s, Vector2(W - 8, by), sz, COL_YELLOW, HORIZONTAL_ALIGNMENT_RIGHT)


func _draw_order_ticket() -> void:
	if order.is_empty():
		return
	var r := Rect2(16, 28, 238, 44)
	draw_rect(r, Color("efe7d6"))
	draw_rect(r, COL_INK, false, 1.5)
	_text("今日訂單", Vector2(r.position.x + 10, r.position.y + 15), 9, Color("7a6a52"))
	_text("牛肉麵", Vector2(r.position.x + 10, r.position.y + 33), 12, COL_INK)
	var wants := []
	for k in TOP_ORDER:
		if order.wants[k]:
			wants.append(k)
	if wants.is_empty():
		_text("原味", Vector2(r.position.x + 70, r.position.y + 33), 10, Color("7a6a52"))
	else:
		var ix := r.position.x + 66
		for k in wants:
			draw_rect(Rect2(ix, r.position.y + 23, 12, 12), TOPPING[k].col)
			draw_rect(Rect2(ix, r.position.y + 23, 12, 12), COL_INK, false, 1.0)
			ix += 15


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
		draw_texture_rect(mb, Rect2(bx + 13 - _tw(mb) / 2.0, by + 15 - _th(mb) / 2.0,
			_tw(mb), _th(mb)), false)
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
func _in_bowl(p: Vector2) -> bool:
	var nx := (p.x - BOWL_OPEN.x) / BOWL_HIT_RX
	var ny := (p.y - BOWL_OPEN.y) / BOWL_HIT_RY
	return nx * nx + ny * ny <= 1.0


func _fill_ellipse(c: Vector2, rx: float, ry: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in range(24):
		var a := TAU * i / 24.0
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	draw_colored_polygon(pts, col)


func _draw_pot_mouth(c: Vector2, item: String) -> void:
	# a broth/water surface sunk into the counter; the pot body is off-frame below
	var broth: Color = C_SOUP if item == "soup" else Color("e3e9ea")
	var broth_d: Color = Color("cf9a28") if item == "soup" else Color("c4cfd0")
	# a little of the near wall under the front rim (hint of depth)
	_fill_ellipse(Vector2(c.x, c.y + 7), 54, 18, Color("241a12"))
	# recessed rim
	_fill_ellipse(c, 55, 19, Color("31241a"))
	_draw_ellipse_ring(c, 55, 19, Color("6f4d31"))
	# broth surface (front half darker)
	_fill_ellipse(c, 47, 14.5, broth_d)
	_fill_ellipse(Vector2(c.x, c.y - 2.0), 47, 13.5, broth)
	# soft sheen + a couple of simmering bubbles
	_fill_ellipse(Vector2(c.x - 16, c.y - 4), 11, 3.2, broth.lightened(0.25))
	var t := Time.get_ticks_msec() / 1000.0
	for i in range(3):
		var bx := c.x + sin(t * 1.3 + i * 2.1) * (13.0 + i * 7.0)
		var by := c.y + cos(t * 1.1 + i * 1.7) * 5.0
		draw_circle(Vector2(bx, by), 1.8, broth.lightened(0.35))


func _draw_ellipse_ring(c: Vector2, rx: float, ry: float, col: Color) -> void:
	var pts := PackedVector2Array()
	var n := 28
	for i in range(n + 1):
		var a := TAU * i / float(n)
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	draw_polyline(pts, col, 1.5)


func _ticket_rect(i: int) -> Rect2:
	return Rect2(18 + i * 132, 24, 116, 40)


func _draw_ticket(i: int) -> void:
	var c = customers[i]
	if c == null:
		return
	var r := _ticket_rect(i)
	draw_rect(r, Color("efe7d6"))
	draw_rect(r, COL_INK, false, 1.0)
	if i == selected_seat:
		draw_rect(r, COL_YELLOW, false, 2.0)
	draw_rect(Rect2(r.position.x + r.size.x / 2 - 2, r.position.y - 3, 4, 5), COL_RED)   # pin
	_text("訂單 #" + str(i + 1), Vector2(r.position.x + 8, r.position.y + 14), 8, Color("7a6a52"))
	_text("牛肉麵", Vector2(r.position.x + 8, r.position.y + 30), 11, COL_INK)
	var wants := []
	for k in TOP_ORDER:
		if c.wants[k]:
			wants.append(k)
	if wants.is_empty():
		_text("原味", Vector2(r.position.x + 64, r.position.y + 30), 9, Color("7a6a52"))
	else:
		var ix := r.position.x + 62
		for k in wants:
			draw_rect(Rect2(ix, r.position.y + 22, 11, 11), TOPPING[k].col)
			draw_rect(Rect2(ix, r.position.y + 22, 11, 11), COL_INK, false, 1.0)
			ix += 14
	# patience
	var pw := r.size.x - 16
	var pf: float = clamp(c.patience / c.max_patience, 0.0, 1.0)
	var pc := COL_GREEN
	if pf < 0.4:
		pc = COL_YELLOW
	draw_rect(Rect2(r.position.x + 8, r.position.y + r.size.y - 7, pw, 3), Color(0, 0, 0, 0.18))
	draw_rect(Rect2(r.position.x + 8, r.position.y + r.size.y - 7, int(pw * pf), 3), pc)


func _draw_noodle_nest(ctr: Vector2) -> void:
	# a tangle of noodle strands (not a solid dough blob)
	var noodle := Color("f1e6bf")
	var noodle_d := Color("dbcb98")
	var rx := 26.0
	var ry := 9.0
	# faint clump shadow so the strands read as a nest in the water
	var sh := PackedVector2Array()
	for i in range(20):
		var a := TAU * i / 20.0
		sh.append(ctr + Vector2(cos(a) * rx, 1.5 + sin(a) * ry))
	draw_colored_polygon(sh, Color(0.42, 0.37, 0.27, 0.22))
	# wavy noodle strands, clipped to the oval at each row
	var n := 11
	for i in range(n):
		var yy := -ry + 2.0 + float(i) / float(n - 1) * (2.0 * ry - 4.0)
		var halfw: float = rx * sqrt(max(0.0, 1.0 - pow(yy / ry, 2.0))) - 1.0
		if halfw < 2.0:
			continue
		var col := noodle if i % 2 == 0 else noodle_d
		var phase := float(i) * 1.7
		var amp := 1.3 + float(i % 3) * 0.7
		var sp := PackedVector2Array()
		var x := -halfw
		while x <= halfw:
			sp.append(ctr + Vector2(x, yy + sin(x * 0.5 + phase) * amp))
			x += 1.8
		draw_polyline(sp, col, 2.0)


func _draw_steam_patch(c: Vector2, hot: bool) -> void:
	# a soft column of steam rising from the (off-screen) pot
	var t: float = Time.get_ticks_msec() / 1000.0
	for i in range(7):
		var ph: float = t * 0.9 + float(i) * 0.8
		var yy: float = c.y - 2.0 - float(i) * 8.5
		var xx: float = c.x + sin(ph) * (3.0 + float(i) * 1.5)
		var rad: float = 15.0 - float(i) * 1.4
		var a: float = (0.42 - float(i) * 0.05) * (1.25 if hot else 1.0)
		draw_circle(Vector2(xx, yy), rad, Color(1, 1, 1, clamp(a, 0.0, 0.55)))


func _draw_station(s: Dictionary) -> void:
	var c: Vector2 = s.center
	var rr: int = s.r
	# 湯 / 麵: a pot mouth set into the counter (body off-frame below) + rising steam
	if s.item == "soup" or s.item == "noodles":
		var bk := "td_bowl_soup" if s.item == "soup" else "td_bowl_noodle"
		if ctex.has(bk):
			var bt: Texture2D = ctex[bk]
			# liquid surface (sprite y=20) lands at the station centre
			draw_texture_rect(bt, Rect2(c.x - _tw(bt) / 2.0, c.y - 20.0,
				_tw(bt), _th(bt)), false)
		if s.item == "soup":
			# a few simmering bubbles on the broth
			var bcol: Color = C_SOUP.lightened(0.35)
			var t := Time.get_ticks_msec() / 1000.0
			for i in range(3):
				var bx := c.x + sin(t * 1.3 + i * 2.1) * (12.0 + i * 7.0)
				var by := c.y + cos(t * 1.1 + i * 1.7) * 4.0
				draw_circle(Vector2(bx, by), 1.8, bcol)
		if s.item == "noodles" and noodle_state == "cooking":
			_draw_noodle_nest(Vector2(c.x, c.y - 1))
			_draw_boil_gauge(Vector2(c.x - 18, c.y + 4))
		# label under the bowl
		_text(s.name, Vector2(c.x + 1, c.y + 39), 12, COL_INK, HORIZONTAL_ALIGNMENT_CENTER)
		_text(s.name, Vector2(c.x, c.y + 38), 12, COL_WHITE, HORIZONTAL_ALIGNMENT_CENTER)
		return
	# ingredient boxes on the right
	var spr := _item_sprite(s.item)
	if ctex.has(spr):
		var t: Texture2D = ctex[spr]
		draw_texture_rect(t, Rect2(c.x - _tw(t) / 2.0, c.y - _th(t) / 2.0,
			_tw(t), _th(t)), false)
	if held == s.item:
		draw_arc(c, rr + 2, 0.0, TAU, 24, COL_YELLOW, 2.0)
	_text(s.name, Vector2(c.x, c.y + rr + 12), 10, COL_WHITE, HORIZONTAL_ALIGNMENT_CENTER)


func _draw_boil_gauge(at: Vector2) -> void:
	# green window = the moment to lift the noodles
	var gw := 36.0
	var gx := at.x
	var gy := at.y
	draw_rect(Rect2(gx, gy, gw, 6), COL_INK)
	var rx0 := gx + gw * (COOK_READY / 8.0)
	var rx1 := gx + gw * (COOK_OVER / 8.0)
	draw_rect(Rect2(rx0, gy, rx1 - rx0, 6), Color(0.37, 0.68, 0.37, 0.5))
	var frac: float = clamp(noodle_t / 8.0, 0.0, 1.0)
	var gc := COL_YELLOW
	if noodle_t >= COOK_READY and noodle_t <= COOK_OVER:
		gc = COL_GREEN
	elif noodle_t > COOK_OVER:
		gc = COL_RED
	draw_rect(Rect2(gx, gy, gw * frac, 6), gc)
	if noodle_t >= COOK_READY and int(Engine.get_frames_drawn() / 12) % 2 == 0:
		_text("提起!", Vector2(gx + gw / 2, gy - 12), 9,
			COL_GREEN if noodle_t <= COOK_OVER else COL_RED, HORIZONTAL_ALIGNMENT_CENTER)


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


# cook sprites are rasterised at ART_SS× their design size (assets/cook/
# gen_svg.py) so curves stay crisp on hi-DPI; divide pixel dims back to logical
const ART_SS := 4.0
func _tw(t: Texture2D) -> float: return t.get_width() / ART_SS
func _th(t: Texture2D) -> float: return t.get_height() / ART_SS


# --- assembly bowl (top-down) ----------------------------------------
func _draw_assembly(center: Vector2) -> void:
	if ctex.has("td_bowl"):
		var b: Texture2D = ctex["td_bowl"]
		var dst := Rect2(center.x - _tw(b) / 2.0, center.y - _th(b) / 2.0,
			_tw(b), _th(b))
		# subtle ring highlight (over the opening) while holding something
		if held != "":
			_draw_ellipse_ring(BOWL_OPEN, BOWL_RX + 2, BOWL_RY + 2, Color(1, 1, 0.4, 0.45))
		draw_texture_rect(b, dst, false)
		# broth fills out from the opening centre as you ladle
		if soup_fill > 0.0 and ctex.has("td_broth"):
			var t: Texture2D = ctex["td_broth"]
			var sc: float = clamp(soup_fill, 0.0, 1.0)
			var w := _tw(t) * sc
			var h := _th(t) * sc
			# keep the broth ellipse centred on the opening (sprite opening at 64,50)
			var pos := BOWL_OPEN - Vector2(_tw(t) * 0.5 * sc, _th(t) * (50.0 / 128.0) * sc)
			draw_texture_rect(t, Rect2(pos, Vector2(w, h)), false)
		if bowl.noodles and ctex.has("td_noodles"):
			draw_texture_rect(ctex["td_noodles"], dst, false)
		if bowl.beef and ctex.has("td_beef"):
			draw_texture_rect(ctex["td_beef"], dst, false)
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
	# soup -> a ladleful of broth; noodles -> chopsticks lifting noodles
	var tool := ""
	if held == "soup":
		tool = "td_pot_soup"
	elif held == "noodles":
		tool = "td_pot_noodle"
	if tool != "" and ctex.has(tool):
		var t: Texture2D = ctex[tool]
		var w: float = _tw(t)
		var h: float = _th(t)
		if held == "noodles":
			# chopstick grip sits at the cursor; the long noodles dangle below
			draw_texture_rect(t, Rect2(p.x - w / 2.0, p.y - 52.0, w, h), false)
		else:
			# the ladle's bowl of broth sits at the cursor
			draw_texture_rect(t, Rect2(p.x - w / 2.0, p.y - h + 14.0, w, h), false)
		return
	# beef + toppings (蔥花/香菜/辣椒): no carried-item cursor visual at all —
	# they only appear once dropped into the bowl


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
	var bs := 9
	# vertically centre the label in the button: baseline = top + (h + asc - desc)/2
	var by: float = BACK_RECT.position.y + (BACK_RECT.size.y + font.get_ascent(bs) - font.get_descent(bs)) / 2.0
	_text("← 選單", Vector2(BACK_RECT.position.x + BACK_RECT.size.x / 2, by),
		bs, COL_WHITE, HORIZONTAL_ALIGNMENT_CENTER)


func _draw_over() -> void:
	# full-screen dim (cover the table on every side, incl. safe-area insets)
	draw_rect(Rect2(-_ox, -_safe_t, _vw, _vh), Color(0.05, 0.04, 0.07, 0.72))
	# a panel, vertically centred on the live screen
	var pt := _vic_top()
	draw_rect(Rect2(24, pt, 222, 250), Color("2a2030"))
	draw_rect(Rect2(24, pt, 222, 250), COL_YELLOW, false, 2.0)
	_text("製作成功", Vector2(135, pt + 30.0), 19, COL_GREEN, HORIZONTAL_ALIGNMENT_CENTER)
	# the finished bowl (scaled preview)
	var bc := Vector2(135, pt + 88.0)
	var sz := 86.0
	var dst := Rect2(bc.x - sz / 2.0, bc.y - sz / 2.0, sz, sz)
	if ctex.has("td_bowl"):
		draw_texture_rect(ctex["td_bowl"], dst, false)
		if soup_fill > 0.0 and ctex.has("td_broth"):
			draw_texture_rect(ctex["td_broth"], dst, false)
		if bowl.noodles and ctex.has("td_noodles"):
			draw_texture_rect(ctex["td_noodles"], dst, false)
		if bowl.beef and ctex.has("td_beef"):
			draw_texture_rect(ctex["td_beef"], dst, false)
		# the toppings shown exactly where the player sprinkled them
		var pscale := sz / 128.0
		var op := Vector2(bc.x, bc.y - sz / 2.0 + 50.0 * pscale)
		for sp in sprinkles:
			var pp: Vector2 = op + (sp.pos - BOWL_OPEN) * pscale
			draw_rect(Rect2(pp.x - 1.25, pp.y - 1.25, 2.5, 2.5), TOPPING[sp.type].col)
	# star rating (always 3 slots)
	var sx0 := 135.0 - 3 * 18.0 / 2.0 + 9.0
	for i in range(3):
		_draw_star(Vector2(sx0 + i * 18.0, pt + 146.0), i < stars)
	var comment := "完美的一碗" if stars >= 3 else "好吃，麵的火候再練練"
	_text(comment, Vector2(135, pt + 166.0), 10, COL_WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	# buttons
	_draw_button(_menu_rect(), "回主選單", COL_PANEL_HI)
	_draw_button(_next_rect(), "再來一單", COL_GREEN)


func _draw_star(c: Vector2, full: bool) -> void:
	var col := COL_YELLOW if full else Color(0.35, 0.3, 0.25)
	var pts := PackedVector2Array()
	for i in range(10):
		var ang := -PI / 2.0 + i * PI / 5.0
		var rad := 7.0 if i % 2 == 0 else 3.0
		pts.append(c + Vector2(cos(ang), sin(ang)) * rad)
	draw_colored_polygon(pts, col)


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
	var p := pos
	if align != HORIZONTAL_ALIGNMENT_LEFT:
		# centre on the ink, not the advance box: the offset is just the last
		# CJK/full-width glyph's trailing advance gap (~size/4), independent of
		# length; ASCII-terminated strings need no correction
		var w: float = font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		var corr := 0.0
		if s.length() > 0 and s.unicode_at(s.length() - 1) >= 0x2000:
			corr = size * 0.25
		var ink: float = w - corr
		if align == HORIZONTAL_ALIGNMENT_CENTER:
			p.x -= ink * 0.5
		else:
			p.x -= ink
	draw_string(font, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)
