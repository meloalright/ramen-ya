extends Node
# =====================================================================
#  Persistent game state + save/load (autoload singleton "Game").
#  Saved to user://ramenya_save.json — a coin wallet that grows from
#  cooking, and the player's last overworld position (for Continue).
# =====================================================================

const PATH := "user://ramenya_save.json"

var coins: int = 0
var world_pos := Vector2.ZERO
var has_pos := false

# upgrade levels (bought at the street's upgrade store)
var up_tip := 0          # +15% tips per level
var up_patience := 0     # +5s customer patience per level
var up_day := 0          # +20s business day per level
const UP_MAX := 5


func has_save() -> bool:
	return FileAccess.file_exists(PATH)


func new_game() -> void:
	coins = 0
	world_pos = Vector2.ZERO
	has_pos = false
	up_tip = 0
	up_patience = 0
	up_day = 0
	save()


func save() -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify({
		"coins": coins, "x": world_pos.x, "y": world_pos.y, "has_pos": has_pos,
		"up_tip": up_tip, "up_patience": up_patience, "up_day": up_day,
	}))
	f.close()


func load_game() -> bool:
	if not has_save():
		return false
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return false
	var d = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(d) != TYPE_DICTIONARY:
		return false
	coins = int(d.get("coins", 0))
	world_pos = Vector2(float(d.get("x", 0.0)), float(d.get("y", 0.0)))
	has_pos = bool(d.get("has_pos", false))
	up_tip = int(d.get("up_tip", 0))
	up_patience = int(d.get("up_patience", 0))
	up_day = int(d.get("up_day", 0))
	return true


func add_coins(n: int) -> void:
	coins = max(0, coins + n)
	save()


func remember_pos(p: Vector2) -> void:
	world_pos = p
	has_pos = true
	save()


func up_level(key: String) -> int:
	match key:
		"tip": return up_tip
		"patience": return up_patience
		"day": return up_day
	return 0


func up_cost(key: String) -> int:
	# escalating: base * (level+1)
	var base: int = {"tip": 150, "patience": 120, "day": 200}.get(key, 150)
	return base * (up_level(key) + 1)


func buy_upgrade(key: String) -> bool:
	if up_level(key) >= UP_MAX:
		return false
	var cost := up_cost(key)
	if coins < cost:
		return false
	coins -= cost
	match key:
		"tip": up_tip += 1
		"patience": up_patience += 1
		"day": up_day += 1
	save()
	return true
