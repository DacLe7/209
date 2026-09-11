extends Node

signal hero_activated(hero_id: String, level: int)
signal hero_upgraded(hero_id: String, new_level: int)
signal upgrade_choices_ready(options: Array[Dictionary])
signal run_reset

const MAX_ACTIVE_HEROES := 4
const HERO_DATA_DIRECTORY := "res://data/heroes"
const MIN_UPGRADE_CHOICES := 2
const MAX_UPGRADE_CHOICES := 3

var roster: Array[HeroData] = []
var active_heroes: Dictionary = {}
var level_system: Node
var random_number_generator := RandomNumberGenerator.new()
var pending_upgrade_options: Array[Dictionary] = []
var pending_choice_requests := 0


func _ready() -> void:
	random_number_generator.randomize()
	load_roster()
	level_system = get_node_or_null("/root/LevelSystem")
	_connect_dependencies()


func load_roster() -> void:
	roster.clear()
	var directory := DirAccess.open(HERO_DATA_DIRECTORY)
	if directory == null:
		return

	var file_names: Array[String] = []
	directory.list_dir_begin()
	var file_name := directory.get_next()
	while not file_name.is_empty():
		if not directory.current_is_dir() and file_name.ends_with(".tres"):
			file_names.append(file_name)
		file_name = directory.get_next()
	directory.list_dir_end()
	file_names.sort()

	for sorted_file_name in file_names:
		var hero_data: HeroData = load("%s/%s" % [HERO_DATA_DIRECTORY, sorted_file_name])
		if hero_data != null and not hero_data.id.is_empty() and not _roster_contains_id(hero_data.id):
			roster.append(hero_data)


func reset_run() -> void:
	active_heroes.clear()
	pending_upgrade_options.clear()
	pending_choice_requests = 0
	run_reset.emit()


func choose_upgrade(option_index: int) -> bool:
	if option_index < 0 or option_index >= pending_upgrade_options.size():
		return false

	var option := pending_upgrade_options[option_index]
	pending_upgrade_options.clear()
	if not _apply_upgrade_option(option):
		_show_next_upgrade_choices()
		return false

	_show_next_upgrade_choices()
	return true


func _on_level_up(_new_level: int) -> void:
	pending_choice_requests += 1
	_show_next_upgrade_choices()


func _show_next_upgrade_choices() -> void:
	if not pending_upgrade_options.is_empty():
		return

	while pending_choice_requests > 0:
		pending_choice_requests -= 1
		var options := _generate_upgrade_options()
		if options.is_empty():
			continue
		pending_upgrade_options = options
		upgrade_choices_ready.emit(pending_upgrade_options.duplicate(true))
		return


func _generate_upgrade_options() -> Array[Dictionary]:
	var activation_candidates := _get_activation_candidates()
	var upgrade_candidates := _get_upgrade_candidates()
	var all_candidates: Array[Dictionary] = []
	all_candidates.append_array(activation_candidates)
	all_candidates.append_array(upgrade_candidates)
	if all_candidates.is_empty():
		return []

	var target_count := mini(MAX_UPGRADE_CHOICES, all_candidates.size())
	if target_count > MIN_UPGRADE_CHOICES:
		target_count = random_number_generator.randi_range(MIN_UPGRADE_CHOICES, target_count)

	var options: Array[Dictionary] = []
	if not activation_candidates.is_empty() and not upgrade_candidates.is_empty():
		options.append(_take_random_candidate(activation_candidates))
		options.append(_take_random_candidate(upgrade_candidates))
		all_candidates.clear()
		all_candidates.append_array(activation_candidates)
		all_candidates.append_array(upgrade_candidates)

	while options.size() < target_count and not all_candidates.is_empty():
		options.append(_take_random_candidate(all_candidates))
	return options


func _apply_upgrade_option(option: Dictionary) -> bool:
	var hero_id: String = option.get("hero_id", "")
	var hero_data := _get_hero_data(hero_id)
	if hero_data == null:
		return false

	if option.get("action") == "activate":
		if active_heroes.size() >= MAX_ACTIVE_HEROES or active_heroes.has(hero_id):
			return false
		active_heroes[hero_id] = 1
		hero_activated.emit(hero_id, 1)
		return true

	if option.get("action") == "upgrade":
		if not active_heroes.has(hero_id) or active_heroes[hero_id] >= hero_data.max_level_per_run:
			return false
		var new_level: int = active_heroes[hero_id] + 1
		active_heroes[hero_id] = new_level
		hero_upgraded.emit(hero_id, new_level)
		return true

	return false


func _get_activation_candidates() -> Array[Dictionary]:
	var candidates: Array[Dictionary] = []
	if active_heroes.size() >= MAX_ACTIVE_HEROES:
		return candidates

	for hero_data in roster:
		if not active_heroes.has(hero_data.id):
			candidates.append(_create_option("activate", hero_data, 0, 1))
	return candidates


func _get_upgrade_candidates() -> Array[Dictionary]:
	var candidates: Array[Dictionary] = []
	for hero_data in roster:
		if active_heroes.has(hero_data.id) and active_heroes[hero_data.id] < hero_data.max_level_per_run:
			var current_level: int = active_heroes[hero_data.id]
			candidates.append(_create_option("upgrade", hero_data, current_level, current_level + 1))
	return candidates


func _create_option(action: String, hero_data: HeroData, current_level: int, next_level: int) -> Dictionary:
	return {
		"action": action,
		"hero_id": hero_data.id,
		"display_name": hero_data.display_name,
		"current_level": current_level,
		"next_level": next_level,
		"max_level": hero_data.max_level_per_run,
	}


func _take_random_candidate(candidates: Array[Dictionary]) -> Dictionary:
	return candidates.pop_at(random_number_generator.randi_range(0, candidates.size() - 1))


func _get_hero_data(hero_id: String) -> HeroData:
	for hero_data in roster:
		if hero_data.id == hero_id:
			return hero_data
	return null


func _roster_contains_id(hero_id: String) -> bool:
	return _get_hero_data(hero_id) != null


func _connect_dependencies() -> void:
	if level_system != null and not level_system.level_up.is_connected(_on_level_up):
		level_system.level_up.connect(_on_level_up)
