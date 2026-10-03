extends Node

var run: Run = null
var pending: Dictionary = {}
var reward: Dictionary = {}
var shop: Dictionary = {}


func default_unlocked() -> Array:
	var out: Array = []
	for id in GameData.cards:
		var c: Dictionary = GameData.cards[id]
		if int(c.get("unlock_cost", 0)) == 0 and str(c.get("rarity", "")) != "starter":
			out.append(id)
	return out


func new_run(char_id := "knight", seed_value := -1) -> void:
	run = Run.new()
	run.start(GameData, char_id, default_unlocked(), randi() if seed_value == -1 else seed_value)
	pending = {}
	reward = {}
	shop = {}


func ensure_run() -> void:
	if run == null or run.result != "":
		new_run()


func enter_node(id: int) -> void:
	run.move_to(id)
	var type := str(run.node(id).get("type", ""))
	match type:
		"battle", "elite", "boss":
			pending = {"node_id": id, "kind": type, "enemies": run.encounter_for(id)}
			SceneRouter.goto("combat")
		"merchant":
			shop = ShopGenerator.generate(GameData, run.character_id, run.unlocked, run.relics, run.removes_done, run.rng)
			SceneRouter.goto("merchant")
		"rest":
			SceneRouter.goto("rest")


func combat_won(hp_left: int) -> void:
	var kind := str(pending.get("kind", "battle"))
	run.finish_combat(true, hp_left)
	if run.result == "victory":
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
	SceneRouter.goto("rewards")


func combat_lost() -> void:
	run.finish_combat(false, 0)
	SceneRouter.goto("run_result")


func leave_node() -> void:
	run.mark_node_done()
	pending = {}
	SceneRouter.goto("map")
