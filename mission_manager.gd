extends Node

signal message(text: String)

const STATION_NAMES := ["Wyrix Central", "Green Valley", "Lake Side", "Hill Top"]
const STATION_FRACS := [0.12, 0.36, 0.60, 0.84]
const STOP_RADIUS := 7.0

var track
var train
var signals: Array = []
var stations: Array = []
var current := 0
var score := 0
var dwell := 0.0
var time_left := 60.0
var red_warning := false
var next_name := ""
var next_dist := 0.0

func setup(t, tr, sigs: Array) -> void:
	track = t
	train = tr
	signals = sigs
	for i in STATION_NAMES.size():
		var pos: float = STATION_FRACS[i] * track.length
		stations.append({"name": STATION_NAMES[i], "pos": pos})
		_platform(pos, STATION_NAMES[i])
	for s in signals:
		s.violated.connect(_on_violation)
	_start_leg()
	message.emit("Stop at %s. Hold GAS / BRAKE (or W / S)" % stations[0].name)

func _box(size: Vector3, pos: Vector3, basis: Basis, color: Color) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	bm.material = m
	mi.mesh = bm
	mi.transform = Transform3D(basis, pos)
	track.add_child(mi)

func _platform(pos: float, nm: String) -> void:
	var f: Transform3D = track.frame_at(pos)
	var b := f.basis
	var o := f.origin + b.x * 5.2
	_box(Vector3(5.0, 0.7, 28.0), o + Vector3(0, 0.35, 0), b, Color(0.7, 0.7, 0.72))
	_box(Vector3(5.4, 0.2, 24.0), o + Vector3(0, 4.2, 0), b, Color(0.15, 0.2, 0.3))
	for z in [-10.0, 10.0]:
		_box(Vector3(0.3, 3.5, 0.3), o + b.z * z + Vector3(0, 2.4, 0), b, Color(0.3, 0.3, 0.33))
	var lb := Label3D.new()
	lb.text = nm
	lb.font_size = 96
	lb.pixel_size = 0.02
	lb.outline_size = 16
	lb.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lb.position = o + Vector3(0, 6.0, 0)
	track.add_child(lb)

func _start_leg() -> void:
	var st = stations[current]
	var dist: float = fposmod(st.pos - train.progress, track.length)
	time_left = 20.0 + dist / 14.0

func _on_violation() -> void:
	score = maxi(score - 50, 0)
	message.emit("Red signal passed!  -50")

func _arrive() -> void:
	var bonus := 100 + int(maxf(time_left, 0.0) * 2.0)
	score += bonus
	message.emit("Arrived at %s  +%d" % [stations[current].name, bonus])
	current = (current + 1) % stations.size()
	dwell = 0.0
	_start_leg()
	if current == 0:
		message.emit("Route complete! Score %d. Next lap starts." % score)

func _process(delta: float) -> void:
	if stations.is_empty():
		return
	var st = stations[current]
	var p: float = train.progress
	var d: float = wrapf(p - st.pos, -track.length * 0.5, track.length * 0.5)
	next_dist = fposmod(st.pos - p, track.length)
	next_name = st.name
	time_left -= delta
	red_warning = false
	for s in signals:
		s.check(p, train.speed)
		var ahead: float = fposmod(s.track_pos - p, track.length)
		if s.is_red and ahead < 90.0 and ahead > 2.0:
			red_warning = true
	if absf(d) <= STOP_RADIUS and train.speed < 0.8:
		dwell += delta
		if dwell >= 2.5:
			_arrive()
	else:
		dwell = 0.0
	if time_left <= 0.0:
		score = maxi(score - 30, 0)
		message.emit("Late!  -30")
		time_left = 25.0
