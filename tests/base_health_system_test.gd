class_name BaseHealthSystemTest
extends RefCounted

const BASE_HEALTH_SYSTEM_SCRIPT: Script = preload("res://scripts/systems/base_health_system.gd")


func run() -> void:
	_test_damage_clamps_health_at_zero()
	_test_health_changed_signal()
	_test_base_defeated_emits_only_once_until_reset()
	_test_reset_health_restores_the_base()


func _test_damage_clamps_health_at_zero() -> void:
	var base_health_system: Variant = _create_base_health_system()

	base_health_system.take_damage(30.0)
	_assert(base_health_system.current_health == 70.0, "Damage should reduce the base health.")
	base_health_system.take_damage(100.0)
	_assert(base_health_system.current_health == 0.0, "Damage must not reduce base health below zero.")
	base_health_system.take_damage(-10.0)
	_assert(base_health_system.current_health == 0.0, "Non-positive damage must not change base health.")
	base_health_system.free()


func _test_health_changed_signal() -> void:
	var base_health_system: Variant = _create_base_health_system()
	var emitted_values: Array[Vector2] = []
	base_health_system.health_changed.connect(func(current: float, maximum: float) -> void:
		emitted_values.append(Vector2(current, maximum))
	)

	base_health_system.take_damage(25.0)
	_assert(emitted_values == [Vector2(75.0, 100.0)], "Damage should emit the updated current and maximum health values.")
	base_health_system.free()


func _test_base_defeated_emits_only_once_until_reset() -> void:
	var base_health_system: Variant = _create_base_health_system()
	var defeat_count := [0]
	base_health_system.base_defeated.connect(func() -> void:
		defeat_count[0] += 1
	)

	base_health_system.take_damage(100.0)
	base_health_system.take_damage(1.0)
	_assert(defeat_count[0] == 1, "Base defeat should emit only once while the base is at zero health.")
	base_health_system.free()


func _test_reset_health_restores_the_base() -> void:
	var base_health_system: Variant = _create_base_health_system()
	var defeat_count := [0]
	base_health_system.base_defeated.connect(func() -> void:
		defeat_count[0] += 1
	)

	base_health_system.take_damage(100.0)
	base_health_system.reset_health()
	_assert(base_health_system.current_health == base_health_system.max_health, "Retry reset should restore base health to its maximum.")
	base_health_system.take_damage(100.0)
	_assert(defeat_count[0] == 2, "Base defeat should be available again after retry reset.")
	base_health_system.free()


func _create_base_health_system() -> Variant:
	var base_health_system: Variant = BASE_HEALTH_SYSTEM_SCRIPT.new()
	base_health_system.max_health = 100.0
	base_health_system.current_health = 100.0
	return base_health_system


func _assert(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		assert(condition, message)
