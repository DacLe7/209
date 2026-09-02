extends SceneTree

const GAME_STATE_TEST_SCRIPT := preload("res://tests/game_state_test.gd")


func _init() -> void:
	var game_state_test: Variant = GAME_STATE_TEST_SCRIPT.new()
	game_state_test.run()
	quit()
