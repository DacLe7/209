extends SceneTree

const ENERGY_SYSTEM_TEST_SCRIPT := preload("res://tests/energy_system_test.gd")


func _init() -> void:
	var energy_system_test: Variant = ENERGY_SYSTEM_TEST_SCRIPT.new()
	energy_system_test.run()
	quit()
