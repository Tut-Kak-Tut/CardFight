class_name EffectResolver extends RefCounted

static func calc_damage(base: int, source: Combatant, tgt: Combatant, state: CombatState, bonus := "") -> int:
	var v: float = base + source.get_status("strength")
	if bonus == "half_block":
		v += floor(source.block / 2.0)
	if source.get_status("weak") > 0:
		v *= float(state.balance.weak_mult)
	if tgt != null and tgt.get_status("vulnerable") > 0:
		v *= float(state.balance.vulnerable_mult)
	return maxi(0, floori(v))

static func _targets(e: Dictionary, source: Combatant, target: Combatant, state: CombatState) -> Array[Combatant]:
	var res: Array[Combatant] = []
	match e.get("target", ""):
		"enemy":
			if target != null:
				res.append(target)
		"all_enemies":
			res.assign(state.alive_enemies())
		"player":
			res.append(state.player)
		_:
			res.append(source)
	return res

static func resolve(effects: Array, source: Combatant, target: Combatant, state: CombatState) -> void:
	for e in effects:
		var value := int(e.get("value", 0))
		match e.get("op", ""):
			"damage":
				var tgts := _targets(e, source, target, state)
				for t in tgts:
					for i in int(e.get("times", 1)):
						if t.is_dead():
							break
						var amount := calc_damage(value, source, t, state, str(e.get("bonus", "")))
						var before_block := t.block
						t.take_damage(amount)
						state.event.emit("damage", {"target": t, "amount": amount, "blocked": mini(before_block, amount)})
						if t.is_dead():
							state.event.emit("death", {"target": t})
			"block":
				source.add_block(value)
				state.event.emit("block", {"target": source, "amount": value})
			"apply":
				for t in _targets(e, source, target, state):
					t.add_status(str(e.get("status", "")), value)
					state.event.emit("status", {"target": t, "status": e.get("status", ""), "amount": value})
			"draw":
				state.draw(value)
			"discard":
				if not state.hand.is_empty():
					state.pending_discard += value
			"energy":
				state.energy += value
			"heal":
				var healed := source.heal(value)
				state.event.emit("heal", {"target": source, "amount": healed})
			_:
				pass
