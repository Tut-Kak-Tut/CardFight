class_name ShopGenerator extends RefCounted

static func generate(data, class_id: String, unlocked: Array, owned_relics: Array, removes_done: int, rng) -> Dictionary:
	var shop: Dictionary = data.balance["shop"]
	var p = RewardGenerator.pool(data, class_id, unlocked)
	var chosen: Array = []
	var cards: Array = []
	for rarity in ["common", "uncommon", "rare"]:
		for i in int(shop["cards"][rarity]):
			var id = RewardGenerator.pick_card(data, p, rarity, chosen, rng)
			if id == "":
				break
			chosen.append(id)
			var real = data.cards[id].get("rarity")
			var j = int(shop["card_price_jitter"][real])
			cards.append({"id": id, "price": int(shop["card_price"][real]) + rng.randi_range(-j, j), "sold": false})
	var relics: Array = []
	for id in RewardGenerator.relic_choices(data, owned_relics, rng, int(shop["relics"])):
		relics.append({"id": id, "price": int(shop["relic_price"]), "sold": false})
	return {
		"cards": cards,
		"relics": relics,
		"remove_price": int(shop["remove_price"]) + int(shop["remove_price_step"]) * removes_done,
		"remove_used": false,
		"heal_price": int(shop["heal_price"]),
		"heal_pct": int(shop["heal_pct"]),
		"heal_used": false,
	}
