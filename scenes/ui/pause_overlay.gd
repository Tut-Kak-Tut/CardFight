class_name PauseOverlay extends Control


signal closed


static func open(parent: Node) -> PauseOverlay:
	var o := PauseOverlay.new()
	parent.add_child(o)
	return o


static func make_button(parent: Control, pos: Vector2) -> TextureButton:
	var b := TextureButton.new()
	b.texture_normal = Art.tex("icon_pause")
	b.ignore_texture_size = true
	b.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	b.position = pos
	b.size = Vector2(100, 100)
	b.z_index = 50
	parent.add_child(b)
	return b


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	z_index = 100


func _ready() -> void:
	get_tree().paused = true
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.85)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	SettingsOverlay.style_panel(panel)
	center.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 40)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 30)
	margin.add_child(box)

	var title := Label.new()
	title.text = "Paused"
	title.add_theme_font_size_override("font_size", 64)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	_btn(box, "Resume", _close)
	_btn(box, "Settings", func() -> void: SettingsOverlay.open(self))
	_btn(box, "Abandon Run", _on_abandon)
	_btn(box, "Main Menu", _on_main_menu)


func _btn(box: Control, text: String, cb: Callable) -> void:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", 44)
	b.custom_minimum_size = Vector2(640, 130)
	SettingsOverlay.style_button(b)
	b.pressed.connect(cb)
	box.add_child(b)


func _close() -> void:
	get_tree().paused = false
	closed.emit()
	queue_free()


func _exit_tree() -> void:
	if is_inside_tree():
		get_tree().paused = false


func _on_abandon() -> void:
	var d := ConfirmDialog.ask(self, "Abandon run? You keep Soul Shards earned so far.")
	var yes: bool = await d.answered
	if yes:
		get_tree().paused = false
		RunState.abandon()


func _on_main_menu() -> void:
	get_tree().paused = false
	RunState.save()
	SceneRouter.goto("main_menu")
