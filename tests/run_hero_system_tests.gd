extends SceneTree

const HERO_SYSTEM_TEST_SCRIPT := preload("res://tests/hero_system_test.gd")


func _init() -> void:
	var hero_system_test: Variant = HERO_SYSTEM_TEST_SCRIPT.new()
	hero_system_test.run()
	quit()
