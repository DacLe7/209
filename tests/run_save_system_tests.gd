extends SceneTree

const SAVE_SYSTEM_TEST_SCRIPT := preload("res://tests/save_system_test.gd")


func _init() -> void:
	var save_system_test: Variant = SAVE_SYSTEM_TEST_SCRIPT.new()
	save_system_test.run()
	quit()
