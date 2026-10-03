extends "res://docs/reports/raw/drive_s3.gd"
func shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.resize(img.get_width() / 2, img.get_height() / 2)
	img.save_png(ProjectSettings.globalize_path(SHOTS + "s4_" + name + ".png"))
	say("shot " + name)

func back(tag: String) -> void:
	var before := cs().name
	cs().notification(NOTIFICATION_WM_GO_BACK_REQUEST)
	await wait(1.0)
	say("BACK on %s(%s): -> scene=%s paused=%s tree_alive" % [tag, before, cs().name if cs() else "null", str(get_tree().paused)])

func tour() -> void:
	var sfx := "_" + phase_tag()
	await shot("menu" + sfx)
	await press("Sanctuary", 1.2)
	await shot("sanctuary" + sfx)
	await back("sanctuary")
	await press("New Run", 1.0)
	await shot("charsel" + sfx)
	await press(">")
	await shot("mage_locked" + sfx)
	await back("charsel")
	say("after back from charsel: " + cs().name)
	await press("New Run", 1.0)
	await press("Begin", 1.2)
	await shot("map" + sfx)
	await back("map")
	if get_tree().paused:
		await press("Resume")
	var nb := first_node_btn()
	nb.pressed.emit()
	await wait(1.2)
	await shot("combat" + sfx)
	await back("combat")
	if get_tree().paused:
		await press("Resume")
	var res := await play_screen_combat()
	say("combat " + res)
	cs().rb.pressed.emit()
	await wait(1.2)
	await shot("rewards" + sfx)
	await back("rewards")
	var r: Run = RunState.run
	r.gold = 300
	RunState.shop = ShopGenerator.generate(GameData, r.character_id, r.unlocked, r.relics, r.removes_done, r.rng)
	RunState.screen = "merchant"
	SceneRouter.goto("merchant")
	await wait(1.0)
	await shot("merchant" + sfx)
	await back("merchant")
	RunState.screen = "rest"
	SceneRouter.goto("rest")
	await wait(1.0)
	await shot("rest" + sfx)
	await back("rest")
	say("scene after rest back: " + cs().name)
	pause_btn_safe()
	RunState.abandon()
	await wait(1.5)
	say("scene " + cs().name)
	await shot("result" + sfx)
	await back("result")
	await back("result2")
	SceneRouter.goto("main_menu")
	await wait(1.0)
	await back("menu")

func pause_btn_safe() -> void:
	pass

func phase_tag() -> String:
	return "fsa" if "--fake-safe-area" in OS.get_cmdline_user_args() else "norm"

func sa() -> void:
	for sc in ["main_menu", "map", "combat"]:
		if sc == "main_menu":
			pass
		elif sc == "map":
			await press("New Run", 1.0)
			await press("Begin", 1.2)
		else:
			first_node_btn().pressed.emit()
			await wait(1.2)
		var r := cs() as Control
		var info := "%s root=%s offs=(%s,%s,%s,%s) children:" % [sc, r.name, r.offset_left, r.offset_top, r.offset_right, r.offset_bottom]
		for c in r.get_children():
			if c is Control:
				info += " %s@%s" % [c.name, str(c.global_position)]
		say(info)
		if sc == "main_menu":
			await press("New Run", 1.0)

func dbg() -> void:
	say("args=" + str(OS.get_cmdline_user_args()) + " ins=" + str(SceneRouter._get_insets()))
	await press("Sanctuary", 1.2)
	var r := cs() as Control
	say("sanct offs %s %s %s %s anchors %s" % [r.offset_left, r.offset_top, r.offset_right, r.offset_bottom, r.anchor_right])
	SceneRouter._apply_safe_area()
	say("after manual apply: %s %s" % [r.offset_top, r.global_position])

func big() -> void:
	await press("Continue", 1.2)
	say("scene " + cs().name)
	if cs().name == "MapScreen":
		first_node_btn().pressed.emit()
		await wait(1.2)
	await shot("big_combat")
	var all: Array = []
	all_nodes(cs(), all)
	for n in all:
		if n is TextureRect and n.texture and "final" in n.texture.resource_path:
			say("final tex %s rect=%s" % [n.texture.resource_path, str(n.get_global_rect())])
