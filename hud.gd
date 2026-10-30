extends CanvasLayer

var train
var mission
var speed_lbl: Label
var mission_lbl: Label
var score_lbl: Label
var msg_lbl: Label
var warn_lbl: Label
var _msg_t := 0.0

func _label(size: int, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", Color.WHITE)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("outline_size", 6)
	l.horizontal_alignment = align
	add_child(l)
	return l

func _place(c: Control, preset: Control.LayoutPreset, l: float, t: float, r: float, b: float) -> void:
	c.set_anchors_preset(preset)
	c.offset_left = l
	c.offset_top = t
	c.offset_right = r
	c.offset_bottom = b

func _btn(text: String, color: Color) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", 34)
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(26)
	var sp: StyleBoxFlat = sb.duplicate()
	sp.bg_color = color.lightened(0.3)
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", sb)
	b.add_theme_stylebox_override("pressed", sp)
	add_child(b)
	return b

func setup(tr, ms) -> void:
	train = tr
	mission = ms
	mission.message.connect(show_msg)
	mission_lbl = _label(30)
	_place(mission_lbl, Control.PRESET_TOP_LEFT, 24, 16, 700, 120)
	score_lbl = _label(36, HORIZONTAL_ALIGNMENT_RIGHT)
	_place(score_lbl, Control.PRESET_TOP_RIGHT, -420, 16, -24, 70)
	msg_lbl = _label(34, HORIZONTAL_ALIGNMENT_CENTER)
	_place(msg_lbl, Control.PRESET_CENTER_TOP, -450, 130, 450, 190)
	msg_lbl.visible = false
	warn_lbl = _label(36, HORIZONTAL_ALIGNMENT_CENTER)
	warn_lbl.text = "RED SIGNAL AHEAD - BRAKE!"
	warn_lbl.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	_place(warn_lbl, Control.PRESET_CENTER_TOP, -450, 200, 450, 260)
	warn_lbl.visible = false
	speed_lbl = _label(54, HORIZONTAL_ALIGNMENT_CENTER)
	_place(speed_lbl, Control.PRESET_CENTER_BOTTOM, -200, -110, 200, -20)
	var brake := _btn("BRAKE", Color(0.75, 0.15, 0.15, 0.85))
	_place(brake, Control.PRESET_BOTTOM_LEFT, 30, -170, 230, -30)
	brake.button_down.connect(func(): train.brake_in = true)
	brake.button_up.connect(func(): train.brake_in = false)
	var gas := _btn("GAS", Color(0.15, 0.6, 0.3, 0.85))
	_place(gas, Control.PRESET_BOTTOM_RIGHT, -230, -170, -30, -30)
	gas.button_down.connect(func(): train.throttle_in = true)
	gas.button_up.connect(func(): train.throttle_in = false)

func show_msg(text: String) -> void:
	msg_lbl.text = text
	msg_lbl.visible = true
	_msg_t = 3.5

func _process(delta: float) -> void:
	if train == null or speed_lbl == null:
		return
	speed_lbl.text = "%d km/h" % int(train.speed * 3.6)
	mission_lbl.text = "Next: %s  %d m\nTime: %d s" % [mission.next_name, int(mission.next_dist), int(maxf(mission.time_left, 0.0))]
	score_lbl.text = "Score %d" % mission.score
	warn_lbl.visible = mission.red_warning
	if _msg_t > 0.0:
		_msg_t -= delta
		if _msg_t <= 0.0:
			msg_lbl.visible = false
