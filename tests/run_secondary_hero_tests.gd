extends SceneTree

const SECONDARY_HERO_TEST_SCRIPT := preload("res://tests/secondary_hero_test.gd")


func _init() -> void:
	var secondary_hero_test: Variant = SECONDARY_HERO_TEST_SCRIPT.new()
	secondary_hero_test.run()
	quit()
