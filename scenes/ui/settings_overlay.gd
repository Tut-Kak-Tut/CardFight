class_name SettingsOverlay extends Control

signal closed


static func _box(bg: Color, border: int, border_col: Color, radius: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_border_width_all(border)
	sb.border_color = border_col
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	return sb


static func style_panel(p: Control) -> void:
	var sb := _box(Color("#14161f"), 3, Color("#c9a24b"), 16)
	sb.set_content_margin_all(0)
	p.add_theme_stylebox_override("panel", sb)


static func style_button(b: Button) -> void:
	var gold := Color("#c9a24b")
	b.add_theme_stylebox_override("normal", _box(Color("#2b2f40"), 2, gold, 10))
	b.add_theme_stylebox_override("hover", _box(Color("#3b4258"), 2, gold, 10))
	b.add_theme_stylebox_override("pressed", _box(Color("#3b4258"), 2, gold, 10))
	b.add_theme_stylebox_override("focus", _box(Color("#2b2f40"), 2, gold, 10))
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(c, Color("#e8e2d0"))


static func open(parent: Node) -> SettingsOverlay:
	var o := SettingsOverlay.new()
	parent.add_child(o)
	return o


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 100


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.85)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(800, 0)
	style_panel(panel)
	center.add_child(panel)

	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 40)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 30)
	margin.add_child(box)

	var title := Label.new()
	title.text = "Settings"
	title.add_theme_font_size_override("font_size", 56)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	box.add_child(_toggle("Sound", "sound"))
	box.add_child(_toggle("Vibration", "vibration"))

	var back := Button.new()
	back.text = "Back"
	back.add_theme_font_size_override("font_size", 44)
	back.custom_minimum_size = Vector2(0, 110)
	style_button(back)
	back.pressed.connect(_on_back)
	box.add_child(back)


func _toggle(label: String, key: String) -> Button:
	var c := Button.new()
	c.toggle_mode = true
	c.add_theme_font_size_override("font_size", 44)
	c.custom_minimum_size = Vector2(0, 120)
	c.button_pressed = bool(MetaState.meta.settings.get(key, true))
	_apply_toggle(c, label, c.button_pressed)
	c.toggled.connect(func(on: bool) -> void:
		MetaState.set_setting(key, on)
		_apply_toggle(c, label, on))
	return c


func _apply_toggle(c: Button, label: String, on: bool) -> void:
	c.text = "%s: %s" % [label, "ON" if on else "OFF"]
	var bg := Color("#3b5a8a") if on else Color("#2a2a2a")
	var fg := Color("#e8e2d0") if on else Color("#888888")
	for st in ["normal", "hover", "pressed", "hover_pressed", "focus"]:
		c.add_theme_stylebox_override(st, _box(bg, 2, Color("#c9a24b") if on else Color("#555555"), 10))
	for col in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		c.add_theme_color_override(col, fg)


func _on_back() -> void:
	closed.emit()
	queue_free()
