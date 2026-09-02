class_name LevelSystemTest
extends RefCounted

const LEVEL_SYSTEM_SCRIPT: Script = preload("res://scripts/systems/level_system.gd")
const BASE_HEALTH_SYSTEM_SCRIPT: Script = preload("res://scripts/systems/base_health_system.gd")
const WAVE_MANAGER_SCRIPT: Script = preload("res://scripts/systems/wave_manager.gd")


func run() -> void:
	_test_enemy_killed_adds_one_exp()
	_test_exp_remainder_is_preserved_across_multiple_levels()
	_test_stage_cleared_emits_once_at_level_thirty()
	_test_base_defeat_resets_progress_automatically()


func _test_exp_remainder_is_preserved_across_multiple_levels() -> void:
	var level_system: Variant = _create_level_system()
	var level_up_values: Array[int] = []
	level_system.level_up.connect(func(new_level: int) -> void:
		level_up_values.append(new_level)
	)

	level_system.add_exp(32)
	_assert(level_system.current_level == 2, "Thirty-two EXP should grant two levels at fifteen EXP each.")
	_assert(level_system.current_exp == 2, "EXP above complete level thresholds should remain available.")
	_assert(level_up_values == [1, 2], "Each completed level should emit level_up in order.")
	level_system.free()


func _test_stage_cleared_emits_once_at_level_thirty() -> void:
	var level_system: Variant = _create_level_system()
	var stage_clear_count := [0]
	level_system.stage_cleared.connect(func() -> void:
		stage_clear_count[0] += 1
	)

	level_system.add_exp(level_system.exp_per_level * 30)
	_assert(level_system.current_level == 30, "Stage should reach the maximum level at thirty thresholds.")
	_assert(stage_clear_count[0] == 1, "Stage clear should emit once when level thirty is reached.")
	level_system.add_exp(100)
	_assert(stage_clear_count[0] == 1, "Additional EXP after level thirty must not emit stage clear again.")
	level_system.free()


func _test_base_defeat_resets_progress_automatically() -> void:
	var base_health_system: Variant = BASE_HEALTH_SYSTEM_SCRIPT.new()
	var level_system: Variant = _create_level_system(base_health_system)
	level_system.add_exp(17)
	_assert(level_system.current_level == 1 and level_system.current_exp == 2, "Test setup should create level progress before defeat.")

	base_health_system.take_damage(100.0)
	_assert(level_system.current_level == 0 and level_system.current_exp == 0, "Base defeat should reset in-run level progress automatically.")
	level_system.free()
	base_health_system.free()


func _create_level_system(base_health_system: Variant = null, wave_manager: Variant = null) -> Variant:
	var level_system: Variant = LEVEL_SYSTEM_SCRIPT.new()
	level_system.exp_per_level = 15
	if wave_manager != null:
		level_system.wave_manager = wave_manager
	if base_health_system != null:
		level_system.base_health_system = base_health_system
	level_system._connect_dependencies()
	return level_system


func _assert(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		assert(condition, message)

func _test_enemy_killed_adds_one_exp() -> void:
	var wave_manager: Variant = WAVE_MANAGER_SCRIPT.new()
	var level_system: Variant = _create_level_system(null, wave_manager)

	wave_manager.enemy_killed.emit(20)
	_assert(level_system.current_exp == 1, "Each enemy_killed signal should add one MVP EXP regardless of enemy value.")
	level_system.free()
	wave_manager.free()

