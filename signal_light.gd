extends Node3D

signal violated

var track_pos := 0.0
var track_len := 1.0
var is_red := false
var period := 8.0
var _t := 0.0
var _prev_d := 1.0
var _red_mat: StandardMaterial3D
var _green_mat: StandardMaterial3D

func setup(track, pos: float, start_red: bool, p: float) -> void:
	track_pos = pos
	track_len = track.length
	is_red = start_red
	period = p
	var f: Transform3D = track.frame_at(pos)
	transform = Transform3D(f.basis, f.origin + f.basis.x * 3.6)
	_build()
	_apply()

func _part(mesh: Mesh, pos: Vector3) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos
	add_child(mi)

func _build() -> void:
	var gray := StandardMaterial3D.new()
	gray.albedo_color = Color(0.3, 0.3, 0.33)
	var pole := CylinderMesh.new()
	pole.top_radius = 0.1
	pole.bottom_radius = 0.12
	pole.height = 5.0
	pole.material = gray
	_part(pole, Vector3(0, 2.5, 0))
	var head := BoxMesh.new()
	head.size = Vector3(0.8, 1.7, 0.4)
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.05, 0.05, 0.06)
	head.material = dark
	_part(head, Vector3(0, 5.4, 0))
	_red_mat = StandardMaterial3D.new()
	_green_mat = StandardMaterial3D.new()
	_red_mat.emission_energy_multiplier = 4.0
	_green_mat.emission_energy_multiplier = 4.0
	var rl := SphereMesh.new()
	rl.radius = 0.28
	rl.height = 0.56
	rl.material = _red_mat
	_part(rl, Vector3(0, 5.8, 0.22))
	var gl := SphereMesh.new()
	gl.radius = 0.28
	gl.height = 0.56
	gl.material = _green_mat
	_part(gl, Vector3(0, 5.0, 0.22))

func _apply() -> void:
	_red_mat.albedo_color = Color(1, 0.1, 0.1) if is_red else Color(0.25, 0.03, 0.03)
	_red_mat.emission_enabled = is_red
	_red_mat.emission = Color(1, 0.1, 0.1)
	_green_mat.albedo_color = Color(0.1, 1, 0.3) if not is_red else Color(0.03, 0.2, 0.06)
	_green_mat.emission_enabled = not is_red
	_green_mat.emission = Color(0.1, 1, 0.3)

func _process(delta: float) -> void:
	_t += delta
	if _t >= period:
		_t = 0.0
		is_red = not is_red
		_apply()

func check(p: float, speed: float) -> void:
	var d := wrapf(p - track_pos, -track_len * 0.5, track_len * 0.5)
	if _prev_d < 0.0 and d >= 0.0 and absf(d) < 5.0 and is_red and speed > 1.0:
		violated.emit()
	_prev_d = d
