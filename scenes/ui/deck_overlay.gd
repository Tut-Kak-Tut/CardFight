class_name DeckOverlay extends Control

signal picked(card: Dictionary)
signal closed

const CARD_SCENE := preload("res://scenes/ui/card_view.tscn")

var _title: Label
var _scroll: ScrollContainer
var _grid: GridContainer
var _close: Button
var _allowed: Array = []
var _pick_mode := false


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.92)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 40)
	_title.position = Vector2(0, 150)
	_title.size = Vector2(1080, 60)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_title)

	_scroll = ScrollContainer.new()
	_scroll.position = Vector2(0, 220)
	_scroll.size = Vector2(1080, 1490)
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(_scroll)

	var center := CenterContainer.new()
	center.custom_minimum_size = Vector2(1080, 0)
	_scroll.add_child(center)

	_grid = GridContainer.new()
	_grid.columns = 3
	_grid.add_theme_constant_override("h_separation", 20)
	_grid.add_theme_constant_override("v_separation", 20)
	center.add_child(_grid)

	_close = Button.new()
	_close.text = "Close"
	_close.add_theme_font_size_override("font_size", 36)
	_close.size = Vector2(300, 110)
	_close.position = Vector2(390, 1760)
	_close.z_index = 1
	_close.pressed.connect(_on_close)
	add_child(_close)


func _on_close() -> void:
	hide()
	closed.emit()


func open(cards: Array, title: String, pick_mode := false, allowed: Array = []) -> void:
	_pick_mode = pick_mode
	_allowed = allowed
	_title.text = title
	for c in _grid.get_children():
		_grid.remove_child(c)
		c.queue_free()
	_scroll.scroll_vertical = 0
	for card in cards:
		var wrap := Control.new()
		wrap.custom_minimum_size = Vector2(240, 340)
		wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var cv: CardView = CARD_SCENE.instantiate()
		cv.card = card
		cv.scale = Vector2(0.95, 0.95)
		wrap.add_child(cv)
		_grid.add_child(wrap)
		if pick_mode:
			var ok: bool = _allowed.has(card.get("deck_index", -1))
			cv.set_playable(ok)
			if ok:
				cv.tapped.connect(_on_card_tapped)
		else:
			# перегляд: картки не перехоплюють події, скрол працює
			cv.mouse_filter = Control.MOUSE_FILTER_PASS
	z_index = 50
	show()
	move_to_front()


func _on_card_tapped(view) -> void:
	picked.emit(view.card)
	hide()
