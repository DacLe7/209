class_name SecondaryHeroTest
extends RefCounted

const SECONDARY_HERO_SCRIPT: Script = preload("res://scripts/entities/secondary_hero.gd")
const WAVE_MANAGER_SCRIPT: Script = preload("res://scripts/systems/wave_manager.gd")
const ENEMY_SCRIPT: Script = preload("res://scripts/entities/enemy.gd")
const COMMANDER_DATA: HeroData = preload("res://data/heroes/hero_commander.tres")
const SNIPER_DATA: HeroData = preload("res://data/heroes/hero_sniper.tres")


func run() -> void:
	_test_fires_at_the_configured_fire_rate()
	_test_single_target_hero_hits_only_nearest_enemy()
	_test_multi_target_hero_hits_every_enemy_in_range()
	_test_rectangular_range_allows_corner_and_rejects_axis_overflow()
	_test_level_scales_damage_and_clamps_to_run_limit()


func _test_fires_at_the_configured_fire_rate() -> void:
	var dependencies := _create_dependencies()
	var hero: Variant = _create_hero(dependencies.wave_manager, SNIPER_DATA, 1)
	var enemy := _add_enemy(dependencies.wave_manager, Vector2(100.0, 0.0))

	hero.advance_combat(1.5)
	_assert(enemy.current_hp == 100.0, "Secondary hero should not fire before its cooldown completes.")
	hero.advance_combat(0.04)
	_assert(is_equal_approx(enemy.current_hp, 82.0), "Sniper should fire once after its configured cooldown.")
	_cleanup(hero, dependencies)


func _test_single_target_hero_hits_only_nearest_enemy() -> void:
	var dependencies := _create_dependencies()
	var hero: Variant = _create_hero(dependencies.wave_manager, SNIPER_DATA, 1)
	var closest_enemy := _add_enemy(dependencies.wave_manager, Vector2(100.0, 0.0))
	var farther_enemy := _add_enemy(dependencies.wave_manager, Vector2(200.0, 0.0))
	var fired_positions: Array[Dictionary] = []
	hero.weapon_fired.connect(func(from: Vector2, to: Vector2) -> void:
		fired_positions.append({"from": from, "to": to})
	)

	hero.advance_combat(2.0)
	_assert(is_equal_approx(closest_enemy.current_hp, 82.0), "Single-target heroes should damage the nearest enemy.")
	_assert(farther_enemy.current_hp == 100.0, "Single-target heroes should not damage other enemies.")
	_assert(fired_positions.size() == 1, "Single-target heroes should emit weapon_fired once per hit.")
	_assert(fired_positions[0]["from"] == Vector2.ZERO and fired_positions[0]["to"] == closest_enemy.global_position, "weapon_fired should report the firing hero and hit target positions.")
	_cleanup(hero, dependencies)


func _test_multi_target_hero_hits_every_enemy_in_range() -> void:
	var dependencies := _create_dependencies()
	var hero: Variant = _create_hero(dependencies.wave_manager, COMMANDER_DATA, 1)
	var near_enemy := _add_enemy(dependencies.wave_manager, Vector2(100.0, 0.0))
	var edge_enemy := _add_enemy(dependencies.wave_manager, Vector2(220.0, 0.0))
	var out_of_range_enemy := _add_enemy(dependencies.wave_manager, Vector2(221.0, 0.0))
	var fired_targets: Array[Vector2] = []
	hero.weapon_fired.connect(func(_from: Vector2, to: Vector2) -> void:
		fired_targets.append(to)
	)

	hero.advance_combat(1.0)
	_assert(is_equal_approx(near_enemy.current_hp, 94.0), "Multi-target heroes should damage enemies in range.")
	_assert(is_equal_approx(edge_enemy.current_hp, 94.0), "Multi-target heroes should include enemies at exact range.")
	_assert(out_of_range_enemy.current_hp == 100.0, "Enemies beyond hero range should not take damage.")
	_assert(fired_targets.size() == 2, "Multi-target heroes should emit weapon_fired for every target hit.")
	_assert(fired_targets.has(near_enemy.global_position) and fired_targets.has(edge_enemy.global_position), "Multi-target hero signals should identify every hit target.")
	_cleanup(hero, dependencies)


func _test_rectangular_range_allows_corner_and_rejects_axis_overflow() -> void:
	var dependencies := _create_dependencies()
	var hero: Variant = _create_hero(dependencies.wave_manager, SNIPER_DATA, 1)
	var corner_enemy := _add_enemy(dependencies.wave_manager, Vector2(260.0, 520.0))
	var horizontal_overflow_enemy := _add_enemy(dependencies.wave_manager, Vector2(261.0, 0.0))
	var vertical_overflow_enemy := _add_enemy(dependencies.wave_manager, Vector2(0.0, 521.0))

	hero.advance_combat(2.0)
	_assert(is_equal_approx(corner_enemy.current_hp, 82.0), "Heroes should hit targets inside both rectangle half-extents even outside the old circular range.")
	_assert(horizontal_overflow_enemy.current_hp == 100.0, "Heroes should reject targets beyond rectangle half-width.")
	_assert(vertical_overflow_enemy.current_hp == 100.0, "Heroes should reject targets beyond rectangle half-height.")
	_cleanup(hero, dependencies)


func _test_level_scales_damage_and_clamps_to_run_limit() -> void:
	var dependencies := _create_dependencies()
	var hero: Variant = _create_hero(dependencies.wave_manager, SNIPER_DATA, 2)
	var enemy := _add_enemy(dependencies.wave_manager, Vector2(100.0, 0.0))

	hero.advance_combat(2.0)
	_assert(is_equal_approx(enemy.current_hp, 78.4), "Level two damage should use multiplicative per-run growth.")
	hero.set_level(999)
	_assert(hero.current_level == SNIPER_DATA.max_level_per_run, "Hero level should not exceed the per-run maximum.")
	hero.set_level(0)
	_assert(hero.current_level == 1, "Hero level should not fall below one.")
	_cleanup(hero, dependencies)


func _create_dependencies() -> Dictionary:
	return {"wave_manager": WAVE_MANAGER_SCRIPT.new()}


func _create_hero(wave_manager: Node, hero_data: HeroData, level: int) -> Variant:
	var hero: Variant = SECONDARY_HERO_SCRIPT.new()
	hero.wave_manager = wave_manager
	hero.global_position = Vector2.ZERO
	hero.initialize(hero_data, level)
	return hero


func _add_enemy(wave_manager: Node, position: Vector2) -> Node2D:
	var enemy_data := EnemyData.new()
	enemy_data.max_hp = 100.0
	enemy_data.move_speed = 0.0
	var enemy: Node2D = ENEMY_SCRIPT.new()
	enemy.initialize(enemy_data)
	enemy.global_position = position
	wave_manager.add_child(enemy)
	return enemy


func _cleanup(hero: Node, dependencies: Dictionary) -> void:
	for enemy in dependencies.wave_manager.get_children():
		enemy.free()
	hero.free()
	dependencies.wave_manager.free()


func _assert(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		assert(condition, message)
