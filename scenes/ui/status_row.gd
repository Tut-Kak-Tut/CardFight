class_name StatusRow extends HBoxContainer

const ORDER := ["strength", "vulnerable", "weak", "poison", "bastion", "strength_per_turn"]


func set_statuses(st: Dictionary) -> void:
	for ch in get_children():
		remove_child(ch)
		ch.queue_free()
	for sname in ORDER:
		var v = st.get(sname, 0)
		if v == 0:
			continue
		var tr := TextureRect.new()
		tr.texture = Art.tex("status_%s" % sname)
		tr.custom_minimum_size = Vector2(40, 40)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(tr)
		var lb := Label.new()
		lb.text = str(v)
		lb.add_theme_font_size_override("font_size", 22)
		lb.add_theme_color_override("font_outline_color", Color.BLACK)
		lb.add_theme_constant_override("outline_size", 4)
		lb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(lb)
