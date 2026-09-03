extends Node

signal weapon_upgraded(weapon_id: String, new_level: int)

const WEAPON_DATA_DIRECTORY := "res://data/weapons"
const DAMAGE_BONUS_PER_LEVEL := 0.10
const FIRE_RATE_BONUS_PER_LEVEL := 0.05

var roster: Array[WeaponData] = []
var weapon_levels: Dictionary = {}
var current_gold := 0


func _ready() -> void:
	load_roster()


func load_roster() -> void:
	roster.clear()
	weapon_levels.clear()
	var directory := DirAccess.open(WEAPON_DATA_DIRECTORY)
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
		var weapon_data: WeaponData = load("%s/%s" % [WEAPON_DATA_DIRECTORY, sorted_file_name])
		if weapon_data != null and not weapon_data.id.is_empty() and not _roster_contains_id(weapon_data.id):
			roster.append(weapon_data)
			weapon_levels[weapon_data.id] = 0


func upgrade_weapon(weapon_id: String) -> bool:
	var weapon_data := _get_weapon_data(weapon_id)
	if weapon_data == null:
		return false

	var current_level: int = weapon_levels[weapon_id]
	if current_level >= weapon_data.upgrade_cost_curve.size():
		return false

	var upgrade_cost: int = weapon_data.upgrade_cost_curve[current_level]
	if current_gold < upgrade_cost:
		return false

	current_gold -= upgrade_cost
	var new_level := current_level + 1
	weapon_levels[weapon_id] = new_level
	weapon_upgraded.emit(weapon_id, new_level)
	return true


func get_weapon_stats(weapon_id: String) -> Dictionary:
	var weapon_data := _get_weapon_data(weapon_id)
	if weapon_data == null:
		return {}

	var level: int = weapon_levels[weapon_id]
	return {
		"level": level,
		"damage": weapon_data.base_damage * (1.0 + DAMAGE_BONUS_PER_LEVEL * level),
		"fire_rate": weapon_data.fire_rate * (1.0 + FIRE_RATE_BONUS_PER_LEVEL * level),
		"target_type": weapon_data.target_type,
		"range_type": weapon_data.range_type,
	}


func _get_weapon_data(weapon_id: String) -> WeaponData:
	for weapon_data in roster:
		if weapon_data.id == weapon_id:
			return weapon_data
	return null


func _roster_contains_id(weapon_id: String) -> bool:
	return _get_weapon_data(weapon_id) != null
