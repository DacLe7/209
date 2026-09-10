class_name WaveManagerTest
extends RefCounted

const WAVE_MANAGER_SCRIPT: Script = preload("res://scripts/systems/wave_manager.gd")
const BASE_HEALTH_SYSTEM_SCRIPT: Script = preload("res://scripts/systems/base_health_system.gd")


func run() -> void:
	_test_new_wave_manager_does_not_start_wave()
	_test_default_lane_configuration_is_safe()
	_test_tier_spawns_the_expected_enemy_count()
	_test_spawned_enemies_receive_vertical_random_lanes()
	_test_enemy_spawned_signal_matches_spawn_count()
	_test_next_tier_starts_while_previous_batch_is_active()
	_test_enemy_signals_are_relayed_to_systems()
	_test_no_batches_are_created_after_tier_thirty()


func _test_tier_spawns_the_expected_enemy_count() -> void:
	var wave_manager: Variant = _create_wave_manager()
	var base_health_system: Node = wave_manager.base_health_system
	wave_manager.advance_time(10.0)

	_assert(wave_manager.active_spawn_batches[0]["tier"] == 1, "The first batch should be tier one.")
	_assert(wave_manager.active_spawn_batches[0]["spawned_count"] == 4, "Tier one should schedule four grunts.")
	_assert(wave_manager.get_child_count() == 4, "Tier one should spawn 3 + tier grunt enemies.")
	wave_manager.clear_wave()
	wave_manager.free()
	base_health_system.free()


func _test_default_lane_configuration_is_safe() -> void:
	var wave_manager: Variant = WAVE_MANAGER_SCRIPT.new()
	_assert(wave_manager.spawn_x_range == Vector2(80.0, 640.0), "WaveManager should provide a safe default horizontal spawn range.")
	_assert(wave_manager.lane_top_y == 80.0 and wave_manager.lane_bottom_y == 1060.0, "WaveManager should provide a complete default vertical lane.")
	wave_manager.free()


func _test_spawned_enemies_receive_vertical_random_lanes() -> void:
	var wave_manager: Variant = _create_wave_manager()
	var base_health_system: Node = wave_manager.base_health_system
	wave_manager.spawn_x_range = Vector2(600.0, 120.0)
	wave_manager.lane_top_y = 60.0
	wave_manager.lane_bottom_y = 1020.0
	wave_manager.advance_time(10.0)

	for enemy in wave_manager.get_children():
		var spawn_x: float = enemy.global_position.x
		_assert(spawn_x >= 120.0 and spawn_x <= 600.0, "Spawned enemy X should stay inside the lane range even when it is configured in reverse.")
		_assert(enemy.global_position.y == 60.0, "Spawned enemy should start at the configured lane top.")
		enemy.move_along_path(1.0)
		_assert(enemy.global_position.x == spawn_x and enemy.global_position.y > 60.0, "Each enemy should move straight down its own vertical lane.")

	wave_manager.clear_wave()
	wave_manager.free()
	base_health_system.free()


func _test_enemy_spawned_signal_matches_spawn_count() -> void:
	var wave_manager: Variant = _create_wave_manager()
	var base_health_system: Node = wave_manager.base_health_system
	var spawned_enemies: Array[Node] = []
	wave_manager.enemy_spawned.connect(func(enemy: Node) -> void:
		spawned_enemies.append(enemy)
	)

	wave_manager.advance_time(5.0)
	var all_spawned_enemies_are_children := true
	for enemy in spawned_enemies:
		if enemy.get_parent() != wave_manager:
			all_spawned_enemies_are_children = false
	_assert(spawned_enemies.size() == 2, "Enemy spawned signal should fire once for each enemy spawned during advance_time.")
	_assert(all_spawned_enemies_are_children, "Enemy spawned signal should provide the spawned child instance.")
	wave_manager.clear_wave()
	wave_manager.free()
	base_health_system.free()


func _test_next_tier_starts_while_previous_batch_is_active() -> void:
	var wave_manager: Variant = _create_wave_manager()
	var base_health_system: Node = wave_manager.base_health_system
	wave_manager.advance_time(5.0)
	_assert(wave_manager.get_child_count() == 2, "Tier one should still have enemies after half of its spawn window.")

	wave_manager.advance_time(5.0)
	_assert(wave_manager.current_tier == 2, "Tier two should begin once tier one's timer expires.")
	_assert(wave_manager.active_spawn_batches.size() == 2, "Tier one and tier two spawn batches should coexist.")
	wave_manager.advance_time(2.0)
	_assert(wave_manager.get_child_count() > 4, "Tier two must spawn even while tier one enemies remain active.")
	wave_manager.clear_wave()
	wave_manager.free()
	base_health_system.free()


func _test_enemy_signals_are_relayed_to_systems() -> void:
	var wave_manager: Variant = _create_wave_manager()
	var killed_exp_values: Array[int] = []
	var reached_base_damage: Array[float] = []
	wave_manager.enemy_killed.connect(func(exp_value: int) -> void:
		killed_exp_values.append(exp_value)
	)
	wave_manager.enemy_reached_base.connect(func(damage: float) -> void:
		reached_base_damage.append(damage)
	)

	wave_manager.advance_time(5.0)
	var enemy: Variant = wave_manager.get_child(0)
	enemy.take_damage(100.0)
	_assert(killed_exp_values == [1], "Enemy death should relay its EXP value through WaveManager.")

	var base_health_system: Node = wave_manager.base_health_system
	base_health_system.reset_health()
	var health_before: float = base_health_system.current_health
	enemy = wave_manager.get_child(1)
	enemy.set_waypoints(PackedVector2Array([Vector2.ZERO, Vector2(1.0, 0.0)]))
	enemy.move_along_path(1.0)
	_assert(reached_base_damage == [1.0], "Enemy reaching base should relay its damage through WaveManager.")
	_assert(base_health_system.current_health == health_before - 1.0, "Enemy reaching base should damage BaseHealthSystem.")
	wave_manager.clear_wave()
	wave_manager.free()
	base_health_system.free()


func _test_no_batches_are_created_after_tier_thirty() -> void:
	var wave_manager: Variant = _create_wave_manager()
	var base_health_system: Node = wave_manager.base_health_system
	wave_manager.advance_time(10.0 * 30.0)
	_assert(wave_manager.current_tier == 30, "Wave schedule must stop at tier thirty.")
	_assert(wave_manager.active_spawn_batches.size() == 30, "Exactly thirty batches should be created.")
	wave_manager.advance_time(100.0)
	_assert(wave_manager.current_tier == 30 and wave_manager.active_spawn_batches.size() == 30, "No batch may be created after tier thirty.")
	wave_manager.clear_wave()
	wave_manager.free()
	base_health_system.free()


func _create_wave_manager() -> Variant:
	var wave_manager: Variant = WAVE_MANAGER_SCRIPT.new()
	wave_manager.tier_duration_seconds = 10.0
	wave_manager.spawn_x_range = Vector2(100.0, 620.0)
	wave_manager.lane_top_y = 0.0
	wave_manager.lane_bottom_y = 1000.0
	wave_manager.grunt_data = _create_enemy_data(1.0)
	wave_manager.boss_data = _create_enemy_data(20.0)
	wave_manager.base_health_system = BASE_HEALTH_SYSTEM_SCRIPT.new()
	wave_manager.start_wave()
	return wave_manager


func _create_enemy_data(exp_value: int) -> EnemyData:
	var enemy_data := EnemyData.new()
	enemy_data.max_hp = 10.0
	enemy_data.move_speed = 10.0
	enemy_data.damage_to_base = 1.0
	enemy_data.exp_value = exp_value
	return enemy_data


func _assert(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		assert(condition, message)

func _test_new_wave_manager_does_not_start_wave() -> void:
	var wave_manager: Variant = WAVE_MANAGER_SCRIPT.new()
	_assert(wave_manager.active_spawn_batches.is_empty(), "A new WaveManager must not create spawn batches before start_wave().")
	_assert(wave_manager.current_tier == 0, "A new WaveManager must remain at tier zero before start_wave().")
	wave_manager.free()
