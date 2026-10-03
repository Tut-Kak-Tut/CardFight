class_name ConfirmDialog extends Control

signal answered(yes: bool)


static func ask(parent: Node, text: String) -> ConfirmDialog:
	var d := ConfirmDialog.new()
	d.z_index = 300
	parent.add_child(d)
	d._build(text)
	return d


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP


func _build(text: String) -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	var panel := Panel.new()
	panel.size = Vector2(800, 420)
	panel.position = Vector2(140, 750)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#1c1f2b")
	sb.set_border_width_all(4)
	sb.border_color = Color("#c9a24b")
	panel.add_theme_stylebox_override("panel", sb)
	add_child(panel)

	var lb := Label.new()
	lb.text = text
	lb.add_theme_font_size_override("font_size", 32)
	lb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lb.position = Vector2(30, 20)
	lb.size = Vector2(740, 200)
	lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lb.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	panel.add_child(lb)

	_button(panel, "Yes", Vector2(100, 270), true)
	_button(panel, "No", Vector2(440, 270), false)


func _button(panel: Control, t: String, pos: Vector2, yes: bool) -> void:
	var b := Button.new()
	b.text = t
	b.add_theme_font_size_override("font_size", 40)
	b.position = pos
	b.size = Vector2(260, 100)
	b.pressed.connect(_answer.bind(yes))
	panel.add_child(b)


func _answer(yes: bool) -> void:
	answered.emit(yes)
	queue_free()
