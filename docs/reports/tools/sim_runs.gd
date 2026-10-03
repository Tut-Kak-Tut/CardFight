extends SceneTree
# Headless full-run simulation.
# godot --headless --path . -s docs/reports/tools/sim_runs.gd -- <seeds> <policy: random|smart>
var G

func _initialize() -> void:
	G = load("res://scripts/autoload/game_data.gd").new()
	G.load_all()
	var args := OS.get_cmdline_user_args()
	var n := int(args[0]) if args.size() > 0 else 200
	var policy: String = args[1] if args.size() > 1 else "random"
	for ch in ["knight", "mage"]:
		var wins := 0
		var turns_tot := 0
		var battles_tot := 0
		var layers_tot := 0
		var death := {}
		var gold_end := 0
		var shards_tot := 0
		var gold_spent := 0
		var gold_earned := 0
		var boss_reached := 0
		var runs_turns: Array = []
		var caps := 0
		var deck_tot := 0
		for s in n:
			var r := _run(ch, 1000 + s, policy)
			if r.cap:
				caps += 1
			if r.result == "victory":
				wins += 1
			else:
				death[r.death] = int(death.get(r.death, 0)) + 1
			turns_tot += r.turns
			battles_tot += r.stats.battles
			layers_tot += r.stats.layers
			gold_end += r.gold
			shards_tot += r.shards
			gold_spent += r.spent
			gold_earned += r.earned
			deck_tot += r.deck
			runs_turns.append(r.turns)
			if r.boss:
				boss_reached += 1
		runs_turns.sort()
		var keys: Array = death.keys()
		keys.sort()
		var ds := ""
		for k in keys:
			ds += "%s=%d " % [k, death[k]]
		print("RESULT %s policy=%s n=%d win=%.1f%% boss_reached=%d avg_turns=%.1f med_turns=%d avg_battles=%.1f avg_layers=%.1f avg_gold_end=%.0f avg_earned=%.0f avg_spent=%.0f avg_shards=%.1f avg_deck=%.1f caps=%d" % [ch, policy, n, 100.0 * wins / n, boss_reached, float(turns_tot) / n, runs_turns[n / 2], float(battles_tot) / n, float(layers_tot) / n, float(gold_end) / n, float(gold_earned) / n, float(gold_spent) / n, float(shards_tot) / n, float(deck_tot) / n, caps])
		print("DEATHS %s %s" % [ch, ds])
	quit(0)


func _run(ch: String, seed_v: int, policy: String) -> Dictionary:
	var run := Run.new()
	var meta := Meta.new()
	meta.setup(G)
	run.start(G, ch, meta.card_pool(), seed_v)
	var brng := RandomNumberGenerator.new()
	brng.seed = seed_v * 7 + 1
	var turns := 0
	var spent := 0
	var earned := 0
	var death := ""
	var cap := false
	var guard := 0
	while run.result == "" and guard < 200:
		guard += 1
		var avail := run.available_nodes()
		if avail.is_empty():
			death = "NO_NODES"
			break
		var id: int = avail[brng.randi() % avail.size()]
		if policy == "smart":
			var best := -99
			for a in avail:
				var tt := str(run.node(a).type)
				var sc := 0
				match tt:
					"rest":
						sc = 3 if run.hp < run.max_hp * 0.6 else 1
					"merchant":
						sc = 2 if run.gold >= 100 else 0
					"battle":
						sc = 2
					"elite":
						sc = 1 if run.hp > run.max_hp * 0.7 else -1
					"boss":
						sc = 5
				if sc > best:
					best = sc
					id = a
		run.move_to(id)
		var t := str(run.node(id).type)
		if t in ["battle", "elite", "boss"]:
			var res := _combat(run, brng)
			turns += res.turns
			if res.has("cap"):
				cap = true
			run.finish_combat(res.won, res.hp)
			if not res.won:
				death = "%s@L%d" % [t, int(run.node(id).layer) + 1]
				break
			if run.result == "victory":
				break
			var gold := RewardGenerator.combat_gold(t, G.balance, run.rng)
			run.gold += gold
			earned += gold
			var choices := RewardGenerator.card_choices(G, ch, run.unlocked, t, run.rng)
			_pick(run, choices, brng, policy)
			if t == "elite":
				var rl := RewardGenerator.relic_choices(G, run.relics, run.rng)
				if not rl.is_empty():
					run.add_relic(rl[brng.randi() % rl.size()])
		elif t == "merchant":
			spent += _shop(run, brng, policy)
		elif t == "rest":
			if run.hp < run.max_hp * (0.7 if policy == "smart" else 0.5) or run.upgradeable_indices().is_empty():
				run.heal(run.heal_pct(int(G.balance.rest_heal_pct)))
			else:
				var up := run.upgradeable_indices()
				run.upgrade_card(up[brng.randi() % up.size()])
		run.mark_node_done()
	if run.result == "" and death == "":
		death = "STUCK"
	return {"result": run.result, "turns": turns, "stats": run.stats, "gold": run.gold, "shards": run.soul_shards(), "spent": spent, "earned": earned, "death": death, "boss": run.stats.boss or death.begins_with("boss"), "deck": run.deck.size(), "cap": cap}


func _pick(run: Run, choices: Array, brng, policy: String) -> void:
	if choices.is_empty():
		return
	if policy == "smart":
		if run.deck.size() >= 20:
			return
		var best: String = choices[0]
		var rk := {"common": 0, "uncommon": 1, "rare": 2}
		for c in choices:
			if rk.get(G.cards[c].get("rarity"), 0) > rk.get(G.cards[best].get("rarity"), 0):
				best = c
		run.add_card(best)
	else:
		if brng.randf() < 0.25:
			run.gold += int(G.balance.skip_reward_gold)
			return
		run.add_card(choices[brng.randi() % choices.size()])


func _shop(run: Run, brng, policy: String) -> int:
	var shop := ShopGenerator.generate(G, run.character_id, run.unlocked, run.relics, run.removes_done, run.rng)
	var spent := 0
	for r in shop.relics:
		if run.gold >= r.price:
			run.gold -= r.price
			spent += r.price
			run.add_relic(r.id)
	if run.can_remove() and run.gold >= shop.remove_price and run.deck.size() > 8:
		for i in run.deck.size():
			if run.deck[i].id in ["strike", "spark"] and run.remove_card(i):
				run.gold -= shop.remove_price
				spent += shop.remove_price
				break
	for c in shop.cards:
		if run.gold >= c.price and run.deck.size() < 20 and (policy == "smart" or brng.randf() < 0.5):
			run.gold -= c.price
			spent += c.price
			run.add_card(c.id)
	if run.hp < run.max_hp * 0.6 and run.gold >= shop.heal_price:
		run.gold -= shop.heal_price
		spent += shop.heal_price
		run.heal(run.heal_pct(int(shop.heal_pct)))
	return spent


func _combat(run: Run, _brng) -> Dictionary:
	var p := Combatant.new()
	p.id = run.character_id
	p.name = "p"
	p.max_hp = run.max_hp
	p.hp = run.hp
	p.is_player = true
	var foes: Array = []
	for id in run.encounter_for(run.current_node):
		foes.append(EnemyAI.create(G.get_enemy(str(id))))
	var st := CombatState.new()
	st.setup(p, run.deck_cards(), foes, G.balance, run.rng.randi())
	st.start_combat()
	EffectResolver.resolve(run.relic_effects("combat_start"), st.player, null, st)
	var turns := 0
	while st.result == "":
		turns += 1
		if turns > 150:
			return {"won": false, "hp": 0, "turns": turns, "cap": true}
		var plays := 0
		while st.result == "" and plays < 40:
			plays += 1
			if st.pending_discard > 0:
				st.choose_discard(0)
				continue
			var idx := _choose(st)
			if idx < 0:
				break
			var card: Dictionary = st.hand[idx]
			var tgt := -1
			if card.get("target", "none") == "enemy":
				var bh := 99999
				for i in st.enemies.size():
					if not st.enemies[i].is_dead() and st.enemies[i].hp < bh:
						bh = st.enemies[i].hp
						tgt = i
			if not st.play_card(idx, tgt):
				break
		if st.result == "":
			st.end_player_turn()
	return {"won": st.result == "win", "hp": maxi(st.player.hp, 0), "turns": turns}


func _fx_sum(card: Dictionary, op: String) -> int:
	var s := 0
	for fx in card.get("effects", []):
		if fx.get("op") == op:
			s += int(fx.get("value", 0)) * int(fx.get("times", 1))
	return s


func _first_alive(st: CombatState) -> int:
	for i in st.enemies.size():
		if not st.enemies[i].is_dead():
			return i
	return -1


func _choose(st: CombatState) -> int:
	var threat := 0
	for e in st.alive_enemies():
		var pv := EnemyAI.preview(e, st)
		if pv.damage > 0:
			threat += pv.damage * pv.times
	var need := threat - st.player.block
	var best := -1
	var bs := -1000.0
	for i in st.hand.size():
		var c: Dictionary = st.hand[i]
		var tg := _first_alive(st) if c.get("target", "none") == "enemy" else -1
		if not st.can_play(i, tg):
			continue
		var sc := 1.0
		var blk := _fx_sum(c, "block")
		var dmg := _fx_sum(c, "damage")
		if _fx_sum(c, "draw") > 0 or _fx_sum(c, "energy") > 0:
			sc += 6
		if c.get("type") == "power":
			sc += 5
		sc += blk * (1.0 if need > 0 else 0.1)
		sc += dmg * 0.8 + _fx_sum(c, "heal") * 0.5
		if c.get("target") == "enemy" and dmg == 0:
			sc += 3
		sc -= float(c.cost) * 0.2
		if sc > bs:
			bs = sc
			best = i
	return best
