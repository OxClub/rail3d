extends Node3D

const STATIONS := [
	{"name": "WYRiX CENTRAL", "hindi": "वाइरिक्स सेंट्रल", "pos": 0.12},
	{"name": "GREEN VALLEY", "hindi": "ग्रीन वैली", "pos": 0.36},
	{"name": "LAKE SIDE", "hindi": "लेक साइड", "pos": 0.60},
	{"name": "HILL TOP", "hindi": "हिल टॉप", "pos": 0.84}
]

var track


func _material(color: Color, metallic := 0.0, emission := false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.metallic = metallic
	m.roughness = 0.8
	if emission:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = 1.5
	return m


func _box(parent: Node3D, size: Vector3, pos: Vector3, basis: Basis, color: Color) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = _material(color)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.transform = Transform3D(basis, pos)
	parent.add_child(mi)
	return mi


func _cylinder(parent: Node3D, radius: float, height: float, pos: Vector3, color: Color) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.material = _material(color, 0.25)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos
	parent.add_child(mi)


func _label(parent: Node3D, text: String, pos: Vector3, color: Color, size := 64) -> void:
	var l := Label3D.new()
	l.text = text
	l.position = pos
	l.font_size = size
	l.pixel_size = 0.025
	l.modulate = color
	l.outline_size = 10
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	parent.add_child(l)


func setup(t) -> void:
	track = t
	for station in STATIONS:
		_station(float(station.pos), str(station.name), str(station.hindi))
	_level_crossing(track.length * 0.48)
	_track_markers()


func _station(frac: float, station_name: String, hindi_name: String) -> void:
	var f: Transform3D = track.frame_at(frac * track.length)
	var b := f.basis
	var o := f.origin

	# Station building on the opposite side of the platform
	var center := o - b.x * 13.0

	_box(self, Vector3(17, 5.5, 25), center + Vector3(0, 3.0, 0), b, Color(0.82, 0.76, 0.61))
	_box(self, Vector3(18, 0.45, 26), center + Vector3(0, 5.9, 0), b, Color(0.48, 0.16, 0.09))

	# Entrance and windows
	_box(self, Vector3(4, 3.2, 0.18), center + b.z * 12.6 + Vector3(0, 1.9, 0), b, Color(0.22, 0.3, 0.35))
	for z in [-8.0, -3.0, 3.0, 8.0]:
		_box(self, Vector3(0.12, 1.5, 2.5), center + b.z * z + Vector3(8.56, 3.0, 0), b, Color(0.12, 0.3, 0.4))

	# Main station sign
	_box(self, Vector3(12, 1.7, 0.35), center + Vector3(0, 7.2, 0), b, Color(0.04, 0.35, 0.16))
	_label(self, station_name, center + Vector3(0, 7.3, 0.25), Color.WHITE, 58)
	_label(self, hindi_name, center + Vector3(0, 6.65, 0.25), Color(1.0, 0.85, 0.25), 42)

	# Platform lamps and shelter pillars
	var platform_center := o + b.x * 7.0
	for z in [-13.0, 0.0, 13.0]:
		var p: Vector3 = platform_center + b.z * z
		_cylinder(self, 0.11, 6.0, p + Vector3(0, 3.0, 0), Color(0.25, 0.27, 0.29))
		_box(self, Vector3(0.8, 0.18, 0.8), p + Vector3(0, 6.1, 0), b, Color(1.0, 0.88, 0.55))
		_box(self, Vector3(0.25, 3.0, 0.25), p + b.x * 3.0 + Vector3(0, 1.5, 0), b, Color(0.35, 0.36, 0.37))

	# Benches
	for z in [-8.0, 8.0]:
		var p: Vector3 = platform_center + b.z * z + b.x * 2.0
		_box(self, Vector3(2.4, 0.18, 0.65), p + Vector3(0, 1.0, 0), b, Color(0.3, 0.2, 0.12))
		_box(self, Vector3(2.4, 0.75, 0.15), p + Vector3(0, 1.4, 0.25), b, Color(0.3, 0.2, 0.12))


func _level_crossing(pos: float) -> void:
	var f: Transform3D = track.frame_at(pos)
	var b := f.basis
	var o := f.origin

	# Road crossing the railway
	_box(self, Vector3(19, 0.16, 10), o + Vector3(0, 0.12, 0), b, Color(0.12, 0.12, 0.13))

	# White road markings
	for x in [-7.0, -3.5, 3.5, 7.0]:
		_box(self, Vector3(0.18, 0.04, 8.0), o + b.x * x + Vector3(0, 0.23, 0), b, Color.WHITE)

	for side in [-1.0, 1.0]:
		var pole_pos: Vector3 = o + b.x * side * 9.0
		_cylinder(self, 0.16, 3.0, pole_pos + Vector3(0, 1.5, 0), Color(0.9, 0.82, 0.08))

		# Crossing barrier
		_box(self, Vector3(0.18, 0.16, 7.0), pole_pos + b.z * 3.0 + Vector3(0, 2.8, 0), b, Color(0.9, 0.08, 0.06))

		# Warning board
		_box(self, Vector3(1.5, 1.3, 0.2), pole_pos + b.z * 5.0 + Vector3(0, 3.5, 0), b, Color(0.9, 0.75, 0.05))
		_label(self, "STOP", pole_pos + b.z * 5.0 + Vector3(0, 3.5, 0.15), Color.BLACK, 48)


func _track_markers() -> void:
	for i in range(1, 9):
		var pos: float = track.length * float(i) / 9.0
		var f: Transform3D = track.frame_at(pos)
		var b := f.basis
		var o := f.origin + b.x * 4.0

		_box(self, Vector3(0.65, 1.3, 0.25), o + Vector3(0, 0.65, 0), b, Color(0.88, 0.84, 0.68))
		_label(self, "%d KM" % (i * 2), o + Vector3(0, 0.75, 0.2), Color.BLACK, 28)
