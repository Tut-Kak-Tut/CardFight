class_name RewardGenerator extends RefCounted

static func pool(data, class_id: String, unlocked: Array) -> Array:
	var res: Array = []
	for id in unlocked:
		var c = data.cards.get(id)
		if c == null:
			continue
		if (c.get("class") == class_id or c.get("class") == "neutral") and c.get("rarity") != "starter":
			res.append(id)
	return res

static func combat_gold(kind: String, balance: Dictionary, rng) -> int:
	if kind == "boss":
		return 0
	var r = balance["gold_elite"] if kind == "elite" else balance["gold_battle"]
	return rng.randi_range(int(r[0]), int(r[1]))

static func roll_rarity(kind: String, balance: Dictionary, rng) -> String:
	var w: Dictionary = balance["rarity_weights"]["elite" if kind == "elite" else "normal"]
	var total := 0
	for k in w:
		total += int(w[k])
	var roll = rng.randi_range(1, total)
	for k in ["common", "uncommon", "rare"]:
		roll -= int(w.get(k, 0))
		if roll <= 0:
			return k
	return "common"

# Picks an unchosen id of the given rarity from pool with fallback; "" if none.
static func pick_card(data, pool_ids: Array, rarity: String, chosen: Array, rng) -> String:
	for r in [rarity, "rare", "uncommon", "common", ""]:
		var cands: Array = []
		for id in pool_ids:
			if chosen.has(id):
				continue
			if r == "" or data.cards[id].get("rarity") == r:
				cands.append(id)
		if not cands.is_empty():
			return cands[rng.randi_range(0, cands.size() - 1)]
	return ""

static func card_choices(data, class_id: String, unlocked: Array, kind: String, rng, n := 3) -> Array:
	var p = pool(data, class_id, unlocked)
	var res: Array = []
	for i in n:
		var id = pick_card(data, p, roll_rarity(kind, data.balance, rng), res, rng)
		if id == "":
			break
		res.append(id)
	return res

static func relic_choices(data, owned: Array, rng, n := 3) -> Array:
	var avail: Array = []
	for id in data.relics:
		if not owned.has(id):
			avail.append(id)
	var res: Array = []
	while res.size() < n and not avail.is_empty():
		var i = rng.randi_range(0, avail.size() - 1)
		res.append(avail[i])
		avail.remove_at(i)
	return res
