extends Control

const ART := "res://assets/art/placeholder/"
const CARD_SCENE := preload("res://scenes/ui/card_view.tscn")
const TOP_BAR_SCENE := preload("res://scenes/ui/top_bar.tscn")

var run: Run
var top_bar: TopBar
var overlay: DeckOverlay
var content: Control
var _busy := false


func _ready() -> void:
	run = RunState.run
	var bg := TextureRect.new()
	bg.texture = load(ART + "bg_merchant.svg")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	content = Control.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(content)

	top_bar = TOP_BAR_SCENE.instantiate()
	add_child(top_bar)
	top_bar.deck_pressed.connect(_on_deck_pressed)

	var leave := Button.new()
	leave.text = "Leave"
	leave.add_theme_font_size_override("font_size", 44)
	leave.position = Vector2(360, 1760)
	leave.size = Vector2(360, 110)
	leave.pressed.connect(func(): RunState.leave_node())
	add_child(leave)

	overlay = DeckOverlay.new()
	overlay.z_index = 100
	add_child(overlay)
	overlay.hide()

	_refresh()


func _on_deck_pressed() -> void:
	if _busy:
		return
	overlay.open(run.deck_cards(), "Your deck")


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


func _price_row(parent: Control, price: int, center_x: float, y: float) -> void:
	var col := Color("#ff6b6b") if run.gold < price else Color.WHITE
	var icon := TextureRect.new()
	icon.texture = load(ART + "icon_gold.svg")
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size = Vector2(40, 40)
	icon.position = Vector2(center_x - 60, y)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(icon)
	_label(parent, str(price), 30, col, Vector2(center_x - 10, y - 5), Vector2(100, 50))


func _refresh() -> void:
	top_bar.refresh(run)
	for c in content.get_children():
		content.remove_child(c)
		c.queue_free()
	var shop: Dictionary = RunState.shop

	# Cards: 3 + 2
	var cards: Array = shop.get("cards", [])
	for i in cards.size():
		var entry: Dictionary = cards[i]
		var row := 0 if i < 3 else 1
		var col := i if i < 3 else i - 3
		var count := mini(3, cards.size()) if row == 0 else cards.size() - 3
		var cell_w := 300.0
		var cx := 540.0 - cell_w * count / 2.0 + cell_w * (col + 0.5)
		var top := 600.0 + row * 320.0
		if entry.get("sold", false):
			_label(content, "SOLD", 30, Color(0.55, 0.55, 0.55), Vector2(cx - 120, top), Vector2(240, 272), HORIZONTAL_ALIGNMENT_CENTER)
			continue
		var cv: CardView = CARD_SCENE.instantiate()
		cv.card = GameData.get_card(entry["id"], false)
		cv.scale = Vector2(0.8, 0.8)
		# pivot (120,340): bottom-center of scaled card sits at position + (120, 340)
		cv.position = Vector2(cx - 120, top + 272 - 340)
		content.add_child(cv)
		cv.tapped.connect(_on_buy.bind("card", i))
		_price_row(content, int(entry["price"]), cx, top + 276)

	# Relics
	var relics: Array = shop.get("relics", [])
	for i in relics.size():
		var entry: Dictionary = relics[i]
		var rel: Dictionary = GameData.get_relic(entry["id"])
		var p := Panel.new()
		p.position = Vector2(40.0 + i * 520.0, 1300)
		p.size = Vector2(480, 160)
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color("#1c1f2b")
		sb.set_border_width_all(2)
		sb.border_color = Color("#c9a24b")
		p.add_theme_stylebox_override("panel", sb)
		content.add_child(p)
		if entry.get("sold", false):
			_label(p, "SOLD", 30, Color(0.55, 0.55, 0.55), Vector2.ZERO, p.size, HORIZONTAL_ALIGNMENT_CENTER)
			continue
		var icon: Control
		var path := ART + "relic_%s.svg" % entry["id"]
		if ResourceLoader.exists(path):
			var tr := TextureRect.new()
			tr.texture = load(path)
			tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tr.stretch_mode = TextureRect.STRETCH_SCALE
			icon = tr
		else:
			var cr := ColorRect.new()
			cr.color = Color("#555555")
			icon = cr
		icon.position = Vector2(10, 32)
		icon.size = Vector2(96, 96)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.add_child(icon)
		_label(p, str(rel.get("name", "")), 26, Color("#c9a24b"), Vector2(116, 4), Vector2(354, 34))
		var t := _label(p, str(rel.get("text", "")), 22, Color.WHITE, Vector2(116, 38), Vector2(354, 80))
		t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		t.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		_price_row(p, int(entry["price"]), 290.0, 116.0)
		p.gui_input.connect(_on_relic_input.bind(i))

	# Services
	var rm_price := int(shop.get("remove_price", 0))
	var heal_price := int(shop.get("heal_price", 0))
	var heal_pct := int(shop.get("heal_pct", 0))
	var rm := _service_button("Remove a card — %d" % rm_price, Vector2(40, 1520),
		shop.get("remove_used", false) or run.gold < rm_price or not run.can_remove())
	rm.pressed.connect(_on_remove)
	var hl := _service_button("Heal +%d%% — %d" % [heal_pct, heal_price], Vector2(550, 1520),
		shop.get("heal_used", false) or run.gold < heal_price)
	hl.pressed.connect(_on_heal)


func _service_button(text: String, pos: Vector2, disabled: bool) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", 32)
	b.position = pos
	b.size = Vector2(490, 120)
	b.disabled = disabled
	content.add_child(b)
	return b


func _on_relic_input(event: InputEvent, i: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_on_buy(null, "relic", i)


func _on_buy(view, kind: String, i: int) -> void:
	if _busy:
		return
	var entry: Dictionary = RunState.shop["cards" if kind == "card" else "relics"][i]
	var price := int(entry["price"])
	if run.gold < price:
		if view is CardView:
			view.shake()
		Input.vibrate_handheld(40)
		return
	var nm: String
	if kind == "card":
		nm = str(GameData.get_card(entry["id"], false).get("name", entry["id"]))
	else:
		nm = str(GameData.get_relic(entry["id"]).get("name", entry["id"]))
	_busy = true
	var d := ConfirmDialog.ask(self, "Buy %s for %d gold?" % [nm, price])
	var yes: bool = await d.answered
	_busy = false
	if not yes or not run.spend(price):
		return
	if kind == "card":
		run.add_card(entry["id"])
	else:
		run.add_relic(entry["id"])
	entry["sold"] = true
	_refresh()


func _on_remove() -> void:
	if _busy:
		return
	var all: Array = []
	for i in run.deck.size():
		all.append(i)
	_busy = true
	overlay.open(run.deck_cards(), "Remove a card", true, all)
	var card: Dictionary = await _await_pick()
	if card.is_empty():
		_busy = false
		return
	var price := int(RunState.shop["remove_price"])
	var d := ConfirmDialog.ask(self, "Remove %s for %d gold?" % [card.get("name", ""), price])
	var yes: bool = await d.answered
	_busy = false
	if not yes or not run.spend(price):
		return
	run.remove_card(int(card["deck_index"]))
	RunState.shop["remove_used"] = true
	_refresh()


func _await_pick() -> Dictionary:
	var result := [{}]
	var done := [false]
	var on_pick := func(c): result[0] = c; done[0] = true
	var on_close := func(): done[0] = true
	overlay.picked.connect(on_pick)
	overlay.closed.connect(on_close)
	while not done[0]:
		await get_tree().process_frame
	overlay.picked.disconnect(on_pick)
	overlay.closed.disconnect(on_close)
	return result[0]


func _on_heal() -> void:
	var shop: Dictionary = RunState.shop
	if shop.get("heal_used", false) or not run.spend(int(shop["heal_price"])):
		return
	run.heal(run.heal_pct(int(shop["heal_pct"])))
	shop["heal_used"] = true
	_refresh()
