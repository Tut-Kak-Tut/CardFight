class_name FloatingText extends Label


static func spawn(parent: Node, text: String, color: Color, global_pos: Vector2) -> FloatingText:
	var ft := FloatingText.new()
	ft.text = text
	ft.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ft.z_index = 200
	ft.add_theme_font_size_override("font_size", 44)
	ft.add_theme_color_override("font_color", color)
	ft.add_theme_color_override("font_outline_color", Color.BLACK)
	ft.add_theme_constant_override("outline_size", 6)
	parent.add_child(ft)
	ft.global_position = global_pos
	var tw := ft.create_tween().set_parallel(true)
	tw.tween_property(ft, "position:y", ft.position.y - 80.0, 0.8)
	tw.tween_property(ft, "modulate:a", 0.0, 0.8)
	tw.chain().tween_callback(ft.queue_free)
	return ft
