extends Node2D

signal weapon_fired(from: Vector2, to: Vector2)

var hero_data: HeroData
var current_level := 1
var wave_manager: Node
var _fire_elapsed_seconds := 0.0


func _ready() -> void:
	wave_manager = get_node_or_null("/root/WaveManager")


func _process(delta: float) -> void:
	advance_combat(delta)


func initialize(new_hero_data: HeroData, starting_level := 1) -> void:
	hero_data = new_hero_data
	set_level(starting_level)


func set_level(new_level: int) -> void:
	if hero_data == null:
		return
	current_level = clampi(new_level, 1, hero_data.max_level_per_run)


func advance_combat(delta: float) -> void:
	if delta <= 0.0 or hero_data == null or wave_manager == null or hero_data.fire_rate <= 0.0:
		return

	var cooldown_seconds := 1.0 / hero_data.fire_rate
	_fire_elapsed_seconds += delta
	while _fire_elapsed_seconds >= cooldown_seconds:
		var targets := _get_targets_in_range()
		if targets.is_empty():
			_fire_elapsed_seconds = cooldown_seconds
			return

		_fire_elapsed_seconds -= cooldown_seconds
		var damage := hero_data.base_damage * pow(hero_data.stat_growth_per_level, current_level - 1)
		for target in targets:
			var target_position := target.global_position
			target.take_damage(damage)
			weapon_fired.emit(global_position, target_position)


func _get_targets_in_range() -> Array[Node2D]:
	var targets_in_range: Array[Node2D] = []
	if wave_manager == null or hero_data == null:
		return targets_in_range

	var range_half_width := hero_data.range_half_width
	var range_half_height := hero_data.range_half_height
	var closest_distance := INF
	var closest_enemy: Node2D
	for enemy in wave_manager.get_active_enemies():
		var enemy_node := enemy as Node2D
		if enemy_node == null:
			continue

		var offset := enemy_node.global_position - global_position
		if absf(offset.x) > range_half_width or absf(offset.y) > range_half_height:
			continue
		var distance := offset.length()

		if hero_data.target_type == WeaponData.TargetType.MULTI:
			targets_in_range.append(enemy_node)
		elif distance < closest_distance:
			closest_distance = distance
			closest_enemy = enemy_node

	if closest_enemy != null:
		targets_in_range.append(closest_enemy)
	return targets_in_range
