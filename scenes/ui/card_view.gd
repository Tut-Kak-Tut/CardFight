class_name CardView extends Control

signal tapped(view)
signal long_pressed(view)
signal drag_moved(view, global_pos)
signal drag_released(view, global_pos)

const LONG_PRESS_SEC := 0.5
const DRAG_THRESHOLD := 20.0

var card: Dictionary = {}

var _bg: TextureRect
var _cost: Label
var _name: Label
var _type: Label
var _text: Label
var _sel: Panel
var _pressed := false
var _dragging := false
var _press_pos := Vector2.ZERO
var _press_id := 0
var _shake_tween: Tween
var _shake_base := 0.0


func _init() -> void:
	custom_minimum_size = Vector2(240, 340)
	size = Vector2(240, 340)
	pivot_offset = Vector2(120, 340)
	mouse_filter = Control.MOUSE_FILTER_STOP


func _ready() -> void:
	_bg = TextureRect.new()
	_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_bg.stretch_mode = TextureRect.STRETCH_SCALE
	_bg.size = Vector2(240, 340)
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg)

	_cost = _make_label(34, Color.WHITE, true)
	_cost.position = Vector2(11, 11)
	_cost.size = Vector2(50, 50)
	_cost.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cost.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	_name = _make_label(26, Color.WHITE, false)
	_name.position = Vector2(0, 70)
	_name.size = Vector2(240, 40)
	_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	_type = _make_label(18, Color(0.7, 0.7, 0.7), false)
	_type.position = Vector2(0, 108)
	_type.size = Vector2(240, 28)
	_type.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	_text = _make_label(26, Color.WHITE, false)
	_text.position = Vector2(16, 130)
	_text.size = Vector2(208, 195)
	_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	_sel = Panel.new()
	_sel.size = Vector2(240, 340)
	_sel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0)
	sb.set_border_width_all(4)
	sb.border_color = Color("#c9a24b")
	_sel.add_theme_stylebox_override("panel", sb)
	_sel.visible = false
	add_child(_sel)

	if not card.is_empty():
		set_card(card)


func _make_label(font_size: int, color: Color, outline: bool) -> Label:
	var lb := Label.new()
	lb.add_theme_font_size_override("font_size", font_size)
	lb.add_theme_color_override("font_color", color)
	if outline:
		lb.add_theme_color_override("font_outline_color", Color.BLACK)
		lb.add_theme_constant_override("outline_size", 4)
	lb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(lb)
	return lb


func set_card(c: Dictionary) -> void:
	card = c
	if _bg == null:
		return
	var type_str := str(c.get("type", "skill")).to_lower()
	var path := "res://assets/art/placeholder/card_frame_%s.svg" % type_str
	_bg.texture = load(path) if ResourceLoader.exists(path) else null
	_cost.text = str(c.get("cost", 0))
	_name.text = str(c.get("name", ""))
	var up = c.get("upgraded", false)
	_name.add_theme_color_override("font_color", Color("#7ed957") if up else Color.WHITE)
	_type.text = type_str.capitalize()
	_text.text = str(c.get("text", ""))
	_text.add_theme_font_size_override("font_size", 26)
	var font := _text.get_theme_font("font")
	var lines := font.get_multiline_string_size(_text.text, HORIZONTAL_ALIGNMENT_LEFT, 208, 26).y / font.get_height(26)
	if lines > 3.01:
		_text.add_theme_font_size_override("font_size", 22)


func set_playable(ok: bool) -> void:
	modulate = Color(1, 1, 1) if ok else Color(0.5, 0.5, 0.5)


func set_selected(on: bool) -> void:
	if _sel:
		_sel.visible = on


func shake() -> void:
	if _shake_tween and _shake_tween.is_valid():
		_shake_tween.kill()
		position.x = _shake_base
	_shake_base = position.x
	_shake_tween = create_tween()
	var step := 0.25 / 6.0
	for i in 3:
		_shake_tween.tween_property(self, "position:x", _shake_base + 12.0, step)
		_shake_tween.tween_property(self, "position:x", _shake_base - 12.0, step)
	_shake_tween.tween_property(self, "position:x", _shake_base, 0.0)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_pressed = true
			_dragging = false
			_press_pos = event.global_position
			_press_id += 1
			_start_long_press(_press_id)
		elif _pressed:
			_pressed = false
			_press_id += 1
			if _dragging:
				_dragging = false
				drag_released.emit(self, event.global_position)
			else:
				tapped.emit(self)
	elif event is InputEventMouseMotion and _pressed:
		if not _dragging and event.global_position.distance_to(_press_pos) > DRAG_THRESHOLD:
			_dragging = true
			_press_id += 1
		if _dragging:
			drag_moved.emit(self, event.global_position)


func _start_long_press(id: int) -> void:
	await get_tree().create_timer(LONG_PRESS_SEC).timeout
	if is_inside_tree() and _pressed and not _dragging and id == _press_id:
		_pressed = false
		long_pressed.emit(self)
