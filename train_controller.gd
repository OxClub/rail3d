extends PathFollow3D

const MAX_SPEED := 30.0
const CAR_SPACING := 8.5

var speed := 0.0
var throttle_in := false
var brake_in := false
var wagons: Array = []
var track_len := 1.0
var cam: Camera3D

func _mat(c: Color, emit := false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.4
	m.metallic = 0.35
	if emit:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = 3.0
	return m

func _box(parent: Node3D, size: Vector3, pos: Vector3, color: Color, emit := false) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	bm.material = _mat(color, emit)
	mi.mesh = bm
	mi.position = pos
	parent.add_child(mi)

func _wheels(parent: Node3D) -> void:
	for side in [-1.2, 1.2]:
		for z in [-3.0, -1.0, 1.0, 3.0]:
			var mi := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.top_radius = 0.45
			cm.bottom_radius = 0.45
			cm.height = 0.16
			cm.material = _mat(Color(0.1, 0.1, 0.1))
			mi.mesh = cm
			mi.rotation_degrees = Vector3(0, 0, 90)
			mi.position = Vector3(side, 0.93, z)
			parent.add_child(mi)

func _prepare(f: PathFollow3D) -> void:
	f.loop = true
	f.rotation_mode = PathFollow3D.ROTATION_ORIENTED
	f.use_model_front = true

func setup(track: Path3D, wagon_count: int) -> void:
	_prepare(self)
	track_len = track.curve.get_baked_length()
	_build_loco()
	var colors := [Color(0.1, 0.3, 0.65), Color(0.85, 0.65, 0.12), Color(0.1, 0.5, 0.35)]
	for i in wagon_count:
		var w := PathFollow3D.new()
		track.add_child(w)
		_prepare(w)
		_box(w, Vector3(2.4, 0.5, 8.2), Vector3(0, 1.35, 0), Color(0.12, 0.12, 0.14))
		_box(w, Vector3(2.8, 2.6, 7.8), Vector3(0, 2.95, 0), colors[i % colors.size()])
		_box(w, Vector3(3.0, 0.2, 8.0), Vector3(0, 4.35, 0), Color(0.8, 0.8, 0.82))
		_box(w, Vector3(2.85, 0.7, 6.0), Vector3(0, 3.2, 0), Color(0.6, 0.85, 1.0, 1.0), true)
		_wheels(w)
		wagons.append(w)

func _build_loco() -> void:
	_box(self, Vector3(2.4, 0.5, 8.2), Vector3(0, 1.35, 0), Color(0.12, 0.12, 0.14))
	_box(self, Vector3(2.4, 2.0, 4.6), Vector3(0, 2.6, -1.8), Color(0.65, 0.1, 0.1))
	_box(self, Vector3(2.8, 3.0, 3.2), Vector3(0, 3.1, 2.4), Color(0.55, 0.08, 0.08))
	_box(self, Vector3(3.1, 0.25, 3.6), Vector3(0, 4.7, 2.4), Color(0.2, 0.2, 0.22))
	_box(self, Vector3(0.7, 0.5, 0.1), Vector3(0, 2.6, -4.12), Color(1, 0.95, 0.7), true)
	var ch := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.3
	cm.bottom_radius = 0.35
	cm.height = 1.3
	cm.material = _mat(Color(0.1, 0.1, 0.1))
	ch.mesh = cm
	ch.position = Vector3(0, 4.2, -3.0)
	add_child(ch)
	_wheels(self)
	var spot := SpotLight3D.new()
	spot.position = Vector3(0, 2.6, -4.3)
	spot.spot_range = 90.0
	spot.spot_angle = 28.0
	spot.light_energy = 4.0
	add_child(spot)
	cam = Camera3D.new()
	cam.position = Vector3(0, 5.6, 11.5)
	cam.rotation_degrees = Vector3(-11, 0, 0)
	cam.fov = 68.0
	cam.current = true
	add_child(cam)

func _process(delta: float) -> void:
	var thr := throttle_in or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP)
	var brk := brake_in or Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN)
	if brk:
		speed -= 13.0 * delta
	elif thr:
		speed += 5.0 * delta * (1.0 - speed / (MAX_SPEED * 1.15))
	else:
		speed -= 0.6 * delta
	speed = clampf(speed, 0.0, MAX_SPEED)
	progress = fposmod(progress + speed * delta, track_len)
	for i in wagons.size():
		wagons[i].progress = fposmod(progress - (i + 1) * CAR_SPACING, track_len)
	if cam:
		cam.fov = 68.0 + speed * 0.6
