extends TestCase

func _gd():
	var gd = load("res://scripts/autoload/game_data.gd").new()
	gd.load_all()
	return gd

func _meta(gd) -> Meta:
	return Meta.from_dict({}, gd)

func test_pool_start() -> void:
	var gd = _gd()
	assert_eq(_meta(gd).card_pool().size(), 11)
	gd.free()

func test_unlock_card() -> void:
	var gd = _gd()
	var m := _meta(gd)
	var id := ""
	for k in gd.cards:
		if int(gd.cards[k].get("unlock_cost", 0)) > 0:
			id = k
			break
	var c := m.cost("card", id)
	assert_true(not m.unlock("card", id))
	m.shards = c + 5
	assert_true(m.unlock("card", id))
	assert_eq(m.shards, 5)
	assert_true(m.is_card_unlocked(id))
	assert_true(m.card_pool().has(id))
	m.shards = c
	assert_true(not m.unlock("card", id))
	assert_eq(m.shards, c)
	gd.free()

func test_unlock_char() -> void:
	var gd = _gd()
	var m := _meta(gd)
	assert_true(m.is_char_unlocked("knight"))
	assert_true(not m.is_char_unlocked("mage"))
	m.shards = m.cost("char", "mage")
	assert_true(m.unlock("char", "mage"))
	assert_true(m.is_char_unlocked("mage"))
	assert_eq(m.shards, 0)
	gd.free()

func test_award_once() -> void:
	var gd = _gd()
	var m := _meta(gd)
	assert_true(m.award(7, 10))
	assert_true(not m.award(7, 10))
	assert_eq(m.shards, 10)
	gd.free()

func test_roundtrip() -> void:
	var gd = _gd()
	var m := _meta(gd)
	m.shards = 500
	m.unlock("char", "mage")
	m.award(99, 3)
	m.settings.sound = false
	var m2 := Meta.from_dict(JSON.parse_string(JSON.stringify(m.to_dict())), gd)
	assert_eq(m2.shards, m.shards)
	assert_eq(m2.unlocked_chars, m.unlocked_chars)
	assert_eq(m2.awarded_runs, m.awarded_runs)
	assert_eq(m2.settings.sound, false)
	assert_eq(m2.settings.vibration, true)
	assert_true(not m2.award(99, 1))
	gd.free()

func test_defaults() -> void:
	var gd = _gd()
	var m := _meta(gd)
	assert_eq(m.shards, 0)
	assert_eq(m.unlocked_cards.size(), 0)
	assert_eq(m.settings.sound, true)
	gd.free()
