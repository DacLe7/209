extends SceneTree

const UI_SYSTEM_TEST_SCRIPT := preload("res://tests/ui_system_test.gd")


func _init() -> void:
	var ui_system_test: Variant = UI_SYSTEM_TEST_SCRIPT.new()
	ui_system_test.run(self)
	print("ALL UI SYSTEM TESTS PASSED SUCCESSFULLY!")
	quit()
