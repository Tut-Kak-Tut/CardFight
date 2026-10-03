extends SceneTree
func _initialize() -> void:
	var specs := {"bg_combat": [Vector2i(1500,1000), Color(0.1,0.5,0.2)], "enemy_ghoul": [Vector2i(1024,1024), Color(0.8,0.2,0.2)], "player_knight": [Vector2i(1024,1024), Color(0.2,0.3,0.9)]}
	for k in specs:
		var im := Image.create(specs[k][0].x, specs[k][0].y, false, Image.FORMAT_RGBA8)
		im.fill(specs[k][1])
		for i in range(0, specs[k][0].x, 100):
			for j in range(specs[k][0].y):
				im.set_pixel(i, j, Color.WHITE)
		for j in range(0, specs[k][0].y, 100):
			for i in range(specs[k][0].x):
				im.set_pixel(i, j, Color.WHITE)
		im.save_png("res://assets/art/final/%s.png" % k)
	quit()
