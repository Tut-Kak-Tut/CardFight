class_name EnemyAI extends RefCounted

static func create(data: Dictionary) -> Combatant:
	var e := Combatant.new()
	e.id = str(data.get("id", ""))
	e.name = str(data.get("name", ""))
	e.max_hp = int(data.max_hp)
	e.hp = e.max_hp
	e.is_player = false
	e.data = data.duplicate(true)
	e.intent = current_step(e)
	return e

static func current_step(e: Combatant) -> Dictionary:
	return e.data.phases[e.phase_index].pattern[e.pattern_index]

static func advance(e: Combatant) -> void:
	var pattern: Array = e.data.phases[e.phase_index].pattern
	e.pattern_index = (e.pattern_index + 1) % pattern.size()
	e.intent = current_step(e)

static func check_phase(e: Combatant, state: CombatState) -> bool:
	if e.data.is_empty():
		return false
	var changed := false
	while not e.is_dead() and e.phase_index + 1 < e.data.phases.size():
		var nxt: Dictionary = e.data.phases[e.phase_index + 1]
		if not nxt.has("hp_threshold_pct") or e.hp * 100 > e.max_hp * int(nxt.hp_threshold_pct):
			break
		e.phase_index += 1
		e.pattern_index = 0
		EffectResolver.resolve(nxt.get("on_enter", []), e, e, state)
		e.intent = current_step(e)
		changed = true
	return changed

static func preview(e: Combatant, state: CombatState) -> Dictionary:
	var dmg := -1
	var times := 1
	var block := 0
	var buff := 0
	var debuff := 0
	for fx in e.intent.get("effects", []):
		match fx.get("op", ""):
			"damage":
				if dmg < 0:
					dmg = EffectResolver.calc_damage(int(fx.get("value", 0)), e, state.player, state, str(fx.get("bonus", "")))
					times = int(fx.get("times", 1))
			"block":
				block += int(fx.get("value", 0))
	return {"intent": e.intent.get("intent", ""), "damage": dmg, "times": times, "block": block, "buff": buff, "debuff": debuff}
