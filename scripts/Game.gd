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


func has_save() -> bool:
	return FileAccess.file_exists(PATH)


func new_game() -> void:
	coins = 0
	world_pos = Vector2.ZERO
	has_pos = false
	save()


func save() -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify({
		"coins": coins, "x": world_pos.x, "y": world_pos.y, "has_pos": has_pos,
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
	return true


func add_coins(n: int) -> void:
	coins = max(0, coins + n)
	save()


func remember_pos(p: Vector2) -> void:
	world_pos = p
	has_pos = true
	save()
