extends Control

const ART := "res://assets/art/placeholder/"
const SWIPE_MIN := 120.0

var _ids: Array = []
var _page := 0
var _portrait: TextureRect
var _name: Label
var _stats: Label
var _dots: HBoxContainer
var _action: Button
var _deck: DeckOverlay
var _press_x := 0.0
var _pressing := false


func _ready() -> void:
	_ids = GameData.characters.keys()
	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.08, 0.12)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	_portrait = TextureRect.new()
	_portrait.position = Vector2(190, 330)
	_portrait.size = Vector2(700, 700)
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_portrait)

	_name = _label(64, 1060)
	_stats = _label(40, 1160)

	var deck_btn := Button.new()
	deck_btn.text = "View Deck"
	deck_btn.add_theme_font_size_override("font_size", 40)
	deck_btn.size = Vector2(420, 120)
	deck_btn.position = Vector2(330, 1260)
	deck_btn.pressed.connect(_on_view_deck)
	add_child(deck_btn)

	_dots = HBoxContainer.new()
	_dots.alignment = BoxContainer.ALIGNMENT_CENTER
	_dots.add_theme_constant_override("separation", 24)
	_dots.position = Vector2(0, 1450)
	_dots.size = Vector2(1080, 40)
	_dots.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_dots)

	_arrow("<", Vector2(10, 600), -1)
	_arrow(">", Vector2(910, 600), 1)

	_action = Button.new()
	_action.add_theme_font_size_override("font_size", 40)
	_action.size = Vector2(640, 130)
	_action.position = Vector2(220, 1650)
	_action.expand_icon = true
	_action.pressed.connect(_on_action)
	add_child(_action)

	var back := Button.new()
	back.text = "Back"
	back.add_theme_font_size_override("font_size", 36)
	back.size = Vector2(220, 100)
	back.position = Vector2(30, 40)
	back.pressed.connect(_on_back)
	add_child(back)

	_deck = DeckOverlay.new()
	add_child(_deck)
	_deck.hide()

	MetaState.changed.connect(_refresh)
	_refresh()


func _label(size_px: int, y: float) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size_px)
	l.position = Vector2(0, y)
	l.size = Vector2(1080, size_px + 20)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)
	return l


func _arrow(t: String, pos: Vector2, dir: int) -> void:
	var b := Button.new()
	b.text = t
	b.add_theme_font_size_override("font_size", 72)
	b.size = Vector2(160, 160)
	b.position = pos
	b.pressed.connect(_turn.bind(dir))
	add_child(b)


func _turn(dir: int) -> void:
	if _ids.is_empty():
		return
	_page = posmod(_page + dir, _ids.size())
	_refresh()


func _cur() -> Dictionary:
	return GameData.get_character(_ids[_page]) if not _ids.is_empty() else {}


func _is_open(id: String) -> bool:
	return MetaState.meta.is_char_unlocked(id)


func _refresh() -> void:
	var c := _cur()
	if c.is_empty():
		return
	var id: String = c["id"]
	var open := _is_open(id)
	var tex: Texture2D = null
	_portrait.modulate = Color.WHITE
	if not open and ResourceLoader.exists(ART + "player_%s_locked.svg" % id):
		tex = load(ART + "player_%s_locked.svg" % id)
	else:
		if ResourceLoader.exists(ART + "player_%s.svg" % id):
			tex = load(ART + "player_%s.svg" % id)
		if not open:
			_portrait.modulate = Color(1, 1, 1, 1) * 0.1
			_portrait.modulate.a = 1.0
	_portrait.texture = tex
	_name.text = str(c.get("name", id))
	_stats.text = "HP %d  ·  Energy %d" % [int(c.get("max_hp", 0)), int(c.get("energy", GameData.balance.get("energy_per_turn", 3)))]
	for d in _dots.get_children():
		_dots.remove_child(d)
		d.queue_free()
	for i in _ids.size():
		var dot := Label.new()
		dot.text = "●" if i == _page else "○"
		dot.add_theme_font_size_override("font_size", 40)
		_dots.add_child(dot)
	if open:
		_action.text = "Begin"
		_action.icon = null
		_action.disabled = false
	else:
		_action.text = "Unlock in Sanctuary · %d" % MetaState.meta.cost("char", id)
		_action.icon = load(ART + "icon_lock.svg")
		_action.disabled = true


func _on_action() -> void:
	var c := _cur()
	if c.is_empty() or not _is_open(c["id"]):
		return
	RunState.new_run(c["id"])
	SceneRouter.goto("map")


func _on_view_deck() -> void:
	var c := _cur()
	var cards: Array = []
	for cid in c.get("deck", []):
		cards.append(GameData.get_card(cid))
	_deck.open(cards, "%s - Starting Deck" % c.get("name", ""))


func _on_back() -> void:
	SceneRouter.goto("main_menu")


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if _deck != null and _deck.visible:
			_deck._on_close()
		else:
			_on_back()


func _input(event: InputEvent) -> void:
	if _deck != null and _deck.visible:
		return
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		if event is InputEventMouseButton and event.button_index != MOUSE_BUTTON_LEFT:
			return
		if event.pressed:
			_press_x = event.position.x
			_pressing = true
		elif _pressing:
			_pressing = false
			var dx: float = event.position.x - _press_x
			if absf(dx) >= SWIPE_MIN:
				_turn(-1 if dx > 0 else 1)
