extends Node

const SAVE_VERSION := 1
const DEFAULT_SAVE_PATH := "user://save_data.json"

var save_path := DEFAULT_SAVE_PATH
var weapon_system: Node
var _is_loading := false


func _ready() -> void:
	weapon_system = get_node_or_null("/root/WeaponSystem")
	_load_weapon_system_state()
	_connect_weapon_system()


func save_game() -> void:
	if weapon_system == null:
		return

	var save_data := {
		"version": SAVE_VERSION,
		"gold": weapon_system.current_gold,
		"weapon_levels": weapon_system.weapon_levels.duplicate(),
		"equipped_weapon_id": weapon_system.equipped_weapon_id,
	}
	var save_file := FileAccess.open(save_path, FileAccess.WRITE)
	if save_file == null:
		return

	save_file.store_string(JSON.stringify(save_data))
	save_file.close()


func load_game() -> Dictionary:
	if not FileAccess.file_exists(save_path):
		return {}

	var save_file := FileAccess.open(save_path, FileAccess.READ)
	if save_file == null:
		return {}

	var parsed_data: Variant = JSON.parse_string(save_file.get_as_text())
	save_file.close()
	if parsed_data is Dictionary:
		return parsed_data
	return {}


func _load_weapon_system_state() -> void:
	if weapon_system == null:
		return

	var save_data := load_game()
	if save_data.is_empty():
		return

	_is_loading = true
	_apply_save_data(save_data)
	_is_loading = false


func _apply_save_data(save_data: Dictionary) -> void:
	var saved_gold: Variant = save_data.get("gold")
	if _is_number(saved_gold):
		weapon_system.current_gold = max(0, int(saved_gold))

	var saved_weapon_levels: Variant = save_data.get("weapon_levels", {})
	if saved_weapon_levels is Dictionary:
		for weapon_data in weapon_system.roster:
			var saved_level: Variant = saved_weapon_levels.get(weapon_data.id)
			if _is_number(saved_level):
				weapon_system.weapon_levels[weapon_data.id] = clampi(
					int(saved_level), 0, weapon_data.upgrade_cost_curve.size()
				)

	var saved_weapon_id: Variant = save_data.get("equipped_weapon_id")
	if saved_weapon_id is String:
		weapon_system.set_equipped_weapon(saved_weapon_id)


func _connect_weapon_system() -> void:
	if weapon_system == null:
		return
	if not weapon_system.gold_changed.is_connected(_on_gold_changed):
		weapon_system.gold_changed.connect(_on_gold_changed)
	if not weapon_system.weapon_upgraded.is_connected(_on_weapon_upgraded):
		weapon_system.weapon_upgraded.connect(_on_weapon_upgraded)
	if not weapon_system.weapon_equipped.is_connected(_on_weapon_equipped):
		weapon_system.weapon_equipped.connect(_on_weapon_equipped)


func _on_gold_changed(_current_gold: int) -> void:
	_autosave()


func _on_weapon_upgraded(_weapon_id: String, _new_level: int) -> void:
	_autosave()


func _on_weapon_equipped(_weapon_id: String) -> void:
	_autosave()


func _autosave() -> void:
	if not _is_loading:
		save_game()


func _is_number(value: Variant) -> bool:
	return value is int or value is float
