extends Control

const GOLD := Color("#c9a24b")
const RED := Color("#e05a4f")
const GREEN := Color("#7ed957")
const CELL_W := 320.0
const CARD_SCALE := 0.9
const CARD_H := 306.0

var balance_lbl: Label
var vbox: VBoxContainer
var msg: Label
var zoom: ColorRect
var _busy := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := TextureRect.new()
	bg.texture = Art.tex("bg_sanctuary")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(0, 200)
	scroll.size = Vector2(1080, 1720)
	scroll.clip_contents = true
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	vbox = VBoxContainer.new()
	vbox.custom_minimum_size.x = 1080
	vbox.add_theme_constant_override("separation", 16)
	scroll.add_child(vbox)

	var header := ColorRect.new()
	header.color = Color("#14161f")
	header.size = Vector2(1080, 200)
	header.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(header)
	_label(self, "Sanctuary", 56, GOLD, Vector2(240, 30), Vector2(600, 80), HORIZONTAL_ALIGNMENT_CENTER)
	var back := Button.new()
	back.text = "Back"
	back.add_theme_font_size_override("font_size", 36)
	back.position = Vector2(20, 30)
	back.size = Vector2(200, 80)
	SettingsOverlay.style_button(back)
	back.pressed.connect(_back)
	add_child(back)

	_tex(self, "icon_shard", Vector2(440, 115), Vector2(56, 56))
	balance_lbl = _label(self, "", 44, Color.WHITE, Vector2(505, 110), Vector2(300, 66))

	msg = _label(self, "Not enough Soul Shards", 40, Color("#ff6b6b"), Vector2(140, 1780), Vector2(800, 70), HORIZONTAL_ALIGNMENT_CENTER)
	msg.visible = false
	msg.z_index = 50

	zoom = ColorRect.new()
	zoom.color = Color(0, 0, 0, 0.7)
	zoom.set_anchors_preset(Control.PRESET_FULL_RECT)
	zoom.z_index = 100
	zoom.visible = false
	zoom.gui_input.connect(_on_zoom_input)
	add_child(zoom)

	MetaState.changed.connect(_refresh)
	_refresh()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_back()


func _back() -> void:
	SceneRouter.goto("main_menu")


func _label(parent: Control, text: String, size: int, color: Color, pos: Vector2, sz: Vector2, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var lb := Label.new()
	lb.text = text
	lb.add_theme_font_size_override("font_size", size)
	lb.add_theme_color_override("font_color", color)
	lb.position = pos
	lb.size = sz
	lb.horizontal_alignment = align
	lb.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(lb)
	return lb


func _tex(parent: Control, art_name: String, pos: Vector2, sz: Vector2) -> TextureRect:
	var t := TextureRect.new()
	t.texture = Art.tex(art_name)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.position = pos
	t.size = sz
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(t)
	return t


func _open(kind: String, id: String) -> bool:
	var m: Meta = MetaState.meta
	return m.is_card_unlocked(id) if kind == "card" else m.is_char_unlocked(id)


func _status(parent: Control, kind: String, id: String, center_x: float, y: float) -> void:
	var m: Meta = MetaState.meta
	if _open(kind, id):
		_tex(parent, "icon_check", Vector2(center_x - 100, y + 4), Vector2(36, 36))
		_label(parent, "Unlocked", 30, GREEN, Vector2(center_x - 56, y), Vector2(160, 44))
		return
	var price := m.cost(kind, id)
	var affordable := m.shards >= price
	_tex(parent, "icon_shard", Vector2(center_x - 70, y + 4), Vector2(36, 36))
	_label(parent, str(price), 32, GOLD if affordable else RED, Vector2(center_x - 26, y), Vector2(120, 44))
	if not affordable:
		parent.modulate = Color(1, 1, 1, 0.6)


func _plate(cell: Control, pos: Vector2, sz: Vector2) -> void:
	var p := ColorRect.new()
	p.color = Color("#14161f", 0.85)
	p.position = pos
	p.size = sz
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cell.add_child(p)


func _section(text: String) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 44)
	l.add_theme_color_override("font_color", GOLD)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.custom_minimum_size = Vector2(1080, 70)
	vbox.add_child(l)


func _refresh() -> void:
	var m: Meta = MetaState.meta
	balance_lbl.text = str(m.shards)
	for c in vbox.get_children():
		vbox.remove_child(c)
		c.queue_free()

	_section("Characters")
	for id in GameData.characters:
		var ch: Dictionary = GameData.characters[id]
		if int(ch.get("unlock_cost", 0)) <= 0:
			continue
		var cell := Control.new()
		cell.custom_minimum_size = Vector2(1080, 300)
		vbox.add_child(cell)
		_plate(cell, Vector2(240, 0), Vector2(600, 300))
		var pname := "player_%s" % id
		if not m.is_char_unlocked(id):
			pname += "_locked"
		var ptex := _tex(cell, pname, Vector2(430, 0), Vector2(220, 220))
		if Art.needs_silhouette(pname):
			ptex.modulate = Color(0, 0, 0, 0.85)
		_label(cell, str(ch.get("name", id)), 36, Color.WHITE, Vector2(240, 220), Vector2(600, 40), HORIZONTAL_ALIGNMENT_CENTER)
		_status(cell, "char", id, 540.0, 255.0)
		cell.gui_input.connect(_on_cell_input.bind("char", id))

	_section("Cards")
	var ids: Array = []
	for id in GameData.cards:
		if int(GameData.cards[id].get("unlock_cost", 0)) > 0:
			ids.append(id)
	ids.sort_custom(func(a, b):
		var ca := int(GameData.cards[a]["unlock_cost"])
		var cb := int(GameData.cards[b]["unlock_cost"])
		return ca < cb if ca != cb else str(a) < str(b))
	var row: HBoxContainer
	for i in ids.size():
		if i % 3 == 0:
			row = HBoxContainer.new()
			row.alignment = BoxContainer.ALIGNMENT_CENTER
			row.add_theme_constant_override("separation", 0)
			vbox.add_child(row)
		var id: String = ids[i]
		var cell := Control.new()
		cell.custom_minimum_size = Vector2(CELL_W, CARD_H + 60)
		row.add_child(cell)
		_plate(cell, Vector2(8, 8), Vector2(CELL_W - 16, CARD_H + 44))
		var cv := CardView.new()
		cv.card = GameData.get_card(id, false)
		cv.scale = Vector2(CARD_SCALE, CARD_SCALE)
		cv.position = Vector2(CELL_W / 2.0 - 120.0, CARD_H - 340.0)
		cv.mouse_filter = Control.MOUSE_FILTER_PASS
		cell.add_child(cv)
		cv.tapped.connect(func(_v): _on_pick("card", id))
		cv.long_pressed.connect(_on_long_press)
		_status(cell, "card", id, CELL_W / 2.0, CARD_H + 8)
	var pad := Control.new()
	pad.custom_minimum_size = Vector2(1, 40)
	vbox.add_child(pad)


func _on_cell_input(event: InputEvent, kind: String, id: String) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_on_pick(kind, id)


func _on_pick(kind: String, id: String) -> void:
	if _busy or _open(kind, id):
		return
	var m: Meta = MetaState.meta
	var price := m.cost(kind, id)
	if m.shards < price:
		_show_msg()
		return
	var src: Dictionary = GameData.cards[id] if kind == "card" else GameData.characters[id]
	_busy = true
	var d := ConfirmDialog.ask(self, "Unlock %s for %d Soul Shards?" % [str(src.get("name", id)), price])
	var yes: bool = await d.answered
	_busy = false
	if yes and MetaState.unlock(kind, id):
		AudioManager.play("shard")


func _show_msg() -> void:
	msg.visible = true
	await get_tree().create_timer(1.5).timeout
	if is_inside_tree():
		msg.visible = false


func _on_long_press(view: CardView) -> void:
	for ch in zoom.get_children():
		ch.queue_free()
	var big := CardView.new()
	big.card = view.card
	big.pivot_offset = Vector2(120, 170)
	big.scale = Vector2(1.6, 1.6)
	big.mouse_filter = Control.MOUSE_FILTER_IGNORE
	big.position = Vector2(540, 960) - Vector2(120, 170)
	zoom.add_child(big)
	zoom.visible = true


func _on_zoom_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		zoom.visible = false
		for ch in zoom.get_children():
			ch.queue_free()
