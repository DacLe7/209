class_name HeroSystemTest
extends RefCounted

const HERO_SYSTEM_SCRIPT: Script = preload("res://scripts/systems/hero_system.gd")
const LEVEL_SYSTEM_SCRIPT: Script = preload("res://scripts/systems/level_system.gd")


func run() -> void:
	_test_roster_loads_unique_hero_data()
	_test_level_up_prepares_options_without_auto_applying()
	_test_choose_upgrade_applies_selected_action_and_emits_existing_signals()
	_test_choices_mix_actions_and_respect_available_candidate_count()
	_test_queued_level_ups_wait_for_each_choice()
	_test_no_candidates_emit_no_options()
	_test_invalid_choice_and_reset_clear_pending_state()


func _test_roster_loads_unique_hero_data() -> void:
	var hero_system: Variant = _create_hero_system()
	hero_system.load_roster()
	_assert(hero_system.roster.size() == 2, "Hero roster should load both sample HeroData resources.")
	_assert(hero_system.roster[0].id != hero_system.roster[1].id, "Hero roster IDs must remain unique.")
	hero_system.free()


func _test_level_up_prepares_options_without_auto_applying() -> void:
	var level_system: Variant = LEVEL_SYSTEM_SCRIPT.new()
	var hero_system: Variant = _create_hero_system(level_system)
	hero_system.roster.append(_create_hero_data("alpha", 2))
	var emitted_options: Array[Array] = []
	hero_system.upgrade_choices_ready.connect(func(options: Array[Dictionary]) -> void:
		emitted_options.append(options)
	)

	level_system.level_up.emit(1)
	_assert(hero_system.active_heroes.is_empty(), "Level-up should not apply a hero action before the player chooses.")
	_assert(emitted_options.size() == 1 and emitted_options[0].size() == 1, "One valid candidate should produce one choice card.")
	var option: Dictionary = emitted_options[0][0]
	_assert(option["action"] == "activate" and option["hero_id"] == "alpha", "Choice cards should describe the available action and hero.")
	_assert(option["display_name"] == "Alpha" and option["current_level"] == 0 and option["next_level"] == 1, "Choice cards should expose display and level details for UI.")
	hero_system.free()
	level_system.free()


func _test_choose_upgrade_applies_selected_action_and_emits_existing_signals() -> void:
	var hero_system: Variant = _create_hero_system()
	hero_system.roster.append(_create_hero_data("alpha", 2))
	var activated_ids: Array[String] = []
	var upgraded_levels: Array[int] = []
	hero_system.hero_activated.connect(func(hero_id: String, _level: int) -> void:
		activated_ids.append(hero_id)
	)
	hero_system.hero_upgraded.connect(func(_hero_id: String, new_level: int) -> void:
		upgraded_levels.append(new_level)
	)

	hero_system._on_level_up(1)
	_assert(hero_system.choose_upgrade(0), "Choosing an activation card should succeed.")
	_assert(activated_ids == ["alpha"] and hero_system.active_heroes["alpha"] == 1, "Activation choice should update state and emit hero_activated.")
	hero_system._on_level_up(2)
	_assert(hero_system.choose_upgrade(0), "Choosing an upgrade card should succeed.")
	_assert(upgraded_levels == [2] and hero_system.active_heroes["alpha"] == 2, "Upgrade choice should update state and emit hero_upgraded.")
	hero_system.free()


func _test_choices_mix_actions_and_respect_available_candidate_count() -> void:
	var hero_system: Variant = _create_hero_system()
	hero_system.roster.append(_create_hero_data("alpha", 2))
	hero_system.roster.append(_create_hero_data("bravo", 1))
	hero_system.roster.append(_create_hero_data("charlie", 1))
	hero_system.active_heroes = {"alpha": 1}
	var emitted_option_sets: Array[Array] = []
	hero_system.upgrade_choices_ready.connect(func(options: Array[Dictionary]) -> void:
		emitted_option_sets.append(options)
	)

	hero_system._on_level_up(1)
	var emitted_options: Array = emitted_option_sets[0]
	_assert(emitted_options.size() >= 2 and emitted_options.size() <= 3, "Choice generation should offer two or three cards when enough candidates exist.")
	var actions: Array[String] = []
	for option in emitted_options:
		actions.append(option["action"])
	_assert(actions.has("activate") and actions.has("upgrade"), "Choices should mix activation and upgrade actions when both are available.")
	hero_system.free()


func _test_queued_level_ups_wait_for_each_choice() -> void:
	var hero_system: Variant = _create_hero_system()
	hero_system.roster.append(_create_hero_data("alpha", 3))
	var emitted_option_sets: Array[Array] = []
	hero_system.upgrade_choices_ready.connect(func(options: Array[Dictionary]) -> void:
		emitted_option_sets.append(options)
	)

	hero_system._on_level_up(1)
	hero_system._on_level_up(2)
	_assert(emitted_option_sets.size() == 1, "A second level-up should queue behind the currently visible choices.")
	hero_system.choose_upgrade(0)
	_assert(emitted_option_sets.size() == 2, "Choosing the first set should generate the next queued set.")
	_assert(emitted_option_sets[1][0]["action"] == "upgrade", "Queued choices should use the state produced by the prior selection.")
	hero_system.free()


func _test_no_candidates_emit_no_options() -> void:
	var hero_system: Variant = _create_hero_system()
	for hero_index in 4:
		hero_system.roster.append(_create_hero_data("hero_%d" % (hero_index + 1), 1))
	hero_system.active_heroes = {"hero_1": 1, "hero_2": 1, "hero_3": 1, "hero_4": 1}
	var ready_count := [0]
	hero_system.upgrade_choices_ready.connect(func(_options: Array[Dictionary]) -> void:
		ready_count[0] += 1
	)

	hero_system._on_level_up(1)
	_assert(ready_count[0] == 0 and hero_system.pending_upgrade_options.is_empty(), "No valid candidate should not emit empty choices.")
	hero_system.free()


func _test_invalid_choice_and_reset_clear_pending_state() -> void:
	var hero_system: Variant = _create_hero_system()
	hero_system.roster.append(_create_hero_data("alpha", 2))
	hero_system._on_level_up(1)
	_assert(not hero_system.choose_upgrade(1), "Out-of-range option indices should fail.")
	_assert(not hero_system.choose_upgrade(-1), "Negative option indices should fail.")
	hero_system.reset_run()
	_assert(hero_system.pending_upgrade_options.is_empty() and hero_system.pending_choice_requests == 0, "Reset should discard visible and queued choices.")
	_assert(not hero_system.choose_upgrade(0), "Choosing after reset should fail because no choice is pending.")
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
	hero_data.display_name = hero_id.capitalize()
	hero_data.max_level_per_run = max_level_per_run
	return hero_data


func _assert(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		assert(condition, message)
