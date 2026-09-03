class_name EnemyTest
extends RefCounted

const ENEMY_SCRIPT: Script = preload("res://scripts/entities/enemy.gd")


func run() -> void:
	_test_initializes_stats_from_enemy_data()
	_test_damage_emits_died_once()
	_test_waypoints_move_enemy_and_emit_reached_base_once()


func _test_initializes_stats_from_enemy_data() -> void:
	var enemy: Variant = _create_enemy()

	_assert(enemy.max_hp == 12.0, "Enemy should initialize max HP from EnemyData.")
	_assert(enemy.current_hp == 12.0, "Enemy should start at its maximum HP.")
	_assert(enemy.move_speed == 10.0, "Enemy should initialize move speed from EnemyData.")
	_assert(enemy.damage_to_base == 3.0, "Enemy should initialize base damage from EnemyData.")
	_assert(enemy.exp_value == 7, "Enemy should initialize EXP value from EnemyData.")
	enemy.free()


func _test_damage_emits_died_once() -> void:
	var enemy: Variant = _create_enemy()
	var emitted_exp_values: Array[int] = []
	enemy.died.connect(func(value: int) -> void:
		emitted_exp_values.append(value)
	)

	enemy.take_damage(5.0)
	_assert(enemy.current_hp == 7.0, "Damage should reduce the enemy HP.")
	enemy.take_damage(100.0)
	_assert(enemy.current_hp == 0.0, "Damage must not reduce enemy HP below zero.")
	_assert(enemy.is_queued_for_deletion(), "Enemy should queue itself for deletion after emitting died.")
	enemy.take_damage(1.0)
	_assert(emitted_exp_values == [7], "Enemy death should emit its EXP value exactly once.")
	enemy.free()


func _test_waypoints_move_enemy_and_emit_reached_base_once() -> void:
	var enemy: Variant = _create_enemy()
	var reached_base_damage: Array[float] = []
	enemy.reached_base.connect(func(damage: float) -> void:
		reached_base_damage.append(damage)
	)

	enemy.set_waypoints(PackedVector2Array([Vector2.ZERO, Vector2(10.0, 0.0), Vector2(10.0, 10.0)]))
	enemy.move_along_path(1.5)
	_assert(enemy.global_position == Vector2(10.0, 5.0), "Enemy should consume movement across multiple waypoints.")
	enemy.move_along_path(0.5)
	enemy.move_along_path(1.0)
	_assert(reached_base_damage == [3.0], "Reaching the final waypoint should emit base damage exactly once.")
	enemy.free()


func _create_enemy() -> Variant:
	var enemy_data := EnemyData.new()
	enemy_data.max_hp = 12.0
	enemy_data.move_speed = 10.0
	enemy_data.damage_to_base = 3.0
	enemy_data.exp_value = 7

	var enemy: Variant = ENEMY_SCRIPT.new()
	enemy.initialize(enemy_data)
	return enemy


func _assert(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		assert(condition, message)
