extends CanvasLayer

var train: Node
var mission: Node
var speed_label: Label
var status_label: Label
var train_label: Label
var route_label: Label
var throttle_button: Button
var brake_button: Button
var horn_button: Button
var light_button: Button
var camera_button: Button
var emergency_button: Button
var throttle_pressed := false
var brake_pressed := false


func setup(train_node: Node, mission_node: Node) -> void:
        train = train_node
        mission = mission_node
        _build_ui()


func _panel(parent: Node, title: String, pos: Vector2, size: Vector2) -> PanelContainer:
        var panel := PanelContainer.new()
        panel.position = pos
        panel.size = size
        parent.add_child(panel)
        return panel


func _build_ui() -> void:
        var root := Control.new()
        root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        add_child(root)

        var top := PanelContainer.new()
        top.position = Vector2(12, 12)
        top.custom_minimum_size = Vector2(310, 112)
        root.add_child(top)

        var info := VBoxContainer.new()
        top.add_child(info)

        train_label = Label.new()
        train_label.text = str(train.get("selected_train_name"))
        train_label.add_theme_font_size_override("font_size", 19)
        info.add_child(train_label)

        route_label = Label.new()
        route_label.text = "WORLDWIDE RAIL SIMULATOR"
        info.add_child(route_label)

        speed_label = Label.new()
        speed_label.text = "0 km/h"
        speed_label.add_theme_font_size_override("font_size", 28)
        info.add_child(speed_label)

        status_label = Label.new()
        status_label.text = "READY"
        info.add_child(status_label)

        var controls := HBoxContainer.new()
        controls.anchor_left = 0.0
        controls.anchor_right = 1.0
        controls.anchor_top = 1.0
        controls.anchor_bottom = 1.0
        controls.offset_left = 8
        controls.offset_right = -8
        controls.offset_top = -92
        controls.offset_bottom = -8
        controls.alignment = BoxContainer.ALIGNMENT_CENTER
        controls.add_theme_constant_override("separation", 8)
        root.add_child(controls)

        throttle_button = _make_button("ACCELERATE", controls)
        throttle_button.button_down.connect(_throttle_down)
        throttle_button.button_up.connect(_throttle_up)

        brake_button = _make_button("BRAKE", controls)
        brake_button.button_down.connect(_brake_down)
        brake_button.button_up.connect(_brake_up)

        emergency_button = _make_button("EMERGENCY", controls)
        emergency_button.pressed.connect(_emergency)

        horn_button = _make_button("HORN", controls)
        horn_button.button_down.connect(_horn_down)
        horn_button.button_up.connect(_horn_up)

        camera_button = _make_button("CAMERA", controls)
        camera_button.pressed.connect(_camera)

        light_button = _make_button("LIGHTS", controls)
        light_button.pressed.connect(_lights)


func _make_button(caption: String, parent: Node) -> Button:
        var b := Button.new()
        b.text = caption
        b.custom_minimum_size = Vector2(92, 58)
        b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        b.add_theme_font_size_override("font_size", 13)
        parent.add_child(b)
        return b


func _throttle_down() -> void:
        if train:
                train.throttle_in = true


func _throttle_up() -> void:
        if train:
                train.throttle_in = false


func _brake_down() -> void:
        if train:
                train.brake_in = true


func _brake_up() -> void:
        if train:
                train.brake_in = false


func _emergency() -> void:
        if train:
                train.emergency_brake = not train.emergency_brake


func _horn_down() -> void:
        if train and train.has_method("sound_horn"):
                train.sound_horn()


func _horn_up() -> void:
        if train and train.has_method("stop_horn"):
                train.stop_horn()


func _camera() -> void:
        if train and train.has_method("change_camera"):
                train.change_camera()


func _lights() -> void:
        if train and train.has_method("toggle_headlights"):
                train.toggle_headlights()


func _process(_delta: float) -> void:
        if not is_instance_valid(train):
                return

        var kmh := float(train.get("speed")) * 3.6
        speed_label.text = "%.0f km/h" % kmh

        if train.get("emergency_brake"):
                status_label.text = "EMERGENCY BRAKE"
        elif train.get("brake_in"):
                status_label.text = "BRAKING"
        elif train.get("throttle_in"):
                status_label.text = "POWER ON"
        else:
                status_label.text = "COASTING"

        train_label.text = str(train.get("selected_train_name"))
