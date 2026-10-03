extends "res://tests/test_case.gd"


func test_placeholder_fallback() -> void:
	var path = Art.path("bg_combat")
	assert_true(path != "" and (path.ends_with(".svg") or path.ends_with(".png")), "bg_combat has valid path")
	assert_true(Art.tex("bg_combat") != null, "tex loads")


func test_missing() -> void:
	assert_eq(Art.path("nonexistent"), "")
	assert_true(Art.tex("nonexistent") == null, "null tex")


func test_locked_fallback() -> void:
	assert_true(Art.path("player_mage_locked") != "", "locked variant resolves")
