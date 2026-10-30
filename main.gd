extends Node3D

const TrackScript = preload("res://track_path.gd")
const TrainScript = preload("res://train_controller.gd")
const SignalScript = preload("res://signal_light.gd")
const MissionScript = preload("res://mission_manager.gd")
const HudScript = preload("res://hud.gd")

func _ready() -> void:
	_environment()
	var track = TrackScript.new()
	add_child(track)
	_ground()
	_mountains()
	_trees(track)

	var train = TrainScript.new()
	track.add_child(train)
	train.setup(track, 3)
	train.progress = 20.0

	var sigs: Array = []
	var periods := [7.0, 9.0, 11.0, 8.0]
	for i in 4:
		var s = SignalScript.new()
		track.add_child(s)
		s.setup(track, track.length * (0.24 + 0.24 * i), i % 2 == 0, periods[i])
		sigs.append(s)

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
	sm.sky_top_color = Color(0.22, 0.45, 0.85)
	sm.sky_horizon_color = Color(0.75, 0.85, 0.95)
	sm.ground_horizon_color = Color(0.75, 0.85, 0.95)
	sm.ground_bottom_color = Color(0.3, 0.4, 0.3)
	sky.sky_material = sm
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.fog_enabled = true
	env.fog_light_color = Color(0.75, 0.85, 0.95)
	env.fog_density = 0.0015
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
