class_name MapLines extends Control

const COL_BASE := Color("#3a3f52")
const COL_AVAIL := Color("#c9a24b")
const COL_DONE := Color("#e8e2d0")

var run
var positions: Dictionary = {}


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	if run == null:
		return
	var avail: Array[int] = run.available_nodes()
	var done := {}
	for i in range(1, run.visited.size()):
		done[Vector2i(run.visited[i - 1], run.visited[i])] = true
	for n in run.map["nodes"]:
		var a: int = int(n["id"])
		for b in n["next"]:
			b = int(b)
			var col := COL_BASE
			if done.has(Vector2i(a, b)):
				col = COL_DONE
			elif a == run.current_node and avail.has(b):
				col = COL_AVAIL
			draw_line(positions[a], positions[b], col, 6.0)
	if run.current_node != -1:
		draw_arc(positions[run.current_node], 75.0, 0.0, TAU, 48, COL_AVAIL, 5.0)
