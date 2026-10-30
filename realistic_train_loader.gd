extends Node3D

@export var model_path := "res://assets/trains/electric-locomotive.glb"
@export var model_scale := 1.0
@export var model_position := Vector3(3.4, 0.0, 0.0)
@export var model_rotation := Vector3.ZERO

var imported_model: Node3D


func load_train_model(target: Node3D) -> bool:
	if not ResourceLoader.exists(model_path):
		push_warning("Train model missing: " + model_path)
		return false

	var packed := load(model_path) as PackedScene
	if packed == null:
		push_error("Could not load train GLB.")
		return false

	imported_model = packed.instantiate() as Node3D
	if imported_model == null:
		push_error("GLB root is not Node3D.")
		return false

	target.add_child(imported_model)
	imported_model.position = model_position
	imported_model.rotation_degrees = model_rotation
	imported_model.scale = Vector3.ONE * model_scale

	# Imported GLB uses its own PBR materials.
	return true
