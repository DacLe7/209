extends SceneTree

const MAIN_HERO_TEST_SCRIPT := preload("res://tests/main_hero_test.gd")


func _init() -> void:
	var main_hero_test: Variant = MAIN_HERO_TEST_SCRIPT.new()
	main_hero_test.run()
	quit()
