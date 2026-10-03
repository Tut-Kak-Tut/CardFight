extends Control

const GOLD := Color("#c9a24b")

var _shards_label: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := TextureRect.new()
	bg.texture = Art.tex("bg_menu")
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var logo := TextureRect.new()
	logo.texture = Art.tex("logo")
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.position = Vector2(0, 250)
	logo.size = Vector2(1080, 300)
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(logo)

	var icon := TextureRect.new()
	icon.texture = Art.tex("icon_shard")
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.position = Vector2(400, 600)
	icon.size = Vector2(60, 60)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(icon)
	_shards_label = Label.new()
	_shards_label.add_theme_font_size_override("font_size", 44)
	_shards_label.add_theme_color_override("font_color", GOLD)
	_shards_label.position = Vector2(480, 600)
	_shards_label.size = Vector2(300, 60)
	_shards_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(_shards_label)
	MetaState.changed.connect(_refresh_shards)
	_refresh_shards()

	var y := 800.0
	if RunState.has_saved_run():
		_button("Continue", y, _on_continue)
		y += 160
	_button("New Run", y, _on_new_run)
	_button("Sanctuary", y + 160, func(): SceneRouter.goto("sanctuary"))
	_button("Settings", y + 320, func(): SettingsOverlay.open(self))
	AudioManager.play_music("ambient_menu")


func _refresh_shards() -> void:
	_shards_label.text = str(MetaState.meta.shards)


func _button(txt: String, y: float, cb: Callable) -> void:
	var b := Button.new()
	b.text = txt
	b.add_theme_font_size_override("font_size", 52)
	b.position = Vector2(220, y)
	b.size = Vector2(640, 130)
	SettingsOverlay.style_button(b)
	b.pressed.connect(cb)
	add_child(b)


func _on_continue() -> void:
	RunState.continue_run()


func _on_new_run() -> void:
	if RunState.has_saved_run():
		var d := ConfirmDialog.ask(self, "Abandon current run?")
		d.answered.connect(func(yes: bool):
			if yes:
				SaveManager.delete(SaveManager.RUN)
				SceneRouter.goto("character_select"))
	else:
		SceneRouter.goto("character_select")


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		get_tree().quit()
