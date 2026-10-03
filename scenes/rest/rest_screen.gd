extends Control

const ART := "res://assets/art/placeholder/"
const CARD_SCENE := preload("res://scenes/ui/card_view.tscn")
const TOP_BAR_SCENE := preload("res://scenes/ui/top_bar.tscn")

var run: Run
var top_bar: TopBar
var overlay: DeckOverlay
var _rest_btn: Button
var _upgrade_btn: Button
var _msg: Label
var _leave: Button
var _compare: Control
var _busy := false
var _done := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if RunState.run == null:
		RunState.ensure_run()
	run = RunState.run
	var bg := TextureRect.new()
	bg.texture = load(ART + "bg_rest.svg")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	top_bar = TOP_BAR_SCENE.instantiate()
	add_child(top_bar)
	top_bar.deck_pressed.connect(func():
		if not _busy:
			overlay.open(run.deck_cards(), "Your deck"))

	var title := Label.new()
	title.text = "Rest Site"
	title.add_theme_font_size_override("font_size", 56)
	title.position = Vector2(0, 250)
	title.size = Vector2(1080, 80)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)

	var pct := int(GameData.balance.get("rest_heal_pct", 30))
	var amount := run.heal_pct(pct)
	_rest_btn = _big_button("Rest (+%d%% HP) +%d" % [pct, amount], 1250)
	_rest_btn.pressed.connect(_on_rest.bind(pct, amount))
	_upgrade_btn = _big_button("Upgrade a card", 1400)
	_upgrade_btn.disabled = run.upgradeable_indices().is_empty()
	_upgrade_btn.pressed.connect(_on_upgrade)

	_msg = Label.new()
	_msg.add_theme_font_size_override("font_size", 48)
	_msg.position = Vector2(0, 1250)
	_msg.size = Vector2(1080, 100)
	_msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_msg.visible = false
	add_child(_msg)

	_leave = Button.new()
	_leave.text = "Leave"
	_leave.add_theme_font_size_override("font_size", 44)
	_leave.position = Vector2(360, 1700)
	_leave.size = Vector2(360, 110)
	_leave.visible = false
	_leave.pressed.connect(func(): RunState.leave_node())
	add_child(_leave)

	overlay = DeckOverlay.new()
	overlay.z_index = 100
	add_child(overlay)
	overlay.hide()

	top_bar.refresh(run)


func _big_button(text: String, y: float) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", 42)
	b.position = Vector2(190, y)
	b.size = Vector2(700, 120)
	add_child(b)
	return b


func _finish(text: String) -> void:
	_done = true
	_rest_btn.visible = false
	_upgrade_btn.visible = false
	_msg.text = text
	_msg.visible = true
	_leave.visible = true
	top_bar.refresh(run)


func _on_rest(pct: int, amount: int) -> void:
	if _busy or _done:
		return
	if run.hp == run.max_hp:
		_busy = true
		var d := ConfirmDialog.ask(self, "HP is full. Rest anyway?")
		var yes: bool = await d.answered
		_busy = false
		if not yes:
			return
	var healed := run.heal(run.heal_pct(pct))
	FloatingText.spawn(self, "+%d" % healed, Color(0.4, 0.9, 0.4), Vector2(480, 1180))
	_finish("You feel rested.")


func _on_upgrade() -> void:
	if _busy or _done:
		return
	_busy = true
	overlay.open(run.deck_cards(), "Upgrade a card", true, run.upgradeable_indices())
	var card: Dictionary = await _await_pick()
	if card.is_empty():
		_busy = false
		return
	var idx := int(card["deck_index"])
	var cid := str(run.deck[idx]["id"])
	_show_compare(cid)
	var ok: bool = await _compare.get_meta("result_signal").call()
	_compare.queue_free()
	_compare = null
	_busy = false
	if not ok:
		return
	run.upgrade_card(idx)
	_finish("%s upgraded." % str(card.get("name", "Card")))


func _show_compare(cid: String) -> void:
	_compare = Control.new()
	_compare.set_anchors_preset(Control.PRESET_FULL_RECT)
	_compare.z_index = 200
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.85)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_compare.add_child(dim)
	var before: CardView = CARD_SCENE.instantiate()
	before.card = GameData.get_card(cid, false)
	before.position = Vector2(100, 600)
	before.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_compare.add_child(before)
	var after: CardView = CARD_SCENE.instantiate()
	after.card = GameData.get_card(cid, true)
	after.position = Vector2(740, 600)
	after.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_compare.add_child(after)
	var arrow := Label.new()
	arrow.text = "→"
	arrow.add_theme_font_size_override("font_size", 90)
	arrow.position = Vector2(340, 700)
	arrow.size = Vector2(400, 140)
	arrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	arrow.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_compare.add_child(arrow)
	var answer := [null]
	var confirm := Button.new()
	confirm.text = "Confirm"
	confirm.position = Vector2(180, 1100)
	var cancel := Button.new()
	cancel.text = "Cancel"
	cancel.position = Vector2(640, 1100)
	for b in [confirm, cancel]:
		b.add_theme_font_size_override("font_size", 40)
		b.size = Vector2(260, 100)
		_compare.add_child(b)
	confirm.pressed.connect(func(): answer[0] = true)
	cancel.pressed.connect(func(): answer[0] = false)
	add_child(_compare)
	_compare.set_meta("result_signal", func() -> bool:
		while answer[0] == null:
			await get_tree().process_frame
		return answer[0])


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
