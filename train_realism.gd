extends Node3D

var train: Node3D

func setup(target: Node3D) -> void:
	train = target
	_add_roof_details()
	_add_front_details()
	_add_side_details()


func material(color: Color, metallic := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.metallic = metallic
	m.roughness = 0.35
	return m


func box(parent: Node3D, size: Vector3, pos: Vector3, color: Color) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = material(color, 0.25)
	var obj := MeshInstance3D.new()
	obj.mesh = mesh
	obj.position = pos
	parent.add_child(obj)


func _add_roof_details() -> void:
	# Roof equipment and ventilation
	for z in [-1.8, 0.0, 1.8]:
		box(self, Vector3(0.75, 0.25, 1.1),
			Vector3(3.4, 4.2, z), Color(0.19, 0.20, 0.22))

	# Roof antenna
	var antenna := MeshInstance3D.new()
	var antenna_mesh := CylinderMesh.new()
	antenna_mesh.top_radius = 0.025
	antenna_mesh.bottom_radius = 0.04
	antenna_mesh.height = 1.0
	antenna_mesh.material = material(Color(0.12, 0.13, 0.14), 0.7)
	antenna.mesh = antenna_mesh
	antenna.position = Vector3(3.4, 4.8, 0)
	add_child(antenna)


func _add_front_details() -> void:
	# Front lamps
	for y in [2.3, 3.25]:
		var lamp := OmniLight3D.new()
		lamp.position = Vector3(3.4, y, -4.15)
		lamp.light_color = Color(1.0, 0.82, 0.48)
		lamp.light_energy = 1.5
		lamp.omni_range = 15.0
		add_child(lamp)

	# Front bumper and couplers
	box(self, Vector3(1.8, 0.25, 0.35),
		Vector3(3.4, 1.25, -4.25), Color(0.12, 0.12, 0.13))
	box(self, Vector3(0.35, 0.35, 0.8),
		Vector3(3.4, 1.1, -4.5), Color(0.20, 0.20, 0.21))


func _add_side_details() -> void:
	# Side ventilation grills
	for side in [-1.0, 1.0]:
		for z in [-2.0, -1.4, 1.4, 2.0]:
			box(self, Vector3(0.06, 0.75, 0.12),
				Vector3(3.4 + side * 1.38, 2.8, z),
				Color(0.08, 0.09, 0.10))

		# Side steps
		for z in [-2.5, 2.5]:
			box(self, Vector3(0.45, 0.12, 0.8),
				Vector3(3.4 + side * 1.48, 0.85, z),
				Color(0.25, 0.26, 0.27))
