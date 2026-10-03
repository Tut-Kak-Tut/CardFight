extends TestCase

func _gd():
	var gd = load("res://scripts/autoload/game_data.gd").new()
	gd.load_all()
	return gd

func _run(gd) -> Run:
	var r := Run.new()
	r.start(gd, "knight", [], 123)
	return r

func test_start() -> void:
	var gd = _gd()
	var r := _run(gd)
	assert_eq(r.hp, gd.get_character("knight").max_hp)
	assert_eq(r.gold, gd.balance.start_gold)
	assert_eq(r.deck.size(), 10)
	assert_eq(r.map.layers.size(), 10)
	gd.free()

func test_movement() -> void:
	var gd = _gd()
	var r := _run(gd)
	var first: int = r.available_nodes()[0]
	assert_eq(r.available_nodes().size(), r.map.layers[0].size())
	var bad := -5
	for n in r.map.nodes:
		if not r.available_nodes().has(int(n.id)):
			bad = int(n.id)
			break
	assert_true(not r.move_to(bad))
	assert_true(r.move_to(first))
	assert_eq(r.available_nodes().size(), r.node(first).next.size())
	for x in r.node(first).next:
		assert_true(r.available_nodes().has(int(x)))
	gd.free()

func test_upgrade_remove() -> void:
	var gd = _gd()
	var r := _run(gd)
	assert_true(r.upgrade_card(0))
	assert_true(str(r.deck_cards()[0].name).ends_with("+"))
	assert_true(not r.upgrade_card(0))
	assert_true(not r.upgradeable_indices().has(0))
	assert_eq(r.deck_cards()[3].deck_index, 3)
	var n := 0
	while r.can_remove():
		assert_true(r.remove_card(0))
		n += 1
	assert_eq(r.deck.size(), gd.balance.deck_min)
	assert_eq(r.removes_done, n)
	assert_true(not r.remove_card(0))
	gd.free()

func test_relics() -> void:
	var gd = _gd()
	var r := _run(gd)
	var mh := r.max_hp
	r.hp = 50
	r.add_relic("knights_heart")
	r.add_relic("knights_heart")
	assert_eq(r.max_hp, mh + 10)
	assert_eq(r.hp, 60)
	assert_eq(r.relics.size(), 1)
	var g := r.gold
	r.add_relic("gold_pouch")
	assert_eq(r.gold, g + 30)
	r.add_relic("healing_flask")
	r.move_to(r.available_nodes()[0])
	r.finish_combat(true, 10)
	assert_eq(r.gold, g + 35)
	assert_eq(r.hp, 16)
	r.hp = r.max_hp - 2
	assert_eq(r.heal(6), 2)
	assert_eq(r.hp, r.max_hp)
	gd.free()

func test_defeat_and_shards() -> void:
	var gd = _gd()
	var r := _run(gd)
	r.finish_combat(false, 0)
	assert_eq(r.result, "defeat")
	assert_eq(r.hp, 0)
	r.stats = {"layers": 5, "elites": 1, "battles": 0, "boss": false}
	var s = gd.balance.shards
	assert_eq(r.soul_shards(), 5 * s.per_layer + s.elite)
	gd.free()

func test_encounters() -> void:
	var gd = _gd()
	var r := _run(gd)
	var id: int = r.map.layers[0][0]
	var enc: Array = r.encounter_for(id)
	assert_true(gd.encounters.normal_early.has(enc))
	var boss := -1
	for n in r.map.nodes:
		if n.type == "boss":
			boss = int(n.id)
	assert_eq(r.encounter_for(boss), ["lich_lord"])
	gd.free()

func test_roundtrip() -> void:
	var gd = _gd()
	var r := _run(gd)
	r.move_to(r.available_nodes()[0])
	r.add_relic("gold_pouch")
	r.upgrade_card(1)
	var r2 := Run.from_dict(JSON.parse_string(JSON.stringify(r.to_dict())), gd)
	assert_eq(r2.hp, r.hp)
	assert_eq(r2.gold, r.gold)
	assert_eq(r2.deck, r.deck)
	assert_eq(r2.relics, r.relics)
	assert_eq(r2.current_node, r.current_node)
	assert_eq(r2.visited, r.visited)
	assert_eq(r2.map.layers.size(), r.map.layers.size())
	assert_eq(r2.encounter_for(r.current_node), r.encounter_for(r.current_node))
	gd.free()
