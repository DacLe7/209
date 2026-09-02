extends SceneTree

const LEVEL_SYSTEM_TEST_SCRIPT := preload("res://tests/level_system_test.gd")


func _init() -> void:
	var level_system_test: Variant = LEVEL_SYSTEM_TEST_SCRIPT.new()
	level_system_test.run()
	quit()
