class_name MainFlowTest
extends RefCounted

const MAIN_SCENE := preload("res://scenes/core/main.tscn")
const BATTLE_ARENA_SCENE := preload("res://scenes/core/battle_arena.tscn")
const BATTLE_ARENA_SCRIPT := preload("res://scripts/core/battle_arena.gd")
const ENEMY_SCRIPT := preload("res://scripts/entities/enemy.gd")

const WAVE_MANAGER_SCRIPT := preload("res://scripts/systems/wave_manager.gd")
const GAME_STATE_SCRIPT := preload("res://scripts/autoload/game_state.gd")
const BASE_HEALTH_SYSTEM_SCRIPT := preload("res://scripts/systems/base_health_system.gd")
const LEVEL_SYSTEM_SCRIPT := preload("res://scripts/systems/level_system.gd")
const HERO_SYSTEM_SCRIPT := preload("res://scripts/systems/hero_system.gd")
const WEAPON_SYSTEM_SCRIPT := preload("res://scripts/systems/weapon_system.gd")
const MAIN_MENU_SCRIPT := preload("res://scripts/ui/main_menu.gd")


func run(tree: SceneTree = null) -> void:
	_test_main_boots_into_main_menu(tree)
	_test_main_menu_transitions_to_map_selection(tree)
	_test_main_transitions_to_battle_arena(tree)
	_test_battle_arena_initialization_and_lane_cleanup(tree)
	_test_bullet_tracer_lifecycle(tree)
	_test_secondary_hero_lifecycle(tree)
	_test_enemy_spawn_attaches_visual(tree)
	_test_upgrade_choice_overlay_lifecycle(tree)
	_test_back_to_map_routing(tree)


func _test_main_boots_into_main_menu(tree: SceneTree) -> void:
	var main: Variant = MAIN_SCENE.instantiate()
	if tree != null and tree.root != null:
		tree.root.add_child(main)
	main._ready()

	_assert(main.current_view != null, "Main should have a current view on boot.")
	_assert(main.current_view.get_script() == MAIN_MENU_SCRIPT, "Main should boot into MainMenu.")
	var menu: Variant = main.current_view
	menu._ready()
	_assert(menu.title_label != null and menu.title_label.text == "PostApocDefense", "MainMenu title should be PostApocDefense.")
	_assert(menu.play_button != null and not menu.play_button.disabled, "PlayButton should be present and enabled.")
	_assert(menu.settings_button != null and menu.settings_button.disabled, "SettingsButton should be present and disabled.")

	if tree != null and tree.root != null:
		tree.root.remove_child(main)
	main.free()


func _test_main_menu_transitions_to_map_selection(tree: SceneTree) -> void:
	var main: Variant = MAIN_SCENE.instantiate()
	if tree != null and tree.root != null:
		tree.root.add_child(main)
	main._ready()

	_assert(main.current_view.get_script() == MAIN_MENU_SCRIPT, "Main should boot into MainMenu.")
	var menu: Variant = main.current_view
	menu._ready()
	menu.play_pressed.emit()
	_assert(main.current_view is MapSelection, "Main should transition to MapSelection after play_pressed.")

	if tree != null and tree.root != null:
		tree.root.remove_child(main)
	main.free()


func _test_main_transitions_to_battle_arena(tree: SceneTree) -> void:
	var main: Variant = MAIN_SCENE.instantiate()
	if tree != null and tree.root != null:
		tree.root.add_child(main)
	main._ready()

	# Chuyển sang trận đấu
	main.start_battle(1)
	_assert(main.current_view != null, "Main should have current view after start_battle.")
	_assert(main.current_view is BattleArena, "Current view should be BattleArena.")
	_assert(main.current_view.stage_id == 1, "BattleArena should receive stage_id = 1 from start_battle.")

	if tree != null and tree.root != null:
		tree.root.remove_child(main)
	main.free()


func _test_battle_arena_initialization_and_lane_cleanup(tree: SceneTree) -> void:
	var wave_mgr: Variant = WAVE_MANAGER_SCRIPT.new()
	var game_state: Variant = GAME_STATE_SCRIPT.new()
	var weapon_sys: Variant = WEAPON_SYSTEM_SCRIPT.new()
	weapon_sys.load_roster()
	weapon_sys.set_equipped_weapon("shotgun_breach")

	var arena: Variant = BATTLE_ARENA_SCENE.instantiate()
	arena.wave_manager = wave_mgr
	arena.game_state = game_state
	arena.weapon_system = weapon_sys

	if tree != null and tree.root != null:
		tree.root.add_child(arena)
	arena._ready()

	_assert(arena.path_line != null, "BattleArena should have a PathLine.")
	_assert(arena.base_view != null, "BattleArena should have a BaseView.")
	_assert(arena.hud != null, "BattleArena should have a BattleHUD.")
	_assert(arena.result_overlay != null, "BattleArena should have a RunResultOverlay.")

	_assert(wave_mgr.spawn_x_range == Vector2(80.0, 640.0), "WaveManager should keep its default independent spawn lanes.")
	_assert(wave_mgr.lane_top_y == 80.0 and wave_mgr.lane_bottom_y == 1060.0, "WaveManager lane defaults should align with the arena bounds.")
	_assert(arena.path_line.get_point_count() == 0, "BattleArena should clear the obsolete shared zigzag PathLine.")
	_assert(arena.base_view.position == Vector2(360.0, 1060.0), "BaseView should be placed at the final waypoint.")

	# Kiểm tra chuyển đổi bộ waypoints theo stage_id
	var arena_stage2: Variant = BATTLE_ARENA_SCENE.instantiate()
	arena_stage2.stage_id = 2
	arena_stage2.wave_manager = wave_mgr
	arena_stage2._ready()
	_assert(arena_stage2.waypoints == BATTLE_ARENA_SCRIPT.get_stage_waypoints(2), "Arena should select Stage 2 waypoints when stage_id is 2.")
	_assert(arena_stage2.path_line.get_point_count() == 0, "Stage changes must not restore the obsolete shared PathLine.")
	arena_stage2.free()

	# Kiểm tra z_index đảm bảo quái và các thực thể không bị che lấp
	var bg: ColorRect = arena.get_node_or_null("Background") as ColorRect
	_assert(bg != null, "BattleArena should have a Background node.")
	_assert(bg.z_index == -10, "Background must have z_index = -10 to always render behind autoload nodes.")
	_assert(arena.path_line.z_index == -5, "PathLine must have z_index = -5.")
	_assert(bg.z_index < arena.path_line.z_index, "Background must render behind PathLine.")
	_assert(arena.path_line.z_index < arena.base_view.z_index or arena.path_line.z_index < 0, "PathLine must render behind BaseView and Enemy entities (z_index >= 0).")

	# Kiểm tra visual của MainHero
	var hero: Node2D = arena.get_node_or_null("MainHero") as Node2D
	_assert(hero != null, "BattleArena should have a MainHero node.")
	var hero_body: Polygon2D = hero.get_node_or_null("Body") as Polygon2D
	var hero_core: Polygon2D = hero.get_node_or_null("Core") as Polygon2D
	_assert(hero_body != null and hero_core != null, "MainHero should have Body and Core Polygon2D visual nodes.")
	_assert(hero_body.color.g > hero_body.color.r and hero_body.color.g > hero_body.color.b, "MainHero Body must be green.")
	_assert(hero_core.color.g > hero_core.color.r and hero_core.color.g > hero_core.color.b, "MainHero Core must be green.")

	# Kiểm tra đồng bộ vũ khí từ WeaponSystem sang MainHero
	_assert(hero.get("equipped_weapon_id") == "shotgun_breach", "MainHero should synchronize equipped weapon from WeaponSystem on ready.")

	# Kiểm tra RangeIndicator của MainHero
	var range_indicator: Node2D = hero.get_node_or_null("RangeIndicator") as Node2D
	_assert(range_indicator != null, "MainHero should have a RangeIndicator child node.")
	_assert(range_indicator.z_index == -1, "RangeIndicator must have z_index = -1 to render behind Hero/Enemies and above PathLine.")
	_assert(range_indicator.half_width == 180.0 and range_indicator.half_height == 220.0, "RangeIndicator half-extents should match equipped weapon range (shotgun_breach = 180x220).")

	# Kiểm tra cập nhật vũ khí qua signal weapon_equipped trong runtime
	weapon_sys.set_equipped_weapon("rifle_standard")
	_assert(hero.get("equipped_weapon_id") == "rifle_standard", "MainHero should update equipped weapon on weapon_equipped signal.")
	_assert(range_indicator.half_width == 280.0 and range_indicator.half_height == 450.0, "RangeIndicator half-extents should update when weapon_equipped is emitted (rifle_standard = 280x450).")

	if tree != null and tree.root != null:
		tree.root.remove_child(arena)
	arena.free()
	weapon_sys.free()
	game_state.free()
	wave_mgr.free()


func _test_bullet_tracer_lifecycle(tree: SceneTree) -> void:
	var wave_mgr: Variant = WAVE_MANAGER_SCRIPT.new()
	var game_state: Variant = GAME_STATE_SCRIPT.new()
	var weapon_sys: Variant = WEAPON_SYSTEM_SCRIPT.new()

	var arena: Variant = BATTLE_ARENA_SCENE.instantiate()
	arena.wave_manager = wave_mgr
	arena.game_state = game_state
	arena.weapon_system = weapon_sys

	if tree != null and tree.root != null:
		tree.root.add_child(arena)
	arena._ready()

	_assert(arena.tracers_container != null, "BattleArena should have a Tracers container.")
	_assert(arena.tracers_container.z_index == 5, "Tracers container should have z_index = 5 to render above other battle elements.")
	_assert(arena.main_hero != null, "BattleArena should have a MainHero.")
	_assert(arena.main_hero.weapon_fired.is_connected(arena._on_main_hero_weapon_fired), "MainHero weapon_fired must be connected to arena.")

	# Giả lập 1 phát bắn từ hero đến quái
	var hero_pos: Vector2 = arena.main_hero.global_position
	var target_pos := Vector2(360.0, 800.0)
	arena.main_hero.weapon_fired.emit(hero_pos, target_pos)

	_assert(arena.tracers_container.get_child_count() == 1, "Tracers container should have 1 child after weapon_fired.")
	var tracer: Line2D = arena.tracers_container.get_child(0) as Line2D
	_assert(tracer != null, "Created tracer must be a Line2D.")
	_assert(tracer.width == 4.5, "Tracer width should be 4.5px.")
	_assert(tracer.default_color == Color(0.65, 1.0, 0.75, 0.9), "Tracer color should match hero bullet color.")
	_assert(tracer.points.size() == 2, "Tracer should have 2 points.")
	_assert(tracer.points[0] == hero_pos, "Tracer start point should be hero position.")
	_assert(tracer.points[1] == target_pos, "Tracer end point should be target position.")
	_assert(arena._active_tracers.size() == 1, "_active_tracers should track 1 tracer.")

	# Kiểm tra thời gian sống: sau 0.15s vẫn còn (vì tổng thời lượng là 0.25s)
	arena._process(0.15)
	_assert(arena._active_tracers.size() == 1, "Tracer should remain active after 0.15s (lifetime is 0.25s).")

	# Sau thêm 0.12s (tổng 0.27s > 0.25s), tia đạn phải được giải phóng
	arena._process(0.12)
	_assert(arena._active_tracers.is_empty(), "Tracer should be removed from active list after 0.25s.")

	# Kiểm tra bắn multi-target (nhiều tia độc lập cùng lúc)
	arena.main_hero.weapon_fired.emit(hero_pos, Vector2(200.0, 700.0))
	arena.main_hero.weapon_fired.emit(hero_pos, Vector2(500.0, 700.0))
	_assert(arena._active_tracers.size() == 2, "Multiple tracers must be tracked independently.")

	# Kiểm tra dọn sạch khi rời khỏi scene (_exit_tree)
	arena._exit_tree()
	_assert(arena._active_tracers.is_empty(), "All active tracers must be cleared on exit_tree.")

	if tree != null and tree.root != null:
		tree.root.remove_child(arena)
	arena.free()
	weapon_sys.free()
	game_state.free()
	wave_mgr.free()


func _test_secondary_hero_lifecycle(tree: SceneTree) -> void:
	var wave_mgr: Variant = WAVE_MANAGER_SCRIPT.new()
	var game_state: Variant = GAME_STATE_SCRIPT.new()
	var weapon_sys: Variant = WEAPON_SYSTEM_SCRIPT.new()
	var hero_sys: Variant = HERO_SYSTEM_SCRIPT.new()
	hero_sys.load_roster()

	var arena: Variant = BATTLE_ARENA_SCENE.instantiate()
	arena.wave_manager = wave_mgr
	arena.game_state = game_state
	arena.weapon_system = weapon_sys
	arena.hero_system = hero_sys

	if tree != null and tree.root != null:
		tree.root.add_child(arena)
	arena._ready()

	_assert(arena.secondary_heroes.is_empty(), "secondary_heroes should initially be empty.")

	# 1. Kích hoạt hero đầu tiên: Commander Sarah -> Slot 0
	hero_sys.hero_activated.emit("commander_sarah", 1)
	_assert(arena.secondary_heroes.has("commander_sarah"), "Arena should track commander_sarah.")
	var sarah: Node2D = arena.secondary_heroes["commander_sarah"]
	_assert(sarah != null, "Sarah instance must exist in scene.")
	_assert(sarah.position == Vector2(360.0, 1060.0) + Vector2(-80.0, -45.0), "Sarah must be positioned at Slot 0.")
	_assert(sarah.get("current_level") == 1, "Sarah initial level should be 1.")

	# Kiểm tra visual của SecondaryHero: 2 Polygon2D Body và Core màu vàng/cam
	var body: Polygon2D = sarah.get_node_or_null("Body") as Polygon2D
	var core: Polygon2D = sarah.get_node_or_null("Core") as Polygon2D
	_assert(body != null and core != null, "SecondaryHero must have Body and Core Polygon2D visual nodes.")
	_assert(body.color == Color(0.95, 0.65, 0.15, 1.0), "Body color should be amber/orange.")
	_assert(core.color == Color(1.0, 0.92, 0.45, 1.0), "Core color should be bright energy yellow.")

	# Kiểm tra kết nối weapon_fired của SecondaryHero vào hệ thống vẽ tia đạn
	_assert(sarah.has_signal("weapon_fired"), "SecondaryHero must declare weapon_fired signal.")
	_assert(sarah.weapon_fired.is_connected(arena._on_main_hero_weapon_fired), "SecondaryHero weapon_fired must be connected to arena tracer handler.")
	sarah.weapon_fired.emit(sarah.global_position, Vector2(280.0, 800.0))
	_assert(arena._active_tracers.size() == 1, "SecondaryHero weapon_fired should spawn a bullet tracer in arena.")
	arena._process(0.26)
	_assert(arena._active_tracers.is_empty(), "SecondaryHero bullet tracer should expire after 0.25s.")

	# 2. Kích hoạt hero thứ 2: Ghost Sniper -> Slot 1
	hero_sys.hero_activated.emit("sniper_ghost", 1)
	_assert(arena.secondary_heroes.has("sniper_ghost"), "Arena should track sniper_ghost.")
	var sniper: Node2D = arena.secondary_heroes["sniper_ghost"]
	_assert(sniper != null, "Sniper instance must exist.")
	_assert(sniper.position == Vector2(360.0, 1060.0) + Vector2(80.0, -45.0), "Sniper must be positioned at Slot 1.")

	# 3. Nâng cấp hero phụ: hero_upgraded
	hero_sys.hero_upgraded.emit("commander_sarah", 3)
	_assert(sarah.get("current_level") == 3, "Sarah level should be updated to 3 after hero_upgraded.")

	# 4. Kiểm tra đồng bộ hero đã kích hoạt sẵn từ trước lúc _ready()
	var pre_active_hero_sys: Variant = HERO_SYSTEM_SCRIPT.new()
	pre_active_hero_sys.load_roster()
	pre_active_hero_sys.active_heroes["sniper_ghost"] = 2
	var arena2: Variant = BATTLE_ARENA_SCENE.instantiate()
	arena2.hero_system = pre_active_hero_sys
	arena2._ready()
	_assert(arena2.secondary_heroes.has("sniper_ghost"), "Pre-existing active heroes must be synced on _ready().")
	_assert(arena2.secondary_heroes["sniper_ghost"].get("current_level") == 2, "Pre-existing active hero level must match.")
	arena2.free()
	pre_active_hero_sys.free()

	# 5. Kiểm tra run_reset dọn sạch toàn bộ hero phụ
	hero_sys.run_reset.emit()
	_assert(arena.secondary_heroes.is_empty(), "All secondary hero instances must be cleared on run_reset.")

	if tree != null and tree.root != null:
		tree.root.remove_child(arena)
	arena.free()
	hero_sys.free()
	weapon_sys.free()
	game_state.free()
	wave_mgr.free()


func _test_enemy_spawn_attaches_visual(tree: SceneTree) -> void:
	var wave_mgr: Variant = WAVE_MANAGER_SCRIPT.new()
	var game_state: Variant = GAME_STATE_SCRIPT.new()

	var arena: Variant = BATTLE_ARENA_SCENE.instantiate()
	arena.wave_manager = wave_mgr
	arena.game_state = game_state

	if tree != null and tree.root != null:
		tree.root.add_child(arena)
	arena._ready()

	var enemy: Variant = ENEMY_SCRIPT.new()
	_assert(enemy.get_child_count() == 0, "Enemy initially has no visual children.")

	# Giả lập WaveManager phát enemy_spawned
	wave_mgr.enemy_spawned.emit(enemy)
	_assert(enemy.get_child_count() > 0, "Enemy should have visual child attached after enemy_spawned.")
	var visual: Node = enemy.get_child(0)
	_assert(visual.has_node("Body"), "Attached visual should have Body polygon.")

	enemy.free()

	if tree != null and tree.root != null:
		tree.root.remove_child(arena)
	arena.free()
	game_state.free()
	wave_mgr.free()


func _test_upgrade_choice_overlay_lifecycle(tree: SceneTree) -> void:
	var wave_mgr: Variant = WAVE_MANAGER_SCRIPT.new()
	var game_state: Variant = GAME_STATE_SCRIPT.new()
	var weapon_sys: Variant = WEAPON_SYSTEM_SCRIPT.new()
	var hero_sys: Variant = HERO_SYSTEM_SCRIPT.new()
	hero_sys.load_roster()

	var arena: Variant = BATTLE_ARENA_SCENE.instantiate()
	arena.wave_manager = wave_mgr
	arena.game_state = game_state
	arena.weapon_system = weapon_sys
	arena.hero_system = hero_sys

	if tree != null and tree.root != null:
		tree.root.add_child(arena)
	arena._ready()

	_assert(arena.upgrade_overlay != null, "BattleArena should have an UpgradeChoiceOverlay.")
	_assert(not arena.upgrade_overlay.visible, "UpgradeChoiceOverlay should initially be hidden.")
	_assert(arena.upgrade_overlay.process_mode == Node.PROCESS_MODE_ALWAYS, "UpgradeChoiceOverlay should have process_mode = PROCESS_MODE_ALWAYS.")

	# 1. Phát signal upgrade_choices_ready từ HeroSystem với 2 options
	var mock_options: Array[Dictionary] = [
		{
			"action": "activate",
			"hero_id": "commander_sarah",
			"display_name": "Commander Sarah",
			"current_level": 0,
			"next_level": 1,
			"max_level": 15
		},
		{
			"action": "upgrade",
			"hero_id": "sniper_ghost",
			"display_name": "Ghost Sniper",
			"current_level": 2,
			"next_level": 3,
			"max_level": 15
		}
	]
	hero_sys.pending_upgrade_options = mock_options.duplicate(true)
	hero_sys.upgrade_choices_ready.emit(mock_options)

	_assert(arena.upgrade_overlay.visible, "UpgradeChoiceOverlay should be visible after upgrade_choices_ready.")
	if tree != null and arena.is_inside_tree():
		_assert(tree.paused, "Game tree should be paused when UpgradeChoiceOverlay is open.")

	var cards_container: HBoxContainer = arena.upgrade_overlay.get_node_or_null("CenterContainer/MainPanel/CardsContainer") as HBoxContainer
	_assert(cards_container != null, "CardsContainer must exist.")
	_assert(cards_container.get_child_count() == 2, "CardsContainer should have 2 cards.")

	var card_0: Control = cards_container.get_child(0) as Control
	_assert(card_0 != null, "Card 0 should exist.")
	var action_label_0: Label = card_0.find_child("ActionLabel", true, false) as Label
	var name_label_0: Label = card_0.find_child("NameLabel", true, false) as Label
	var level_label_0: Label = card_0.find_child("LevelLabel", true, false) as Label
	var button_0: Button = card_0.find_child("SelectButton", true, false) as Button
	_assert(action_label_0 != null and action_label_0.text.contains("MỞ MỚI"), "Card 0 action should be MỞ MỚI.")
	_assert(name_label_0 != null and name_label_0.text == "Commander Sarah", "Card 0 name should be Commander Sarah.")
	_assert(level_label_0 != null and level_label_0.text.contains("Cấp 1"), "Card 0 level should mention Cấp 1.")
	_assert(button_0 != null, "Card 0 should have a SelectButton.")

	var card_1: Control = cards_container.get_child(1) as Control
	var action_label_1: Label = card_1.find_child("ActionLabel", true, false) as Label
	_assert(action_label_1 != null and action_label_1.text.contains("NÂNG CẤP"), "Card 1 action should be NÂNG CẤP.")

	# 2. Bấm chọn thẻ 0
	var chosen_index := [-1]
	var signal_received := [false]
	var choice_callable := func(idx: int) -> void:
		chosen_index[0] = idx
		signal_received[0] = true
	arena.upgrade_overlay.upgrade_chosen.connect(choice_callable)

	button_0.pressed.emit()

	_assert(signal_received[0], "upgrade_chosen signal should be emitted on card selection.")
	_assert(chosen_index[0] == 0, "Selected index should be 0.")
	_assert(not arena.upgrade_overlay.visible, "Overlay should hide after card selection.")
	if tree != null and arena.is_inside_tree():
		_assert(not tree.paused, "Game tree should be unpaused after overlay closes.")

	arena.upgrade_overlay.upgrade_chosen.disconnect(choice_callable)

	# 3. Test reset: khi overlay đang hiện mà có run_reset thì overlay tự ẩn
	hero_sys.pending_upgrade_options = mock_options.duplicate(true)
	hero_sys.upgrade_choices_ready.emit(mock_options)
	_assert(arena.upgrade_overlay.visible, "Overlay should be visible again.")
	hero_sys.run_reset.emit()
	_assert(not arena.upgrade_overlay.visible, "Overlay should hide on run_reset.")
	if tree != null and arena.is_inside_tree():
		_assert(not tree.paused, "Tree should not remain paused after run_reset.")

	# 4. Kiểm tra trường hợp cạnh: upgrade_choices_ready và run_failed xảy ra đồng thời
	hero_sys.pending_upgrade_options = mock_options.duplicate(true)
	hero_sys.upgrade_choices_ready.emit(mock_options)
	_assert(arena.upgrade_overlay.visible, "Overlay should be visible on upgrade choices.")
	game_state.run_failed.emit()
	_assert(not arena.upgrade_overlay.visible, "UpgradeChoiceOverlay must immediately hide when run_failed emits to not block RunResultOverlay.")
	_assert(arena.result_overlay.visible, "RunResultOverlay should be visible on defeat.")

	# 5. Kiểm tra trường hợp cạnh: upgrade_choices_ready và run_completed xảy ra đồng thời
	hero_sys.run_reset.emit()
	hero_sys.pending_upgrade_options = mock_options.duplicate(true)
	hero_sys.upgrade_choices_ready.emit(mock_options)
	_assert(arena.upgrade_overlay.visible, "Overlay should be visible on upgrade choices.")
	game_state.run_completed.emit()
	_assert(not arena.upgrade_overlay.visible, "UpgradeChoiceOverlay must immediately hide when run_completed emits.")
	_assert(arena.result_overlay.visible, "RunResultOverlay should be visible on victory.")

	# 6. Kiểm tra không hiện lại overlay nâng cấp khi trận đấu đã kết thúc
	hero_sys.upgrade_choices_ready.emit(mock_options)
	_assert(not arena.upgrade_overlay.visible, "UpgradeChoiceOverlay must not show if run is already finished.")

	if tree != null and tree.root != null:
		tree.root.remove_child(arena)
	arena.free()
	hero_sys.free()
	weapon_sys.free()
	game_state.free()
	wave_mgr.free()


func _test_back_to_map_routing(tree: SceneTree) -> void:
	var main: Variant = MAIN_SCENE.instantiate()
	if tree != null and tree.root != null:
		tree.root.add_child(main)
	main._ready()

	# Sang battle arena
	main.start_battle(1)
	_assert(main.current_view is BattleArena, "Should be in BattleArena.")

	# Bấm về bản đồ
	var arena: Variant = main.current_view
	arena._on_back_to_map_pressed()
	_assert(main.current_view is MapSelection, "Should route back to MapSelection.")

	if tree != null and tree.root != null:
		tree.root.remove_child(main)
	main.free()


func _assert(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		assert(condition, message)
