extends SceneTree

const ENEMY_TEST_SCRIPT := preload("res://tests/enemy_test.gd")


func _init() -> void:
	var enemy_test: Variant = ENEMY_TEST_SCRIPT.new()
	enemy_test.run()
	quit()
