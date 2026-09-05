class_name UISystemTest
extends RefCounted

const BATTLE_HUD_SCENE := preload("res://scenes/ui/battle_hud.tscn")
const MAP_SELECTION_SCENE := preload("res://scenes/ui/map_selection.tscn")
const WEAPON_HUB_SCENE := preload("res://scenes/ui/weapon_upgrade_hub.tscn")
const RUN_RESULT_OVERLAY_SCENE := preload("res://scenes/ui/run_result_overlay.tscn")
const ENEMY_VIEW_SCENE := preload("res://scenes/entities/enemy_view.tscn")
const BASE_VIEW_SCENE := preload("res://scenes/core/base_view.tscn")

const BASE_HEALTH_SYSTEM_SCRIPT := preload("res://scripts/systems/base_health_system.gd")
const ENERGY_SYSTEM_SCRIPT := preload("res://scripts/systems/energy_system.gd")
const LEVEL_SYSTEM_SCRIPT := preload("res://scripts/systems/level_system.gd")
const HERO_SYSTEM_SCRIPT := preload("res://scripts/systems/hero_system.gd")
const WEAPON_SYSTEM_SCRIPT := preload("res://scripts/systems/weapon_system.gd")
const GAME_STATE_SCRIPT := preload("res://scripts/autoload/game_state.gd")


func run(tree: SceneTree = null) -> void:
	_test_scenes_can_instantiate()
	_test_hud_signal_bindings(tree)
	_test_hud_hero_slot_bindings(tree)
	_test_run_result_overlay(tree)
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

	var result_instance: Variant = RUN_RESULT_OVERLAY_SCENE.instantiate()
	_assert(result_instance != null, "Run Result Overlay scene must instantiate successfully.")
	_assert(result_instance is Control, "Run Result Overlay must be a Control node.")
	result_instance.free()

	var enemy_view: Variant = ENEMY_VIEW_SCENE.instantiate()
	_assert(enemy_view != null, "Enemy view scene must instantiate successfully.")
	_assert(enemy_view is Node2D, "Enemy view must be a Node2D.")
	_assert(enemy_view.has_node("Body"), "Enemy view must have a Body polygon.")
	enemy_view.free()

	var base_view: Variant = BASE_VIEW_SCENE.instantiate()
	_assert(base_view != null, "Base view scene must instantiate successfully.")
	_assert(base_view is Node2D, "Base view must be a Node2D.")
	_assert(base_view.has_node("Body"), "Base view must have a Body polygon.")
	base_view.free()


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


func _test_hud_hero_slot_bindings(tree: SceneTree) -> void:
	var hero_sys: Variant = HERO_SYSTEM_SCRIPT.new()
	hero_sys.load_roster()

	var hud: Variant = BATTLE_HUD_SCENE.instantiate()
	hud.hero_system = hero_sys

	if tree != null and tree.root != null:
		tree.root.add_child(hud)
	hud._ready()

	# Initially all 4 slots must be "[Trống]"
	_assert(hud.hero_slot_labels.size() == 4, "HUD must have 4 hero slot labels cached.")
	for i in range(4):
		_assert(hud.hero_slot_labels[i].text == "[Trống]", "Hero slot %d should initially be [Trống]." % i)

	# Activate first hero
	hero_sys.active_heroes["commander_sarah"] = 1
	hero_sys.hero_activated.emit("commander_sarah", 1)
	_assert(hud.hero_slot_labels[0].text.contains("Commander Sarah"), "Slot 0 should show Commander Sarah.")
	_assert(hud.hero_slot_labels[0].text.contains("Lv.1"), "Slot 0 should show Lv.1.")
	_assert(hud.hero_slot_labels[1].text == "[Trống]", "Slot 1 should remain [Trống].")

	# Activate second hero
	hero_sys.active_heroes["sniper_locke"] = 1
	hero_sys.hero_activated.emit("sniper_locke", 1)
	_assert(hud.hero_slot_labels[1].text.contains("Sniper Locke"), "Slot 1 should show Sniper Locke.")
	_assert(hud.hero_slot_labels[1].text.contains("Lv.1"), "Slot 1 should show Lv.1.")

	# Upgrade first hero
	hero_sys.active_heroes["commander_sarah"] = 2
	hero_sys.hero_upgraded.emit("commander_sarah", 2)
	_assert(hud.hero_slot_labels[0].text.contains("Lv.2"), "Slot 0 should update to Lv.2.")

	# Test reset hero slots via hero_system.run_reset signal
	hero_sys.reset_run()
	for i in range(4):
		_assert(hud.hero_slot_labels[i].text == "[Trống]", "Hero slot %d should be [Trống] after run_reset." % i)

	if tree != null and tree.root != null:
		tree.root.remove_child(hud)
	hud.free()
	hero_sys.free()


func _test_run_result_overlay(tree: SceneTree) -> void:
	var game_state: Variant = GAME_STATE_SCRIPT.new()
	var overlay: Variant = RUN_RESULT_OVERLAY_SCENE.instantiate()
	overlay.game_state = game_state

	if tree != null and tree.root != null:
		tree.root.add_child(overlay)
	overlay._ready()

	# Initially overlay should be hidden
	_assert(not overlay.visible, "RunResultOverlay should be hidden initially.")

	# Test run_failed signal
	game_state.run_failed.emit()
	_assert(overlay.visible, "Overlay should be visible after run_failed.")
	_assert(overlay.title_label.text == "THẤT BẠI", "Title should be THẤT BẠI.")
	_assert(overlay.retry_button.visible, "Retry button should be visible on defeat.")
	_assert(not overlay.back_to_map_button.visible, "Back to map button should be hidden on defeat.")

	# Test retry click
	overlay._on_retry_pressed()
	_assert(not overlay.visible, "Overlay should hide after pressing retry.")

	# Test run_completed signal
	game_state.run_completed.emit()
	_assert(overlay.visible, "Overlay should be visible after run_completed.")
	_assert(overlay.title_label.text == "HOÀN THÀNH MÀN", "Title should be HOÀN THÀNH MÀN.")
	_assert(not overlay.retry_button.visible, "Retry button should be hidden on victory.")
	_assert(overlay.back_to_map_button.visible, "Back to map button should be visible on victory.")

	# Test back_to_map click
	var back_to_map_emitted := [false]
	overlay.back_to_map_requested.connect(func() -> void:
		back_to_map_emitted[0] = true
	)
	overlay._on_back_to_map_pressed()
	_assert(not overlay.visible, "Overlay should hide after pressing back to map.")
	_assert(back_to_map_emitted[0], "Overlay should emit back_to_map_requested.")

	if tree != null and tree.root != null:
		tree.root.remove_child(overlay)
	overlay.free()
	game_state.free()


func _test_weapon_hub_interactions(tree: SceneTree) -> void:
	var weapon_sys: Variant = WEAPON_SYSTEM_SCRIPT.new()
	weapon_sys.load_roster()
	weapon_sys.current_gold = 0

	var hub: Variant = WEAPON_HUB_SCENE.instantiate()
	hub.weapon_system = weapon_sys

	if tree != null and tree.root != null:
		tree.root.add_child(hub)
	hub._ready()

	# Khẳng định không có lỗ hổng tự tặng 1000 vàng khi gold == 0
	_assert(weapon_sys.current_gold == 0, "WeaponSystem gold must stay 0, Hub must not give free 1000 gold.")
	_assert(hub.gold_label.text == "💰 VÀNG: 0", "Gold label should display 0 initially.")

	# Thiết lập fixture vàng cho test nâng cấp
	weapon_sys.current_gold = 500
	hub._show_weapon(0)

	_assert(hub.weapon_title.text == "Standard Rifle", "Initial weapon should be Standard Rifle.")
	_assert(hub.type_label.text.contains("Single"), "Rifle should be Single target.")
	_assert(hub.level_label.text.contains("0 / 4"), "Initial level should be 0 / 4.")
	_assert(hub.gold_label.text.contains("500"), "Gold should display 500.")
	_assert(hub.upgrade_button.text.contains("100"), "First upgrade cost should be 100.")

	# Thực hiện nâng cấp thật
	hub._on_upgrade_pressed()
	_assert(weapon_sys.weapon_levels["rifle_standard"] == 1, "Rifle level should be 1 after upgrade.")
	_assert(weapon_sys.current_gold == 400, "Gold should decrease to 400.")
	_assert(hub.level_label.text.contains("1 / 4"), "UI should update to Cấp 1 / 4.")
	_assert(hub.damage_label.text.contains("8.8"), "Damage should update with 10% bonus (8.0 * 1.10 = 8.8).")

	# Kiểm tra trạng thái KHÔNG ĐỦ VÀNG
	weapon_sys.current_gold = 50 # Chi phí cấp 1 lên 2 là 250
	hub._show_weapon(0)
	_assert(hub.upgrade_button.text.contains("KHÔNG ĐỦ VÀNG"), "Button should show KHÔNG ĐỦ VÀNG when short on gold.")

	# Kiểm tra trạng thái MAX CẤP
	weapon_sys.current_gold = 10000
	weapon_sys.weapon_levels["rifle_standard"] = 4
	hub._show_weapon(0)
	_assert(hub.upgrade_button.text == "MAX CẤP", "Button should show MAX CẤP at max level.")
	_assert(hub.upgrade_button.disabled, "Upgrade button should be disabled at max level.")

	# Chuyển sang shotgun
	hub._select_shotgun()
	_assert(hub.weapon_title.text == "Breaching Shotgun", "Selected weapon should be Breaching Shotgun.")
	_assert(hub.type_label.text.contains("AOE"), "Shotgun should be Multi/AOE target.")

	# Kiểm tra lắng nghe weapon_upgraded từ nơi khác
	weapon_sys.weapon_levels["shotgun_breach"] = 2
	weapon_sys.weapon_upgraded.emit("shotgun_breach", 2)
	_assert(hub.level_label.text.contains("2 / 4"), "External weapon_upgraded signal should update UI.")

	# Kiểm tra trạng thái nút trang bị ban đầu (Rifle)
	hub._select_rifle()
	_assert(hub.equip_button.text == "ĐANG TRANG BỊ", "Rifle initial equip button should say ĐANG TRANG BỊ.")
	_assert(hub.equip_button.disabled, "Rifle equip button should be disabled when already equipped.")

	# Chuyển sang shotgun: chưa trang bị nên nút mở
	hub._select_shotgun()
	_assert(hub.equip_button.text == "TRANG BỊ", "Shotgun equip button should say TRANG BỊ.")
	_assert(not hub.equip_button.disabled, "Shotgun equip button should not be disabled.")

	# Bấm nút TRANG BỊ
	hub._on_equip_pressed()
	_assert(weapon_sys.equipped_weapon_id == "shotgun_breach", "WeaponSystem equipped_weapon_id should be shotgun_breach.")
	_assert(hub.equip_button.text == "ĐANG TRANG BỊ", "Shotgun equip button should now say ĐANG TRANG BỊ.")
	_assert(hub.equip_button.disabled, "Shotgun equip button should be disabled after equipping.")
	_assert(hub.notice_label.text.contains("Đã trang bị"), "Notice label should notify successful equip.")

	# Chuyển lại rifle: lúc này rifle thành chưa trang bị
	hub._select_rifle()
	_assert(hub.equip_button.text == "TRANG BỊ", "Rifle equip button should now say TRANG BỊ.")
	_assert(not hub.equip_button.disabled, "Rifle equip button should not be disabled after swapping.")

	# Kiểm tra lắng nghe weapon_equipped phát từ bên ngoài
	weapon_sys.set_equipped_weapon("rifle_standard")
	_assert(hub.equip_button.text == "ĐANG TRANG BỊ", "UI should reflect external weapon_equipped signal.")
	_assert(hub.equip_button.disabled, "Rifle equip button should be disabled after external equip.")

	# Kiểm tra lắng nghe gold_changed cập nhật UI
	weapon_sys.add_gold(150)
	_assert(hub.gold_label.text.contains(str(weapon_sys.current_gold)), "UI should reflect gold_changed signal.")

	if tree != null and tree.root != null:
		tree.root.remove_child(hub)
	hub.free()
	weapon_sys.free()


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
