extends Control

const GOLD := Color("#c9a24b")


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if RunState.run == null:
		SceneRouter.goto("main_menu")
		return
	var run: Run = RunState.run
	var bg := TextureRect.new()
	bg.texture = Art.tex("bg_combat")
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	var won: bool = run.result == "victory"
	_label("Victory" if won else "Defeat", 88, 400, 120, Color("#c9a24b") if won else Color("#a8322d"))
	var lines: Array[String] = ["Floors cleared: %d" % run.stats.layers,
		"Battles won: %d" % run.stats.battles, "Elites defeated: %d" % run.stats.elites]
	if run.stats.boss:
		lines.append("Boss defeated")
	for i in lines.size():
		_label(lines[i], 32, 650 + i * 60, 50, Color.WHITE)
	_label("Soul Shards earned: %d" % run.soul_shards(), 40, 1150, 60, GOLD)

	_label("Total Soul Shards: %d" % MetaState.meta.shards, 32, 1220, 50, Color.WHITE)
	AudioManager.play("victory" if won else "defeat")
	if run.soul_shards() > 0:
		get_tree().create_timer(0.6).timeout.connect(func(): AudioManager.play("shard"))
	_button("Continue", 1450, _on_continue)
	_button("Sanctuary", 1600, _on_sanctuary)


func _button(txt: String, y: float, cb: Callable) -> void:
	var b := Button.new()
	b.text = txt
	b.add_theme_font_size_override("font_size", 44)
	b.position = Vector2(190, y)
	b.size = Vector2(700, 120)
	b.pressed.connect(cb)
	add_child(b)


func _label(txt: String, size_px: int, y: float, h: float, color: Color) -> void:
	var lb := Label.new()
	lb.text = txt
	lb.add_theme_font_size_override("font_size", size_px)
	lb.add_theme_color_override("font_color", color)
	lb.position = Vector2(0, y)
	lb.size = Vector2(1080, h)
	lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lb.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(lb)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		pass


func _on_continue() -> void:
	RunState.run = null
	SceneRouter.goto("character_select")


func _on_sanctuary() -> void:
	RunState.run = null
	SceneRouter.goto("sanctuary")
