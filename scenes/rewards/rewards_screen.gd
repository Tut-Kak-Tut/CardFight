extends Control

const CARD_SCENE := preload("res://scenes/ui/card_view.tscn")
const GOLD := Color("#c9a24b")

var top_bar: TopBar
var deck_overlay: DeckOverlay
var content: Control
var zoom_overlay: Control
var confirm_popup: Control
var card_views: Array[CardView] = []
var selected: CardView = null
var take_btn: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	RunState.ensure_run()
	_build()


func _run() -> Run:
	return RunState.run


func _label(txt: String, size_px: int, pos: Vector2, sz: Vector2, color := Color.WHITE, parent: Control = null) -> Label:
	var lb := Label.new()
	lb.text = txt
	lb.add_theme_font_size_override("font_size", size_px)
	lb.add_theme_color_override("font_color", color)
	lb.position = pos
	lb.size = sz
	lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lb.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	(parent if parent else content).add_child(lb)
	return lb


func _button(txt: String, size_px: int, pos: Vector2, sz: Vector2, cb: Callable) -> Button:
	var b := Button.new()
	b.text = txt
	b.add_theme_font_size_override("font_size", size_px)
	b.position = pos
	b.size = sz
	b.pressed.connect(cb)
	content.add_child(b)
	return b


func _icon(art_name: String, pos: Vector2, sz: Vector2, parent: Control) -> void:
	var t := Art.tex(art_name)
	if t == null:
		return
	var tr := TextureRect.new()
	tr.texture = t
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.position = pos
	tr.size = sz
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(tr)


func _build() -> void:
	var bg := TextureRect.new()
	bg.texture = Art.tex("bg_combat")
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	content = Control.new()
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(content)

	top_bar = TopBar.new()
	add_child(top_bar)
	top_bar.refresh(_run())

	deck_overlay = DeckOverlay.new()
	deck_overlay.visible = false
	add_child(deck_overlay)
	top_bar.deck_pressed.connect(func(): deck_overlay.open(_run().deck_cards(), "Deck"))

	zoom_overlay = ColorRect.new()
	(zoom_overlay as ColorRect).color = Color(0, 0, 0, 0.6)
	zoom_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	zoom_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	zoom_overlay.visible = false
	zoom_overlay.gui_input.connect(_on_zoom_input)
	add_child(zoom_overlay)

	_build_confirm()
	_rebuild()


func _rebuild() -> void:
	for c in content.get_children():
		content.remove_child(c)
		c.queue_free()
	card_views.clear()
	selected = null
	take_btn = null
	var r := RunState.reward
	_label("Rewards", 56, Vector2(0, 180), Vector2(1080, 80))

	if not r.is_empty() and not r.get("gold_taken", true):
		var gb := Button.new()
		gb.position = Vector2(190, 300)
		gb.size = Vector2(700, 110)
		gb.pressed.connect(_take_gold)
		content.add_child(gb)
		_icon("icon_gold", Vector2(20, 15), Vector2(80, 80), gb)
		_label("%d Gold" % int(r.get("gold", 0)), 40, Vector2(100, 0), Vector2(500, 110), GOLD, gb)

	if not r.is_empty():
		if not r.get("card_done", true):
			_build_cards(r)
		elif r.has("card_msg"):
			_label(str(r["card_msg"]), 32, Vector2(0, 600), Vector2(1080, 60))
		if not r.get("relic_done", true) and not r.get("relics", []).is_empty():
			_build_relics(r)

	_button("Continue", 44, Vector2(340, 1700), Vector2(400, 120), _on_continue)


func _take_gold() -> void:
	var r := RunState.reward
	_run().gold += int(r.get("gold", 0))
	r["gold_taken"] = true
	AudioManager.play("gold")
	RunState.mark_dirty()
	top_bar.refresh(_run())
	_rebuild()


func _build_cards(r: Dictionary) -> void:
	_label("Choose a card", 32, Vector2(0, 480), Vector2(1080, 50))
	var ids: Array = r.get("cards", [])
	var n := ids.size()
	for i in n:
		var cv: CardView = CARD_SCENE.instantiate()
		cv.card = GameData.get_card(str(ids[i]))
		cv.scale = Vector2(0.95, 0.95)
		var cx := 540.0 + (i - (n - 1) / 2.0) * 330.0
		cv.position = Vector2(cx - 114.0 - 6.0, 560.0 - 17.0)
		cv.tapped.connect(_on_card_tapped)
		cv.long_pressed.connect(_on_card_long)
		content.add_child(cv)
		card_views.append(cv)
	var skip_gold := int(GameData.balance.get("skip_reward_gold", 0))
	take_btn = _button("Take", 38, Vector2(190, 940), Vector2(300, 100), _on_take)
	take_btn.disabled = true
	_button("Skip (+%d Gold)" % skip_gold, 34, Vector2(530, 940), Vector2(360, 100), _on_skip.bind(skip_gold))


func _on_card_tapped(view) -> void:
	selected = view
	for cv in card_views:
		cv.set_selected(cv == view)
	if take_btn:
		take_btn.disabled = false


func _on_take() -> void:
	if selected == null:
		return
	var idx := card_views.find(selected)
	_run().add_card(str(RunState.reward["cards"][idx]))
	AudioManager.play("card_play")
	RunState.reward["card_done"] = true
	RunState.reward["card_msg"] = "Card added: %s" % str(selected.card.get("name", ""))
	RunState.mark_dirty()
	top_bar.refresh(_run())
	_rebuild()


func _on_skip(skip_gold: int) -> void:
	_run().gold += skip_gold
	RunState.reward["card_done"] = true
	RunState.reward["card_msg"] = "Skipped"
	RunState.mark_dirty()
	top_bar.refresh(_run())
	_rebuild()


func _on_card_long(view) -> void:
	for ch in zoom_overlay.get_children():
		ch.queue_free()
	var big: CardView = CARD_SCENE.instantiate()
	big.card = view.card
	big.scale = Vector2(1.6, 1.6)
	big.position = Vector2(420.0, 500.0)
	big.mouse_filter = Control.MOUSE_FILTER_IGNORE
	zoom_overlay.add_child(big)
	zoom_overlay.visible = true


func _on_zoom_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		zoom_overlay.visible = false
		for ch in zoom_overlay.get_children():
			ch.queue_free()


func _build_relics(r: Dictionary) -> void:
	_label("Choose a relic", 32, Vector2(0, 1100), Vector2(1080, 50))
	var ids: Array = r.get("relics", [])
	for i in ids.size():
		var id := str(ids[i])
		var relic: Dictionary = GameData.get_relic(id)
		var b := Button.new()
		b.position = Vector2(90, 1170 + i * 120)
		b.size = Vector2(900, 100)
		b.pressed.connect(_on_relic.bind(id))
		content.add_child(b)
		_icon("relic_%s" % id, Vector2(10, 10), Vector2(80, 80), b)
		var nm := _label(str(relic.get("name", id)), 28, Vector2(100, 5), Vector2(780, 45), GOLD, b)
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		var tx := _label(str(relic.get("text", "")), 22, Vector2(100, 50), Vector2(780, 40), Color.WHITE, b)
		tx.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT


func _on_relic(id: String) -> void:
	_run().add_relic(id)
	AudioManager.play("upgrade")
	RunState.reward["relic_done"] = true
	RunState.mark_dirty()
	top_bar.refresh(_run())
	_rebuild()


func _build_confirm() -> void:
	confirm_popup = ColorRect.new()
	(confirm_popup as ColorRect).color = Color(0, 0, 0, 0.75)
	confirm_popup.set_anchors_preset(Control.PRESET_FULL_RECT)
	confirm_popup.mouse_filter = Control.MOUSE_FILTER_STOP
	confirm_popup.visible = false
	add_child(confirm_popup)
	var panel := ColorRect.new()
	panel.color = Color("#1a1d27")
	panel.position = Vector2(140, 760)
	panel.size = Vector2(800, 360)
	confirm_popup.add_child(panel)
	_label("Leave without taking rewards?", 36, Vector2(0, 40), Vector2(800, 120), Color.WHITE, panel)
	var yes := Button.new()
	yes.text = "Yes"
	yes.add_theme_font_size_override("font_size", 36)
	yes.position = Vector2(90, 210)
	yes.size = Vector2(280, 100)
	yes.pressed.connect(_leave)
	panel.add_child(yes)
	var no := Button.new()
	no.text = "No"
	no.add_theme_font_size_override("font_size", 36)
	no.position = Vector2(430, 210)
	no.size = Vector2(280, 100)
	no.pressed.connect(func(): confirm_popup.visible = false)
	panel.add_child(no)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		pass


func _on_continue() -> void:
	var r := RunState.reward
	if not r.is_empty() and (not r.get("card_done", true) or not r.get("relic_done", true)):
		confirm_popup.visible = true
	else:
		_leave()


func _leave() -> void:
	var r := RunState.reward
	if not r.is_empty() and not r.get("gold_taken", true):
		_run().gold += int(r.get("gold", 0))
		r["gold_taken"] = true
	RunState.reward = {}
	RunState.leave_node()
