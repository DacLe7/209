extends SceneTree

const WEAPON_SYSTEM_TEST_SCRIPT := preload("res://tests/weapon_system_test.gd")


func _init() -> void:
	var weapon_system_test: Variant = WEAPON_SYSTEM_TEST_SCRIPT.new()
	weapon_system_test.run()
	quit()
