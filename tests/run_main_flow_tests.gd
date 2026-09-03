extends SceneTree

const MAIN_FLOW_TEST_SCRIPT := preload("res://tests/main_flow_test.gd")


func _init() -> void:
	var main_flow_test: Variant = MAIN_FLOW_TEST_SCRIPT.new()
	main_flow_test.run(self)
	print("ALL MAIN FLOW TESTS PASSED SUCCESSFULLY!")
	quit()
