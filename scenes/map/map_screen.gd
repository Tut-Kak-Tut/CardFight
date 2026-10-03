extends Control

const ART := "res://assets/art/placeholder/"
const LAYER_H := 240
const TOP_H := 120
const VIEW_H := 1800

var run: Run
var top_bar: TopBar
var deck_overlay: DeckOverlay
var scroll: ScrollContainer
var lines: MapLines
var _entering := false


func _ready() -> void:
	if RunState.run == null and not RunState.has_saved_run():
		SceneRouter.goto("main_menu")
		return
	RunState.ensure_run()
	run = RunState.run
	if run.result != "":
		SceneRouter.goto("run_result")
		return

	var bg := TextureRect.new()
	bg.texture = load(ART + "bg_map.svg")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var layers_n: int = run.map["layers"].size()
	var content_h := layers_n * LAYER_H + 300

	scroll = ScrollContainer.new()
	scroll.position = Vector2(0, TOP_H)
	scroll.size = Vector2(1080, VIEW_H)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.scroll_deadzone = 20
	add_child(scroll)

	var content := Control.new()
	content.custom_minimum_size = Vector2(1080, content_h)
	scroll.add_child(content)

	var pos := {}
	for n in run.map["nodes"]:
		var layer: int = int(n["layer"])
		var cnt: int = run.map["layers"][layer].size()
		var x := 90.0 + (int(n["index"]) + 0.5) / cnt * 900.0 + (hash(int(n["id"])) % 81 - 40)
		var y := float(content_h - 200 - layer * LAYER_H)
		if n["type"] == "boss":
			x = 540.0
			y -= 60.0
		pos[int(n["id"])] = Vector2(x, y)

	lines = MapLines.new()
	lines.run = run
	lines.positions = pos
	lines.size = Vector2(1080, content_h)
	content.add_child(lines)

	var avail: Array[int] = run.available_nodes()
	for n in run.map["nodes"]:
		_add_node(content, n, pos[int(n["id"])], avail)

	top_bar = TopBar.new()
	add_child(top_bar)
	top_bar.refresh(run)
	top_bar.deck_pressed.connect(_on_deck_pressed)

	PauseOverlay.make_button(self, Vector2(970, 128)).pressed.connect(_open_pause)
	get_tree().set_quit_on_go_back(false)
	AudioManager.play_music("ambient_menu")

	deck_overlay = DeckOverlay.new()
	add_child(deck_overlay)
	deck_overlay.hide()

	var target_layer := 0
	if run.current_node != -1:
		target_layer = int(run.node(run.current_node)["layer"])
	var ty := content_h - 200 - target_layer * LAYER_H
	_scroll_to.call_deferred(ty - int(VIEW_H * 0.7))


func _open_pause() -> void:
	if not get_tree().paused:
		PauseOverlay.open(self)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_open_pause()


func _scroll_to(v: int) -> void:
	scroll.scroll_vertical = maxi(v, 0)


func _add_node(parent: Control, n: Dictionary, p: Vector2, avail: Array[int]) -> void:
	var id := int(n["id"])
	var s := 180.0 if n["type"] == "boss" else 140.0
	var b := TextureButton.new()
	b.texture_normal = load(ART + "node_%s.svg" % n["type"])
	b.ignore_texture_size = true
	b.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	b.size = Vector2(s, s)
	b.position = p - Vector2(s, s) / 2.0
	b.pivot_offset = Vector2(s, s) / 2.0
	parent.add_child(b)
	if avail.has(id):
		b.pressed.connect(_on_node_pressed.bind(id, b))
		var tw := b.create_tween().set_loops()
		tw.tween_property(b, "scale", Vector2(1.12, 1.12), 0.4)
		tw.tween_property(b, "scale", Vector2.ONE, 0.4)
	elif run.visited.has(id):
		b.modulate = Color("#8a8f9c")
		b.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var ck := TextureRect.new()
		ck.texture = load(ART + "icon_check.svg")
		ck.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ck.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ck.size = Vector2(48, 48)
		ck.position = Vector2(s - 48, 0)
		ck.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(ck)
	else:
		b.modulate = Color(1, 1, 1, 0.45)
		b.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _on_node_pressed(id: int, b: Control) -> void:
	if _entering:
		return
	_entering = true
	var tw := create_tween()
	tw.tween_property(b, "scale", Vector2(1.25, 1.25), 0.12)
	await tw.finished
	RunState.enter_node(id)


func _on_deck_pressed() -> void:
	deck_overlay.open(run.deck_cards(), "Deck")
