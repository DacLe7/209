class_name HeroSystemTest
extends RefCounted

const HERO_SYSTEM_SCRIPT: Script = preload("res://scripts/systems/hero_system.gd")
const LEVEL_SYSTEM_SCRIPT: Script = preload("res://scripts/systems/level_system.gd")


func run() -> void:
	_test_roster_loads_unique_hero_data()
	_test_level_up_activates_then_upgrades_when_only_one_action_is_possible()
	_test_active_hero_limit_blocks_additional_activation()
	_test_reset_run_clears_active_heroes()


func _test_roster_loads_unique_hero_data() -> void:
	var hero_system: Variant = _create_hero_system()
	hero_system.load_roster()
	_assert(hero_system.roster.size() == 2, "Hero roster should load both sample HeroData resources.")
	_assert(hero_system.roster[0].id != hero_system.roster[1].id, "Hero roster IDs must remain unique.")
	hero_system.free()


func _test_level_up_activates_then_upgrades_when_only_one_action_is_possible() -> void:
	var level_system: Variant = LEVEL_SYSTEM_SCRIPT.new()
	var hero_system: Variant = _create_hero_system(level_system)
	hero_system.roster.append(_create_hero_data("alpha", 2))
	var activated_ids: Array[String] = []
	var upgraded_levels: Array[int] = []
	hero_system.hero_activated.connect(func(hero_id: String, _level: int) -> void:
		activated_ids.append(hero_id)
	)
	hero_system.hero_upgraded.connect(func(_hero_id: String, new_level: int) -> void:
		upgraded_levels.append(new_level)
	)

	level_system.level_up.emit(1)
	level_system.level_up.emit(2)
	level_system.level_up.emit(3)
	_assert(activated_ids == ["alpha"], "A level-up should activate the only available hero.")
	_assert(upgraded_levels == [2], "The next level-up should upgrade the active hero while it is below max level.")
	_assert(hero_system.active_heroes["alpha"] == 2, "A maxed hero should not receive more upgrades.")
	hero_system.free()
	level_system.free()


func _test_active_hero_limit_blocks_additional_activation() -> void:
	var hero_system: Variant = _create_hero_system()
	for hero_index in 5:
		hero_system.roster.append(_create_hero_data("hero_%d" % (hero_index + 1), 1))
	hero_system.active_heroes = {"hero_1": 1, "hero_2": 1, "hero_3": 1, "hero_4": 1}
	var activation_count := [0]
	hero_system.hero_activated.connect(func(_hero_id: String, _level: int) -> void:
		activation_count[0] += 1
	)

	hero_system._on_level_up(1)
	_assert(hero_system.active_heroes.size() == 4, "HeroSystem must not activate a fifth hero.")
	_assert(activation_count[0] == 0, "HeroSystem must not emit activation after all slots are full.")
	hero_system.free()


func _test_reset_run_clears_active_heroes() -> void:
	var hero_system: Variant = _create_hero_system()
	hero_system.active_heroes = {"alpha": 2, "bravo": 1}
	hero_system.reset_run()
	_assert(hero_system.active_heroes.is_empty(), "Reset should clear every active hero for a new run.")
	hero_system.free()


func _create_hero_system(level_system: Variant = null) -> Variant:
	var hero_system: Variant = HERO_SYSTEM_SCRIPT.new()
	hero_system.random_number_generator.seed = 12345
	if level_system != null:
		hero_system.level_system = level_system
		hero_system._connect_dependencies()
	return hero_system


func _create_hero_data(hero_id: String, max_level_per_run: int) -> HeroData:
	var hero_data := HeroData.new()
	hero_data.id = hero_id
	hero_data.max_level_per_run = max_level_per_run
	return hero_data


func _assert(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		assert(condition, message)
