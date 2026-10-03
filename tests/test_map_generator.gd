extends TestCase

func _cfg() -> Dictionary:
	var d = JSON.parse_string(FileAccess.get_file_as_string("res://data/balance.json"))
	return d["map"]

func _gen(seed_value: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return MapGenerator.generate(_cfg(), rng)

func test_500_seeds_valid() -> void:
	var cfg := _cfg()
	var bad := -1
	for s in range(500):
		if not MapGenerator.validate(_gen(s), cfg).is_empty():
			bad = s
			break
	assert_eq(bad, -1, "first invalid seed")

func test_merchant_max() -> void:
	var cfg := _cfg()
	cfg["merchant_max"] = 3
	var bad := -1
	for s in range(500):
		var rng := RandomNumberGenerator.new()
		rng.seed = s
		var m := MapGenerator.generate(cfg, rng)
		var cnt := 0
		for n in m["nodes"]:
			if n["type"] == "merchant":
				cnt += 1
		if cnt > 3 or not MapGenerator.validate(m, cfg).is_empty():
			bad = s
			break
	assert_eq(bad, -1, "first bad seed")

func test_deterministic() -> void:
	assert_true(_gen(42) == _gen(42), "same seed same map")

func test_shape() -> void:
	var m := _gen(7)
	assert_eq(m["layers"].size(), 10)
	assert_eq(m["layers"][0].size(), 2)
	for id in m["layers"][0]:
		assert_eq(m["nodes"][id]["type"], "battle")
	var last: Array = m["layers"][9]
	assert_eq(last.size(), 1)
	assert_eq(m["nodes"][last[0]]["type"], "boss")

func test_distribution() -> void:
	var battle := 0
	var total := 0
	for s in range(500):
		var m := _gen(s)
		for l in range(1, 9):
			for id in m["layers"][l]:
				total += 1
				if m["nodes"][id]["type"] == "battle":
					battle += 1
	var frac := float(battle) / float(total)
	assert_true(frac >= 0.4 and frac <= 0.6, "battle share %f" % frac)
