class_name GameStateTest
extends RefCounted

const GAME_STATE_SCRIPT: Script = preload("res://scripts/autoload/game_state.gd")
const BASE_HEALTH_SYSTEM_SCRIPT: Script = preload("res://scripts/systems/base_health_system.gd")
const WAVE_MANAGER_SCRIPT: Script = preload("res://scripts/systems/wave_manager.gd")
const LEVEL_SYSTEM_SCRIPT: Script = preload("res://scripts/systems/level_system.gd")
const HERO_SYSTEM_SCRIPT: Script = preload("res://scripts/systems/hero_system.gd")


func run() -> void:
	_test_base_defeat_stops_waves_and_emits_run_failed()
	_test_stage_clear_stops_waves_and_emits_run_completed()
	_test_retry_stage_restores_initial_state()


func _test_base_defeat_stops_waves_and_emits_run_failed() -> void:
	var dependencies := _create_dependencies()
	var game_state: Variant = _create_game_state(dependencies)
	var failed_count := [0]
	game_state.run_failed.connect(func() -> void:
		failed_count[0] += 1
	)

	dependencies.base_health_system.take_damage(100.0)
	var tier_at_failure: int = dependencies.wave_manager.current_tier
	dependencies.wave_manager.advance_time(100.0)
	_assert(failed_count[0] == 1, "Base defeat should emit run_failed once.")
	_assert(tier_at_failure == 0 and dependencies.wave_manager.current_tier == 0, "Base defeat should clear and freeze WaveManager.")
	_cleanup(game_state, dependencies)


func _test_stage_clear_stops_waves_and_emits_run_completed() -> void:
	var dependencies := _create_dependencies()
	var game_state: Variant = _create_game_state(dependencies)
	var completed_count := [0]
	game_state.run_completed.connect(func() -> void:
		completed_count[0] += 1
	)

	dependencies.level_system.stage_cleared.emit()
	var tier_at_completion: int = dependencies.wave_manager.current_tier
	dependencies.wave_manager.advance_time(100.0)
	_assert(completed_count[0] == 1, "Stage clear should emit run_completed once.")
	_assert(tier_at_completion == 0 and dependencies.wave_manager.current_tier == 0, "Stage clear should clear and freeze WaveManager.")
	_cleanup(game_state, dependencies)


func _test_retry_stage_restores_initial_state() -> void:
	var dependencies := _create_dependencies()
	var game_state: Variant = _create_game_state(dependencies)
	dependencies.base_health_system.take_damage(25.0)
	dependencies.level_system.add_exp(17)
	dependencies.hero_system.active_heroes = {"commander_sarah": 2}
	dependencies.wave_manager.advance_time(10.0)

	game_state.retry_stage()
	_assert(dependencies.base_health_system.current_health == dependencies.base_health_system.max_health, "Retry should restore full base health.")
	_assert(dependencies.level_system.current_level == 0 and dependencies.level_system.current_exp == 0, "Retry should reset in-run level progress.")
	_assert(dependencies.hero_system.active_heroes.is_empty(), "Retry should reset in-run hero state.")
	_assert(dependencies.wave_manager.current_tier == 1, "Retry should restart WaveManager from tier one.")
	_assert(dependencies.wave_manager.active_spawn_batches.size() == 1, "Retry should leave only the new tier-one batch.")
	_cleanup(game_state, dependencies)


func _create_dependencies() -> Dictionary:
	var base_health_system: Variant = BASE_HEALTH_SYSTEM_SCRIPT.new()
	var wave_manager: Variant = WAVE_MANAGER_SCRIPT.new()
	wave_manager.tier_duration_seconds = 10.0
	wave_manager.path_waypoints = PackedVector2Array([Vector2.ZERO, Vector2(1000.0, 0.0)])
	wave_manager.base_health_system = base_health_system
	wave_manager.start_wave()
	var level_system: Variant = LEVEL_SYSTEM_SCRIPT.new()
	level_system.base_health_system = base_health_system
	level_system._connect_dependencies()
	var hero_system: Variant = HERO_SYSTEM_SCRIPT.new()
	return {
		"base_health_system": base_health_system,
		"wave_manager": wave_manager,
		"level_system": level_system,
		"hero_system": hero_system,
	}


func _create_game_state(dependencies: Dictionary) -> Variant:
	var game_state: Variant = GAME_STATE_SCRIPT.new()
	game_state.base_health_system = dependencies.base_health_system
	game_state.wave_manager = dependencies.wave_manager
	game_state.level_system = dependencies.level_system
	game_state.hero_system = dependencies.hero_system
	game_state._connect_dependencies()
	return game_state


func _cleanup(game_state: Variant, dependencies: Dictionary) -> void:
	dependencies.wave_manager.clear_wave()
	game_state.free()
	dependencies.level_system.free()
	dependencies.hero_system.free()
	dependencies.wave_manager.free()
	dependencies.base_health_system.free()


func _assert(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		assert(condition, message)
