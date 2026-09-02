class_name EnergySystemTest
extends RefCounted

const ENERGY_SYSTEM_SCRIPT: Script = preload("res://scripts/systems/energy_system.gd")


func run() -> void:
	_test_spend_energy_and_can_play()
	_test_energy_regenerates_at_the_configured_interval()
	_test_energy_changed_signal()


func _test_spend_energy_and_can_play() -> void:
	var energy_system: Variant = _create_energy_system()
	energy_system.current_energy = 1
	energy_system._last_energy_update_unix_seconds = int(Time.get_unix_time_from_system())

	_assert(energy_system.can_play(), "Energy should allow a level to start when at least one unit remains.")
	_assert(energy_system.spend_energy(), "Spending available energy should succeed.")
	_assert(energy_system.current_energy == 0, "Spending energy should decrease the current value by one.")
	_assert(not energy_system.can_play(), "Energy should prevent a level from starting at zero.")
	_assert(not energy_system.spend_energy(), "Spending energy at zero should fail.")
	energy_system.free()


func _test_energy_regenerates_at_the_configured_interval() -> void:
	var energy_system: Variant = _create_energy_system()
	energy_system.current_energy = 2
	energy_system._last_energy_update_unix_seconds = 100

	energy_system.refresh_energy(100 + energy_system.recharge_interval_seconds - 1)
	_assert(energy_system.current_energy == 2, "Energy must not restore before a full interval passes.")

	energy_system.refresh_energy(100 + energy_system.recharge_interval_seconds)
	_assert(energy_system.current_energy == 3, "Energy should restore one unit after one interval.")

	energy_system.refresh_energy(100 + energy_system.recharge_interval_seconds * 10)
	_assert(energy_system.current_energy == energy_system.max_energy, "Energy regeneration must not exceed the maximum.")
	energy_system.free()


func _test_energy_changed_signal() -> void:
	var energy_system: Variant = _create_energy_system()
	var emitted_values: Array[Vector2i] = []
	energy_system.energy_changed.connect(func(current: int, maximum: int) -> void:
		emitted_values.append(Vector2i(current, maximum))
	)

	energy_system.spend_energy()
	_assert(emitted_values == [Vector2i(4, 5)], "Spending energy should emit the updated current and maximum values.")
	energy_system.free()


func _create_energy_system() -> Variant:
	var energy_system: Variant = ENERGY_SYSTEM_SCRIPT.new()
	energy_system.max_energy = 5
	energy_system.current_energy = 5
	energy_system.recharge_interval_seconds = 20 * 60
	energy_system._last_energy_update_unix_seconds = int(Time.get_unix_time_from_system())
	return energy_system


func _assert(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		assert(condition, message)
