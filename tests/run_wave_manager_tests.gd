extends SceneTree

const WAVE_MANAGER_TEST_SCRIPT := preload("res://tests/wave_manager_test.gd")


func _init() -> void:
	var wave_manager_test: Variant = WAVE_MANAGER_TEST_SCRIPT.new()
	wave_manager_test.run()
	quit()
