extends Node2D

@export var equipped_weapon_id := "rifle_standard"

var weapon_system: Node
var wave_manager: Node
var _fire_elapsed_seconds := 0.0


func _ready() -> void:
	weapon_system = get_node_or_null("/root/WeaponSystem")
	wave_manager = get_node_or_null("/root/WaveManager")


func _process(delta: float) -> void:
	advance_combat(delta)


func equip(weapon_id: String) -> void:
	equipped_weapon_id = weapon_id
	_fire_elapsed_seconds = 0.0


func advance_combat(delta: float) -> void:
	if delta <= 0.0 or weapon_system == null or wave_manager == null:
		return

	var weapon_stats: Dictionary = weapon_system.get_weapon_stats(equipped_weapon_id)
	var fire_rate: float = weapon_stats.get("fire_rate", 0.0)
	if weapon_stats.is_empty() or fire_rate <= 0.0:
		return

	var cooldown_seconds := 1.0 / fire_rate
	_fire_elapsed_seconds += delta
	while _fire_elapsed_seconds >= cooldown_seconds:
		var targets := _get_targets_in_range(weapon_stats)
		if targets.is_empty():
			_fire_elapsed_seconds = cooldown_seconds
			return

		_fire_elapsed_seconds -= cooldown_seconds
		var damage: float = weapon_stats["damage"]
		for target in targets:
			target.take_damage(damage)


func _get_targets_in_range(weapon_stats: Dictionary) -> Array[Node2D]:
	var targets_in_range: Array[Node2D] = []
	if wave_manager == null:
		return targets_in_range

	var range_distance: float = weapon_stats.get("range_distance", 0.0)
	var closest_distance := INF
	var closest_enemy: Node2D
	for enemy in wave_manager.get_active_enemies():
		var enemy_node := enemy as Node2D
		if enemy_node == null:
			continue

		var distance := global_position.distance_to(enemy_node.global_position)
		if distance > range_distance:
			continue

		if weapon_stats["target_type"] == WeaponData.TargetType.MULTI:
			targets_in_range.append(enemy_node)
		elif distance < closest_distance:
			closest_distance = distance
			closest_enemy = enemy_node

	if closest_enemy != null:
		targets_in_range.append(closest_enemy)
	return targets_in_range
