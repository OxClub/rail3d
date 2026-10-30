extends PathFollow3D

const MAX_SPEED := 33.33
const ACCELERATION := 2.8
const SERVICE_BRAKE := 8.0
const EMERGENCY_BRAKE := 15.0

var max_speed_mps: float = MAX_SPEED
var train_acceleration: float = ACCELERATION
var train_service_brake: float = SERVICE_BRAKE
var train_emergency_brake: float = EMERGENCY_BRAKE
var selected_train_name: String = "Default Locomotive"
var selected_train_country: String = "Worldwide"

const COAST_RESISTANCE := 0.18
const CAR_SPACING := 10.5

var speed := 0.0
var throttle_in := false
var brake_in := false
var emergency_brake := false
var camera_mode := 0
var horn_active := false
var headlights_on := true
var door_open := false
var selected_body_color := Color(0.72, 0.035, 0.035)
var _horn_key_locked := false
var _light_key_locked := false
var wagons: Array[PathFollow3D] = []
var track_len := 1.0
var cam: Camera3D

var loco_red := Color(0.72, 0.035, 0.035)
var loco_white := Color(0.88, 0.88, 0.84)
var dark := Color(0.07, 0.075, 0.08)
var glass := Color(0.035, 0.15, 0.22)
var yellow := Color(1.0, 0.72, 0.04)


func _mat(c: Color, metal := 0.2, rough := 0.4, glow := false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.metallic = metal
	m.roughness = rough
	if glow:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = 2.0
	return m


func _box(parent: Node3D, size: Vector3, pos: Vector3, color: Color, metal := 0.2) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = _mat(color, metal)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos
	parent.add_child(mi)
	return mi


func _cylinder(parent: Node3D, radius: float, height: float, pos: Vector3, color: Color) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.material = _mat(color, 0.65, 0.35)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos
	mi.rotation_degrees.z = 90
	parent.add_child(mi)


func _sphere(parent: Node3D, radius: float, pos: Vector3, color: Color, glow := false) -> void:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.material = _mat(color, 0.1, 0.25, glow)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos
	parent.add_child(mi)


func _prepare(f: PathFollow3D) -> void:
	f.loop = true
	f.rotation_mode = PathFollow3D.ROTATION_ORIENTED
	f.use_model_front = true


func setup(track: Path3D, wagon_count: int) -> void:
	_prepare(self)
	track_len = track.curve.get_baked_length()
	_build_loco()

	var coach_colors := [
		Color(0.72, 0.035, 0.035),
		Color(0.75, 0.78, 0.80),
		Color(0.72, 0.035, 0.035)
	]

	for i in range(wagon_count):
		var w := PathFollow3D.new()
		track.add_child(w)
		_prepare(w)
		_build_coach(w, coach_colors[i % coach_colors.size()])
		wagons.append(w)


func _build_loco() -> void:
	# Main chassis
	_box(self, Vector3(2.9, 0.65, 9.0), Vector3(0, 1.25, 0), dark, 0.7)

	# Main locomotive body
	_box(self, Vector3(2.8, 2.25, 7.5), Vector3(0, 2.75, 0), loco_red)

	# Front sloped-looking cab section
	_box(self, Vector3(2.85, 2.3, 2.6), Vector3(0, 2.95, -2.45), loco_red)

	# Front windscreen
	_box(self, Vector3(2.25, 0.88, 0.08), Vector3(0, 3.65, -3.78), glass)

	# Side cab windows
	for side in [-1.0, 1.0]:
		_box(self, Vector3(0.06, 0.9, 1.5), Vector3(side * 1.43, 3.5, -2.4), glass)
		_box(self, Vector3(0.06, 0.7, 1.4), Vector3(side * 1.43, 3.45, 0.0), glass)

	# Yellow safety stripe
	_box(self, Vector3(2.86, 0.18, 7.2), Vector3(0, 1.95, 0), yellow)

	# White side markings
	for side in [-1.0, 1.0]:
		_box(self, Vector3(0.035, 0.16, 5.5), Vector3(side * 1.43, 2.25, 0), loco_white)

	# Roof
	_box(self, Vector3(2.95, 0.22, 8.0), Vector3(0, 4.05, 0), dark, 0.6)

	# Roof electrical equipment
	_box(self, Vector3(0.7, 0.28, 2.0), Vector3(0, 4.3, 0.5), Color(0.3, 0.32, 0.34), 0.8)

	# Pantograph base and frame
	_box(self, Vector3(1.0, 0.12, 1.4), Vector3(0, 4.3, 1.9), dark)

	for side in [-0.42, 0.42]:
		_box(self, Vector3(0.08, 0.9, 0.08), Vector3(side, 4.78, 1.9), yellow)
		_box(self, Vector3(0.08, 0.9, 0.08), Vector3(-side, 4.78, 1.9), yellow)

	_box(self, Vector3(1.1, 0.08, 0.08), Vector3(0, 5.23, 1.9), dark)

	# Headlights and marker lights at front
	for side in [-0.85, 0.85]:
		_sphere(self, 0.19, Vector3(side, 2.65, -3.85), Color(1.0, 0.95, 0.65), true)
		_sphere(self, 0.11, Vector3(side, 2.2, -3.86), Color(1.0, 0.15, 0.05), true)

		var light := SpotLight3D.new()
		light.position = Vector3(side, 2.65, -3.9)
		light.rotation_degrees.x = -90
		light.spot_range = 90.0
		light.spot_angle = 28.0
		light.light_energy = 2.5
		add_child(light)

	# Buffers and coupler
	for side in [-0.95, 0.95]:
		_cylinder(self, 0.22, 0.3, Vector3(side, 1.45, -4.65), dark)

	_box(self, Vector3(0.3, 0.2, 0.8), Vector3(0, 1.25, -4.6), dark)

	# Bogies
	for z in [-2.8, 2.8]:
		_box(self, Vector3(2.5, 0.4, 1.8), Vector3(0, 0.95, z), Color(0.16, 0.17, 0.18))

	_wheels(self)

	# Driver camera
	cam = Camera3D.new()
	cam.position = Vector3(0, 5.7, 12.5)
	cam.rotation_degrees = Vector3(-15, 180, 0)
	cam.fov = 72.0
	add_child(cam)
	cam.current = true


func _build_coach(w: PathFollow3D, body_color: Color) -> void:
	# Underframe
	_box(w, Vector3(2.7, 0.5, 10.0), Vector3(0, 1.25, 0), dark)

	# Coach body
	_box(w, Vector3(2.8, 2.65, 9.5), Vector3(0, 2.9, 0), body_color)

	# Roof
	_box(w, Vector3(2.85, 0.18, 9.6), Vector3(0, 4.28, 0), Color(0.82, 0.83, 0.84))

	# Windows on both sides
	for side in [-1.0, 1.0]:
		for z in range(-4, 5):
			_box(w, Vector3(0.045, 0.72, 0.65), Vector3(side * 1.425, 3.25, float(z)), glass)

		# Doors
		for z in [-4.35, 4.35]:
			_box(w, Vector3(0.06, 2.1, 0.8), Vector3(side * 1.45, 2.9, z), Color(0.48, 0.5, 0.52))

		# Lower coach stripe
		_box(w, Vector3(0.04, 0.16, 9.0), Vector3(side * 1.45, 2.0, 0), yellow)

	# End windows
	_box(w, Vector3(1.0, 0.7, 0.05), Vector3(0, 3.25, -4.78), glass)
	_box(w, Vector3(1.0, 0.7, 0.05), Vector3(0, 3.25, 4.78), glass)

	# Bogies and wheels
	for z in [-3.1, 3.1]:
		_box(w, Vector3(2.45, 0.35, 1.6), Vector3(0, 0.95, z), Color(0.16, 0.17, 0.18))

		for side in [-1.2, 1.2]:
			_cylinder(w, 0.45, 0.16, Vector3(side, 0.85, z - 0.55), dark)
			_cylinder(w, 0.45, 0.16, Vector3(side, 0.85, z + 0.55), dark)


func change_camera() -> void:
	if cam == null:
		return

	camera_mode = (camera_mode + 1) % 3

	match camera_mode:
		0:
			cam.position = Vector3(0, 5.7, 12.5)
			cam.rotation_degrees = Vector3(-15, 180, 0)
		1:
			cam.position = Vector3(0, 3.7, -0.3)
			cam.rotation_degrees = Vector3(0, 180, 0)
		2:
			cam.position = Vector3(0, 8.0, -13.0)
			cam.rotation_degrees = Vector3(-12, 0, 0)


func apply_profile(profile: Dictionary) -> void:
	selected_train_name = str(profile.get("name", "Train"))
	selected_train_country = str(profile.get("country", "Worldwide"))

	var top_speed_kmh: float = float(profile.get("max_speed", 120))
	max_speed_mps = maxf(5.0, top_speed_kmh / 3.6)

	var acceleration_profile: float = float(profile.get("acceleration", 0.65))
	var brake_profile: float = float(profile.get("brake", 1.0))

	train_acceleration = clampf(acceleration_profile * 2.5, 0.5, 4.5)
	train_service_brake = clampf(brake_profile * 3.0, 1.0, 5.0)
	train_emergency_brake = train_service_brake * 1.7

	var body_color: Color = profile.get("color", Color(0.65, 0.1, 0.1))
	_apply_livery(self, body_color)
	for wagon in wagons:
		_apply_livery(wagon, body_color)


func _apply_livery(node: Node, color: Color) -> void:
	selected_body_color = color
	_repaint_body_parts(node, color)


func _repaint_body_parts(node: Node, color: Color) -> void:
	for child in node.get_children():
		if child is MeshInstance3D and child.mesh is BoxMesh:
			var old_material = child.material_override
			if old_material == null:
				old_material = child.mesh.material
			if old_material is StandardMaterial3D:
				var old_color: Color = old_material.albedo_color
				if old_color.r > 0.25 and old_color.g < 0.45 and old_color.b < 0.45:
					var material := StandardMaterial3D.new()
					material.albedo_color = color
					material.metallic = 0.3
					material.roughness = 0.42
					child.material_override = material
		_repaint_body_parts(child, color)


func set_headlights(enabled: bool) -> void:
	headlights_on = enabled
	for child in get_children():
		if child is SpotLight3D:
			child.visible = enabled


func toggle_headlights() -> void:
	set_headlights(not headlights_on)


func toggle_doors() -> void:
	door_open = not door_open


func sound_horn() -> void:
	horn_active = true


func stop_horn() -> void:
	horn_active = false


func _physics_process(delta: float) -> void:
	var throttle: bool = throttle_in or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP)
	var brake: bool = brake_in or Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN)

	if Input.is_key_pressed(KEY_H):
		horn_active = true
	else:
		horn_active = false

	if Input.is_key_pressed(KEY_L):
		if not _light_key_locked:
			toggle_headlights()
			_light_key_locked = true
	else:
		_light_key_locked = false

	if Input.is_key_pressed(KEY_E):
		emergency_brake = true

	if Input.is_key_pressed(KEY_R):
		emergency_brake = false

	if Input.is_key_pressed(KEY_C):
		if not _camera_key_locked:
			change_camera()
			_camera_key_locked = true
	else:
		_camera_key_locked = false

	var speed_ratio: float = clampf(speed / maxf(max_speed_mps, 0.1), 0.0, 1.0)
	var traction: float = train_acceleration * (1.0 - 0.55 * speed_ratio)
	var rolling_drag: float = COAST_RESISTANCE + speed * 0.018

	if emergency_brake:
		speed = move_toward(speed, 0.0, train_emergency_brake * delta)
	elif brake:
		speed = move_toward(speed, 0.0, train_service_brake * delta)
	elif throttle:
		speed = move_toward(speed, max_speed_mps, maxf(0.0, traction - rolling_drag) * delta)
	else:
		speed = move_toward(speed, 0.0, rolling_drag * delta)

	speed = clampf(speed, 0.0, max_speed_mps)
	progress = fposmod(progress + speed * delta, track_len)

	for i in range(wagons.size()):
		wagons[i].progress = fposmod(progress - (i + 1) * CAR_SPACING, track_len)

	if cam:
		cam.fov = 72.0 + speed * 0.15


var _camera_key_locked := false


func _wheels(parent: Node3D) -> void:
	var wheel_mat := StandardMaterial3D.new()
	wheel_mat.albedo_color = Color(0.12, 0.13, 0.14)
	wheel_mat.metallic = 0.65
	wheel_mat.roughness = 0.4

	var rim_mat := StandardMaterial3D.new()
	rim_mat.albedo_color = Color(0.55, 0.57, 0.59)
	rim_mat.metallic = 0.85
	rim_mat.roughness = 0.25

	for side in [-1.0, 1.0]:
		for z in [-2.8, 2.8]:
			var wheel := MeshInstance3D.new()
			var mesh := CylinderMesh.new()
			mesh.top_radius = 0.58
			mesh.bottom_radius = 0.58
			mesh.height = 0.22
			mesh.radial_segments = 24
			mesh.material = wheel_mat
			wheel.mesh = mesh
			wheel.position = Vector3(side * 1.25, 0.72, z)
			wheel.rotation_degrees.z = 90
			parent.add_child(wheel)

			var rim := MeshInstance3D.new()
			var rim_mesh := CylinderMesh.new()
			rim_mesh.top_radius = 0.25
			rim_mesh.bottom_radius = 0.25
			rim_mesh.height = 0.235
			rim_mesh.radial_segments = 20
			rim_mesh.material = rim_mat
			rim.mesh = rim_mesh
			rim.position = wheel.position
			rim.rotation_degrees.z = 90
			parent.add_child(rim)
