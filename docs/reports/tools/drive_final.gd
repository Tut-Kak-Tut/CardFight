extends "res://docs/reports/raw/drive_s3.gd"
# Headless scene driver for final test. Screenshots disabled. Usage: godot --headless --path . res://docs/reports/tools/drive_final.tscn -- <phase>
func shot(_n: String) -> void:
	pass

func back(tag: String) -> void:
	var before := cs().name
	cs().notification(NOTIFICATION_WM_GO_BACK_REQUEST)
	await wait(0.8)
	say("BACK on %s(%s): -> scene=%s paused=%s" % [tag, before, cs().name if cs() else "null", str(get_tree().paused)])
	if get_tree().paused:
		await press("Resume", 0.4)

func probe() -> void:
	await press("New Run", 0.8)
	await press("Yes", 0.8)
	say("charsel: " + str(btn_texts()))
	say("sel btns=" + str(btn_texts()))
	await press("Begin", 1.0)
	say("map: " + str(btn_texts()))
	first_node_btn().pressed.emit()
	await wait(1.0)
	var res := await play_screen_combat()
	say("combat " + res + " btns=" + str(btn_texts()))
	cs().rb.pressed.emit()
	await wait(1.0)
	say("rewards: " + str(btn_texts()))
	for b in buttons(cs()):
		say("  btn %s text='%s'" % [b.get_class(), b.text if "text" in b else ""])

func node_btn(want: String) -> TextureButton:
	var pb := pause_btn()
	for b in buttons(cs()):
		if b is TextureButton and b != pb and not b.disabled and b.texture_normal and b.texture_normal.resource_path.get_file() == want and b.get_signal_connection_list("pressed").size() > 1:
			return b
	return null

var visits := {}
func tour() -> void:
	# Continue from existing save
	say("menu btns=" + str(btn_texts()))
	if find_btn("Continue"):
		await press("Continue", 1.0)
		say("CONTINUE -> scene=" + cs().name)
		st("continue")
		await back("continued")
		say("after back scene=" + cs().name)
		SceneRouter.goto("main_menu")
		await wait(0.8)
	await press("Sanctuary", 1.0)
	say("sanctuary scene=" + cs().name + " btns=" + str(btn_texts()))
	await back("sanctuary")
	say("after sanctuary back: " + cs().name)
	if cs().name != "MainMenu" and find_btn("Back"):
		await press("Back", 0.8)
	await press("New Run", 0.8)
	await press("Yes", 0.8)
	await back("charsel")
	say("after charsel back: " + cs().name)
	if find_btn("New Run") == null and find_btn("Begin") == null:
		say("ODD no btns")
	if find_btn("Begin") == null:
		await press("New Run", 0.8)
		if find_btn("Yes"): await press("Yes", 0.8)
	var ch := RunState.run
	await press("Begin", 1.0)
	st("begin")
	await back("map")
	for step in 60:
		var sn: String = cs().name
		visits[sn] = int(visits.get(sn, 0)) + 1
		if sn == "MapScreen":
			var b: TextureButton = node_btn("node_rest.svg")
			if b == null or RunState.run.hp > RunState.run.max_hp * 0.7: b = node_btn("node_merchant.svg")
			if b == null: b = node_btn("node_boss.svg")
			if b == null: b = node_btn("node_battle.svg")
			if b == null: b = node_btn("node_elite.svg")
			if b == null:
				say("MAP: no node button, btns=" + str(btn_texts())); break
			if step == 3: await back("map"); 
			b.pressed.emit()
			await wait(1.0)
			say("entered -> " + cs().name)
		elif sn == "CombatScreen":
			if step < 6: await back("combat")
			var res := await play_screen_combat(60)
			say("combat result=%s hp=%d" % [res, RunState.run.hp])
			if res == "": say("COMBAT TIMEOUT"); break
			var c := find_btn("Continue")
			if c: c.pressed.emit()
			await wait(1.2)
		elif sn == "RewardsScreen":
			if step < 8: await back("rewards")
			var empties: Array = []
			for b in buttons(cs()):
				if b is Button and b.text == "" and not b.disabled: empties.append(b)
			say("rewards empties=%d btns=%s" % [empties.size(), str(btn_texts())])
			for b in empties.slice(0, 1): b.pressed.emit(); await wait(0.4)
			if empties.size() > 1:
				empties[1].pressed.emit(); await wait(0.4)
			if find_btn("Take") and not find_btn("Take").disabled: await press("Take", 0.5)
			if find_btn("Yes"): await press("Yes", 0.5)
			say("rewards after: " + str(btn_texts()))
			await press("Continue", 1.0)
		elif sn == "MerchantScreen":
			say("merchant btns=" + str(btn_texts()))
			await back("merchant")
			RunState.run.gold = 400
			for b in buttons(cs()):
				if b is Button and b.text != "Leave" and not b.disabled and b.text != "": 
					b.pressed.emit(); await wait(0.3)
					if find_btn("Yes"): await press("Yes", 0.3)
			st("merchant-bought")
			await press("Leave", 1.0)
		elif sn == "RestScreen":
			say("rest btns=" + str(btn_texts()))
			await back("rest")
			var rb := find_btn("Upgrade a card")
			if rb and not rb.disabled and step % 2 == 0:
				await press("Upgrade a card", 0.6)
				say("upgrade overlay btns=" + str(btn_texts()))
				var cand: Array = []
				for b in buttons(get_tree().root):
					if b is BaseButton and b.text == "" and b.get_class() != "TextureButton": cand.append(b)
				say("upgrade cand=%d" % cand.size())
				if cand.size() > 0: cand[0].pressed.emit(); await wait(0.6)
				st("after-upgrade")
			else:
				for b in buttons(cs()):
					if b is Button and b.text.begins_with("Rest"): b.pressed.emit(); await wait(0.6); break
			say("rest after btns=" + str(btn_texts()))
			if find_btn("Leave"): await press("Leave", 1.0)
			elif find_btn("Continue"): await press("Continue", 1.0)
		elif sn == "RunResultScreen":
			say("RESULT screen btns=" + str(btn_texts()))
			st("result")
			files()
			await back("result")
			say("scene after result back: " + cs().name)
			break
		else:
			say("UNKNOWN SCENE " + sn + " " + str(btn_texts()))
			await wait(0.5)
	say("visits=" + str(visits))
	st("end")
	files()
	if cs().name != "MainMenu":
		SceneRouter.goto("main_menu"); await wait(0.8)
	await press("Sanctuary", 1.0)
	st("sanct2")
	say("sanct btns=" + str(btn_texts()))
	await back("sanct2")

func tour2() -> void:
	# Sanctuary unlock flow with fake shards (meta restored by caller)
	MetaState.meta.shards = 500
	await press("Sanctuary", 1.0)
	say("sanct btns=" + str(btn_texts()))
	var n := 0
	var sc = cs()
	sc._on_pick("character", "mage")
	await wait(0.5)
	if find_btn("Yes"): await press("Yes", 0.5); n += 1
	for cid in GameData.cards:
		if int(GameData.cards[cid].get("unlock_cost", 0)) == 40:
			sc._on_pick("card", cid)
			await wait(0.5)
			if find_btn("No"): await press("No", 0.5)
			sc._on_pick("card", cid)
			await wait(0.5)
			if find_btn("Yes"): await press("Yes", 0.5); n += 1
			break
	say("sanct pressed %d unlock btns; shards=%d unlocked_cards=%d chars=%s btns=%s" % [n, MetaState.meta.shards, MetaState.meta.unlocked_cards.size(), str(MetaState.meta.unlocked_chars), str(btn_texts())])
	await press("Back", 0.8)
	await press("New Run", 0.8)
	if find_btn("Yes"): await press("Yes", 0.8)
	await press(">", 0.5)
	say("mage page btns=" + str(btn_texts()))
	await press("Begin", 1.0)
	st("mage-begin")
	# merchant
	var r: Run = RunState.run
	r.gold = 400
	r.hp = 30
	RunState.shop = ShopGenerator.generate(GameData, r.character_id, r.unlocked, r.relics, r.removes_done, r.rng)
	RunState.screen = "merchant"
	SceneRouter.goto("merchant")
	await wait(1.0)
	say("merchant btns=" + str(btn_texts()))
	for b in buttons(cs()):
		if b is Button and b.text != "Leave" and b.text != "" and not b.disabled:
			b.pressed.emit(); await wait(0.3)
			if find_btn("Yes"): await press("Yes", 0.3)
			var cand: Array = []
			if find_btn("Cancel"): await press("Cancel", 0.3)
	st("merchant-after")
	await back("merchant")
	say("scene after merchant back: " + cs().name)
	# rest
	r.hp = 20
	RunState.screen = "rest"
	SceneRouter.goto("rest")
	await wait(1.0)
	say("rest btns=" + str(btn_texts()))
	for b in buttons(cs()):
		if b is Button and b.text.begins_with("Rest"):
			b.pressed.emit(); await wait(0.6); break
	st("rest-after")
	say("rest after btns=" + str(btn_texts()))
	if find_btn("Leave"): await press("Leave", 1.0)
	elif find_btn("Continue"): await press("Continue", 1.0)
	say("scene after rest: " + cs().name)
	# save / continue roundtrip
	var before := JSON.stringify(RunState.run.to_dict())
	RunState.save()
	SceneRouter.goto("main_menu")
	await wait(0.8)
	await press("Continue", 1.0)
	var after := JSON.stringify(RunState.run.to_dict())
	say("CONTINUE roundtrip same=%s scene=%s" % [str(before == after), cs().name])
	var da = JSON.parse_string(before)
	var db = JSON.parse_string(after)
	for k in da:
		if JSON.stringify(da[k]) != JSON.stringify(db[k]): say("DIFF key=" + k + " before=" + JSON.stringify(da[k]).substr(0, 200) + " after=" + JSON.stringify(db[k]).substr(0, 200))
	# victory via boss
	var rr: Run = RunState.run
	var boss := -1
	for nd in rr.map.nodes:
		if nd.type == "boss": boss = int(nd.id) if nd.has("id") else rr.map.nodes.find(nd)
	rr.current_node = boss
	RunState.pending = {"node_id": boss, "kind": "boss", "enemies": []}
	RunState.combat_won(40)
	await wait(1.2)
	say("after boss win scene=%s btns=%s result=%s shards=%d" % [cs().name, str(btn_texts()), rr.result, MetaState.meta.shards])
	files()
	await press("Continue", 1.0)
	say("after result Continue: " + cs().name + " " + str(btn_texts()))
	if cs().name != "MainMenu":
		await press("Sanctuary", 1.0) if find_btn("Sanctuary") else null
		say("scene " + cs().name)
	say("has_saved_run=" + str(RunState.has_saved_run()))
