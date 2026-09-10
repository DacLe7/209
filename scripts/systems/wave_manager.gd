extends Node

signal enemy_spawned(enemy: Node)
signal enemy_killed(exp_value: int)
signal enemy_reached_base(damage: float)

const MAX_TIERS := 30
const ENEMY_SCRIPT: Script = preload("res://scripts/entities/enemy.gd")

@export var tier_duration_seconds: float = 15.0
@export var spawn_x_range := Vector2(80.0, 640.0)
@export var lane_top_y := 80.0
@export var lane_bottom_y := 1060.0
@export var grunt_data: EnemyData = preload("res://data/enemies/enemy_grunt.tres")
@export var boss_data: EnemyData = preload("res://data/enemies/enemy_boss_stage1.tres")

var active_spawn_batches: Array[Dictionary] = []
var current_tier := 0
var base_health_system: Node
var _tier_elapsed_seconds := 0.0
var _is_wave_running := false


func _ready() -> void:
	base_health_system = get_node_or_null("/root/BaseHealthSystem")


func _process(delta: float) -> void:
	advance_time(delta)


func start_wave() -> void:
	clear_wave()
	_is_wave_running = true
	_create_next_tier_batch()


func clear_wave() -> void:
	for enemy in get_children():
		if enemy is Node2D:
			enemy.queue_free()
	active_spawn_batches.clear()
	current_tier = 0
	_tier_elapsed_seconds = 0.0
	_is_wave_running = false


func advance_time(delta: float) -> void:
	if not _is_wave_running or delta <= 0.0 or tier_duration_seconds <= 0.0:
		return

	for batch in active_spawn_batches:
		_advance_batch(batch, delta)

	_tier_elapsed_seconds += delta
	while _tier_elapsed_seconds >= tier_duration_seconds and current_tier < MAX_TIERS:
		_tier_elapsed_seconds -= tier_duration_seconds
		_create_next_tier_batch()


func _create_next_tier_batch() -> void:
	if current_tier >= MAX_TIERS:
		return

	current_tier += 1
	var spawn_data: Array[EnemyData] = []
	for _enemy_index in get_grunt_count_for_tier(current_tier):
		spawn_data.append(grunt_data)
	if current_tier == MAX_TIERS:
		spawn_data.append(boss_data)

	active_spawn_batches.append({
		"tier": current_tier,
		"spawn_data": spawn_data,
		"spawned_count": 0,
		"elapsed_seconds": 0.0,
		"spawn_interval_seconds": tier_duration_seconds / float(spawn_data.size()),
	})


func _advance_batch(batch: Dictionary, delta: float) -> void:
	if batch["spawned_count"] >= batch["spawn_data"].size():
		return

	batch["elapsed_seconds"] += delta
	while batch["spawned_count"] < batch["spawn_data"].size() and batch["elapsed_seconds"] >= batch["spawn_interval_seconds"]:
		batch["elapsed_seconds"] -= batch["spawn_interval_seconds"]
		var enemy_data: EnemyData = batch["spawn_data"][batch["spawned_count"]]
		batch["spawned_count"] += 1
		_spawn_enemy(enemy_data, batch["tier"])


func _spawn_enemy(enemy_data: EnemyData, _tier: int) -> Node2D:
	var enemy: Node2D = ENEMY_SCRIPT.new()
	enemy.initialize(enemy_data)
	var spawn_x := randf_range(minf(spawn_x_range.x, spawn_x_range.y), maxf(spawn_x_range.x, spawn_x_range.y))
	enemy.set_waypoints(PackedVector2Array([
		Vector2(spawn_x, lane_top_y),
		Vector2(spawn_x, lane_bottom_y),
	]))
	enemy.died.connect(_on_enemy_died)
	enemy.reached_base.connect(_on_enemy_reached_base)
	add_child(enemy)
	enemy_spawned.emit(enemy)
	return enemy


func _on_enemy_died(exp_value: int) -> void:
	enemy_killed.emit(exp_value)


func _on_enemy_reached_base(damage: float) -> void:
	if base_health_system != null:
		base_health_system.take_damage(damage)
	enemy_reached_base.emit(damage)


func get_active_enemies() -> Array:
	var active_enemies: Array = []
	for enemy in get_children():
		if enemy is Node2D and enemy.has_method("take_damage") and not enemy.is_queued_for_deletion() and enemy.get("current_hp") > 0.0:
			active_enemies.append(enemy)
	return active_enemies


func get_grunt_count_for_tier(tier: int) -> int:
	return 3 + clampi(tier, 1, MAX_TIERS)
