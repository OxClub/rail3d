extends Node

var train: Node
var engine_player: AudioStreamPlayer3D
var horn_player: AudioStreamPlayer3D
var brake_player: AudioStreamPlayer3D
var last_speed := 0.0

func setup(target: Node) -> void:
	train = target

	engine_player = _make_player("EngineSound")
	horn_player = _make_player("HornSound")
	brake_player = _make_player("BrakeSound")

	engine_player.stream = _load_sound("res://audio/engine.wav")
	horn_player.stream = _load_sound("res://audio/horn.wav")
	brake_player.stream = _load_sound("res://audio/brake.wav")

	if engine_player.stream:
		engine_player.play()


func _make_player(player_name: String) -> AudioStreamPlayer3D:
	var p := AudioStreamPlayer3D.new()
	p.name = player_name
	p.volume_db = -5.0
	p.max_distance = 100.0
	p.unit_size = 12.0
	add_child(p)
	return p


func _load_sound(path: String) -> AudioStream:
	if ResourceLoader.exists(path):
		return load(path) as AudioStream
	return null


func play_horn() -> void:
	if horn_player and horn_player.stream:
		horn_player.play()


func stop_horn() -> void:
	if horn_player:
		horn_player.stop()


func _process(_delta: float) -> void:
	if not is_instance_valid(train):
		return

	var current_speed := float(train.get("speed")) if train.get("speed") != null else 0.0

	if engine_player and engine_player.playing:
		engine_player.pitch_scale = clampf(0.75 + absf(current_speed) / 35.0, 0.75, 1.8)
		engine_player.volume_db = lerpf(-18.0, -4.0, clampf(absf(current_speed) / 30.0, 0.0, 1.0))

	if last_speed > 2.0 and current_speed < last_speed - 3.0:
		if brake_player and brake_player.stream and not brake_player.playing:
			brake_player.play()

	last_speed = current_speed
