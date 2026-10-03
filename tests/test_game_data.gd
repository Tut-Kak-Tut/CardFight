extends TestCase

func _gd():
	var gd = load("res://scripts/autoload/game_data.gd").new()
	gd.load_all()
	return gd

func test_counts() -> void:
	var gd = _gd()
	assert_eq(gd.cards.size(), 30)
	assert_eq(gd.characters.size(), 2)
	assert_true(gd.enemies.size() >= 8)
	for pool in gd.encounters.values():
		if not pool is Array:
			continue
		for enc in pool:
			for id in enc:
				assert_true(gd.enemies.has(id), "unknown enemy " + str(id))
	assert_eq(gd.relics.size(), 6)
	gd.free()

func test_validate_clean() -> void:
	var gd = _gd()
	var errs = gd.validate()
	assert_true(errs.is_empty(), "\n".join(errs))
	gd.free()

func test_upgrade() -> void:
	var gd = _gd()
	var c = gd.get_card("strike", true)
	assert_eq(c.name, "Strike+")
	assert_eq(c.effects[0].value, 9)
	assert_eq(c.upgraded, true)
	assert_eq(gd.get_card("bastion", true).cost, 1)
	gd.free()

func test_ints() -> void:
	var gd = _gd()
	assert_eq(typeof(gd.get_card("strike").cost), TYPE_INT)
	gd.free()

func test_validate_catches() -> void:
	var gd = _gd()
	gd.cards["strike"].effects[0].op = "bogus"
	assert_true(not gd.validate().is_empty())
	gd.free()
