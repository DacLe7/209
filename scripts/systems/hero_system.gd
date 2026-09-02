extends Node

signal hero_activated(hero_id: String, level: int)
signal hero_upgraded(hero_id: String, new_level: int)

const MAX_ACTIVE_HEROES := 4
const HERO_DATA_DIRECTORY := "res://data/heroes"

var roster: Array[HeroData] = []
var active_heroes: Dictionary = {}
var level_system: Node
var random_number_generator := RandomNumberGenerator.new()


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


func _on_level_up(_new_level: int) -> void:
	var can_activate := active_heroes.size() < MAX_ACTIVE_HEROES and not _get_inactive_heroes().is_empty()
	var can_upgrade := not _get_upgradeable_hero_ids().is_empty()
	if not can_activate and not can_upgrade:
		return

	if can_activate and can_upgrade:
		if random_number_generator.randf() < 0.5:
			_activate_random_hero()
		else:
			_upgrade_random_hero()
	elif can_activate:
		_activate_random_hero()
	else:
		_upgrade_random_hero()


func _activate_random_hero() -> void:
	var inactive_heroes := _get_inactive_heroes()
	if inactive_heroes.is_empty():
		return

	var hero_data: HeroData = inactive_heroes[random_number_generator.randi_range(0, inactive_heroes.size() - 1)]
	active_heroes[hero_data.id] = 1
	hero_activated.emit(hero_data.id, 1)


func _upgrade_random_hero() -> void:
	var upgradeable_hero_ids := _get_upgradeable_hero_ids()
	if upgradeable_hero_ids.is_empty():
		return

	var hero_id: String = upgradeable_hero_ids[random_number_generator.randi_range(0, upgradeable_hero_ids.size() - 1)]
	var new_level: int = active_heroes[hero_id] + 1
	active_heroes[hero_id] = new_level
	hero_upgraded.emit(hero_id, new_level)


func _get_inactive_heroes() -> Array[HeroData]:
	var inactive_heroes: Array[HeroData] = []
	for hero_data in roster:
		if not active_heroes.has(hero_data.id):
			inactive_heroes.append(hero_data)
	return inactive_heroes


func _get_upgradeable_hero_ids() -> Array[String]:
	var upgradeable_hero_ids: Array[String] = []
	for hero_data in roster:
		if active_heroes.has(hero_data.id) and active_heroes[hero_data.id] < hero_data.max_level_per_run:
			upgradeable_hero_ids.append(hero_data.id)
	return upgradeable_hero_ids


func _roster_contains_id(hero_id: String) -> bool:
	for hero_data in roster:
		if hero_data.id == hero_id:
			return true
	return false


func _connect_dependencies() -> void:
	if level_system != null and not level_system.level_up.is_connected(_on_level_up):
		level_system.level_up.connect(_on_level_up)
