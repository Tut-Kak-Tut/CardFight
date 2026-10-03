extends TestCase

var _gd = null

func _data():
	if _gd == null:
		_gd = load("res://scripts/autoload/game_data.gd").new()
		_gd.load_all()
	return _gd

func _done() -> void:
	if _gd != null:
		_gd.free()
		_gd = null

func _defend() -> Dictionary:
	return {"id": "defend", "name": "Defend", "type": "skill", "cost": 1, "target": "none", "exhaust": false,
		"effects": [{"op": "block", "value": 5}], "upgraded": false}

func _player(hp := 50) -> Combatant:
	var p := Combatant.new()
	p.id = "player"
	p.name = "player"
	p.max_hp = hp
	p.hp = hp
	p.is_player = true
	return p

func _fight(ids: Array, php := 50) -> CombatState:
	var foes: Array = []
	for id in ids:
		foes.append(EnemyAI.create(_data().get_enemy(id)))
	var deck: Array = []
	for i in 10:
		deck.append(_defend())
	var s := CombatState.new()
	s.setup(_player(php), deck, foes, _data().balance, 1)
	s.start_combat()
	return s

func _fx(id: String, phase: int, step: int, idx := 0) -> Dictionary:
	return _data().get_enemy(id).phases[phase].pattern[step].effects[idx]

func _skel_hit() -> int:
	return int(_fx("skeleton_warrior", 0, 0).value)

func test_skeleton_pattern() -> void:
	var s := _fight(["skeleton_warrior"])
	var e := s.enemies[0]
	var seen: Array = []
	for i in 4:
		seen.append(e.intent.intent)
		EnemyAI.advance(e)
	assert_eq(seen, ["attack", "attack", "defend", "attack"])
	_done()

func test_enemy_turn_damage() -> void:
	var s := _fight(["skeleton_warrior"])
	s.end_player_turn()
	assert_eq(s.player.hp, 50 - _skel_hit())
	assert_eq(s.turn, 2)
	assert_eq(s.energy, 3)
	assert_eq(s.hand.size(), 5)
	_done()

func test_block_absorbs_enemy() -> void:
	var s := _fight(["skeleton_warrior"])
	assert_true(s.play_card(0))
	s.end_player_turn()
	assert_eq(s.player.hp, 50 - maxi(0, _skel_hit() - 5))
	_done()

func test_preview_strength() -> void:
	var s := _fight(["dark_cultist"])
	var e := s.enemies[0]
	s.end_player_turn()
	var st := int(_fx("dark_cultist", 0, 0).value)
	var base := int(_fx("dark_cultist", 0, 1).value)
	assert_eq(e.get_status("strength"), st)
	assert_eq(EnemyAI.preview(e, s).damage, base + st)
	s.player.add_status("vulnerable", 1)
	assert_eq(EnemyAI.preview(e, s).damage, floori((base + st) * float(_data().balance.vulnerable_mult)))
	_done()

func test_weak_reduces() -> void:
	var s := _fight(["skeleton_warrior"])
	s.enemies[0].add_status("weak", 2)
	s.end_player_turn()
	assert_eq(s.player.hp, 50 - floori(_skel_hit() * float(_data().balance.weak_mult)))
	_done()

func _lich_phase2() -> CombatState:
	var s := _fight(["lich_lord"])
	s.enemies[0].block = 0
	EffectResolver.resolve([{"op": "damage", "value": 70, "target": "enemy"}], s.player, s.enemies[0], s)
	return s

func test_lich_phase() -> void:
	var s := _lich_phase2()
	var e := s.enemies[0]
	var ls := int(_data().get_enemy("lich_lord").phases[1].on_enter[0].value)
	assert_eq(e.hp, e.max_hp - 70)
	assert_eq(e.phase_index, 1)
	assert_eq(e.get_status("strength"), ls)
	assert_eq(e.intent.intent, "attack")
	assert_eq(EnemyAI.preview(e, s).damage, int(_fx("lich_lord", 1, 0).value) + ls)
	_done()

func test_lich_phase_from_poison() -> void:
	var s := _fight(["lich_lord"])
	var e := s.enemies[0]
	var thr := e.max_hp * int(_data().get_enemy("lich_lord").phases[1].hp_threshold_pct) / 100
	e.hp = thr + 2
	e.add_status("poison", 3)
	s.end_player_turn()
	assert_eq(e.phase_index, 1)
	assert_eq(e.get_status("strength"), int(_data().get_enemy("lich_lord").phases[1].on_enter[0].value))
	_done()

func test_lich_multi_hit() -> void:
	var s := _lich_phase2()
	var e := s.enemies[0]
	EnemyAI.advance(e)
	assert_eq(EnemyAI.preview(e, s).times, 2)
	s.end_player_turn()
	var f := _fx("lich_lord", 1, 1)
	assert_eq(s.player.hp, 50 - (int(f.value) + e.get_status("strength")) * int(f.times))
	_done()

func test_poison_kills() -> void:
	var s := _fight(["skeleton_archer"])
	s.enemies[0].hp = 3
	s.enemies[0].add_status("poison", 5)
	s.end_player_turn()
	assert_eq(s.result, "win")
	assert_eq(s.player.hp, 50)
	_done()

func test_player_defeat() -> void:
	var s := _fight(["skeleton_warrior"], 5)
	s.end_player_turn()
	assert_eq(s.result, "lose")
	assert_eq(s.turn, 1)
	_done()
