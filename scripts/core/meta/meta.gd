class_name Meta extends RefCounted

var data
var shards := 0
var unlocked_cards: Array[String] = []
var unlocked_chars: Array[String] = []
var settings := {"sound": true, "vibration": true}
var awarded_runs: Array[int] = []


func setup(p_data) -> void:
	data = p_data


func card_pool() -> Array:
	var out: Array = []
	for id in data.cards:
		var c: Dictionary = data.cards[id]
		if int(c.get("unlock_cost", 0)) == 0 and str(c.get("rarity", "")) != "starter":
			out.append(id)
	for id in unlocked_cards:
		if not out.has(id):
			out.append(id)
	return out


func is_char_unlocked(id: String) -> bool:
	return cost("char", id) == 0 or unlocked_chars.has(id)


func is_card_unlocked(id: String) -> bool:
	return cost("card", id) == 0 or unlocked_cards.has(id)


func cost(kind: String, id: String) -> int:
	var d: Dictionary = data.cards.get(id, {}) if kind == "card" else data.characters.get(id, {})
	return int(d.get("unlock_cost", 0))


func _is_open(kind: String, id: String) -> bool:
	return is_card_unlocked(id) if kind == "card" else is_char_unlocked(id)


func can_unlock(kind: String, id: String) -> bool:
	var known: bool = data.cards.has(id) if kind == "card" else data.characters.has(id)
	return known and not _is_open(kind, id) and shards >= cost(kind, id)


func unlock(kind: String, id: String) -> bool:
	if not can_unlock(kind, id):
		return false
	shards -= cost(kind, id)
	if kind == "card":
		unlocked_cards.append(id)
	else:
		unlocked_chars.append(id)
	return true


func award(run_seed: int, amount: int) -> bool:
	if awarded_runs.has(run_seed):
		return false
	awarded_runs.append(run_seed)
	shards += amount
	return true


func to_dict() -> Dictionary:
	return {
		"shards": shards,
		"unlocked_cards": unlocked_cards.duplicate(),
		"unlocked_chars": unlocked_chars.duplicate(),
		"settings": settings.duplicate(),
		"awarded_runs": awarded_runs.duplicate(),
	}


static func from_dict(d: Dictionary, p_data) -> Meta:
	var m := Meta.new()
	m.setup(p_data)
	m.shards = int(d.get("shards", 0))
	for id in d.get("unlocked_cards", []):
		m.unlocked_cards.append(str(id))
	for id in d.get("unlocked_chars", []):
		m.unlocked_chars.append(str(id))
	for id in d.get("awarded_runs", []):
		m.awarded_runs.append(int(id))
	var s: Dictionary = d.get("settings", {})
	for k in s:
		m.settings[k] = s[k]
	return m
