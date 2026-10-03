extends Node

const SCENES := {"map": "res://scenes/map/map_screen.tscn", "combat": "res://scenes/combat/combat_screen.tscn",
	"rewards": "res://scenes/rewards/rewards_screen.tscn", "merchant": "res://scenes/merchant/merchant_screen.tscn",
	"rest": "res://scenes/rest/rest_screen.tscn", "run_result": "res://scenes/run_result/run_result_screen.tscn",
	"main_menu": "res://scenes/main_menu/main_menu.tscn",
	"character_select": "res://scenes/character_select/character_select.tscn",
	"sanctuary": "res://scenes/sanctuary/sanctuary.tscn"}

var _layer: CanvasLayer
var _fade: ColorRect
var _busy := false


func _ready() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 100
	add_child(_layer)
	_fade = ColorRect.new()
	_fade.color = Color.BLACK
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.modulate.a = 0.0
	_layer.add_child(_fade)
	get_viewport().size_changed.connect(_apply_safe_area)
	_apply_after_change(null)


func goto(name: String) -> void:
	var path: String = SCENES.get(name, "")
	if path == "" or not ResourceLoader.exists(path):
		push_error("SceneRouter: scene not found: %s" % name)
		return
	if _busy:
		return
	_busy = true
	_fade.mouse_filter = Control.MOUSE_FILTER_STOP
	var tw := create_tween()
	tw.tween_property(_fade, "modulate:a", 1.0, 0.15)
	await tw.finished
	var old := get_tree().current_scene
	get_tree().change_scene_to_file(path)
	await _apply_after_change(old)
	tw = create_tween()
	tw.tween_property(_fade, "modulate:a", 0.0, 0.15)
	await tw.finished
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_busy = false


# Відступи safe-area (у координатах viewport): Rect2 з top/bottom/left/right як position/size не підходить,
# тому повертаємо Vector4(left, top, right, bottom).
func _get_insets() -> Vector4:
	var vis := get_viewport().get_visible_rect().size
	if "--fake-safe-area" in OS.get_cmdline_user_args():
		return Vector4(0, 120, 0, 80)
	var screen := Vector2(DisplayServer.screen_get_size())
	var safe := Rect2(DisplayServer.get_display_safe_area())
	if screen.x <= 0 or screen.y <= 0 or safe.size.x <= 0 or safe.size.y <= 0:
		return Vector4.ZERO
	var k := Vector2(vis.x / screen.x, vis.y / screen.y)
	return Vector4(maxf(safe.position.x, 0.0) * k.x, maxf(safe.position.y, 0.0) * k.y,
		maxf(screen.x - safe.end.x, 0.0) * k.x, maxf(screen.y - safe.end.y, 0.0) * k.y)


# Корінь сцени (Control з full-rect anchors) отримує offsets = відступи safe-area.
# Фон (перший дочірній TextureRect з full-rect anchors; у сценах він створюється без імені)
# отримує від'ємні offsets, що компенсують відступ, тож лишається на весь екран.
func _apply_safe_area() -> void:
	var root := get_tree().current_scene as Control
	if root == null:
		return
	var ins := _get_insets()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = ins.x
	root.offset_top = ins.y
	root.offset_right = -ins.z
	root.offset_bottom = -ins.w
	for c in root.get_children():
		if c is TextureRect:
			var t := c as TextureRect
			var full := t.anchor_left == 0.0 and t.anchor_top == 0.0 and t.anchor_right == 1.0 and t.anchor_bottom == 1.0
			if full or t.name.to_lower().begins_with("bg"):
				t.set_anchors_preset(Control.PRESET_FULL_RECT)
				t.offset_left = -ins.x
				t.offset_top = -ins.y
				t.offset_right = ins.z
				t.offset_bottom = ins.w
			break


# Зміна сцени відкладена: чекаємо, доки current_scene стане новою (не old і не null), потім застосовуємо.
func _apply_after_change(old: Node) -> void:
	var tree := get_tree()
	for i in 30:
		await tree.process_frame
		var cur := tree.current_scene
		if cur != null and cur != old and cur.is_inside_tree():
			break
	_apply_safe_area()
