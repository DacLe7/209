class_name SaveSystemTest
extends RefCounted

const SAVE_SYSTEM_SCRIPT: Script = preload("res://scripts/systems/save_system.gd")
const WEAPON_SYSTEM_SCRIPT: Script = preload("res://scripts/systems/weapon_system.gd")
const TEST_SAVE_PATH := "user://save_system_test_data.json"


func run() -> void:
	_remove_test_save()
	_test_missing_and_invalid_save_return_empty_data()
	_test_save_and_load_restore_valid_weapon_progress()
	_test_load_ignores_unknown_ids_and_clamps_invalid_values()
	_test_weapon_signals_autosave_changes()
	_remove_test_save()


func _test_missing_and_invalid_save_return_empty_data() -> void:
	var save_system: Variant = _create_save_system()
	_assert(save_system.load_game().is_empty(), "A missing save should return an empty dictionary.")

	_write_test_file("{not valid json")
	_assert(save_system.load_game().is_empty(), "Malformed JSON should return an empty dictionary without crashing.")
	_assert(FileAccess.file_exists(TEST_SAVE_PATH), "Loading malformed JSON should not overwrite the original file.")
	_cleanup_save_system(save_system)
	_remove_test_save()


func _test_save_and_load_restore_valid_weapon_progress() -> void:
	var save_system: Variant = _create_save_system()
	save_system.weapon_system.current_gold = 275
	save_system.weapon_system.weapon_levels["rifle_standard"] = 2
	save_system.weapon_system.set_equipped_weapon("shotgun_breach")
	save_system.save_game()
	_cleanup_save_system(save_system)

	var loaded_weapon_system: Variant = _create_weapon_system()
	var loader: Variant = SAVE_SYSTEM_SCRIPT.new()
	loader.save_path = TEST_SAVE_PATH
	loader.weapon_system = loaded_weapon_system
	loader._load_weapon_system_state()
	_assert(loaded_weapon_system.current_gold == 275, "Load should restore saved gold.")
	_assert(loaded_weapon_system.weapon_levels["rifle_standard"] == 2, "Load should restore saved weapon levels.")
	_assert(loaded_weapon_system.equipped_weapon_id == "shotgun_breach", "Load should restore the equipped roster weapon.")
	_cleanup_save_system(loader)
	_remove_test_save()


func _test_load_ignores_unknown_ids_and_clamps_invalid_values() -> void:
	_write_test_file(JSON.stringify({
		"gold": -50,
		"weapon_levels": {"rifle_standard": 999, "removed_weapon": 3},
		"equipped_weapon_id": "removed_weapon",
	}))
	var save_system: Variant = _create_save_system()
	save_system._load_weapon_system_state()
	_assert(save_system.weapon_system.current_gold == 0, "Negative saved gold should clamp to zero.")
	_assert(save_system.weapon_system.weapon_levels["rifle_standard"] == 4, "Saved levels should clamp to the current cost-curve maximum.")
	_assert(not save_system.weapon_system.weapon_levels.has("removed_weapon"), "Unknown saved weapon IDs should be ignored.")
	_assert(save_system.weapon_system.equipped_weapon_id == "rifle_standard", "Unknown equipped IDs should preserve the default weapon.")
	_cleanup_save_system(save_system)
	_remove_test_save()


func _test_weapon_signals_autosave_changes() -> void:
	var save_system: Variant = _create_save_system()
	save_system._connect_weapon_system()
	save_system.weapon_system.add_gold(500)
	_assert(save_system.weapon_system.upgrade_weapon("rifle_standard"), "The autosave fixture should make the rifle upgrade affordable.")
	_assert(save_system.weapon_system.set_equipped_weapon("shotgun_breach"), "The autosave fixture should equip a valid weapon.")

	var saved_data: Dictionary = save_system.load_game()
	_assert(saved_data.get("gold") == 400, "gold_changed should autosave the gold remaining after upgrade.")
	_assert(saved_data.get("weapon_levels", {}).get("rifle_standard") == 1, "weapon_upgraded should autosave the new level.")
	_assert(saved_data.get("equipped_weapon_id") == "shotgun_breach", "weapon_equipped should autosave the selected weapon.")
	_cleanup_save_system(save_system)
	_remove_test_save()


func _create_save_system() -> Variant:
	var save_system: Variant = SAVE_SYSTEM_SCRIPT.new()
	save_system.save_path = TEST_SAVE_PATH
	save_system.weapon_system = _create_weapon_system()
	return save_system


func _create_weapon_system() -> Variant:
	var weapon_system: Variant = WEAPON_SYSTEM_SCRIPT.new()
	weapon_system.load_roster()
	return weapon_system


func _write_test_file(contents: String) -> void:
	var save_file := FileAccess.open(TEST_SAVE_PATH, FileAccess.WRITE)
	save_file.store_string(contents)
	save_file.close()


func _remove_test_save() -> void:
	if FileAccess.file_exists(TEST_SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE_PATH))


func _cleanup_save_system(save_system: Variant) -> void:
	var weapon_system: Variant = save_system.weapon_system
	save_system.free()
	weapon_system.free()


func _assert(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		assert(condition, message)
