class_name RelicBar extends HBoxContainer

var _popup: PanelContainer
var _popup_id := 0


func _init() -> void:
	add_theme_constant_override("separation", 8)


func set_relics(ids: Array, data) -> void:
	_close_popup()
	for c in get_children():
		remove_child(c)
		c.queue_free()
	for id in ids:
		var relic: Dictionary = data.get_relic(id) if data else {}
		var rtex := Art.tex("relic_%s" % id)
		var icon: Control
		if rtex != null:
			var tr := TextureRect.new()
			tr.texture = rtex
			tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tr.stretch_mode = TextureRect.STRETCH_SCALE
			icon = tr
		else:
			var cr := ColorRect.new()
			cr.color = Color("#555555")
			var lb := Label.new()
			lb.text = str(id).substr(0, 1).to_upper()
			lb.add_theme_font_size_override("font_size", 36)
			lb.size = Vector2(64, 64)
			lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lb.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			lb.mouse_filter = Control.MOUSE_FILTER_IGNORE
			cr.add_child(lb)
			icon = cr
		icon.custom_minimum_size = Vector2(64, 64)
		icon.mouse_filter = Control.MOUSE_FILTER_STOP
		icon.gui_input.connect(_on_icon_input.bind(icon, relic))
		add_child(icon)


func _on_icon_input(event: InputEvent, icon: Control, relic: Dictionary) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_show_popup(icon, relic)


func _close_popup() -> void:
	_popup_id += 1
	if _popup and is_instance_valid(_popup):
		_popup.queue_free()
	_popup = null


func _show_popup(icon: Control, relic: Dictionary) -> void:
	_close_popup()
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#151821")
	sb.set_border_width_all(2)
	sb.border_color = Color("#c9a24b")
	sb.set_content_margin_all(12)
	panel.add_theme_stylebox_override("panel", sb)
	var vb := VBoxContainer.new()
	panel.add_child(vb)
	var name_lb := Label.new()
	name_lb.text = str(relic.get("name", ""))
	name_lb.add_theme_font_size_override("font_size", 26)
	name_lb.add_theme_color_override("font_color", Color("#c9a24b"))
	vb.add_child(name_lb)
	var text_lb := Label.new()
	text_lb.text = str(relic.get("text", ""))
	text_lb.add_theme_font_size_override("font_size", 22)
	text_lb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_lb.custom_minimum_size = Vector2(360, 0)
	vb.add_child(text_lb)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.top_level = true
	add_child(panel)
	panel.global_position = icon.global_position + Vector2(0, 72)
	_popup = panel
	var id := _popup_id
	await get_tree().create_timer(2.5).timeout
	if id == _popup_id:
		_close_popup()
