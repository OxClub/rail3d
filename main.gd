extends Node3D

const TrackScript = preload("res://track_path.gd")
const TrainScript = preload("res://train_controller.gd")
const SignalScript = preload("res://signal_light.gd")
const MissionScript = preload("res://mission_manager.gd")
const HudScript = preload("res://hud.gd")
const WorldMenuScript = preload("res://world_train_menu.gd")
const RailwayEnvironmentScript = preload("res://railway_environment.gd")
const WorldUpgradeScript = preload("res://world_upgrade.gd")
const TrainRealismScript = preload("res://train_realism.gd")
const TrainAudioScript = preload("res://train_audio.gd")
const WorldwideGameplayScript = preload("res://worldwide_gameplay.gd")

func _ready() -> void:
	var menu = WorldMenuScript.new()
	add_child(menu)
	menu.train_selected.connect(_start_game)


func _start_game(profile: Dictionary) -> void:
	_environment()
	var track = TrackScript.new()
	track.set_meta("route_profile", profile.get("route", {}))
	add_child(track)
	_ground()
	_mountains()
	_trees(track)
	var world_upgrade = WorldUpgradeScript.new()
	add_child(world_upgrade)
	world_upgrade.setup(track, profile)

	var train = TrainScript.new()
	track.add_child(train)
	train.setup(track, 3)
	var realism = TrainRealismScript.new()
	train.add_child(realism)
	realism.setup(train)

	var audio_system = TrainAudioScript.new()
	train.add_child(audio_system)
	audio_system.setup(train)

	train.progress = 20.0

	var worldwide_systems = WorldwideGameplayScript.new()
	add_child(worldwide_systems)
	worldwide_systems.setup(track, train, profile)


	if train.has_method("apply_profile"):
		train.apply_profile(profile)

	var sigs: Array = []
	var periods := [7.0, 9.0, 11.0, 8.0]
	for i in 4:
		var signal_node = SignalScript.new()
		track.add_child(signal_node)
		signal_node.setup(track, track.length * (0.24 + 0.24 * i), i % 2 == 0, periods[i])
		sigs.append(signal_node)

	var mission = MissionScript.new()
	add_child(mission)
	var hud = HudScript.new()
	add_child(hud)
	hud.setup(train, mission)
	mission.setup(track, train, sigs)


func _environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY

	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color(0.12, 0.30, 0.62)
	sm.sky_horizon_color = Color(0.75, 0.84, 0.95)
	sm.ground_horizon_color = Color(0.55, 0.65, 0.48)
	sm.ground_bottom_color = Color(0.18, 0.28, 0.15)
	sky.sky_material = sm

	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.fog_enabled = true
	env.fog_light_color = Color(0.72, 0.81, 0.91)
	env.fog_density = 0.0012

	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -35, 0)
	sun.light_energy = 1.3
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 160.0
	add_child(sun)


func _ground() -> void:
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(1100, 1100)

	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.18, 0.36, 0.15)
	m.roughness = 1.0
	pm.material = m

	mi.mesh = pm
	mi.position.y = -0.02
	add_child(mi)


func _mountains() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7

	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.35, 0.42, 0.5)
	m.roughness = 1.0

	for i in 20:
		var a := TAU * float(i) / 20.0
		var h := rng.randf_range(70.0, 140.0)

		var cm := CylinderMesh.new()
		cm.top_radius = 0.0
		cm.bottom_radius = rng.randf_range(70.0, 110.0)
		cm.height = h
		cm.material = m

		var mi := MeshInstance3D.new()
		mi.mesh = cm
		mi.position = Vector3(420.0 * cos(a), h * 0.5, 420.0 * sin(a))
		add_child(mi)


func _trees(track) -> void:
	var pts: PackedVector3Array = track.curve.get_baked_points()
	var rng := RandomNumberGenerator.new()
	rng.seed = 42

	var spots: Array[Transform3D] = []
	var tries := 0

	while spots.size() < 150 and tries < 1500:
		tries += 1
		var p := Vector3(rng.randf_range(-330, 330), 0, rng.randf_range(-250, 250))
		var ok := true

		for j in range(0, pts.size(), 4):
			if p.distance_to(pts[j]) < 16.0:
				ok = false
				break

		if not ok:
			continue

		var s := rng.randf_range(0.8, 1.6)
		spots.append(Transform3D(Basis().scaled(Vector3(s, s, s)), p))

	var trunk := CylinderMesh.new()
	trunk.top_radius = 0.2
	trunk.bottom_radius = 0.3
	trunk.height = 2.5

	var tm := StandardMaterial3D.new()
	tm.albedo_color = Color(0.36, 0.24, 0.14)
	trunk.material = tm

	var crown := CylinderMesh.new()
	crown.top_radius = 0.0
	crown.bottom_radius = 1.9
	crown.height = 5.5

	var cmat := StandardMaterial3D.new()
	cmat.albedo_color = Color(0.1, 0.32, 0.14)
	crown.material = cmat

	_multi(trunk, spots, 1.25)
	_multi(crown, spots, 4.7)


func _multi(mesh: Mesh, spots: Array[Transform3D], lift: float) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = spots.size()

	for i in spots.size():
		var t := spots[i]
		t.origin.y = lift * t.basis.y.y
		mm.set_instance_transform(i, t)

	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	add_child(mmi)


func _trackside_details(track: Path3D) -> void:
	var length := track.curve.get_baked_length()
	if length <= 0.0:
		return

	var pole_mat := StandardMaterial3D.new()
	pole_mat.albedo_color = Color(0.38, 0.40, 0.43)
	pole_mat.metallic = 0.65

	var arm_mat := StandardMaterial3D.new()
	arm_mat.albedo_color = Color(0.22, 0.24, 0.27)
	arm_mat.metallic = 0.7

	var wire_mat := StandardMaterial3D.new()
	wire_mat.albedo_color = Color(0.12, 0.13, 0.14)
	wire_mat.metallic = 0.8

	var poles: Array[Vector3] = []

	for d in range(12, int(length), 38):
		var distance := float(d)
		var p := track.curve.sample_baked(distance)
		var ahead := track.curve.sample_baked(fposmod(distance + 1.0, length))
		var behind := track.curve.sample_baked(fposmod(distance - 1.0, length))

		var tangent := (ahead - behind).normalized()
		var side := tangent.cross(Vector3.UP).normalized()

		if side.length_squared() < 0.01:
			continue

		var pole := MeshInstance3D.new()
		var pm := CylinderMesh.new()
		pm.top_radius = 0.09
		pm.bottom_radius = 0.17
		pm.height = 10.0
		pm.material = pole_mat
		pole.mesh = pm
		pole.position = p + side * 5.8 + Vector3.UP * 5.0
		add_child(pole)

		var arm := MeshInstance3D.new()
		var am := BoxMesh.new()
		am.size = Vector3(5.5, 0.16, 0.18)
		am.material = arm_mat
		arm.mesh = am
		arm.position = p + side * 5.8 + Vector3.UP * 9.5
		arm.look_at(arm.position + tangent, Vector3.UP)
		add_child(arm)

		poles.append(p + Vector3.UP * 9.2)

	var wire_mesh := ImmediateMesh.new()
	wire_mesh.surface_begin(Mesh.PRIMITIVE_LINES, wire_mat)

	for i in range(poles.size() - 1):
		wire_mesh.surface_add_vertex(poles[i])
		wire_mesh.surface_add_vertex(poles[i + 1])

	wire_mesh.surface_end()

	var wire_instance := MeshInstance3D.new()
	wire_instance.mesh = wire_mesh
	add_child(wire_instance)
