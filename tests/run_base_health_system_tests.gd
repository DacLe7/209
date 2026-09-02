extends SceneTree

const BASE_HEALTH_SYSTEM_TEST_SCRIPT := preload("res://tests/base_health_system_test.gd")


func _init() -> void:
	var base_health_system_test: Variant = BASE_HEALTH_SYSTEM_TEST_SCRIPT.new()
	base_health_system_test.run()
	quit()
