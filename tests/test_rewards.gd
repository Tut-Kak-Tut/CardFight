extends TestCase

func _gd():
	var gd = load("res://scripts/autoload/game_data.gd").new()
	gd.load_all()
	return gd

func _rng(s := 1):
	var r = RandomNumberGenerator.new()
	r.seed = s
	return r

func _start_unlocked(gd) -> Array:
	var u: Array = []
	for id in gd.cards:
		var c = gd.cards[id]
		if int(c.get("unlock_cost", 0)) == 0 and c["rarity"] != "starter":
			u.append(id)
	return u

func _all_nonstarter(gd) -> Array:
	var u: Array = []
	for id in gd.cards:
		if gd.cards[id]["rarity"] != "starter":
			u.append(id)
	return u

func test_pool() -> void:
	var gd = _gd()
	var p = RewardGenerator.pool(gd, "knight", _start_unlocked(gd))
	assert_true(not p.is_empty())
	for id in p:
		assert_true(gd.cards[id]["class"] != "mage", "mage card " + id)
		assert_true(gd.cards[id]["rarity"] != "starter", "starter " + id)
	gd.free()

func test_card_choices() -> void:
	var gd = _gd()
	var rng = _rng()
	var p = RewardGenerator.pool(gd, "knight", _start_unlocked(gd))
	for i in 200:
		var ch = RewardGenerator.card_choices(gd, "knight", _start_unlocked(gd), "battle", rng)
		assert_eq(ch.size(), 3)
		var seen := {}
		for id in ch:
			assert_true(p.has(id))
			seen[id] = true
		assert_eq(seen.size(), 3)
	var full = _all_nonstarter(gd)
	var rares := {"battle": 0, "elite": 0}
	for kind in rares:
		for i in 200:
			for id in RewardGenerator.card_choices(gd, "knight", full, kind, rng):
				if gd.cards[id]["rarity"] == "rare":
					rares[kind] += 1
	assert_true(rares["elite"] > rares["battle"], str(rares))
	gd.free()

func test_gold() -> void:
	var gd = _gd()
	var rng = _rng()
	var b = gd.balance
	for i in 100:
		var g = RewardGenerator.combat_gold("battle", b, rng)
		assert_true(g >= b["gold_battle"][0] and g <= b["gold_battle"][1])
		g = RewardGenerator.combat_gold("elite", b, rng)
		assert_true(g >= b["gold_elite"][0] and g <= b["gold_elite"][1])
	assert_eq(RewardGenerator.combat_gold("boss", b, rng), 0)
	gd.free()

func test_relics() -> void:
	var gd = _gd()
	var rng = _rng()
	var owned = ["knights_heart", "energy_crystal"]
	for i in 50:
		var ch = RewardGenerator.relic_choices(gd, owned, rng)
		assert_eq(ch.size(), 3)
		for id in ch:
			assert_true(not owned.has(id))
	var five = gd.relics.keys().slice(0, 5)
	var ch2 = RewardGenerator.relic_choices(gd, five, rng)
	assert_eq(ch2.size(), 1)
	assert_true(not five.has(ch2[0]))
	gd.free()

func test_shop() -> void:
	var gd = _gd()
	var rng = _rng()
	var sh = gd.balance["shop"]
	for i in 50:
		var s = ShopGenerator.generate(gd, "knight", _all_nonstarter(gd), [], 2, rng)
		assert_eq(s["cards"].size(), 5)
		var seen := {}
		for c in s["cards"]:
			seen[c["id"]] = true
			var r = gd.cards[c["id"]]["rarity"]
			var base = sh["card_price"][r]
			var j = sh["card_price_jitter"][r]
			assert_true(c["price"] >= base - j and c["price"] <= base + j)
		assert_eq(seen.size(), 5)
		assert_eq(s["relics"].size(), 2)
		assert_eq(s["remove_price"], sh["remove_price"] + sh["remove_price_step"] * 2)
	gd.free()
