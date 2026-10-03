extends TestCase

const BAL := {"energy_per_turn": 3, "hand_draw": 5, "hand_max": 10, "vulnerable_mult": 1.5, "weak_mult": 0.75}

func _card(id: String, type: String, cost: int, effects: Array, target := "none", exhaust := false) -> Dictionary:
	return {"id": id, "name": id, "type": type, "cost": cost, "target": target, "exhaust": exhaust, "effects": effects, "upgraded": false}

func _dmg(v: int, times := 1, bonus := "") -> Dictionary:
	var e := {"op": "damage", "value": v, "target": "enemy", "times": times}
	if bonus != "":
		e["bonus"] = bonus
	return e

func _strike() -> Dictionary:
	return _card("strike", "attack", 1, [_dmg(6)], "enemy")

func _mk(id: String, hp: int, is_player := false) -> Combatant:
	var c := Combatant.new()
	c.id = id
	c.name = id
	c.max_hp = hp
	c.hp = hp
	c.is_player = is_player
	return c

func _state(deck: Array, enemy_hp := [30]) -> CombatState:
	var foes: Array = []
	for hp in enemy_hp:
		foes.append(_mk("e", hp))
	var s := CombatState.new()
	s.setup(_mk("player", 50, true), deck, foes, BAL, 1)
	return s

func _hand_with(s: CombatState, card: Dictionary) -> void:
	s.hand.append(card.duplicate(true))
	s.energy = 3

func test_block_absorbs() -> void:
	var s := _state([])
	s.player.block = 5
	var lost := s.player.take_damage(8)
	assert_eq(lost, 3)
	assert_eq(s.player.hp, 47)
	assert_eq(s.player.block, 0)

func test_strength_vulnerable_weak() -> void:
	var s := _state([])
	s.player.add_status("strength", 2)
	s.enemies[0].add_status("vulnerable", 1)
	assert_eq(EffectResolver.calc_damage(6, s.player, s.enemies[0], s), 12)
	var s2 := _state([])
	s2.player.add_status("weak", 1)
	assert_eq(EffectResolver.calc_damage(6, s2.player, s2.enemies[0], s2), 4)

func test_double_strike_death_once() -> void:
	var s := _state([], [6])
	var deaths := [0]
	var hits := [0]
	s.event.connect(func(kind, _d):
		if kind == "death":
			deaths[0] += 1
		if kind == "damage":
			hits[0] += 1)
	_hand_with(s, _card("ds", "attack", 1, [_dmg(6, 2)], "enemy"))
	assert_true(s.play_card(0, 0))
	assert_eq(deaths[0], 1)
	assert_eq(hits[0], 1)

func test_energy_limit() -> void:
	var s := _state([])
	_hand_with(s, _card("big", "attack", 3, [_dmg(6)], "enemy"))
	s.energy = 2
	assert_true(not s.play_card(0, 0))
	assert_eq(s.hand.size(), 1)

func test_card_destinations() -> void:
	var s := _state([])
	_hand_with(s, _card("ex", "skill", 0, [{"op": "block", "value": 1}], "none", true))
	_hand_with(s, _card("pw", "power", 0, []))
	_hand_with(s, _card("n", "skill", 0, [{"op": "block", "value": 1}]))
	assert_true(s.play_card(0))
	assert_true(s.play_card(0))
	assert_true(s.play_card(0))
	assert_eq(s.exhaust_pile.size(), 1)
	assert_eq(s.powers.size(), 1)
	assert_eq(s.discard_pile.size(), 1)

func test_draw_reshuffle() -> void:
	var s := _state([_strike(), _strike(), _strike()])
	for i in 4:
		s.discard_pile.append(_strike())
	var shuffled := [false]
	s.event.connect(func(kind, _d):
		if kind == "shuffle":
			shuffled[0] = true)
	s.draw(5)
	assert_eq(s.hand.size(), 5)
	assert_true(shuffled[0])

func test_hand_limit() -> void:
	var s := _state([_strike()])
	for i in 10:
		s.hand.append(_strike())
	s.draw(1)
	assert_eq(s.hand.size(), 10)
	assert_eq(s.discard_pile.size(), 1)

func test_poison() -> void:
	var s := _state([])
	s.player.add_status("poison", 3)
	s.start_player_turn()
	assert_eq(s.player.hp, 47)
	assert_eq(s.player.get_status("poison"), 2)

func test_bastion() -> void:
	var s := _state([])
	s.player.block = 7
	s.player.add_status("bastion", 1)
	s.start_player_turn()
	assert_eq(s.player.block, 7)
	var s2 := _state([])
	s2.player.block = 7
	s2.start_player_turn()
	assert_eq(s2.player.block, 0)

func test_strength_per_turn() -> void:
	var s := _state([])
	s.player.add_status("strength_per_turn", 1)
	s.start_player_turn()
	s.start_player_turn()
	assert_eq(s.player.get_status("strength"), 2)

func test_discard_choice() -> void:
	var s := _state([_strike(), _strike(), _strike()])
	_hand_with(s, _card("focus", "skill", 1, [{"op": "draw", "value": 2}, {"op": "discard", "value": 1}]))
	_hand_with(s, _strike())
	assert_true(s.play_card(0))
	assert_eq(s.pending_discard, 1)
	assert_true(not s.play_card(0, 0))
	assert_true(s.choose_discard(0))
	assert_eq(s.pending_discard, 0)

func test_half_block() -> void:
	var s := _state([])
	s.player.block = 10
	_hand_with(s, _card("vengeance", "attack", 1, [_dmg(6, 1, "half_block")], "enemy"))
	assert_true(s.play_card(0, 0))
	assert_eq(s.enemies[0].hp, 19)

func test_win() -> void:
	var s := _state([], [5])
	_hand_with(s, _strike())
	assert_true(s.play_card(0, 0))
	assert_eq(s.result, "win")
