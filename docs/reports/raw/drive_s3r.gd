extends Node
# Stage 3 driver. Phase via user arg: godot ... res://docs/reports/raw/drive_s3.tscn -- p1
const SHOTS := "res://docs/reports/screens/"
var phase := "p1"

func _ready() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		phase = a[0]
	process_mode = Node.PROCESS_MODE_ALWAYS
	_detach.call_deferred()

func _detach() -> void:
	reparent(get_tree().root)
	get_tree().current_scene = null
	get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")
	await wait(1.0)
	await call(phase)
	print("DRIVE DONE ", phase)
	get_tree().quit()

func wait(t := 0.7) -> void:
	await get_tree().create_timer(t, true).timeout

func cs() -> Node:
	return get_tree().current_scene

func say(s: String) -> void:
	print("[", phase, "] ", s)

func shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path(SHOTS + "s3r_" + name + ".png"))
	say("shot " + name)

func all_nodes(n: Node, out: Array) -> void:
	out.append(n)
	for c in n.get_children():
		all_nodes(c, out)

func buttons(root: Node = null) -> Array:
	var r: Node = root if root else get_tree().root
	var out: Array = []
	all_nodes(r, out)
	var res: Array = []
	for n in out:
		if n is BaseButton and n.is_visible_in_tree():
			res.append(n)
	return res

func btn_texts() -> Array:
	var t: Array = []
	for b in buttons(cs()):
		if "text" in b and b.text != "":
			t.append(b.text + ("(dis)" if b.disabled else ""))
	return t

func find_btn(text: String) -> BaseButton:
	for b in buttons(get_tree().root):
		if "text" in b and b.text == text:
			return b
	return null

func press(text: String, w := 0.8) -> bool:
	var b := find_btn(text)
	if b == null:
		say("NO BUTTON '%s' in %s" % [text, btn_texts()])
		return false
	if b.disabled:
		say("button '%s' disabled" % text)
	b.pressed.emit()
	await wait(w)
	return true

func pause_btn() -> TextureButton:
	for b in buttons(cs()):
		if b is TextureButton and b.texture_normal and b.texture_normal.resource_path.ends_with("icon_pause.svg"):
			return b
	return null

func st(tag := "") -> void:
	var r = RunState.run
	var s := "scene=%s paused=%s shards=%d " % [cs().name if cs() else "null", str(get_tree().paused), MetaState.meta.shards]
	if r:
		var ids := []
		for c in r.deck:
			ids.append(c.id + ("+" if c.upgraded else ""))
		s += "run: char=%s hp=%d/%d gold=%d deck=%d %s relics=%s node=%d result='%s' layers=%d screen=%s" % [r.character_id, r.hp, r.max_hp, r.gold, r.deck.size(), str(ids), str(r.relics), r.current_node, r.result, r.stats.layers, RunState.screen]
	else:
		s += "run=null"
	say(tag + " " + s)

func files() -> void:
	var d := OS.get_user_data_dir()
	for f in ["meta.json", "run.json"]:
		var p: String = d + "/" + f
		if FileAccess.file_exists(p):
			var t := FileAccess.get_file_as_string(p)
			say("FILE %s (%d B)%s" % [f, t.length(), (": " + t.substr(0, 400)) if f == "meta.json" else ""])
		else:
			say("FILE %s ABSENT" % f)

func _tgt(state: CombatState) -> int:
	var bi := -1
	var bh := 99999
	for i in state.enemies.size():
		if not state.enemies[i].is_dead() and state.enemies[i].hp < bh:
			bh = state.enemies[i].hp
			bi = i
	return bi

func play_screen_combat(max_turns := 40) -> String:
	var s = cs()
	var state: CombatState = s.state
	var turns := 0
	while state.result == "" and turns < max_turns:
		turns += 1
		var guard := 0
		while guard < 20 and state.result == "":
			guard += 1
			if state.pending_discard > 0:
				state.choose_discard(0)
				continue
			var best := -1
			var bc := -1
			for i in state.hand.size():
				var c: Dictionary = state.hand[i]
				if state.can_play(i, _tgt(state)) and int(c.cost) > bc:
					bc = int(c.cost)
					best = i
			if best < 0:
				break
			state.play_card(best, _tgt(state))
			s.refresh()
			await wait(0.05)
		if state.result != "":
			break
		s._on_end_turn()
		while s.input_locked and state.result == "":
			await wait(0.1)
	await wait(0.6)
	return state.result

func first_node_btn(want := "node_battle.svg") -> TextureButton:
	var pb := pause_btn()
	for b in buttons(cs()):
		if b is TextureButton and b != pb and not b.disabled and b.get_signal_connection_list("pressed").size() > 1 and b.texture_normal.resource_path.get_file() == want:
			return b
	return null

# =========================== PHASE 1 ===========================
func p1() -> void:
	say("--- MAIN MENU ---")
	await shot("menu")
	say("buttons: " + str(btn_texts()))
	var logo: TextureRect
	var all: Array = []
	all_nodes(cs(), all)
	for n in all:
		if n is TextureRect and n.texture and n.texture.resource_path.ends_with("logo.svg"):
			logo = n
	say("logo tex size=%s rect=%s" % [str(logo.texture.get_size()), str(logo.get_global_rect())])
	st("menu")
	files()
	await press("Settings")
	await shot("settings")
	var all2: Array = []
	all_nodes(get_tree().root, all2)
	for n in all2:
		if n is CheckButton:
			say("toggle '%s' pressed=%s" % [n.text, str(n.button_pressed)])
	for n in all2:
		if n is CheckButton and n.text == "Sound":
			n.button_pressed = false
	for n in all2:
		if n is CheckButton and n.text == "Vibration":
			n.button_pressed = false
	await wait(0.3)
	await shot("settings_off")
	await press("Back")
	files()
	say("--- NEW RUN / CHAR SELECT ---")
	await press("New Run")
	say("scene=" + cs().name + " btns=" + str(btn_texts()))
	await shot("character_select")
	await press(">")
	say("mage page: btns=" + str(btn_texts()))
	await shot("character_mage_locked")
	var act := find_btn("Unlock in Sanctuary · 150")
	if act:
		act.pressed.emit()
		await wait(0.8)
		say("after pressing locked action: scene=" + cs().name + " run=" + str(RunState.run))
	await press("View Deck")
	await shot("character_mage_deck")
	cs()._deck._on_close()
	await wait(0.4)
	await press("<")
	say("back on knight, btns=" + str(btn_texts()))
	var down := InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	down.position = Vector2(800, 700)
	Input.parse_input_event(down)
	await wait(0.1)
	var up := InputEventMouseButton.new()
	up.button_index = MOUSE_BUTTON_LEFT
	up.pressed = false
	up.position = Vector2(300, 700)
	Input.parse_input_event(up)
	await wait(0.4)
	say("after swipe left: page=%d btns=%s" % [cs()._page, str(btn_texts())])
	await press("<")
	await press("View Deck")
	await shot("character_knight_deck")
	cs()._deck._on_close()
	await wait(0.4)
	await press("Begin", 1.2)
	st("after Begin")
	await shot("map")
	files()
	say("--- PAUSE ON MAP ---")
	var pb := pause_btn()
	say("pause btn rect=" + str(pb.get_global_rect()))
	pb.pressed.emit()
	await wait(0.5)
	await shot("pause_map")
	say("paused=" + str(get_tree().paused) + " btns=" + str(btn_texts()))
	await press("Settings")
	await shot("pause_settings")
	await press("Back")
	await press("Resume")
	say("after resume paused=" + str(get_tree().paused))
	pause_btn().pressed.emit()
	await wait(0.4)
	await press("Main Menu", 1.2)
	say("scene=" + cs().name + " btns=" + str(btn_texts()))
	st("menu after pause->menu")
	await shot("menu_with_continue")
	files()
	await press("Continue", 1.2)
	st("after Continue")
	say("--- ENTER BATTLE ---")
	var nb := first_node_btn()
	say("node btn: " + str(nb))
	nb.pressed.emit()
	await wait(1.2)
	st("combat start")
	await shot("combat")
	say("combat pause btn rect=" + str(pause_btn().get_global_rect()))
	pause_btn().pressed.emit()
	await wait(0.5)
	await shot("pause_combat")
	await press("Resume")
	say("combat resumed paused=" + str(get_tree().paused))
	var s = cs()
	s.state.play_card(0, _tgt(s.state))
	s.refresh()
	say("combat after 1 card: hand=%d energy=%d enemyhp=%s" % [s.state.hand.size(), s.state.energy, str(s.state.enemies.map(func(e): return e.hp))])
	pause_btn().pressed.emit()
	await wait(0.4)
	await press("Main Menu", 1.2)
	await press("Continue", 1.2)
	s = cs()
	say("after continue mid-combat: scene=%s hand=%d energy=%d enemyhp=%s" % [s.name, s.state.hand.size(), s.state.energy, str(s.state.enemies.map(func(e): return e.hp))])
	var res := await play_screen_combat()
	say("combat result=" + res + " php=" + str(s.state.player.hp))
	await shot("combat_result")
	s.rb.pressed.emit()
	await wait(1.2)
	st("rewards")
	await shot("rewards")
	for b in buttons(cs()):
		if b.get_child_count() > 1 and b.get_child(1) is Label and b.get_child(1).text.ends_with("Gold"):
			b.pressed.emit()
			break
	await wait(0.5)
	st("gold taken")
	var rs = cs()
	rs.card_views[0].tapped.emit(rs.card_views[0])
	await wait(0.3)
	await press("Take")
	st("card taken")
	await shot("rewards_done")
	await press("Continue", 1.2)
	st("map after reward")
	files()
	var r = RunState.run
	var f := FileAccess.open("user://snap.txt", FileAccess.WRITE)
	f.store_string(JSON.stringify({"hp": r.hp, "gold": r.gold, "deck": r.deck.size(), "node": r.current_node}))
	f.close()
	say("SNAPSHOT saved; quitting")

# =========================== PHASE 2 ===========================
func p2() -> void:
	say("snapshot: " + FileAccess.get_file_as_string("user://snap.txt"))
	say("menu btns=" + str(btn_texts()))
	await press("Continue", 1.2)
	st("after cold Continue")
	await shot("map_after_restart")
	var r: Run = RunState.run
	r.gold = 300
	RunState.shop = ShopGenerator.generate(GameData, r.character_id, r.unlocked, r.relics, r.removes_done, r.rng)
	RunState.screen = "merchant"
	RunState.save()
	SceneRouter.goto("merchant")
	await wait(1.0)
	await shot("merchant")
	var all: Array = []
	all_nodes(cs(), all)
	var cv: CardView
	for n in all:
		if n is CardView:
			cv = n
			break
	say("buying card " + str(cv.card.get("id")))
	cv.tapped.emit(cv)
	await wait(0.5)
	await shot("merchant_confirm")
	await press("Yes", 0.8)
	st("after buy")
	await shot("merchant_bought")
	files()

# =========================== PHASE 3 ===========================
func p3() -> void:
	await press("Continue", 1.2)
	st("after cold Continue (expect merchant)")
	await shot("merchant_after_restart")
	await press("Leave", 1.2)
	st("map")
	var nb := first_node_btn()
	say("node btn " + str(nb) + " pos=" + str(nb.global_position) + " n_btns=" + str(buttons(cs()).size()))
	nb.pressed.emit()
	await wait(2.0)
	say("scene now " + cs().name + " screen=" + RunState.screen + " node=" + str(RunState.run.current_node) + " type=" + str(RunState.run.node(RunState.run.current_node).get("type")))
	var s = cs()
	s.state.play_card(0, _tgt(s.state))
	s.refresh()
	st("combat, 1 card played")
	say("hand=%d energy=%d enemyhp=%s php=%d" % [s.state.hand.size(), s.state.energy, str(s.state.enemies.map(func(e): return e.hp)), s.state.player.hp])
	files()

# =========================== PHASE 4 ===========================
func p4() -> void:
	await press("Continue", 1.2)
	var s = cs()
	st("after cold Continue (expect combat)")
	say("hand=%d energy=%d enemyhp=%s php=%d" % [s.state.hand.size(), s.state.energy, str(s.state.enemies.map(func(e): return e.hp)), s.state.player.hp])
	var res := await play_screen_combat()
	say("result " + res)
	s.rb.pressed.emit()
	await wait(1.2)
	await press("Skip (+10 Gold)")
	await press("Continue", 1.2)
	st("map after 1 win")
	pause_btn().pressed.emit()
	await wait(0.4)
	await press("Abandon Run", 0.6)
	await shot("abandon_confirm")
	await press("Yes", 1.3)
	st("run result")
	await shot("run_result")
	var all: Array = []
	all_nodes(cs(), all)
	for n in all:
		if n is Label and n.text != "":
			say("label: " + n.text)
	files()
	say("btns=" + str(btn_texts()))
	say("second finish_run attempt (should not double award)")
	RunState.finish_run()
	files()
	await press("Sanctuary", 1.2)
	say("scene=" + cs().name)
	st("sanctuary")
	await shot("sanctuary_low")
	await press("Back", 1.0)
	say("menu btns=" + str(btn_texts()))

func p5() -> void:
	say("SETTINGS " + str(MetaState.meta.settings) + " AudioManager: " + str(AudioManager.get_property_list().size()))
	say("menu btns=" + str(btn_texts()))
	st("cold")
	files()

# =========================== SANCTUARY ===========================
func s1() -> void:
	st("start")
	await shot("menu_999")
	await press("Sanctuary", 1.2)
	await shot("sanctuary")
	var sc = cs()
	var all: Array = []
	all_nodes(sc, all)
	var cvs: Array = []
	for n in all:
		if n is CardView:
			cvs.append(n)
	say("sanctuary card views=%d" % cvs.size())
	for n in all:
		if n is ScrollContainer:
			n.scroll_vertical = 100000
	await wait(0.4)
	await shot("sanctuary_bottom")
	for n in all:
		if n is ScrollContainer:
			n.scroll_vertical = 0
	var cv: CardView = cvs[0]
	say("buy card " + str(cv.card.get("id")))
	cv.tapped.emit(cv)
	await wait(0.5)
	await shot("sanctuary_confirm")
	await press("Yes", 0.8)
	say("shards=%d unlocked_cards=%s" % [MetaState.meta.shards, str(MetaState.meta.unlocked_cards)])
	sc._on_pick("char", "mage")
	await wait(0.5)
	await shot("sanctuary_mage_confirm")
	await press("Yes", 0.8)
	say("shards=%d unlocked_chars=%s" % [MetaState.meta.shards, str(MetaState.meta.unlocked_chars)])
	await shot("sanctuary_after")
	files()

func s2() -> void:
	st("cold")
	files()
	await press("Sanctuary", 1.2)
	await shot("sanctuary_after_restart")
	await press("Back", 1.0)
	await press("New Run", 1.0)
	await press(">")
	say("mage page btns=" + str(btn_texts()))
	await shot("character_mage_open")
	await press("Begin", 1.2)
	st("mage run")
	await shot("map_mage")
	first_node_btn().pressed.emit()
	await wait(1.2)
	await shot("combat_mage")
	var s = cs()
	var res := await play_screen_combat()
	say("mage UI fight result=%s php=%d/%d" % [res, s.state.player.hp, s.state.player.max_hp])
	await shot("combat_mage_end")

# =========================== SIMULATION ===========================
func sim_combat(run: Run, enc: Array, seed_v: int) -> String:
	var ch := GameData.get_character(run.character_id)
	var p := Combatant.new()
	p.id = run.character_id
	p.name = str(ch.get("name", ""))
	p.max_hp = run.max_hp
	p.hp = run.hp
	p.is_player = true
	var foes: Array = []
	for id in enc:
		foes.append(EnemyAI.create(GameData.get_enemy(str(id))))
	var state := CombatState.new()
	state.setup(p, run.deck_cards(), foes, GameData.balance, seed_v)
	state.start_combat()
	EffectResolver.resolve(run.relic_effects("combat_start"), state.player, null, state)
	var turns := 0
	while state.result == "" and turns < 60:
		turns += 1
		var guard := 0
		while guard < 30 and state.result == "":
			guard += 1
			if state.pending_discard > 0:
				state.choose_discard(0)
				continue
			var best := -1
			var bs := -1.0
			for i in state.hand.size():
				var c: Dictionary = state.hand[i]
				if not state.can_play(i, _tgt(state)):
					continue
				var sc := float(c.cost) + randf() * 0.5
				if c.get("type", "") == "power":
					sc += 10
				if sc > bs:
					bs = sc
					best = i
			if best < 0:
				break
			state.play_card(best, _tgt(state))
		if state.result != "":
			break
		state.end_player_turn()
	run.hp = clampi(state.player.hp, 0, run.max_hp)
	return state.result

func sim_run(char_id: String, seed_v: int, pool: Array) -> Dictionary:
	var run := Run.new()
	run.start(GameData, char_id, pool, seed_v)
	var guard := 0
	var hp_log := []
	while run.result == "" and guard < 40:
		guard += 1
		var av := run.available_nodes()
		if av.is_empty():
			break
		var pick: int = av[run.rng.randi_range(0, av.size() - 1)]
		for id in av:
			if str(run.node(id).get("type")) == "rest" and run.hp < run.max_hp * 0.6:
				pick = id
		run.move_to(pick)
		var n := run.node(pick)
		var type := str(n.get("type"))
		match type:
			"battle", "elite", "boss":
				var enc := run.encounter_for(pick)
				var hp_before := run.hp
				var res := sim_combat(run, enc, run.rng.randi())
				hp_log.append("%s L%d %s hp %d->%d" % [type, int(n.get("layer", 0)), str(enc), hp_before, run.hp])
				if res == "win":
					run.finish_combat(true, run.hp)
					if run.result == "":
						run.gold += RewardGenerator.combat_gold(type, GameData.balance, run.rng)
						var chs := RewardGenerator.card_choices(GameData, char_id, run.unlocked, type, run.rng)
						if not chs.is_empty():
							run.add_card(str(chs[0]))
						if type == "elite":
							var rl := RewardGenerator.relic_choices(GameData, run.relics, run.rng)
							if not rl.is_empty():
								run.add_relic(str(rl[0]))
						run.mark_node_done()
				else:
					run.finish_combat(false, 0)
					return {"result": "defeat", "type": type, "layer": int(n.get("layer", 0)), "log": hp_log, "shards": run.soul_shards(), "enc": enc}
			"rest":
				run.heal(run.heal_pct(int(GameData.balance.rest_heal_pct)))
				run.mark_node_done()
			"merchant":
				run.mark_node_done()
	return {"result": run.result, "type": "boss", "layer": 99, "log": hp_log, "shards": run.soul_shards(), "enc": []}

func m() -> void:
	for ch in ["knight", "mage"]:
		var pool: Array = MetaState.meta.card_pool()
		var wins := 0
		var deaths := {}
		var shards := 0
		var N := 60
		var sample := ""
		for i in N:
			var r := sim_run(ch, 1000 + i, pool)
			shards += int(r.shards)
			if r.result == "victory":
				wins += 1
			else:
				var k: String = "%s@L%d" % [r.type, int(r.layer)]
				deaths[k] = int(deaths.get(k, 0)) + 1
				var ek := "enc " + str(r.get("enc", []))
				deaths[ek] = int(deaths.get(ek, 0)) + 1
			if i == 0:
				sample = str(r.log)
		say("SIM %s: runs=%d wins=%d (%.0f%%) avg shards=%.1f" % [ch, N, wins, 100.0 * wins / N, float(shards) / N])
		say("SIM %s deaths: %s" % [ch, str(deaths)])
		say("SIM %s sample run: %s" % [ch, sample])

func r1() -> void:
	await shot("menu")
	await press("Settings")
	await shot("settings")
	for n in buttons(get_tree().root):
		if n is CheckButton and (n.text == "Sound" or n.text == "Vibration"):
			n.button_pressed = false
	await wait(0.3)
	await shot("settings_off")
	await press("Back")
	await press("Sanctuary", 1.2)
	await shot("sanctuary")
	var all: Array = []
	all_nodes(cs(), all)
	for n in all:
		if n is ScrollContainer:
			n.scroll_vertical = 300
	await wait(0.4)
	await shot("sanctuary_scrolled")
	for n in all:
		if n is ScrollContainer:
			n.scroll_vertical = 100000
	await wait(0.4)
	await shot("sanctuary_bottom")
	await press("Back", 1.0)
	await press("New Run", 1.0)
	await press("Begin", 1.2)
	first_node_btn().pressed.emit()
	await wait(1.5)
	pause_btn().pressed.emit()
	await wait(0.5)
	await shot("pause")
	var rects := []
	for b in buttons(get_tree().root):
		if "text" in b and b.text != "":
			rects.append("%s=%s" % [b.text, str(b.get_global_rect())])
	say("rects " + str(rects))

func r2() -> void:
	await press("New Run", 1.0)
	await press(">")
	await press("Begin", 1.2)
	first_node_btn().pressed.emit()
	await wait(1.5)
	await shot("combat_mage")

func r3() -> void:
	var all: Array = []
	all_nodes(cs(), all)
	for n in all:
		if n is TextureRect and n.texture:
			say("TR %s %s vis=%s rect=%s mod=%s" % [n.name, n.texture.resource_path.get_file(), str(n.is_visible_in_tree()), str(n.get_global_rect()), str(n.modulate)])
	await press("Settings")
	await press("Sound: ON", 0.4)
	await shot("settings_sound_off")
	await press("Vibration: ON", 0.4)
	await shot("settings_both_off")
	say("btns " + str(btn_texts()))

func r4() -> void:
	await press("Settings")
	for t in ["Sound: ON", "Vibration: ON"]:
		var b := find_btn(t)
		b.button_pressed = not b.button_pressed
		await wait(0.4)
	say("btns " + str(btn_texts()) + " settings=" + str(MetaState.meta.settings))
	await shot("settings_both_off")
	var b2 := find_btn("Sound: OFF")
	if b2:
		b2.button_pressed = not b2.button_pressed
		await wait(0.4)
		await shot("settings_sound_on_vib_off")
