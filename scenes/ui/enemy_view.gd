class_name EnemyView extends Control

signal tapped(view)


var enemy = null

var _intent_icon: TextureRect
var _intent_label: Label
var _sprite: TextureRect
var _fallback: ColorRect
var _name: Label
var _hp_bar: ProgressBar
var _hp_label: Label
var _block_box: HBoxContainer
var _block_label: Label
var _statuses: StatusRow
var _target_frame: Panel
var _pulse: Tween
var _hit_tween: Tween


func _init() -> void:
	custom_minimum_size = Vector2(300, 420)
	size = Vector2(300, 420)
	mouse_filter = Control.MOUSE_FILTER_STOP


func _ready() -> void:
	var vb := VBoxContainer.new()
	vb.size = Vector2(300, 420)
	vb.add_theme_constant_override("separation", 4)
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vb)

	var intent_row := HBoxContainer.new()
	intent_row.alignment = BoxContainer.ALIGNMENT_CENTER
	intent_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(intent_row)
	_intent_icon = TextureRect.new()
	_intent_icon.custom_minimum_size = Vector2(64, 64)
	_intent_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_intent_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_intent_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	intent_row.add_child(_intent_icon)
	_intent_label = Label.new()
	_intent_label.add_theme_font_size_override("font_size", 30)
	_intent_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	intent_row.add_child(_intent_label)

	var sprite_holder := Control.new()
	sprite_holder.custom_minimum_size = Vector2(300, 256)
	sprite_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(sprite_holder)
	_sprite = TextureRect.new()
	_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sprite_holder.add_child(_sprite)
	_fallback = ColorRect.new()
	_fallback.color = Color(0.5, 0.5, 0.5)
	_fallback.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sprite_holder.add_child(_fallback)

	_name = Label.new()
	_name.add_theme_font_size_override("font_size", 26)
	_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(_name)

	var hp_holder := CenterContainer.new()
	hp_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(hp_holder)
	_hp_bar = ProgressBar.new()
	_hp_bar.custom_minimum_size = Vector2(260, 34)
	_hp_bar.show_percentage = false
	_hp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("#a8322d")
	_hp_bar.add_theme_stylebox_override("fill", fill)
	hp_holder.add_child(_hp_bar)
	_hp_label = Label.new()
	_hp_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_hp_label.add_theme_font_size_override("font_size", 28)
	_hp_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_hp_label.add_theme_constant_override("outline_size", 4)
	_hp_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hp_bar.add_child(_hp_label)

	_block_box = HBoxContainer.new()
	_block_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_block_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(_block_box)
	var bi := TextureRect.new()
	bi.texture = Art.tex("icon_block")
	bi.custom_minimum_size = Vector2(40, 40)
	bi.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bi.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	bi.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_block_box.add_child(bi)
	_block_label = Label.new()
	_block_label.add_theme_font_size_override("font_size", 22)
	_block_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_block_box.add_child(_block_label)

	_statuses = StatusRow.new()
	_statuses.alignment = BoxContainer.ALIGNMENT_CENTER
	_statuses.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(_statuses)

	_target_frame = Panel.new()
	_target_frame.size = Vector2(300, 420)
	_target_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0)
	sb.set_border_width_all(4)
	sb.border_color = Color(0.9, 0.15, 0.15)
	_target_frame.add_theme_stylebox_override("panel", sb)
	_target_frame.visible = false
	add_child(_target_frame)

	if enemy != null:
		set_enemy(enemy)


func set_enemy(e) -> void:
	enemy = e
	if _sprite == null:
		return
	var id := str(e.id)
	var s := Vector2(300, 300) if id == "lich_lord" else Vector2(256, 256)
	var etex := Art.tex("enemy_%s" % id)
	var has_tex := etex != null
	_sprite.texture = etex
	_sprite.visible = has_tex
	_fallback.visible = not has_tex
	for n in [_sprite, _fallback]:
		n.size = s
		n.position = Vector2((300 - s.x) / 2.0, 256 - s.y)
	_name.text = str(e.name)
	_update_stats()


func _update_stats() -> void:
	if enemy == null or _hp_bar == null:
		return
	_hp_bar.max_value = max(1, enemy.max_hp)
	_hp_bar.value = enemy.hp
	_hp_label.text = "%d/%d" % [enemy.hp, enemy.max_hp]
	_block_box.modulate.a = 1.0 if enemy.block > 0 else 0.0
	_block_label.text = str(enemy.block)
	_statuses.set_statuses(enemy.statuses)
	var dead: bool = enemy.hp <= 0
	modulate.a = 0.0 if dead else 1.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE if dead else Control.MOUSE_FILTER_STOP


func refresh(preview: Dictionary) -> void:
	_update_stats()
	var kind := str(preview.get("intent", ""))
	var icon := ""
	match kind:
		"attack", "attack_debuff", "attack_defend":
			icon = "intent_attack"
		"defend":
			icon = "intent_defend"
		"buff":
			icon = "intent_buff"
		"debuff":
			icon = "intent_debuff"
	_intent_icon.texture = Art.tex(icon) if icon != "" else null
	var dmg := int(preview.get("damage", -1))
	var times := int(preview.get("times", 1))
	var dtxt := ("%dx%d" % [dmg, times]) if times > 1 else str(dmg)
	match kind:
		"attack", "attack_debuff":
			_intent_label.text = dtxt if dmg >= 0 else ""
		"attack_defend":
			_intent_label.text = "%s / %d" % [dtxt if dmg >= 0 else "0", int(preview.get("block", 0))]
		"defend":
			_intent_label.text = str(int(preview.get("block", 0)))
		"buff":
			_intent_label.text = "+%d" % int(preview.get("buff", 0))
		"debuff":
			_intent_label.text = str(int(preview.get("debuff", 0)))
		_:
			_intent_label.text = dtxt if dmg >= 0 else ""


func set_targetable(on: bool) -> void:
	if _pulse and _pulse.is_valid():
		_pulse.kill()
	if _target_frame == null:
		return
	_target_frame.visible = on
	_target_frame.modulate.a = 1.0
	if on:
		_pulse = create_tween().set_loops()
		_pulse.tween_property(_target_frame, "modulate:a", 0.3, 0.5)
		_pulse.tween_property(_target_frame, "modulate:a", 1.0, 0.5)


func flash_hit() -> void:
	if _hit_tween and _hit_tween.is_valid():
		_hit_tween.kill()
	_sprite.modulate = Color(1, 0.2, 0.2)
	_fallback.modulate = Color(1, 0.2, 0.2)
	_hit_tween = create_tween()
	_hit_tween.tween_interval(0.15)
	_hit_tween.tween_callback(_reset_hit)


func _reset_hit() -> void:
	_sprite.modulate = Color.WHITE
	_fallback.modulate = Color.WHITE


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		tapped.emit(self)
