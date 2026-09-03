class_name WeaponSystemTest
extends RefCounted

const WEAPON_SYSTEM_SCRIPT: Script = preload("res://scripts/systems/weapon_system.gd")


func run() -> void:
	_test_roster_loads_all_sample_weapons()
	_test_upgrade_deducts_gold_and_emits_signal()
	_test_stats_scale_linearly_with_level()
	_test_upgrade_fails_without_gold_or_after_max_level()


func _test_roster_loads_all_sample_weapons() -> void:
	var weapon_system: Variant = _create_weapon_system()
	_assert(weapon_system.roster.size() == 2, "Weapon roster should load both sample WeaponData resources.")
	_assert(weapon_system.weapon_levels["rifle_standard"] == 0, "Loaded weapons should start at upgrade level zero.")
	_assert(weapon_system.weapon_levels["shotgun_breach"] == 0, "Each roster weapon should receive its own level state.")
	weapon_system.free()


func _test_upgrade_deducts_gold_and_emits_signal() -> void:
	var weapon_system: Variant = _create_weapon_system()
	weapon_system.current_gold = 100
	var emitted_levels: Array[int] = []
	weapon_system.weapon_upgraded.connect(func(weapon_id: String, new_level: int) -> void:
		if weapon_id == "rifle_standard":
			emitted_levels.append(new_level)
	)

	_assert(weapon_system.upgrade_weapon("rifle_standard"), "An affordable upgrade should succeed.")
	_assert(weapon_system.current_gold == 0, "Upgrade should deduct the current level's cost from gold.")
	_assert(weapon_system.weapon_levels["rifle_standard"] == 1, "Upgrade should increase the weapon level by one.")
	_assert(emitted_levels == [1], "Upgrade should emit the weapon ID and new level.")
	weapon_system.free()


func _test_stats_scale_linearly_with_level() -> void:
	var weapon_system: Variant = _create_weapon_system()
	weapon_system.weapon_levels["rifle_standard"] = 2
	var stats: Dictionary = weapon_system.get_weapon_stats("rifle_standard")
	_assert(is_equal_approx(stats["damage"], 9.6), "Level two rifle damage should be base damage plus 20 percent of base.")
	_assert(is_equal_approx(stats["fire_rate"], 1.32), "Level two rifle fire rate should be base fire rate plus 10 percent of base.")
	_assert(stats["target_type"] == WeaponData.TargetType.SINGLE, "Combat metadata should be included with scaled stats.")
	weapon_system.free()


func _test_upgrade_fails_without_gold_or_after_max_level() -> void:
	var weapon_system: Variant = _create_weapon_system()
	_assert(not weapon_system.upgrade_weapon("rifle_standard"), "Upgrade should fail when gold is insufficient.")
	_assert(not weapon_system.upgrade_weapon("unknown"), "Upgrade should fail for an unknown weapon ID.")
	weapon_system.weapon_levels["rifle_standard"] = 4
	weapon_system.current_gold = 9999
	_assert(not weapon_system.upgrade_weapon("rifle_standard"), "Upgrade should fail after the final cost-curve level.")
	weapon_system.free()


func _create_weapon_system() -> Variant:
	var weapon_system: Variant = WEAPON_SYSTEM_SCRIPT.new()
	weapon_system.load_roster()
	return weapon_system


func _assert(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		assert(condition, message)
