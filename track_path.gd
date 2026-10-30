extends Path3D

const GAUGE := 0.75
var length := 0.0

func _ready() -> void:
	var n := 160
	var pts: Array[Vector3] = []
	for i in n:
		var t := TAU * float(i) / n
		var r := 1.0 + 0.12 * sin(3.0 * t) + 0.06 * cos(5.0 * t)
		pts.append(Vector3(130.0 * r * cos(t), 0.0, 80.0 * r * sin(t)))
	curve = Curve3D.new()
	curve.bake_interval = 1.0
	for i in n:
		var h := (pts[(i + 1) % n] - pts[(i - 1 + n) % n]) / 6.0
		curve.add_point(pts[i], -h, h)
	var h0 := (pts[1] - pts[n - 1]) / 6.0
	curve.add_point(pts[0], -h0, h0)
	length = curve.get_baked_length()
	_build()

func frame_at(d: float) -> Transform3D:
	d = fposmod(d, length)
	var p := curve.sample_baked(d)
	var a := curve.sample_baked(fposmod(d - 0.5, length))
	var b := curve.sample_baked(fposmod(d + 0.5, length))
	var fwd := (b - a).normalized()
	return Transform3D(Basis.looking_at(fwd, Vector3.UP), p)

func _build() -> void:
	var ballast: Array[Transform3D] = []
	var sleepers: Array[Transform3D] = []
	var rails: Array[Transform3D] = []
	for i in int(length):
		var f := frame_at(float(i))
		var b := f.basis
		var o := f.origin
		ballast.append(Transform3D(b, o + Vector3(0, 0.1, 0)))
		sleepers.append(Transform3D(b, o + Vector3(0, 0.26, 0)))
		rails.append(Transform3D(b, o + b.x * GAUGE + Vector3(0, 0.4, 0)))
		rails.append(Transform3D(b, o - b.x * GAUGE + Vector3(0, 0.4, 0)))
	_multi(Vector3(3.6, 0.2, 1.05), Color(0.38, 0.36, 0.34), ballast, 0.0, 1.0)
	_multi(Vector3(2.6, 0.12, 0.35), Color(0.25, 0.16, 0.1), sleepers, 0.0, 1.0)
	_multi(Vector3(0.1, 0.16, 1.1), Color(0.75, 0.75, 0.78), rails, 0.8, 0.25)

func _multi(size: Vector3, color: Color, xf: Array[Transform3D], metal: float, rough: float) -> void:
	var bm := BoxMesh.new()
	bm.size = size
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.metallic = metal
	m.roughness = 1.0 - metal * 0.6 if rough >= 1.0 else rough
	bm.material = m
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = bm
	mm.instance_count = xf.size()
	for i in xf.size():
		mm.set_instance_transform(i, xf[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	add_child(mmi)
