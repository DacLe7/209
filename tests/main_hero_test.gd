class_name MainHeroTest
extends RefCounted

const MAIN_HERO_SCRIPT: Script = preload("res://scripts/entities/main_hero.gd")
const WAVE_MANAGER_SCRIPT: Script = preload("res://scripts/systems/wave_manager.gd")
const WEAPON_SYSTEM_SCRIPT: Script = preload("res://scripts/systems/weapon_system.gd")
const ENEMY_SCRIPT: Script = preload("res://scripts/entities/enemy.gd")


func run() -> void:
	_test_fires_at_the_configured_fire_rate()
	_test_single_weapon_hits_only_the_nearest_enemy()
	_test_multi_weapon_hits_all_enemies_in_range()
	_test_rectangular_range_allows_corner_and_rejects_axis_overflow()


func _test_fires_at_the_configured_fire_rate() -> void:
	var dependencies := _create_dependencies()
	var hero: Variant = _create_hero(dependencies)
	var enemy: Node2D = _add_enemy(dependencies.wave_manager, Vector2(100.0, 0.0))

	hero.advance_combat(0.8)
	_assert(enemy.current_hp == 100.0, "Hero should not fire before the rifle cooldown completes.")
	hero.advance_combat(0.1)
	_assert(enemy.current_hp == 92.0, "Hero should fire once after the rifle cooldown completes.")
	hero.advance_combat(0.7)
	_assert(enemy.current_hp == 92.0, "Hero should preserve partial cooldown time without firing early.")
	hero.advance_combat(0.1)
	_assert(enemy.current_hp == 84.0, "Hero should fire a second time at the next cooldown.")
	_cleanup(hero, dependencies)


func _test_single_weapon_hits_only_the_nearest_enemy() -> void:
	var dependencies := _create_dependencies()
	var hero: Variant = _create_hero(dependencies)
	var closest_enemy: Node2D = _add_enemy(dependencies.wave_manager, Vector2(100.0, 0.0))
	var farther_enemy: Node2D = _add_enemy(dependencies.wave_manager, Vector2(200.0, 0.0))
	var fired_positions: Array[Dictionary] = []
	hero.weapon_fired.connect(func(from: Vector2, to: Vector2) -> void:
		fired_positions.append({"from": from, "to": to})
	)

	hero.advance_combat(1.0)
	_assert(closest_enemy.current_hp == 92.0, "Single-target weapon should damage the closest enemy in range.")
	_assert(farther_enemy.current_hp == 100.0, "Single-target weapon should not damage farther enemies.")
	_assert(fired_positions.size() == 1, "Single-target weapon should emit weapon_fired once per hit.")
	_assert(fired_positions[0]["from"] == Vector2.ZERO and fired_positions[0]["to"] == closest_enemy.global_position, "weapon_fired should report the hero and hit target positions.")
	_cleanup(hero, dependencies)


func _test_multi_weapon_hits_all_enemies_in_range() -> void:
	var dependencies := _create_dependencies()
	var hero: Variant = _create_hero(dependencies)
	hero.equip("shotgun_breach")
	var near_enemy: Node2D = _add_enemy(dependencies.wave_manager, Vector2(100.0, 0.0))
	var edge_enemy: Node2D = _add_enemy(dependencies.wave_manager, Vector2(180.0, 0.0))
	var distant_enemy: Node2D = _add_enemy(dependencies.wave_manager, Vector2(181.0, 0.0))
	var fired_targets: Array[Vector2] = []
	hero.weapon_fired.connect(func(_from: Vector2, to: Vector2) -> void:
		fired_targets.append(to)
	)

	hero.advance_combat(1.3)
	_assert(near_enemy.current_hp == 84.0, "Multi-target weapon should damage enemies in close range.")
	_assert(edge_enemy.current_hp == 84.0, "Multi-target weapon should include enemies exactly at range distance.")
	_assert(distant_enemy.current_hp == 100.0, "Multi-target weapon should not damage enemies beyond range distance.")
	_assert(fired_targets.size() == 2, "Multi-target weapon should emit weapon_fired once for each hit enemy.")
	_assert(fired_targets.has(near_enemy.global_position) and fired_targets.has(edge_enemy.global_position), "Multi-target weapon should report every target that took damage.")
	_cleanup(hero, dependencies)


func _test_rectangular_range_allows_corner_and_rejects_axis_overflow() -> void:
	var dependencies := _create_dependencies()
	var hero: Variant = _create_hero(dependencies)
	var corner_enemy: Node2D = _add_enemy(dependencies.wave_manager, Vector2(280.0, 450.0))
	var horizontal_overflow_enemy: Node2D = _add_enemy(dependencies.wave_manager, Vector2(281.0, 0.0))
	var vertical_overflow_enemy: Node2D = _add_enemy(dependencies.wave_manager, Vector2(0.0, 451.0))

	hero.advance_combat(0.9)
	_assert(corner_enemy.current_hp == 92.0, "Enemies inside both rectangle half-extents should be damaged even outside the old circular range.")
	_assert(horizontal_overflow_enemy.current_hp == 100.0, "Enemies beyond rectangle half-width must not be damaged.")
	_assert(vertical_overflow_enemy.current_hp == 100.0, "Enemies beyond rectangle half-height must not be damaged.")
	_cleanup(hero, dependencies)


func _create_dependencies() -> Dictionary:
	var wave_manager: Variant = WAVE_MANAGER_SCRIPT.new()
	var weapon_system: Variant = WEAPON_SYSTEM_SCRIPT.new()
	weapon_system.load_roster()
	return {"wave_manager": wave_manager, "weapon_system": weapon_system}


func _create_hero(dependencies: Dictionary) -> Variant:
	var hero: Variant = MAIN_HERO_SCRIPT.new()
	hero.weapon_system = dependencies.weapon_system
	hero.wave_manager = dependencies.wave_manager
	hero.global_position = Vector2.ZERO
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
	dependencies.weapon_system.free()


func _assert(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		assert(condition, message)
