extends "res://tests/test_case.gd"


func test_placeholder_fallback() -> void:
	assert_true(Art.path("bg_combat").ends_with(".svg"), "bg_combat falls back to svg")
	assert_true(Art.tex("bg_combat") != null, "tex loads")


func test_missing() -> void:
	assert_eq(Art.path("nonexistent"), "")
	assert_true(Art.tex("nonexistent") == null, "null tex")
