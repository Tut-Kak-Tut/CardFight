extends Node

var run: Run = null
var pending: Dictionary = {}
var reward: Dictionary = {}
var shop: Dictionary = {}
var screen := "map"


func new_run(char_id := "knight", seed_value := -1) -> void:
	run = Run.new()
	run.start(GameData, char_id, MetaState.meta.card_pool(), randi() if seed_value == -1 else seed_value)
	pending = {}
	reward = {}
	shop = {}
	screen = "map"
	save()


func ensure_run() -> void:
	if run != null and run.result == "":
		return
	if run == null and has_saved_run():
		_load()
		return
	new_run()


func save() -> void:
	if run == null:
		return
	SaveManager.save_json(SaveManager.RUN, {"run": run.to_dict(), "pending": pending, "reward": reward,
		"shop": shop, "screen": screen})


func mark_dirty() -> void:
	save()


func has_saved_run() -> bool:
	var d := SaveManager.load_json(SaveManager.RUN)
	return d.has("run") and d["run"] is Dictionary and str(d["run"].get("result", "")) == ""


func _load() -> void:
	var d := SaveManager.load_json(SaveManager.RUN)
	run = Run.from_dict(d["run"], GameData)
	pending = _fix_ints(d.get("pending", {}))
	reward = d.get("reward", {})
	shop = d.get("shop", {})
	screen = str(d.get("screen", "map"))


func _fix_ints(p: Dictionary) -> Dictionary:
	if p.has("node_id"):
		p["node_id"] = int(p["node_id"])
	return p


func continue_run() -> void:
	if not has_saved_run():
		return
	_load()
	SceneRouter.goto(screen)


func finish_run() -> void:
	if run == null or run.result == "":
		return
	MetaState.award(run.seed_value, run.soul_shards())
	SaveManager.delete(SaveManager.RUN)


func abandon() -> void:
	if run == null:
		return
	run.result = "defeat"
	finish_run()
	SceneRouter.goto("run_result")


func enter_node(id: int) -> void:
	run.move_to(id)
	var type := str(run.node(id).get("type", ""))
	match type:
		"battle", "elite", "boss":
			pending = {"node_id": id, "kind": type, "enemies": run.encounter_for(id)}
			screen = "combat"
			save()
			SceneRouter.goto("combat")
		"merchant":
			shop = ShopGenerator.generate(GameData, run.character_id, run.unlocked, run.relics, run.removes_done, run.rng)
			screen = "merchant"
			save()
			SceneRouter.goto("merchant")
		"rest":
			screen = "rest"
			save()
			SceneRouter.goto("rest")


func combat_won(hp_left: int) -> void:
	var kind := str(pending.get("kind", "battle"))
	run.finish_combat(true, hp_left)
	if run.result == "victory":
		finish_run()
		SceneRouter.goto("run_result")
		return
	reward = {
		"kind": kind,
		"gold": RewardGenerator.combat_gold(kind, GameData.balance, run.rng),
		"gold_taken": false,
		"cards": RewardGenerator.card_choices(GameData, run.character_id, run.unlocked, kind, run.rng),
		"card_done": false,
		"relics": RewardGenerator.relic_choices(GameData, run.relics, run.rng) if kind == "elite" else [],
		"relic_done": kind != "elite",
	}
	screen = "rewards"
	save()
	SceneRouter.goto("rewards")


func combat_lost() -> void:
	run.finish_combat(false, 0)
	finish_run()
	SceneRouter.goto("run_result")


func leave_node() -> void:
	run.mark_node_done()
	pending = {}
	screen = "map"
	save()
	SceneRouter.goto("map")
