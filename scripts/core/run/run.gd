class_name Run extends RefCounted

var data
var character_id: String
var max_hp: int
var hp: int
var gold: int
var deck: Array = []
var relics: Array[String] = []
var unlocked: Array = []
var map: Dictionary = {}
var current_node := -1
var visited: Array[int] = []
var removes_done := 0
var result := ""
var stats := {"layers": 0, "battles": 0, "elites": 0, "boss": false}
var rng := RandomNumberGenerator.new()
var seed_value := 0

func start(p_data, char_id: String, p_unlocked: Array, p_seed: int) -> void:
	data = p_data
	character_id = char_id
	unlocked = p_unlocked.duplicate()
	seed_value = p_seed
	rng.seed = p_seed
	var ch: Dictionary = data.get_character(char_id)
	max_hp = int(ch.get("max_hp", 1))
	hp = max_hp
	gold = int(data.balance.get("start_gold", 0))
	deck = []
	for cid in ch.get("deck", []):
		deck.append({"id": cid, "upgraded": false})
	map = MapGenerator.generate(data.balance.map, rng)

func deck_cards() -> Array:
	var out: Array = []
	for i in deck.size():
		var c: Dictionary = data.get_card(deck[i]["id"], deck[i]["upgraded"])
		c["deck_index"] = i
		out.append(c)
	return out

func add_card(id: String) -> void:
	deck.append({"id": id, "upgraded": false})

func can_remove() -> bool:
	return deck.size() > int(data.balance.deck_min)

func remove_card(index: int) -> bool:
	if not can_remove() or index < 0 or index >= deck.size():
		return false
	deck.remove_at(index)
	removes_done += 1
	return true

func upgradeable_indices() -> Array[int]:
	var out: Array[int] = []
	for i in deck.size():
		if not deck[i]["upgraded"]:
			out.append(i)
	return out

func upgrade_card(index: int) -> bool:
	if index < 0 or index >= deck.size() or deck[index]["upgraded"]:
		return false
	deck[index]["upgraded"] = true
	return true

func add_relic(id: String) -> void:
	if relics.has(id):
		return
	var r: Dictionary = data.get_relic(id)
	if r.is_empty():
		return
	relics.append(id)
	for e in r.get("hooks", {}).get("on_pickup", []):
		match e.get("op"):
			"max_hp":
				max_hp += int(e["value"])
				hp += int(e["value"])
			"gold":
				gold += int(e["value"])

func relic_effects(hook: String) -> Array:
	var out: Array = []
	for id in relics:
		out.append_array(data.get_relic(id).get("hooks", {}).get(hook, []))
	return out

func heal(n: int) -> int:
	var before := hp
	hp = mini(hp + n, max_hp)
	return hp - before

func heal_pct(pct: int) -> int:
	return floori(max_hp * pct / 100.0)

func spend(amount: int) -> bool:
	if gold < amount:
		return false
	gold -= amount
	return true

func node(id: int) -> Dictionary:
	var nodes: Array = map.get("nodes", [])
	if id < 0 or id >= nodes.size():
		return {}
	return nodes[id]

func available_nodes() -> Array[int]:
	var out: Array[int] = []
	if result != "":
		return out
	var src: Array = map["layers"][0] if current_node == -1 else node(current_node).get("next", [])
	for x in src:
		out.append(int(x))
	return out

func move_to(id: int) -> bool:
	if not available_nodes().has(id):
		return false
	current_node = id
	visited.append(id)
	return true

func encounter_for(id: int) -> Array:
	var n := node(id)
	var key := "normal_late"
	match n.get("type"):
		"battle":
			if int(n.get("layer", 0)) + 1 <= int(data.encounters.early_max_layer):
				key = "normal_early"
		"elite":
			key = "elite"
		"boss":
			key = "boss"
	var list: Array = data.encounters[key]
	return list[rng.randi_range(0, list.size() - 1)].duplicate()

func finish_combat(won: bool, hp_left: int) -> void:
	hp = clampi(hp_left, 0, max_hp)
	if not won:
		result = "defeat"
		return
	match node(current_node).get("type"):
		"battle":
			stats.battles += 1
		"elite":
			stats.elites += 1
		"boss":
			stats.boss = true
			stats.layers += 1
			result = "victory"
	for e in relic_effects("combat_end"):
		match e.get("op"):
			"heal":
				heal(int(e["value"]))
			"gold":
				gold += int(e["value"])

func mark_node_done() -> void:
	stats.layers += 1

func soul_shards() -> int:
	var s: Dictionary = data.balance.shards
	var total: int = stats.layers * int(s.per_layer) + stats.elites * int(s.elite)
	if stats.boss:
		total += int(s.boss)
	return total

func to_dict() -> Dictionary:
	return {
		"character_id": character_id, "max_hp": max_hp, "hp": hp, "gold": gold,
		"deck": deck.duplicate(true), "relics": relics.duplicate(), "unlocked": unlocked.duplicate(),
		"map": map.duplicate(true), "current_node": current_node, "visited": visited.duplicate(),
		"removes_done": removes_done, "result": result, "stats": stats.duplicate(true),
		"seed_value": seed_value, "rng_state": str(rng.state), "rng_seed": str(rng.seed),
	}

static func from_dict(d: Dictionary, p_data) -> Run:
	var r := Run.new()
	r.data = p_data
	r.character_id = d["character_id"]
	r.max_hp = int(d["max_hp"])
	r.hp = int(d["hp"])
	r.gold = int(d["gold"])
	for c in d["deck"]:
		r.deck.append({"id": c["id"], "upgraded": bool(c["upgraded"])})
	for x in d["relics"]:
		r.relics.append(str(x))
	r.unlocked = d["unlocked"].duplicate()
	r.map = d["map"].duplicate(true)
	r.current_node = int(d["current_node"])
	for x in d["visited"]:
		r.visited.append(int(x))
	r.removes_done = int(d["removes_done"])
	r.result = d["result"]
	r.stats = d["stats"].duplicate(true)
	r.seed_value = int(d["seed_value"])
	r.rng.seed = int(d["rng_seed"])
	r.rng.state = int(d["rng_state"])
	return r
