extends Control

const ART := "res://assets/art/placeholder/"
const HAND_BOTTOM_Y := 1460.0
const PLAY_LINE_Y := 1350.0

@export var character_id := "knight"
@export var encounter: Array = []

var state: CombatState
var enemy_views: Array[EnemyView] = []
var card_views: Array[CardView] = []
var selected_uid := -1
var input_locked := false
var in_run := false
var dragging: CardView = null

var hand_layer: Control
var player_sprite: TextureRect
var hp_bar: ProgressBar
var hp_label: Label
var block_box: HBoxContainer
var block_label: Label
var player_status: StatusRow
var energy_label: Label
var draw_label: Label
var discard_label: Label
var end_btn: Button
var banner: Control
var result_overlay: Control
var result_label: Label
var rb: Button
var zoom_overlay: Control


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	in_run = RunState.run != null and not RunState.pending.is_empty()
	var seed_value := randi()
	if in_run:
		character_id = RunState.run.character_id
		encounter = RunState.pending.enemies
		seed_value = RunState.run.rng.randi()
	elif encounter.is_empty():
		var pool: Array = GameData.encounters.get("normal_late", [])
		encounter = pool[randi() % pool.size()]
	_build_ui()
	var ch := GameData.get_character(character_id)
	var player := Combatant.new()
	player.id = character_id
	player.name = str(ch.get("name", ""))
	player.max_hp = int(ch.get("max_hp", 1))
	player.hp = player.max_hp
	player.is_player = true
	var deck: Array = []
	if in_run:
		player.max_hp = RunState.run.max_hp
		player.hp = RunState.run.hp
		deck = RunState.run.deck_cards()
	else:
		for id in ch.get("deck", []):
			deck.append(GameData.get_card(str(id)))
	var foes: Array = []
	for id in encounter:
		foes.append(EnemyAI.create(GameData.get_enemy(str(id))))
	state = CombatState.new()
	state.setup(player, deck, foes, GameData.balance, seed_value)
	state.event.connect(_on_event)
	_build_enemies()
	state.start_combat()
	if in_run:
		EffectResolver.resolve(RunState.run.relic_effects("combat_start"), state.player, null, state)
	refresh()
	PauseOverlay.make_button(self, Vector2(970, 20)).pressed.connect(_open_pause)
	get_tree().set_quit_on_go_back(false)
	AudioManager.play_music("boss" if str(RunState.pending.get("kind", "")) == "boss" else "ambient_combat")


func _open_pause() -> void:
	if not get_tree().paused:
		PauseOverlay.open(self)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_open_pause()


# ---------- UI build ----------

func _label(txt: String, size_px: int, pos: Vector2, sz: Vector2) -> Label:
	var lb := Label.new()
	lb.text = txt
	lb.add_theme_font_size_override("font_size", size_px)
	lb.add_theme_color_override("font_outline_color", Color.BLACK)
	lb.add_theme_constant_override("outline_size", 4)
	lb.position = pos
	lb.size = sz
	lb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return lb


func _icon(path: String, pos: Vector2, sz: Vector2) -> TextureRect:
	var tr := TextureRect.new()
	tr.texture = load(path)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.position = pos
	tr.size = sz
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return tr


func _build_ui() -> void:
	var bg := TextureRect.new()
	bg.texture = load(ART + "bg_combat.svg")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# Player
	player_sprite = _icon(ART + "player_%s.svg" % character_id, Vector2(412, 700), Vector2(256, 256))
	add_child(player_sprite)
	hp_bar = ProgressBar.new()
	hp_bar.position = Vector2(340, 970)
	hp_bar.size = Vector2(400, 28)
	hp_bar.show_percentage = false
	hp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("#a8322d")
	hp_bar.add_theme_stylebox_override("fill", fill)
	add_child(hp_bar)
	hp_label = Label.new()
	hp_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hp_label.add_theme_font_size_override("font_size", 20)
	hp_label.add_theme_color_override("font_outline_color", Color.BLACK)
	hp_label.add_theme_constant_override("outline_size", 4)
	hp_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_bar.add_child(hp_label)

	block_box = HBoxContainer.new()
	block_box.position = Vector2(340, 1010)
	block_box.size = Vector2(400, 48)
	block_box.alignment = BoxContainer.ALIGNMENT_CENTER
	block_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(block_box)
	var bi := TextureRect.new()
	bi.texture = load(ART + "icon_block.svg")
	bi.custom_minimum_size = Vector2(44, 44)
	bi.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bi.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	bi.mouse_filter = Control.MOUSE_FILTER_IGNORE
	block_box.add_child(bi)
	block_label = Label.new()
	block_label.add_theme_font_size_override("font_size", 30)
	block_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	block_box.add_child(block_label)

	player_status = StatusRow.new()
	player_status.position = Vector2(290, 1070)
	player_status.size = Vector2(500, 48)
	player_status.alignment = BoxContainer.ALIGNMENT_CENTER
	player_status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(player_status)

	# Energy
	var circle := Control.new()
	circle.position = Vector2(40, 1250)
	circle.size = Vector2(120, 120)
	circle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(circle)
	circle.add_child(_icon(ART + "icon_energy.svg", Vector2.ZERO, Vector2(120, 120)))
	energy_label = _label("", 48, Vector2.ZERO, Vector2(120, 120))
	energy_label.add_theme_constant_override("outline_size", 8)
	energy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	energy_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	circle.add_child(energy_label)

	draw_label = _label("", 28, Vector2(40, 1190), Vector2(300, 44))
	add_child(draw_label)
	discard_label = _label("", 28, Vector2(740, 1190), Vector2(300, 44))
	discard_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(discard_label)

	end_btn = Button.new()
	end_btn.text = "End Turn"
	end_btn.add_theme_font_size_override("font_size", 34)
	for st in ["normal", "hover", "pressed", "disabled"]:
		var sbx := StyleBoxFlat.new()
		sbx.bg_color = Color("#555555") if st == "disabled" else Color("#a8322d")
		sbx.set_border_width_all(3)
		sbx.border_color = Color("#e8e2d0")
		end_btn.add_theme_stylebox_override(st, sbx)
	for cn in ["font_color", "font_hover_color", "font_pressed_color", "font_disabled_color", "font_focus_color"]:
		end_btn.add_theme_color_override(cn, Color.WHITE)
	end_btn.position = Vector2(800, 1230)
	end_btn.size = Vector2(240, 110)
	end_btn.pressed.connect(_on_end_turn)
	add_child(end_btn)

	hand_layer = Control.new()
	hand_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hand_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(hand_layer)

	# Banner
	var strip := ColorRect.new()
	strip.color = Color(0, 0, 0, 0.7)
	strip.position = Vector2(0, 100)
	strip.size = Vector2(1080, 60)
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	strip.visible = false
	var bl := _label("Choose a card to discard", 30, Vector2.ZERO, Vector2(1080, 60))
	bl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	strip.add_child(bl)
	add_child(strip)
	banner = strip

	# Zoom overlay
	zoom_overlay = ColorRect.new()
	zoom_overlay.color = Color(0, 0, 0, 0.6)
	zoom_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	zoom_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	zoom_overlay.visible = false
	zoom_overlay.gui_input.connect(_on_zoom_input)
	add_child(zoom_overlay)

	# Result overlay
	result_overlay = ColorRect.new()
	result_overlay.color = Color(0, 0, 0, 0.7)
	result_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	result_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	result_overlay.visible = false
	add_child(result_overlay)
	result_label = _label("", 72, Vector2(0, 600), Vector2(1080, 120))
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_overlay.add_child(result_label)
	rb = Button.new()
	rb.text = "Restart"
	rb.add_theme_font_size_override("font_size", 40)
	rb.position = Vector2(390, 1300)
	rb.size = Vector2(300, 120)
	rb.pressed.connect(_on_result_pressed)
	result_overlay.add_child(rb)


func _on_result_pressed() -> void:
	if not in_run:
		get_tree().reload_current_scene()
	elif state.result == "win":
		RunState.combat_won(state.player.hp)
	else:
		RunState.combat_lost()


func _build_enemies() -> void:
	var box := HBoxContainer.new()
	box.position = Vector2(0, 180)
	box.size = Vector2(1080, 420)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 20)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(box)
	move_child(box, 1)
	for e in state.enemies:
		var v := EnemyView.new()
		v.enemy = e
		if state.enemies.size() >= 3:
			v.pivot_offset = Vector2(150, 210)
			v.scale = Vector2(0.85, 0.85)
		v.tapped.connect(_on_enemy_tapped)
		box.add_child(v)
		enemy_views.append(v)


# ---------- Refresh ----------

func refresh() -> void:
	var p := state.player
	hp_bar.max_value = max(1, p.max_hp)
	hp_bar.value = p.hp
	hp_label.text = "%d/%d" % [p.hp, p.max_hp]
	block_box.modulate.a = 1.0 if p.block > 0 else 0.0
	block_label.text = str(p.block)
	player_status.set_statuses(p.statuses)
	energy_label.text = "%d/%d" % [state.energy, state.max_energy]
	energy_label.add_theme_color_override("font_color", Color("#ff6b6b") if state.energy <= 0 else Color.WHITE)
	draw_label.text = "Draw %d" % state.draw_pile.size()
	discard_label.text = "Discard %d" % state.discard_pile.size()
	for i in enemy_views.size():
		enemy_views[i].refresh(EnemyAI.preview(state.enemies[i], state))
	_rebuild_hand()
	banner.visible = state.pending_discard > 0
	if state.result != "":
		result_label.text = "Victory" if state.result == "win" else "Defeat"
		rb.text = "Continue" if (state.result == "win" or in_run) else "Restart"
		result_overlay.visible = true


func _rebuild_hand() -> void:
	for v in card_views:
		hand_layer.remove_child(v)
		v.queue_free()
	card_views.clear()
	dragging = null
	var sel_found := false
	for i in state.hand.size():
		var c: Dictionary = state.hand[i]
		var v := CardView.new()
		v.card = c
		v.scale = Vector2(0.9, 0.9)
		v.tapped.connect(_on_card_tapped)
		v.long_pressed.connect(_on_card_long_pressed)
		v.drag_moved.connect(_on_card_drag_moved)
		v.drag_released.connect(_on_card_drag_released)
		hand_layer.add_child(v)
		card_views.append(v)
		v.set_playable(state.pending_discard > 0 or int(c.cost) <= state.energy)
		if int(c.uid) == selected_uid:
			sel_found = true
	if not sel_found:
		selected_uid = -1
	_layout_hand()
	_update_selection()


func _layout_hand() -> void:
	var n := card_views.size()
	var dx: float = minf(240.0 * 0.9 + 6.0, 1040.0 / maxf(n, 1))
	var half := (n - 1) / 2.0
	for i in n:
		var v := card_views[i]
		var off := i - half
		v.z_index = 0
		v.rotation_degrees = off * 2.0
		var edge := absf(off) / maxf(half, 1.0)
		var y := HAND_BOTTOM_Y + 10.0 * edge
		if int(v.card.uid) == selected_uid:
			y -= 40.0
		v.position = Vector2(540.0 + off * dx - 120.0, y)


func _update_selection() -> void:
	var target_sel := false
	for v in card_views:
		var on := int(v.card.uid) == selected_uid
		v.set_selected(on)
		if on and v.card.get("target", "none") == "enemy":
			target_sel = true
	for i in enemy_views.size():
		enemy_views[i].set_targetable(target_sel and not state.enemies[i].is_dead())


func _clear_selection() -> void:
	selected_uid = -1
	_layout_hand()
	_update_selection()


# ---------- Input ----------

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not input_locked:
			_clear_selection()


func _on_card_tapped(view: CardView) -> void:
	if input_locked or state.result != "":
		return
	var i := card_views.find(view)
	if i < 0:
		return
	if state.pending_discard > 0:
		state.choose_discard(i)
		refresh()
		return
	var card: Dictionary = view.card
	if int(card.cost) > state.energy:
		view.shake()
		Input.vibrate_handheld(40)
		return
	if card.get("target", "none") == "enemy":
		selected_uid = int(card.uid)
		_layout_hand()
		_update_selection()
	else:
		if selected_uid == int(card.uid):
			_play(i, -1)
		else:
			selected_uid = int(card.uid)
			_layout_hand()
			_update_selection()


func _on_enemy_tapped(view: EnemyView) -> void:
	if input_locked or selected_uid < 0 or state.pending_discard > 0:
		return
	var ei := enemy_views.find(view)
	for i in card_views.size():
		var c: Dictionary = card_views[i].card
		if int(c.uid) == selected_uid and c.get("target", "none") == "enemy":
			_play(i, ei)
			return


func _play(hand_index: int, target_index: int) -> void:
	selected_uid = -1
	if state.play_card(hand_index, target_index):
		AudioManager.play("card_play")
		refresh()
	else:
		_layout_hand()
		_update_selection()


func _on_card_drag_moved(view: CardView, gp: Vector2) -> void:
	if input_locked or state.pending_discard > 0 or state.result != "":
		return
	if dragging != view:
		dragging = view
		view.z_index = 100
		view.rotation = 0.0
	view.position = gp - view.pivot_offset + Vector2(0, 150)


func _on_card_drag_released(view: CardView, gp: Vector2) -> void:
	if dragging != view:
		return
	dragging = null
	var i := card_views.find(view)
	var card: Dictionary = view.card
	if i >= 0 and not input_locked and int(card.cost) <= state.energy:
		if card.get("target", "none") == "enemy":
			for ei in enemy_views.size():
				var ev := enemy_views[ei]
				if state.enemies[ei].is_dead():
					continue
				var local := ev.get_global_transform().affine_inverse() * gp
				if Rect2(Vector2.ZERO, ev.size).has_point(local):
					_play(i, ei)
					return
		elif gp.y < PLAY_LINE_Y:
			_play(i, -1)
			return
	_layout_hand()
	_update_selection()


func _on_card_long_pressed(view: CardView) -> void:
	for ch in zoom_overlay.get_children():
		ch.queue_free()
	var big := CardView.new()
	big.card = view.card
	big.pivot_offset = Vector2(120, 170)
	big.scale = Vector2(1.6, 1.6)
	big.mouse_filter = Control.MOUSE_FILTER_IGNORE
	big.position = Vector2(540, 960) - Vector2(120, 170)
	zoom_overlay.add_child(big)
	zoom_overlay.visible = true


func _on_zoom_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		zoom_overlay.visible = false
		for ch in zoom_overlay.get_children():
			ch.queue_free()


func _on_end_turn() -> void:
	if input_locked or state.result != "":
		return
	input_locked = true
	end_btn.disabled = true
	selected_uid = -1
	state.begin_enemy_phase()
	refresh()
	for i in state.enemies.size():
		if state.enemies[i].is_dead() or state.result != "":
			continue
		state.enemy_act(i)
		refresh()
		var ev := enemy_views[i]
		var y0 := ev.position.y
		var tw := create_tween()
		tw.tween_property(ev, "position:y", y0 + 30.0, 0.1)
		tw.tween_property(ev, "position:y", y0, 0.1)
		await get_tree().create_timer(0.45).timeout
	state.finish_enemy_phase()
	refresh()
	end_btn.disabled = false
	input_locked = false


# ---------- Events ----------

func _target_pos(t: Combatant) -> Vector2:
	if t == state.player:
		return player_sprite.global_position + Vector2(100, 40)
	var i := state.enemies.find(t)
	if i >= 0:
		return enemy_views[i].get_global_transform() * Vector2(110, 80)
	return Vector2(540, 600)


func _on_event(kind: String, data: Dictionary) -> void:
	match kind:
		"damage":
			var t: Combatant = data.target
			var pos := _target_pos(t)
			var amount := int(data.amount)
			var blocked := int(data.get("blocked", 0))
			FloatingText.spawn(self, "-%d" % amount, Color(1, 0.25, 0.25), pos)
			if amount > 0:
				AudioManager.play("hit")
			if blocked > 0:
				FloatingText.spawn(self, "-%d" % blocked, Color(0.35, 0.6, 1.0), pos + Vector2(70, 30))
			var i := state.enemies.find(t)
			if i >= 0:
				enemy_views[i].flash_hit()
			elif t == state.player and amount > 0:
				AudioManager.vibrate()
		"block":
			AudioManager.play("block")
			FloatingText.spawn(self, "+%d" % int(data.amount), Color(0.35, 0.6, 1.0), _target_pos(data.target))
		"heal":
			FloatingText.spawn(self, "+%d" % int(data.amount), Color(0.4, 0.9, 0.4), _target_pos(data.target))
