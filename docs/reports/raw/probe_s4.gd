extends SceneTree
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	change_scene_to_file("res://scenes/main_menu/main_menu.tscn")
	await create_timer(1.0).timeout
	var r := current_scene as Control
	print("PROBE menu offs ", r.offset_top, " ", r.offset_bottom)
	root.get_node("SceneRouter").goto("sanctuary")
	await create_timer(1.5).timeout
	r = current_scene as Control
	print("PROBE sanct offs ", r.offset_top, " ", r.offset_bottom, " ", r.name)
	quit()
