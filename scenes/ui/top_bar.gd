class_name TopBar extends Control

signal deck_pressed

var _hp: Label
var _gold: Label
var _relics: RelicBar
var _deck: Button


func _init() -> void:
	custom_minimum_size = Vector2(1080, 120)
	size = Vector2(1080, 120)


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color("#0d0f15")
	bg.size = Vector2(1080, 120)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var line := ColorRect.new()
	line.color = Color("#c9a24b")
	line.position = Vector2(0, 118)
	line.size = Vector2(1080, 2)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(line)

	var row := HBoxContainer.new()
	row.position = Vector2(16, 0)
	row.size = Vector2(1048, 120)
	row.add_theme_constant_override("separation", 12)
	add_child(row)

	_add_icon(row, "icon_hp", "H")
	_hp = _add_label(row, Color.WHITE)
	_add_icon(row, "icon_gold", "G")
	_gold = _add_label(row, Color("#c9a24b"))

	_relics = RelicBar.new()
	_relics.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_relics.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_relics)

	_deck = Button.new()
	_deck.custom_minimum_size = Vector2(160, 90)
	_deck.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_deck.add_theme_font_size_override("font_size", 30)
	_deck.text = "Deck 0"
	_deck.pressed.connect(_on_deck_pressed)
	row.add_child(_deck)


func _on_deck_pressed() -> void:
	deck_pressed.emit()


func _add_icon(row: Control, icon_name: String, letter: String) -> void:
	var itex := Art.tex(icon_name)
	var ctl: Control
	if itex != null:
		var tr := TextureRect.new()
		tr.texture = itex
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ctl = tr
	else:
		var cr := ColorRect.new()
		cr.color = Color("#555555")
		var lb := Label.new()
		lb.text = letter
		lb.add_theme_font_size_override("font_size", 34)
		lb.size = Vector2(56, 56)
		lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lb.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		cr.add_child(lb)
		ctl = cr
	ctl.custom_minimum_size = Vector2(56, 56)
	ctl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ctl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(ctl)


func _add_label(row: Control, color: Color) -> Label:
	var lb := Label.new()
	lb.add_theme_font_size_override("font_size", 34)
	lb.add_theme_color_override("font_color", color)
	lb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(lb)
	return lb


func refresh(run) -> void:
	_hp.text = "%d/%d" % [run.hp, run.max_hp]
	_gold.text = str(run.gold)
	_relics.set_relics(run.relics, run.data)
	_deck.text = "Deck %d" % run.deck.size()
