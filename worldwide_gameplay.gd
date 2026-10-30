extends Node3D
class_name WorldwideGameplay

var track: Path3D
var player_train: PathFollow3D
var profile: Dictionary = {}
var ai_trains: Array[PathFollow3D] = []
var ai_speeds: Array[float] = []
var station_positions: Array[float] = []
var passengers: Array[Node3D] = []
var world_env: WorldEnvironment
var sun: DirectionalLight3D
var cycle_time := 0.28
var cycle_duration := 900.0
var save_path := "user://wyrix_save.cfg"
var weather_particles: GPUParticles3D
var status_label: Label

func setup(t: Path3D, train: PathFollow3D, selected_profile: Dictionary) -> void:
	track = t
	player_train = train
	profile = selected_profile
	name = "WorldwideGameplay"
	_find_lighting()
	_build_stations()
	_build_ai_trains()
	_build_passengers()
	_build_weather()
	_build_route_landmarks()
	_load_game()
	_build_quick_save_button()


func _material(color: Color, metallic := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.metallic = metallic
	m.roughness = 0.8
	return m


func _box(parent: Node3D, size: Vector3, pos: Vector3, color: Color) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = _material(color)
	var obj := MeshInstance3D.new()
	obj.mesh = mesh
	obj.position = pos
	parent.add_child(obj)
	return obj


func _find_lighting() -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	world_env = scene.find_child("WorldEnvironment", true, false) as WorldEnvironment
	sun = scene.find_child("DirectionalLight3D", true, false) as DirectionalLight3D


func _build_stations() -> void:
	if track == null or track.curve == null:
		return

	var length := track.curve.get_baked_length()
	if length <= 0.0:
		return

	var names := ["Central Station", "River Junction", "Mountain Terminal", "International Hub"]
	var fractions := [0.10, 0.34, 0.62, 0.86]

	for i in fractions.size():
		var distance := length * fractions[i]
		station_positions.append(distance)
		var point := track.curve.sample_baked(distance)
		var ahead := track.curve.sample_baked(fposmod(distance + 2.0, length))
		var tangent := (ahead - point).normalized()
		var side := tangent.cross(Vector3.UP).normalized()

		var station := Node3D.new()
		station.name = names[i].replace(" ", "_")
		add_child(station)
		station.global_position = point

		var platform := _box(station, Vector3(5.0, 0.35, 34.0),
			Vector3(0, 0.45, 0), Color(0.42, 0.44, 0.46))
		platform.rotation.y = atan2(tangent.x, tangent.z)

		var roof := _box(station, Vector3(7.0, 0.18, 28.0),
			Vector3(0, 5.2, 0), Color(0.16, 0.19, 0.23))
		roof.rotation.y = platform.rotation.y

		for x in [-2.8, 2.8]:
			var column := _box(station, Vector3(0.18, 4.6, 0.18),
				Vector3(x, 2.6, 0), Color(0.28, 0.30, 0.32))
			column.rotation.y = platform.rotation.y

		var sign := Label3D.new()
		sign.text = names[i]
		sign.font_size = 48
		sign.position = Vector3(0, 6.0, 0)
		sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		station.add_child(sign)

		station.global_position += side * 4.0


func _build_ai_trains() -> void:
	if track == null:
		return

	var length := track.curve.get_baked_length()
	for i in 3:
		var follower := PathFollow3D.new()
		follower.name = "AI_Train_%d" % (i + 1)
		follower.loop = true
		follower.rotation_mode = PathFollow3D.ROTATION_ORIENTED
		follower.use_model_front = true
		track.add_child(follower)
		follower.progress = length * (0.20 + float(i) * 0.25)

		var color := [Color(0.08, 0.28, 0.72), Color(0.75, 0.18, 0.08), Color(0.12, 0.48, 0.30)][i]
		_box(follower, Vector3(2.8, 2.4, 8.0), Vector3(0, 2.4, 0), color)
		_box(follower, Vector3(2.5, 0.8, 2.0), Vector3(0, 3.5, -3.0), color)
		_box(follower, Vector3(2.9, 0.2, 8.2), Vector3(0, 3.7, 0), Color(0.12, 0.13, 0.15))
		_box(follower, Vector3(2.2, 0.65, 0.08), Vector3(0, 3.0, -4.05), Color(0.02, 0.08, 0.13))

		ai_trains.append(follower)
		ai_speeds.append([12.0, 17.0, 9.0][i])


func _build_passengers() -> void:
	if station_positions.is_empty():
		return

	for distance in station_positions:
		var point := track.curve.sample_baked(distance)
		var ahead := track.curve.sample_baked(fposmod(distance + 2.0, track.curve.get_baked_length()))
		var side := (ahead - point).normalized().cross(Vector3.UP).normalized()

		for i in 5:
			var person := Node3D.new()
			person.position = point + side * (7.0 + float(i % 2) * 1.2) + Vector3(0, 0, float(i) * 2.0 - 4.0)
			add_child(person)

			var body := CapsuleMesh.new()
			body.radius = 0.28
			body.height = 1.5
			body.material = _material([Color(0.2, 0.35, 0.8), Color(0.7, 0.25, 0.12), Color(0.2, 0.55, 0.3)][i % 3])
			var body_obj := MeshInstance3D.new()
			body_obj.mesh = body
			body_obj.position.y = 0.9
			person.add_child(body_obj)

			var head := SphereMesh.new()
			head.radius = 0.22
			head.height = 0.44
			head.material = _material(Color(0.72, 0.53, 0.38))
			var head_obj := MeshInstance3D.new()
			head_obj.mesh = head
			head_obj.position.y = 1.78
			person.add_child(head_obj)
			passengers.append(person)


func _build_weather() -> void:
	var route: Dictionary = profile.get("route", {})
	var weather := str(route.get("weather", "Clear")).to_lower()
	if not weather.contains("rain") and not weather.contains("snow"):
		return

	weather_particles = GPUParticles3D.new()
	weather_particles.name = "RouteWeather"
	weather_particles.position = Vector3(0, 20, 0)
	weather_particles.amount = 650
	weather_particles.lifetime = 3.0 if weather.contains("rain") else 5.0
	weather_particles.emitting = true
	weather_particles.visibility_aabb = AABB(Vector3(-120, -30, -120), Vector3(240, 70, 240))

	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents = Vector3(100, 15, 100)
	process.direction = Vector3(0, -1, 0)
	process.spread = 10.0 if weather.contains("rain") else 35.0
	process.initial_velocity_min = 20.0 if weather.contains("rain") else 2.0
	process.initial_velocity_max = 30.0 if weather.contains("rain") else 5.0
	process.gravity = Vector3(0, -18, 0)
	weather_particles.process_material = process

	if weather.contains("rain"):
		var drop := BoxMesh.new()
		drop.size = Vector3(0.025, 0.5, 0.025)
		drop.material = _material(Color(0.55, 0.72, 0.9))
		weather_particles.draw_pass_1 = drop
	else:
		var snow := SphereMesh.new()
		snow.radius = 0.08
		snow.height = 0.16
		snow.material = _material(Color.WHITE)
		weather_particles.draw_pass_1 = snow

	add_child(weather_particles)


func _build_route_landmarks() -> void:
	var route: Dictionary = profile.get("route", {})
	var terrain := str(route.get("terrain", "")).to_lower()
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(str(route.get("id", "worldwide")))

	for i in 18:
		var angle := TAU * float(i) / 18.0
		var radius := 280.0
		var height := rng.randf_range(25.0, 75.0)
		if terrain.contains("mountain") or terrain.contains("alpine"):
			height = rng.randf_range(65.0, 145.0)
		elif terrain.contains("desert"):
			height = rng.randf_range(12.0, 38.0)

		var hill := MeshInstance3D.new()
		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.0
		mesh.bottom_radius = rng.randf_range(18.0, 42.0)
		mesh.height = height
		mesh.material = _material(Color(0.30, 0.36, 0.30))
		hill.mesh = mesh
		hill.position = Vector3(cos(angle) * radius, height * 0.5, sin(angle) * radius)
		add_child(hill)


func save_game() -> void:
	if not is_instance_valid(player_train):
		return

	var config := ConfigFile.new()
	config.set_value("game", "train_name", str(player_train.get("selected_train_name")))
	config.set_value("game", "speed", float(player_train.get("speed")))
	config.set_value("game", "progress", float(player_train.progress))
	config.set_value("game", "country", str(profile.get("country", "Worldwide")))
	config.set_value("game", "route", str(profile.get("name", "Route")))
	config.set_value("game", "headlights", bool(player_train.get("headlights_on")))
	config.set_value("game", "cycle_time", cycle_time)
	config.save(save_path)


func _load_game() -> void:
	var config := ConfigFile.new()
	if config.load(save_path) != OK:
		return

	if is_instance_valid(player_train):
		player_train.progress = float(config.get_value("game", "progress", player_train.progress))
		player_train.speed = 0.0
		player_train.headlights_on = bool(config.get_value("game", "headlights", true))
	cycle_time = float(config.get_value("game", "cycle_time", cycle_time))


func _build_quick_save_button() -> void:
	var layer := CanvasLayer.new()
	layer.name = "SaveControls"
	add_child(layer)

	var button := Button.new()
	button.text = "SAVE GAME"
	button.position = Vector2(18, 18)
	button.size = Vector2(150, 52)
	button.add_theme_font_size_override("font_size", 18)
	button.pressed.connect(save_game)
	layer.add_child(button)


func _process(delta: float) -> void:
	if track != null and track.curve != null:
		var length := track.curve.get_baked_length()
		for i in ai_trains.size():
			if is_instance_valid(ai_trains[i]):
				ai_trains[i].progress = fposmod(ai_trains[i].progress + ai_speeds[i] * delta, length)

	cycle_time = fposmod(cycle_time + delta / cycle_duration, 1.0)
	var daylight := clampf(0.5 + 0.5 * sin(cycle_time * TAU - PI / 2.0), 0.0, 1.0)

	if sun != null:
		sun.rotation_degrees.x = -10.0 - daylight * 65.0
		sun.light_energy = 0.12 + daylight * 1.25

	if world_env != null and world_env.environment != null:
		world_env.environment.ambient_light_energy = 0.25 + daylight * 0.75

	if weather_particles != null and is_instance_valid(player_train):
		weather_particles.global_position = player_train.global_position + Vector3(0, 18, 0)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED:
		save_game()
