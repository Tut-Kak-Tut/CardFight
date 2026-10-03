extends SceneTree
# Headless full-run simulator with a "decent average player" bot (core logic only, no scenes).
# Usage: "$GODOT" --headless --path . -s tools/sim.gd -- <runs=300> <character=all|knight|mage> [beam=10] [first_seed=1000]
# Combat bot: per-turn beam search over card play orders on cloned CombatState (hidden draw order is
# reshuffled in clones, replan after any card that draws). Evaluation = damage/kills/poison value,
# incoming damage after block (from enemy intents), buffs, HP.
var G
var beam_w := 25
var max_depth := 8

const RELIC_RANK := ["demon_skull", "energy_crystal", "knights_heart", "healing_flask", "old_shield", "gold_pouch"]
# archetype weights per character: [damage, block, poison, draw, strength, aoe]
const ARCH := {
	"knight": {"damage": 0.5, "block": 0.45, "poison": 0.3, "draw": 2.0, "strength": 5.0, "bastion": 4.0, "debuff": 2.0},
	"mage": {"damage": 0.45, "block": 0.35, "poison": 1.3, "draw": 3.0, "strength": 3.0, "bastion": 2.0, "debuff": 2.0},
}
var _cs_cache := {}
var play_counts := {}
var pick_counts := {}


func _initialize() -> void:
	G = load("res://scripts/autoload/game_data.gd").new()
	G.load_all()
	var args := OS.get_cmdline_user_args()
	var n := int(args[0]) if args.size() > 0 else 300
	var who: String = args[1] if args.size() > 1 else "all"
	if args.size() > 2:
		beam_w = int(args[2])
	var seed0 := int(args[3]) if args.size() > 3 else 1000
	var chars: Array = ["knight", "mage"] if who == "all" else [who]
	var t0 := Time.get_ticks_msec()
	for ch in chars:
		_report(ch, n, seed0)
	print("elapsed_s=%.1f" % ((Time.get_ticks_msec() - t0) / 1000.0))
	quit(0)


func _report(ch: String, n: int, seed0: int) -> void:
	play_counts = {}
	pick_counts = {}
	var wins := 0
	var d_type := {}
	var d_layer := {}
	var d_enc := {}
	var turns_tot := 0
	var battles_tot := 0
	var boss_reached := 0
	var boss_hp := 0.0
	var gold_e := 0
	var gold_s := 0
	var shards := 0
	var deck_tot := 0
	var caps := 0
	var plays_runs := 0
	for s in n:
		var r := _run(ch, seed0 + s)
		if r.cap:
			caps += 1
		if r.result == "victory":
			wins += 1
		else:
			d_type[r.dtype] = int(d_type.get(r.dtype, 0)) + 1
			d_layer[r.dlayer] = int(d_layer.get(r.dlayer, 0)) + 1
			d_enc[r.denc] = int(d_enc.get(r.denc, 0)) + 1
		turns_tot += r.turns
		battles_tot += r.battles
		if r.boss_hp >= 0.0:
			boss_reached += 1
			boss_hp += r.boss_hp
		gold_e += r.earned
		gold_s += r.spent
		shards += r.shards
		deck_tot += r.deck
		plays_runs += 1
	var losses := n - wins
	print("== %s runs=%d ==" % [ch, n])
	print("win_rate=%.1f%% caps=%d avg_player_turns=%.1f avg_battles=%.1f boss_reached=%.1f%% hp_at_boss=%.0f%% gold_earned=%.0f gold_spent=%.0f shards=%.1f deck=%.1f" % [100.0 * wins / n, caps, float(turns_tot) / n, float(battles_tot) / n, 100.0 * boss_reached / n, 100.0 * boss_hp / maxf(boss_reached, 1), float(gold_e) / n, float(gold_s) / n, float(shards) / n, float(deck_tot) / n])
	print("deaths_by_type(%% of losses): " + _pct(d_type, losses))
	print("deaths_by_layer(%% of losses): " + _pct(d_layer, losses))
	print("deaths_by_encounter(top): " + _top(d_enc, 8, losses))
	print("cards_taken(per run, top): " + _topf(pick_counts, 10, n))
	print("cards_played(per run, top): " + _topf(play_counts, 10, n))


func _pct(d: Dictionary, tot: int) -> String:
	var keys := d.keys()
	keys.sort()
	var s := ""
	for k in keys:
		s += "%s=%.0f%% " % [k, 100.0 * d[k] / maxf(tot, 1)]
	return s


func _top(d: Dictionary, k: int, tot: int) -> String:
	var items: Array = []
	for key in d:
		items.append([key, d[key]])
	items.sort_custom(func(a, b): return a[1] > b[1])
	var s := ""
	for i in mini(k, items.size()):
		s += "%s=%.0f%% " % [items[i][0], 100.0 * items[i][1] / maxf(tot, 1)]
	return s


func _topf(d: Dictionary, k: int, n: int) -> String:
	var items: Array = []
	for key in d:
		items.append([key, d[key]])
	items.sort_custom(func(a, b): return a[1] > b[1])
	var s := ""
	for i in mini(k, items.size()):
		s += "%s=%.2f " % [items[i][0], float(items[i][1]) / n]
	return s


# ---------------------------------------------------------------- run

func _run(ch: String, seed_v: int) -> Dictionary:
	var run := Run.new()
	var meta := Meta.new()
	meta.setup(G)
	run.start(G, ch, meta.card_pool(), seed_v)
	var turns := 0
	var spent := 0
	var earned := 0
	var dtype := ""
	var dlayer := ""
	var denc := ""
	var cap := false
	var boss_hp := -1.0
	var guard := 0
	while run.result == "" and guard < 200:
		guard += 1
		var avail := run.available_nodes()
		if avail.is_empty():
			break
		var id := _pick_node(run, avail)
		run.move_to(id)
		var t := str(run.node(id).type)
		if t in ["battle", "elite", "boss"]:
			if t == "boss":
				boss_hp = float(run.hp) / run.max_hp
			var enc: Array = run.encounter_for(id)
			var res := _combat(run, enc)
			turns += res.turns
			if res.has("cap"):
				cap = true
			run.finish_combat(res.won, res.hp)
			if not res.won:
				dtype = t
				dlayer = "L%d" % (int(run.node(id).layer) + 1)
				denc = ",".join(enc)
				break
			if run.result == "victory":
				break
			var gold := RewardGenerator.combat_gold(t, G.balance, run.rng)
			run.gold += gold
			earned += gold
			_reward_card(run, RewardGenerator.card_choices(G, ch, run.unlocked, t, run.rng))
			if t == "elite":
				var rl := RewardGenerator.relic_choices(G, run.relics, run.rng)
				if not rl.is_empty():
					run.add_relic(_best_relic(rl))
		elif t == "merchant":
			spent += _shop(run)
		elif t == "rest":
			_rest(run)
		run.mark_node_done()
	return {"result": run.result, "turns": turns, "battles": run.stats.battles + run.stats.elites, "earned": earned, "spent": spent, "shards": run.soul_shards(), "deck": run.deck.size(), "dtype": dtype, "dlayer": dlayer, "denc": denc, "cap": cap, "boss_hp": boss_hp}


func _pick_node(run: Run, avail: Array) -> int:
	var best := -999.0
	var id: int = avail[0]
	var frac := float(run.hp) / run.max_hp
	for a in avail:
		var sc := 0.0
		match str(run.node(a).type):
			"rest":
				sc = 5.0 if frac < 0.6 else 2.0
			"merchant":
				sc = 3.0 if run.gold >= 100 else 1.0
			"battle":
				sc = 3.0
			"elite":
				sc = 3.5 if frac >= 0.6 else -5.0
			"boss":
				sc = 100.0
		if sc > best:
			best = sc
			id = a
	return id


func _best_relic(list: Array) -> String:
	var best: String = list[0]
	var br := 99
	for r in list:
		var k := RELIC_RANK.find(r)
		if k < 0:
			k = 50
		if k < br:
			br = k
			best = r
	return best


func _reward_card(run: Run, choices: Array) -> void:
	var best := ""
	var bs := _take_threshold(run)
	for c in choices:
		var sc := _cscore(G.get_card(c, false), run.character_id) - _dup_penalty(run, c)
		if sc > bs:
			bs = sc
			best = c
	if best == "":
		run.gold += int(G.balance.skip_reward_gold)
		return
	run.add_card(best)
	pick_counts[best] = int(pick_counts.get(best, 0)) + 1


func _take_threshold(run: Run) -> float:
	return 2.0 + maxf(0.0, run.deck.size() - 12) * 0.5


func _dup_penalty(run: Run, id: String) -> float:
	var n := 0
	for c in run.deck:
		if c.id == id:
			n += 1
	return n * 1.5


func _shop(run: Run) -> int:
	var shop := ShopGenerator.generate(G, run.character_id, run.unlocked, run.relics, run.removes_done, run.rng)
	var spent := 0
	if run.can_remove() and run.gold >= shop.remove_price and run.deck.size() > 8:
		var idx := -1
		for base in ["strike", "spark", "defend", "barrier"]:
			if base in ["defend", "barrier"] and _count_id(run, base) <= 2:
				continue
			for i in run.deck.size():
				if run.deck[i].id == base and not run.deck[i].upgraded:
					idx = i
					break
			if idx >= 0:
				break
		if idx >= 0 and run.remove_card(idx):
			run.gold -= shop.remove_price
			spent += shop.remove_price
	for r in shop.relics:
		if run.gold >= r.price:
			run.gold -= r.price
			spent += r.price
			run.add_relic(r.id)
	var cards: Array = shop.cards.duplicate()
	cards.sort_custom(func(a, b): return _cscore(G.get_card(a.id, false), run.character_id) > _cscore(G.get_card(b.id, false), run.character_id))
	for c in cards:
		var sc := _cscore(G.get_card(c.id, false), run.character_id) - _dup_penalty(run, c.id)
		if run.gold >= c.price and sc > _take_threshold(run) + 1.0:
			run.gold -= c.price
			spent += c.price
			run.add_card(c.id)
			pick_counts[c.id] = int(pick_counts.get(c.id, 0)) + 1
	if run.hp < run.max_hp * 0.5 and run.gold >= shop.heal_price:
		run.gold -= shop.heal_price
		spent += shop.heal_price
		run.heal(run.heal_pct(int(shop.heal_pct)))
	return spent


func _count_id(run: Run, id: String) -> int:
	var n := 0
	for c in run.deck:
		if c.id == id:
			n += 1
	return n


func _rest(run: Run) -> void:
	var up := run.upgradeable_indices()
	if run.hp < run.max_hp * 0.5 or up.is_empty():
		run.heal(run.heal_pct(int(G.balance.rest_heal_pct)))
		return
	var best: int = up[0]
	var bs := -999.0
	for i in up:
		var sc := _cscore(G.get_card(run.deck[i].id, true), run.character_id)
		if sc > bs:
			bs = sc
			best = i
	run.upgrade_card(best)


# ---------------------------------------------------------------- card static score

func _fx_sum(card: Dictionary, op: String, status := "") -> float:
	var s := 0.0
	for fx in card.get("effects", []):
		if fx.get("op") == op and (status == "" or fx.get("status", "") == status):
			var v := float(fx.get("value", 0)) * float(fx.get("times", 1))
			if fx.get("target", "") == "all_enemies":
				v *= 1.7
			s += v
	return s


func _cscore(card: Dictionary, ch: String) -> float:
	var key := "%s|%s|%s" % [card.id, card.get("upgraded", ""), ch]
	var sig := key + str(card.get("effects", []).hash()) + str(card.cost)
	if _cs_cache.has(sig):
		return _cs_cache[sig]
	var w: Dictionary = ARCH.get(ch, ARCH.knight)
	var cost := float(card.cost)
	var s := 0.0
	s += _fx_sum(card, "damage") * w.damage
	s += _fx_sum(card, "block") * w.block
	s += _fx_sum(card, "apply", "poison") * w.poison
	s += _fx_sum(card, "draw") * w.draw
	s += _fx_sum(card, "energy") * 4.0
	s += _fx_sum(card, "heal") * 0.5
	s += _fx_sum(card, "apply", "strength") * w.strength
	s += _fx_sum(card, "apply", "strength_per_turn") * w.strength * 3.0
	s += _fx_sum(card, "apply", "bastion") * w.bastion
	s += (_fx_sum(card, "apply", "vulnerable") + _fx_sum(card, "apply", "weak")) * w.debuff
	if card.get("exhaust", false):
		s *= 0.8
	s -= cost * 1.2
	if card.get("rarity") == "rare":
		s += 2.0
	if card.get("rarity") == "starter":
		s -= 2.0
	_cs_cache[sig] = s
	return s


# ---------------------------------------------------------------- combat

func _combat(run: Run, enc: Array) -> Dictionary:
	var p := Combatant.new()
	p.id = run.character_id
	p.name = "p"
	p.max_hp = run.max_hp
	p.hp = run.hp
	p.is_player = true
	var foes: Array = []
	for id in enc:
		foes.append(EnemyAI.create(G.get_enemy(str(id))))
	var st := CombatState.new()
	st.setup(p, run.deck_cards(), foes, G.balance, run.rng.randi())
	st.start_combat()
	EffectResolver.resolve(run.relic_effects("combat_start"), st.player, null, st)
	var turns := 0
	while st.result == "":
		turns += 1
		if turns > 60:
			return {"won": false, "hp": 0, "turns": turns, "cap": true}
		var guard := 0
		while st.result == "" and guard < 30:
			guard += 1
			_resolve_discards(st)
			var plan := _plan(st)
			if plan.is_empty():
				break
			var replan := false
			for act in plan:
				var hi := _find_uid(st, int(act.uid))
				if hi < 0 or not st.can_play(hi, int(act.tgt)):
					break
				var card: Dictionary = st.hand[hi]
				var cid := str(card.id)
				play_counts[cid] = int(play_counts.get(cid, 0)) + 1
				st.play_card(hi, int(act.tgt))
				_resolve_discards(st)
				if st.result != "" or _reveals(card):
					break
		if st.result == "":
			st.end_player_turn()
	return {"won": st.result == "win", "hp": maxi(st.player.hp, 0), "turns": turns}


func _reveals(card: Dictionary) -> bool:
	return _fx_sum(card, "draw") > 0


func _find_uid(st: CombatState, uid: int) -> int:
	for i in st.hand.size():
		if int(st.hand[i].uid) == uid:
			return i
	return -1


func _resolve_discards(st: CombatState) -> void:
	var g := 0
	while st.pending_discard > 0 and not st.hand.is_empty() and g < 10:
		g += 1
		var bi := 0
		var bv := 1e9
		for i in st.hand.size():
			var c: Dictionary = st.hand[i]
			var v := _cscore(c, st.player.id)
			if int(c.cost) > st.energy:
				v -= 3.0
			if v < bv:
				bv = v
				bi = i
		st.choose_discard(bi)


func _clone(st: CombatState) -> CombatState:
	var c := CombatState.new()
	c.player = _clone_c(st.player)
	for e in st.enemies:
		c.enemies.append(_clone_c(e))
	c.draw_pile = st.draw_pile.duplicate()
	c.hand = st.hand.duplicate()
	c.discard_pile = st.discard_pile.duplicate()
	c.exhaust_pile = st.exhaust_pile.duplicate()
	c.powers.assign(st.powers)
	c.energy = st.energy
	c.max_energy = st.max_energy
	c.turn = st.turn
	c.balance = st.balance
	c.pending_discard = st.pending_discard
	c.result = st.result
	c.rng.seed = st.rng.seed
	c.rng.state = st.rng.state
	return c


func _clone_c(x: Combatant) -> Combatant:
	var c := Combatant.new()
	c.id = x.id
	c.name = x.name
	c.max_hp = x.max_hp
	c.hp = x.hp
	c.block = x.block
	c.statuses = x.statuses.duplicate()
	c.is_player = x.is_player
	c.data = x.data
	c.phase_index = x.phase_index
	c.pattern_index = x.pattern_index
	c.intent = x.intent
	return c


func _plan(st: CombatState) -> Array:
	var root := _clone(st)
	root._shuffle(root.draw_pile) # hide the real draw order from the planner
	var best_score := _eval(root)
	var best_acts: Array = []
	var frontier: Array = [{"st": root, "acts": [], "sig": []}]
	for depth in max_depth:
		var nxt: Array = []
		var seen := {}
		for node in frontier:
			var s: CombatState = node.st
			var tried := {}
			for i in s.hand.size():
				var c: Dictionary = s.hand[i]
				var tg_list: Array = [-1]
				if c.get("target", "none") == "enemy":
					tg_list = []
					for k in s.enemies.size():
						if not s.enemies[k].is_dead():
							tg_list.append(k)
				for tg in tg_list:
					if not s.can_play(i, tg):
						continue
					var tk := "%s|%s|%s" % [c.id, c.get("upgraded", ""), tg]
					if tried.has(tk):
						continue
					tried[tk] = true
					var ns := _clone(s)
					ns.play_card(i, tg)
					_resolve_discards(ns)
					var sig: Array = node.sig.duplicate()
					sig.append(int(c.uid) * 10 + tg + 1)
					var sk := str(_sorted(sig))
					if seen.has(sk):
						continue
					seen[sk] = true
					var acts: Array = node.acts.duplicate()
					acts.append({"uid": c.uid, "tgt": tg})
					var sc := _eval(ns)
					nxt.append({"st": ns, "acts": acts, "sig": sig, "sc": sc})
					if sc > best_score:
						best_score = sc
						best_acts = acts
		if nxt.is_empty():
			break
		nxt.sort_custom(func(a, b): return a.sc > b.sc)
		if nxt.size() > beam_w:
			nxt.resize(beam_w)
		frontier = nxt
	return best_acts


func _sorted(a: Array) -> Array:
	var b := a.duplicate()
	b.sort()
	return b


func _eval(st: CombatState) -> float:
	var p := st.player
	if st.result == "win":
		return 10000.0 + p.hp * 3.0
	if st.result == "lose" or p.hp <= 0:
		return -10000.0
	var sc := 0.0
	var incoming := 0.0
	for e in st.enemies:
		if e.is_dead():
			sc += 12.0 + e.max_hp * 0.3
			continue
		var pz := e.get_status("poison")
		var pval := minf(pz * (pz + 1) * 0.5, float(e.hp)) * 0.65
		sc += (e.max_hp - e.hp - e.block) * 1.0 + pval
		sc += 2.5 * mini(e.get_status("vulnerable"), 2)
		var pv := EnemyAI.preview(e, st)
		if pv.damage > 0:
			incoming += pv.damage * pv.times
	var unblocked := maxf(0.0, incoming - p.block)
	if unblocked >= p.hp:
		sc -= 5000.0 + unblocked
	sc -= unblocked * 1.6
	sc += p.hp * 1.6
	if p.get_status("bastion") > 0:
		sc += 8.0 + minf(maxf(0.0, p.block - incoming), 20.0) * 0.4
	sc += p.get_status("strength") * 4.0 + p.get_status("strength_per_turn") * 10.0
	sc -= p.get_status("weak") * 1.5 + p.get_status("vulnerable") * 2.0 + p.get_status("poison") * 2.0
	sc += st.exhaust_pile.size() * -0.8
	return sc
