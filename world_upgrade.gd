extends Node3D

var track_ref: Path3D
var ai_trains: Array[PathFollow3D] = []
var ai_speeds: Array[float] = []
var cycle_time := 0.0
var cycle_duration := 240.0
var world_env: WorldEnvironment
var sun: DirectionalLight3D


func setup(track: Path3D, profile: Dictionary) -> void:
	track_ref = track
	_build_stations()
	_build_ai_train()
	_setup_weather(profile)
	_find_environment()


func _make_material(color: Color, metallic := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.metallic = metallic
	m.roughness = 0.75
	return m


func _make_box(parent: Node3D, size: Vector3, pos: Vector3, color: Color) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = _make_material(color)
	var obj := MeshInstance3D.new()
	obj.mesh = mesh
	obj.position = pos
	parent.add_child(obj)
	return obj


func _build_stations() -> void:
	if track_ref == null or track_ref.curve == null:
		return

	var length := track_ref.curve.get_baked_length()
	if length < 20.0:
		return

	_build_station(length * 0.20, "WY RIX CENTRAL")
	_build_station(length * 0.68, "WORLD RAIL STATION")


func _build_station(distance: float, station_name: String) -> void:
	var length := track_ref.curve.get_baked_length()
	var p := track_ref.curve.sample_baked(distance)
	var ahead := track_ref.curve.sample_baked(fposmod(distance + 2.0, length))
	var root := Node3D.new()
	root.name = station_name.replace(" ", "_")
	root.position = p
	add_child(root)
	root.look_at(p + (ahead - p).normalized(), Vector3.UP)

	var platform_mat := Color(0.42, 0.44, 0.46)
	var building_mat := Color(0.72, 0.74, 0.77)
	var roof_mat := Color(0.12, 0.17, 0.24)

	# Platform
	_make_box(root, Vector3(10.0, 0.55, 48.0), Vector3(5.5, 0.28, 0), platform_mat)
	_make_box(root, Vector3(0.35, 0.12, 46.0), Vector3(1.0, 0.62, 0), Color(0.95, 0.76, 0.12))

	# Station building
	_make_box(root, Vector3(13.0, 5.0, 22.0), Vector3(14.0, 2.5, 0), building_mat)
	_make_box(root, Vector3(14.0, 0.45, 23.0), Vector3(14.0, 5.2, 0), roof_mat)

	# Doors and windows
	for z in [-7.0, -2.5, 2.5, 7.0]:
		_make_box(root, Vector3(0.12, 2.2, 1.6), Vector3(7.35, 2.0, z), Color(0.10, 0.25, 0.34))

	# Station name board
	_make_box(root, Vector3(0.25, 1.6, 10.0), Vector3(6.8, 6.5, 0), Color(0.04, 0.16, 0.27))

	# Platform lamps
	for z in [-19.0, -9.0, 9.0, 19.0]:
		var pole := MeshInstance3D.new()
		var pole_mesh := CylinderMesh.new()
		pole_mesh.top_radius = 0.07
		pole_mesh.bottom_radius = 0.10
		pole_mesh.height = 5.0
		pole_mesh.material = _make_material(Color(0.22, 0.23, 0.25), 0.5)
		pole.mesh = pole_mesh
		pole.position = Vector3(5.5, 2.8, z)
		root.add_child(pole)

		var lamp := OmniLight3D.new()
		lamp.position = Vector3(5.5, 5.3, z)
		lamp.light_color = Color(1.0, 0.86, 0.62)
		lamp.light_energy = 1.1
		lamp.omni_range = 12.0
		root.add_child(lamp)


func _build_ai_train() -> void:
	if track_ref == null or track_ref.curve == null:
		return

	var length := track_ref.curve.get_baked_length()
	if length < 30.0:
		return

	var follower := PathFollow3D.new()
	follower.name = "AI_Train"
	follower.loop = true
	follower.rotation_mode = PathFollow3D.ROTATION_ORIENTED
	follower.use_model_front = true
	track_ref.add_child(follower)
	follower.progress = length * 0.52

	var body := _make_box(follower, Vector3(2.7, 2.5, 8.0), Vector3(3.4, 2.7, 0), Color(0.12, 0.32, 0.68))
	_make_box(follower, Vector3(2.8, 0.35, 8.3), Vector3(3.4, 4.0, 0), Color(0.18, 0.19, 0.22))
	_make_box(follower, Vector3(0.06, 0.85, 5.8), Vector3(4.78, 3.1, 0), Color(0.04, 0.15, 0.23))
	_make_box(follower, Vector3(0.06, 0.85, 5.8), Vector3(2.02, 3.1, 0), Color(0.04, 0.15, 0.23))

	for z in [-2.7, 2.7]:
		var wheel := MeshInstance3D.new()
		var wheel_mesh := CylinderMesh.new()
		wheel_mesh.top_radius = 0.48
		wheel_mesh.bottom_radius = 0.48
		wheel_mesh.height = 0.18
		wheel_mesh.material = _make_material(Color(0.08, 0.08, 0.09), 0.6)
		wheel.mesh = wheel_mesh
		wheel.position = Vector3(3.4, 1.0, z)
		wheel.rotation_degrees.z = 90
		follower.add_child(wheel)

	ai_trains.append(follower)
	ai_speeds.append(10.0)


func _setup_weather(profile: Dictionary) -> void:
	var route: Dictionary = profile.get("route", {})
	var weather := str(route.get("weather", "Clear")).to_lower()

	if weather.contains("rain"):
		_create_particles(true)
	elif weather.contains("snow"):
		_create_particles(false)


func _create_particles(is_rain: bool) -> void:
	var particles := GPUParticles3D.new()
	particles.name = "WeatherParticles"
	particles.position = Vector3(0, 22, 0)
	particles.amount = 900 if is_rain else 500
	particles.lifetime = 1.8 if is_rain else 5.0
	particles.emitting = true
	particles.visibility_aabb = AABB(Vector3(-100, -35, -100), Vector3(200, 90, 200))

	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents = Vector3(90, 15, 90)
	process.direction = Vector3(0, -1, 0)
	process.spread = 8.0 if is_rain else 30.0
	process.initial_velocity_min = 22.0 if is_rain else 2.0
	process.initial_velocity_max = 32.0 if is_rain else 5.0
	process.gravity = Vector3(0, -18, 0)
	process.scale_min = 0.5
	process.scale_max = 1.0
	particles.process_material = process

	if is_rain:
		var drop := BoxMesh.new()
		drop.size = Vector3(0.025, 0.65, 0.025)
		drop.material = _make_material(Color(0.55, 0.72, 0.9, 0.65))
		particles.draw_pass_1 = drop
	else:
		var flake := SphereMesh.new()
		flake.radius = 0.07
		flake.height = 0.14
		flake.material = _make_material(Color(0.95, 0.97, 1.0))
		particles.draw_pass_1 = flake

	add_child(particles)


func _find_environment() -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return

	world_env = scene.find_child("WorldEnvironment", true, false) as WorldEnvironment
	sun = scene.find_child("DirectionalLight3D", true, false) as DirectionalLight3D


func _process(delta: float) -> void:
	if track_ref != null and track_ref.curve != null:
		var length := track_ref.curve.get_baked_length()
		for i in range(ai_trains.size()):
			if is_instance_valid(ai_trains[i]):
				ai_trains[i].progress = fposmod(ai_trains[i].progress + ai_speeds[i] * delta, length)

	# Gradual day/night lighting cycle
	cycle_time = fposmod(cycle_time + delta / cycle_duration, 1.0)
	var daylight := clampf(0.5 + 0.5 * sin(cycle_time * TAU - PI / 2.0), 0.0, 1.0)

	if sun:
		sun.rotation_degrees.x = -10.0 - daylight * 65.0
		sun.light_energy = 0.12 + daylight * 1.25

	if world_env and world_env.environment:
		world_env.environment.ambient_light_energy = 0.25 + daylight * 0.75
