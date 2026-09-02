extends Node2D

signal died(exp_value: int)
signal reached_base(damage: float)

@export var enemy_data: EnemyData:
	set(value):
		enemy_data = value
		if enemy_data != null:
			_apply_enemy_data()

var max_hp: float = 0.0
var current_hp: float = 0.0
var move_speed: float = 0.0
var damage_to_base: float = 0.0
var exp_value: int = 0

var _waypoints: PackedVector2Array = []
var _waypoint_index := 0
var _has_died := false
var _has_reached_base := false


func initialize(data: EnemyData) -> void:
	enemy_data = data


func set_waypoints(waypoints: PackedVector2Array) -> void:
	_waypoints = waypoints
	_waypoint_index = 0
	_has_reached_base = false
	if not _waypoints.is_empty():
		global_position = _waypoints[0]


func _process(delta: float) -> void:
	move_along_path(delta)


func take_damage(amount: float) -> void:
	if amount <= 0.0 or current_hp <= 0.0 or _has_reached_base:
		return

	current_hp = maxf(current_hp - amount, 0.0)
	if current_hp == 0.0 and not _has_died:
		_has_died = true
		died.emit(exp_value)


func move_along_path(delta: float) -> void:
	if _has_died or _has_reached_base or _waypoints.size() < 2:
		return

	var movement_remaining := move_speed * delta
	while movement_remaining > 0.0 and _waypoint_index < _waypoints.size() - 1:
		var next_waypoint := _waypoints[_waypoint_index + 1]
		var distance_to_next := global_position.distance_to(next_waypoint)
		if distance_to_next <= movement_remaining:
			global_position = next_waypoint
			movement_remaining -= distance_to_next
			_waypoint_index += 1
		else:
			global_position = global_position.move_toward(next_waypoint, movement_remaining)
			movement_remaining = 0.0

	if _waypoint_index == _waypoints.size() - 1:
		_has_reached_base = true
		reached_base.emit(damage_to_base)


func _apply_enemy_data() -> void:
	max_hp = maxf(0.0, enemy_data.max_hp)
	current_hp = max_hp
	move_speed = maxf(0.0, enemy_data.move_speed)
	damage_to_base = enemy_data.damage_to_base
	exp_value = enemy_data.exp_value
	_has_died = false
	_has_reached_base = false
	# TODO: Instantiate enemy_data.model_scene here after the visual scene pipeline is defined.
