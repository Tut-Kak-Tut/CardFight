extends Node

const OPS := ["damage", "block", "apply", "draw", "discard", "energy", "heal", "max_hp", "gold"]
const STATUSES := ["vulnerable", "weak", "strength", "poison", "bastion", "strength_per_turn"]
const TARGETS := ["enemy", "all_enemies", "self", "player"]
const TYPES := ["attack", "skill", "power"]
const RARITIES := ["starter", "common", "uncommon", "rare"]
const INTENTS := ["attack", "defend", "buff", "debuff", "attack_defend", "attack_debuff"]

var cards: Dictionary = {}
var characters: Dictionary = {}
var enemies: Dictionary = {}
var relics: Dictionary = {}
var encounters: Dictionary = {}
var balance: Dictionary = {}

func _ready() -> void:
	load_all()

func load_all(dir := "res://data/") -> void:
	cards = _load_indexed(dir, "cards")
	characters = _load_indexed(dir, "characters")
	enemies = _load_indexed(dir, "enemies")
	relics = _load_indexed(dir, "relics")
	var enc = _load_json(dir + "encounters.json")
	encounters = _ints(enc) if enc is Dictionary else {}
	var bal = _load_json(dir + "balance.json")
	balance = _ints(bal) if bal is Dictionary else {}

func _load_json(path: String):
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed == null:
		push_error("GameData: failed to parse " + path)
	return parsed

func _load_indexed(dir: String, key: String) -> Dictionary:
	var out := {}
	var data = _load_json(dir + key + ".json")
	if not (data is Dictionary) or not (data.get(key) is Array):
		return out
	for item in _ints(data[key]):
		out[item["id"]] = item
	return out

func _ints(v):
	if v is float:
		return int(v) if v == floorf(v) else v
	if v is Dictionary:
		var d := {}
		for k in v:
			d[k] = _ints(v[k])
		return d
	if v is Array:
		var a := []
		for x in v:
			a.append(_ints(x))
		return a
	return v

func get_card(id: String, upgraded := false) -> Dictionary:
	if not cards.has(id):
		return {}
	var c: Dictionary = cards[id].duplicate(true)
	var up = c.get("upgraded", {})
	if upgraded and up is Dictionary:
		for k in up:
			c[k] = up[k]
		c["name"] = str(c["name"]) + "+"
	c["upgraded"] = upgraded
	c["can_upgrade"] = not upgraded
	return c

func get_character(id: String) -> Dictionary:
	return characters[id].duplicate(true) if characters.has(id) else {}

func get_enemy(id: String) -> Dictionary:
	return enemies[id].duplicate(true) if enemies.has(id) else {}

func get_relic(id: String) -> Dictionary:
	return relics[id].duplicate(true) if relics.has(id) else {}

func validate() -> Array[String]:
	var errs: Array[String] = []
	for id in cards:
		var c: Dictionary = cards[id]
		var f := "cards: " + str(id) + ": "
		if not (c.get("upgraded") is Dictionary):
			errs.append(f + "missing upgraded")
		else:
			_check_effects(c["upgraded"].get("effects", []), f + "upgraded: ", errs)
		if not TYPES.has(c.get("type")):
			errs.append(f + "bad type " + str(c.get("type")))
		if not RARITIES.has(c.get("rarity")):
			errs.append(f + "bad rarity " + str(c.get("rarity")))
		if not (c.get("cost") is int or c.get("cost") is float) or c["cost"] < 0:
			errs.append(f + "bad cost " + str(c.get("cost")))
		_check_effects(c.get("effects", []), f, errs)
	for id in characters:
		for cid in characters[id].get("deck", []):
			if not cards.has(cid):
				errs.append("characters: " + str(id) + ": unknown card " + str(cid))
	for id in enemies:
		var f := "enemies: " + str(id) + ": "
		for ph in enemies[id].get("phases", []):
			_check_effects(ph.get("on_enter", []), f + "on_enter: ", errs)
			for step in ph.get("pattern", []):
				if not INTENTS.has(step.get("intent")):
					errs.append(f + "bad intent " + str(step.get("intent")))
				_check_effects(step.get("effects", []), f, errs)
	for id in relics:
		var hooks = relics[id].get("hooks", {})
		for h in hooks:
			_check_effects(hooks[h], "relics: " + str(id) + ": " + str(h) + ": ", errs)
	for key in encounters:
		_check_enemy_ids(encounters[key], "encounters: " + str(key) + ": ", errs)
	return errs

func _check_enemy_ids(v, prefix: String, errs: Array[String]) -> void:
	if v is Array:
		for x in v:
			_check_enemy_ids(x, prefix, errs)
	elif v is String and not enemies.has(v):
		errs.append(prefix + "unknown enemy " + v)

func _check_effects(effects, prefix: String, errs: Array[String]) -> void:
	if not (effects is Array):
		errs.append(prefix + "effects is not an array")
		return
	for e in effects:
		if not OPS.has(e.get("op")):
			errs.append(prefix + "bad op " + str(e.get("op")))
		elif e["op"] == "apply" and not STATUSES.has(e.get("status")):
			errs.append(prefix + "bad status " + str(e.get("status")))
		if e.has("target") and not TARGETS.has(e["target"]):
			errs.append(prefix + "bad target " + str(e["target"]))
