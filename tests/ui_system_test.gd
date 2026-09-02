class_name UISystemTest
extends RefCounted

const BATTLE_HUD_SCENE := preload("res://scenes/ui/battle_hud.tscn")
const MAP_SELECTION_SCENE := preload("res://scenes/ui/map_selection.tscn")
const WEAPON_HUB_SCENE := preload("res://scenes/ui/weapon_upgrade_hub.tscn")

const BASE_HEALTH_SYSTEM_SCRIPT := preload("res://scripts/systems/base_health_system.gd")
const ENERGY_SYSTEM_SCRIPT := preload("res://scripts/systems/energy_system.gd")
const LEVEL_SYSTEM_SCRIPT := preload("res://scripts/systems/level_system.gd")


func run(tree: SceneTree = null) -> void:
	_test_scenes_can_instantiate()
	_test_hud_signal_bindings(tree)
	_test_weapon_hub_interactions(tree)
	_test_map_selection_interactions(tree)


func _test_scenes_can_instantiate() -> void:
	var hud_instance: Variant = BATTLE_HUD_SCENE.instantiate()
	_assert(hud_instance != null, "Battle HUD scene must instantiate successfully.")
	_assert(hud_instance is Control, "Battle HUD must be a Control node.")
	hud_instance.free()

	var map_instance: Variant = MAP_SELECTION_SCENE.instantiate()
	_assert(map_instance != null, "Map Selection scene must instantiate successfully.")
	_assert(map_instance is Control, "Map Selection must be a Control node.")
	map_instance.free()

	var weapon_instance: Variant = WEAPON_HUB_SCENE.instantiate()
	_assert(weapon_instance != null, "Weapon Upgrade Hub scene must instantiate successfully.")
	_assert(weapon_instance is Control, "Weapon Upgrade Hub must be a Control node.")
	weapon_instance.free()


func _test_hud_signal_bindings(tree: SceneTree) -> void:
	var base_health_sys: Variant = BASE_HEALTH_SYSTEM_SCRIPT.new()
	var energy_sys: Variant = ENERGY_SYSTEM_SCRIPT.new()
	var level_sys: Variant = LEVEL_SYSTEM_SCRIPT.new()

	var hud: Variant = BATTLE_HUD_SCENE.instantiate()
	hud.base_health_system = base_health_sys
	hud.energy_system = energy_sys
	hud.level_system = level_sys

	if tree != null and tree.root != null:
		tree.root.add_child(hud)
	hud._ready()

	# Test initial values
	_assert(hud.health_bar.value == 100.0, "HUD initial health bar value should be 100.0.")
	_assert(hud.energy_label.text.contains("5 / 5"), "HUD initial energy label should be 5 / 5.")
	_assert(hud.level_label.text.contains("0 / 30"), "HUD initial level label should be 0 / 30.")

	# Test BaseHealthSystem.health_changed signal binding
	base_health_sys.take_damage(40.0)
	_assert(hud.health_bar.value == 60.0, "HUD health_bar must update to 60.0 when health_changed is emitted.")
	_assert(hud.health_label.text.contains("60 / 100"), "HUD health_label must display updated current/max health.")

	# Test EnergySystem.energy_changed signal binding
	energy_sys.spend_energy()
	_assert(hud.energy_label.text.contains("4 / 5"), "HUD energy_label must display updated energy after spend.")

	# Test LevelSystem.level_up signal binding
	level_sys.level_up.emit(15)
	_assert(hud.level_label.text.contains("15 / 30"), "HUD level_label must display updated level.")

	if tree != null and tree.root != null:
		tree.root.remove_child(hud)
	hud.free()
	level_sys.free()
	energy_sys.free()
	base_health_sys.free()


func _test_weapon_hub_interactions(tree: SceneTree) -> void:
	var hub: Variant = WEAPON_HUB_SCENE.instantiate()
	if tree != null and tree.root != null:
		tree.root.add_child(hub)
	hub._ready()

	_assert(hub.weapon_title.text == "Standard Rifle", "Initial weapon should be Standard Rifle.")
	_assert(hub.type_label.text.contains("Single"), "Rifle should be Single target.")

	# Select shotgun
	hub._select_shotgun()
	_assert(hub.weapon_title.text == "Breaching Shotgun", "Selected weapon should be Breaching Shotgun.")
	_assert(hub.type_label.text.contains("AOE"), "Shotgun should be Multi/AOE target.")

	# Test upgrade button static click
	hub._on_upgrade_pressed()
	_assert(hub.notice_label.text.contains("WeaponSystem"), "Notice label should indicate WeaponSystem is pending.")

	if tree != null and tree.root != null:
		tree.root.remove_child(hub)
	hub.free()


func _test_map_selection_interactions(tree: SceneTree) -> void:
	var energy_sys: Variant = ENERGY_SYSTEM_SCRIPT.new()
	var map_sel: Variant = MAP_SELECTION_SCENE.instantiate()
	map_sel.energy_system = energy_sys

	if tree != null and tree.root != null:
		tree.root.add_child(map_sel)
	map_sel._ready()

	var selected_stages: Array[int] = []
	map_sel.map_selected.connect(func(stage_id: int) -> void:
		selected_stages.append(stage_id)
	)

	# Simulate pressing play on stage 1
	map_sel._on_stage1_play_pressed()
	_assert(selected_stages == [1], "Pressing stage 1 play should emit map_selected(1).")
	_assert(energy_sys.current_energy == 4, "Playing stage 1 should consume 1 energy.")

	if tree != null and tree.root != null:
		tree.root.remove_child(map_sel)
	map_sel.free()
	energy_sys.free()


func _assert(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		assert(condition, message)
