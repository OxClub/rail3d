extends CanvasLayer

signal train_selected(profile: Dictionary)

var selected_country := "India"
var selected_train := "wap7"
var selected_route := "mumbai_delhi"

var country_list: OptionButton
var route_list: OptionButton
var train_list: OptionButton
var info: Label

func _ready() -> void:
    _build()

func _build() -> void:
    var bg := ColorRect.new()
    bg.color = Color(0.015, 0.025, 0.05, 0.96)
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(bg)

    var center := CenterContainer.new()
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(center)

    var panel := PanelContainer.new()
    var screen_size := get_viewport().get_visible_rect().size
    panel.custom_minimum_size = Vector2(
        minf(600.0, screen_size.x - 28.0),
        minf(650.0, screen_size.y - 28.0)
    )
    center.add_child(panel)

    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 18)
    margin.add_theme_constant_override("margin_right", 18)
    margin.add_theme_constant_override("margin_top", 14)
    margin.add_theme_constant_override("margin_bottom", 14)
    panel.add_child(margin)

    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 10)
    margin.add_child(box)

    var title := Label.new()
    title.text = "WYRIX RAIL 3D"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 28)
    box.add_child(title)

    var subtitle := Label.new()
    subtitle.text = "WORLDWIDE TRAIN SIMULATOR"
    subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    subtitle.add_theme_font_size_override("font_size", 14)
    box.add_child(subtitle)

    _add_label(box, "1. SELECT COUNTRY")
    country_list = OptionButton.new()
    country_list.add_theme_font_size_override("font_size", 18)
    for country in RouteCatalog.get_countries():
        country_list.add_item(country)
    box.add_child(country_list)
    country_list.item_selected.connect(_on_country)

    _add_label(box, "2. SELECT RAILWAY ROUTE")
    route_list = OptionButton.new()
    route_list.add_theme_font_size_override("font_size", 17)
    box.add_child(route_list)
    route_list.item_selected.connect(_on_route)

    _add_label(box, "3. SELECT TRAIN")
    train_list = OptionButton.new()
    train_list.add_theme_font_size_override("font_size", 17)
    box.add_child(train_list)
    train_list.item_selected.connect(_on_train)

    info = Label.new()
    info.custom_minimum_size.y = 110
    info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    info.add_theme_font_size_override("font_size", 15)
    box.add_child(info)

    var spacer := Control.new()
    spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
    box.add_child(spacer)

    var start := Button.new()
    start.text = "START JOURNEY"
    start.custom_minimum_size.y = 56
    start.add_theme_font_size_override("font_size", 22)
    box.add_child(start)
    start.pressed.connect(_start)

    _refresh_routes()
    _refresh_trains()

func _add_label(parent: VBoxContainer, text_value: String) -> void:
    var label := Label.new()
    label.text = text_value
    label.add_theme_font_size_override("font_size", 15)
    parent.add_child(label)

func _on_country(index: int) -> void:
    selected_country = country_list.get_item_text(index)
    _refresh_routes()
    _refresh_trains()

func _refresh_routes() -> void:
    route_list.clear()
    var routes := RouteCatalog.get_routes(selected_country)
    for route in routes:
        route_list.add_item(route["name"])
    if not routes.is_empty():
        selected_route = routes[0]["id"]

func _on_route(index: int) -> void:
    var routes := RouteCatalog.get_routes(selected_country)
    if index >= 0 and index < routes.size():
        selected_route = routes[index]["id"]
        _update_info()

func _refresh_trains() -> void:
    train_list.clear()
    var trains := TrainCatalog.get_country_trains(selected_country)
    for train in trains:
        train_list.add_item(train["name"])
    if not trains.is_empty():
        selected_train = trains[0]["id"]
    _update_info()

func _on_train(index: int) -> void:
    var trains := TrainCatalog.get_country_trains(selected_country)
    if index >= 0 and index < trains.size():
        selected_train = trains[index]["id"]
        _update_info()

func _update_info() -> void:
    var train := TrainCatalog.get_train(selected_train)
    var route := RouteCatalog.get_route(selected_route)
    info.text = "%s | %s\n%s\nDistance: %d km | %s\nTerrain: %s\nTop speed: %d km/h" % [
        route["country"], route["type"], route["name"],
        route["distance"], route["weather"],
        route["terrain"], train["max_speed"]
    ]

func _start() -> void:
    var profile := TrainCatalog.get_train(selected_train)
    profile["route"] = RouteCatalog.get_route(selected_route)
    train_selected.emit(profile)
    queue_free()
