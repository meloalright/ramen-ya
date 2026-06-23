extends Node
# =====================================================================
#  Looping 8-bit BGM (assets/audio/bgm.wav), registered as an autoload so
#  it keeps playing seamlessly across scene changes (World → Shop → Main).
#  Press [0] to mute/unmute.
# =====================================================================

var player: AudioStreamPlayer
var click_player: AudioStreamPlayer   # persistent UI click — survives scene changes


func click() -> void:
	# short button-click blip shared by every button across all scenes
	if click_player != null and click_player.stream != null:
		click_player.play()


func _ready() -> void:
	click_player = AudioStreamPlayer.new()
	click_player.bus = "Master"
	click_player.volume_db = -4.0
	add_child(click_player)
	if ResourceLoader.exists("res://assets/audio/click.wav"):
		click_player.stream = load("res://assets/audio/click.wav")

	player = AudioStreamPlayer.new()
	player.bus = "Master"
	player.volume_db = -9.0
	add_child(player)

	if not ResourceLoader.exists("res://assets/audio/bgm.wav"):
		return
	var s = load("res://assets/audio/bgm.wav")
	if s is AudioStreamWAV:
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD
		s.loop_begin = 0
		s.loop_end = s.data.size() / 2          # mono 16-bit → 2 bytes/frame
	player.stream = s
	player.play()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_0:
		player.stream_paused = not player.stream_paused
