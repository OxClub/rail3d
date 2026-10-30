extends Node3D
class_name WorldwideTrainModels

const PROFILES := {
	"wap7": {
		"name": "Indian WAP-7",
		"type": "electric",
		"color": Color(0.12, 0.32, 0.72),
		"stripe": Color(1.0, 0.75, 0.08),
		"length": 16.0,
		"height": 4.2
	},
	"vande_bharat": {
		"name": "Vande Bharat",
		"type": "highspeed",
		"color": Color(0.88, 0.90, 0.92),
		"stripe": Color(0.0, 0.48, 0.65),
		"length": 20.0,
		"height": 4.0
	},
	"n700": {
		"name": "Japan N700 Shinkansen",
		"type": "bullet",
		"color": Color(0.91, 0.93, 0.94),
		"stripe": Color(0.0, 0.45, 0.72),
		"length": 25.0,
		"height": 3.8
	},
	"e5": {
		"name": "Japan E5 Hayabusa",
		"type": "bullet",
		"color": Color(0.05, 0.48, 0.35),
		"stripe": Color(0.85, 0.85, 0.87),
		"length": 25.0,
		"height": 3.8
	},
	"ice3": {
		"name": "Germany ICE 3",
		"type": "bullet",
		"color": Color(0.88, 0.90, 0.92),
		"stripe": Color(0.65, 0.04, 0.08),
		"length": 25.0,
		"height": 3.8
	},
	"tgv": {
		"name": "France TGV",
		"type": "bullet",
		"color": Color(0.12, 0.15, 0.20),
		"stripe": Color(0.90, 0.43, 0.08),
		"length": 25.0,
		"height": 3.9
	},
	"acela": {
		"name": "USA Acela",
		"type": "highspeed",
		"color": Color(0.10, 0.13, 0.18),
		"stripe": Color(0.75, 0.08, 0.10),
		"length": 21.0,
		"height": 4.0
	},
	"sd70": {
		"name": "USA SD70ACe",
		"type": "diesel",
		"color": Color(0.12, 0.32, 0.20),
		"stripe": Color(0.90, 0.75, 0.08),
		"length": 18.0,
		"height": 4.5
	},
	"cr400": {
		"name": "China CR400 Fuxing",
		"type": "bullet",
		"color": Color(0.92, 0.92, 0.94),
		"stripe": Color(0.70, 0.04, 0.08),
		"length": 25.0,
		"height": 3.8
	},
	"re460": {
		"name": "Swiss Re 460",
		"type": "electric",
		"color": Color(0.80, 0.05, 0.08),
		"stripe": Color(0.90, 0.90, 0.90),
		"length": 17.0,
		"height": 4.2
	}
}

var train_root: Node3D
var train_profile: Dictionary


func create_train(train_id: String, coach_count := 5) -> Node3D:
	train_profile = PROFILES.get(train_id, PROFILES["wap7"])
	train_root = Node3D.new()
	train_root.name = str(train_profile.name).replace(" ", "_")

	_build_locomotive()
	for i in range(coach_count):
		_build_coach(float(i + 1) * 11.0)

	return train_root


func mat(color: Color, metal := 0.15, rough := 0.4) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.metallic = metal
	m.roughness = rough
	return m


func box(parent: Node3D, size: Vector3, pos: Vector3,
		color: Color, bevel := false) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = mat(color)
	var obj := MeshInstance3D.new()
	obj.mesh = mesh
	obj.position = pos
	parent.add_child(obj)
	return obj


func cylinder(parent: Node3D, radius: float, height: float,
		pos: Vector3, color: Color) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 24
	mesh.material = mat(color, 0.75, 0.3)
	var obj := MeshInstance3D.new()
	obj.mesh = mesh
	obj.position = pos
	obj.rotation_degrees.z = 90
	parent.add_child(obj)


func _build_locomotive() -> void:
	var color: Color = train_profile.color
	var stripe: Color = train_profile.stripe
	var length: float = train_profile.length
	var height: float = train_profile.height
	var kind: String = train_profile.type

	# Main locomotive body
	box(train_root, Vector3(2.8, height - 0.5, length),
		Vector3(0, height / 2.0 + 0.3, 0), color)

	# Roof
	box(train_root, Vector3(2.65, 0.25, length - 0.4),
		Vector3(0, height + 0.35, 0), Color(0.18, 0.19, 0.21))

	# Front nose
	if kind == "bullet" or kind == "highspeed":
		var nose := SphereMesh.new()
		nose.radius = 1.4
		nose.height = 2.7
		nose.radial_segments = 32
		nose.rings = 16
		nose.material = mat(color)
		var nose_obj := MeshInstance3D.new()
		nose_obj.mesh = nose
		nose_obj.scale = Vector3(1.0, 0.9, 1.9)
		nose_obj.position = Vector3(0, height / 2.0 + 0.3, -length / 2.0)
		train_root.add_child(nose_obj)
	else:
		box(train_root, Vector3(2.55, 1.1, 0.7),
			Vector3(0, 1.0, -length / 2.0 - 0.2), color)

	# Side stripe
	for side in [-1.0, 1.0]:
		box(train_root, Vector3(0.045, 0.25, length - 1.0),
			Vector3(side * 1.42, 1.75, 0), stripe)

		# Cab windows
		box(train_root, Vector3(0.06, 0.85, 2.0),
			Vector3(side * 1.43, height - 0.8, -length / 2.0 + 3.0),
			Color(0.025, 0.10, 0.16))

		# Side vents
		for z in [-3.0, -1.5, 1.5, 3.0]:
			box(train_root, Vector3(0.055, 0.65, 0.12),
				Vector3(side * 1.43, 2.7, z),
				Color(0.09, 0.10, 0.11))

	# Front windscreen
	box(train_root, Vector3(1.8, 0.85, 0.07),
		Vector3(0, height - 0.75, -length / 2.0 - 0.38),
		Color(0.015, 0.07, 0.12))

	# Headlights
	for x in [-0.9, 0.9]:
		var light := OmniLight3D.new()
		light.position = Vector3(x, 1.7, -length / 2.0 - 0.5)
		light.light_color = Color(1.0, 0.85, 0.55)
		light.light_energy = 2.0
		light.omni_range = 18.0
		train_root.add_child(light)

	# Bogies and wheels
	for z in [-length * 0.32, length * 0.32]:
		box(train_root, Vector3(2.2, 0.45, 2.2),
			Vector3(0, 0.75, z), Color(0.15, 0.16, 0.17))
		for side in [-1.0, 1.0]:
			for offset in [-0.7, 0.7]:
				cylinder(train_root, 0.55, 0.20,
					Vector3(side * 1.42, 0.65, z + offset),
					Color(0.08, 0.09, 0.10))

	# Electric pantograph
	if kind == "electric" or kind == "bullet":
		_build_pantograph()


func _build_pantograph() -> void:
	for z in [-1.8, 1.8]:
		cylinder(train_root, 0.08, 1.1,
			Vector3(0, train_profile.height + 0.95, z),
			Color(0.16, 0.17, 0.18))
		box(train_root, Vector3(1.8, 0.08, 0.08),
			Vector3(0, train_profile.height + 1.5, z),
			Color(0.16, 0.17, 0.18))


func _build_coach(offset: float) -> void:
	var color: Color = train_profile.color
	var stripe: Color = train_profile.stripe

	box(train_root, Vector3(2.65, 3.0, 9.5),
		Vector3(0, 2.0, offset + 5.5), color)

	box(train_root, Vector3(2.68, 0.18, 9.6),
		Vector3(0, 3.62, offset + 5.5),
		Color(0.16, 0.17, 0.19))

	for side in [-1.0, 1.0]:
		box(train_root, Vector3(0.05, 0.22, 9.2),
			Vector3(side * 1.35, 1.55, offset + 5.5), stripe)

		for i in range(6):
			var z := offset + 1.8 + float(i) * 1.4
			box(train_root, Vector3(0.06, 0.85, 0.9),
				Vector3(side * 1.37, 2.65, z),
				Color(0.025, 0.10, 0.15))

		for z in [offset + 2.0, offset + 8.8]:
			cylinder(train_root, 0.48, 0.18,
				Vector3(side * 1.38, 0.65, z),
				Color(0.07, 0.08, 0.09))

