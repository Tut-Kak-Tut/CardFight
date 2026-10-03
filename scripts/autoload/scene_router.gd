extends Node

const SCENES := {"map": "res://scenes/map/map_screen.tscn", "combat": "res://scenes/combat/combat_screen.tscn",
	"rewards": "res://scenes/rewards/rewards_screen.tscn", "merchant": "res://scenes/merchant/merchant_screen.tscn",
	"rest": "res://scenes/rest/rest_screen.tscn", "run_result": "res://scenes/run_result/run_result_screen.tscn"}

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
	get_tree().change_scene_to_file(path)
	tw = create_tween()
	tw.tween_property(_fade, "modulate:a", 0.0, 0.15)
	await tw.finished
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_busy = false
