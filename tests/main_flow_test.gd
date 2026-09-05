class_name MainFlowTest
extends RefCounted

const MAIN_SCENE := preload("res://scenes/core/main.tscn")
const BATTLE_ARENA_SCENE := preload("res://scenes/core/battle_arena.tscn")
const ENEMY_SCRIPT := preload("res://scripts/entities/enemy.gd")

const WAVE_MANAGER_SCRIPT := preload("res://scripts/systems/wave_manager.gd")
const GAME_STATE_SCRIPT := preload("res://scripts/autoload/game_state.gd")
const BASE_HEALTH_SYSTEM_SCRIPT := preload("res://scripts/systems/base_health_system.gd")
const LEVEL_SYSTEM_SCRIPT := preload("res://scripts/systems/level_system.gd")
const HERO_SYSTEM_SCRIPT := preload("res://scripts/systems/hero_system.gd")
const WEAPON_SYSTEM_SCRIPT := preload("res://scripts/systems/weapon_system.gd")


func run(tree: SceneTree = null) -> void:
	_test_main_boots_into_map_selection(tree)
	_test_main_transitions_to_battle_arena(tree)
	_test_battle_arena_initialization_and_waypoints(tree)
	_test_enemy_spawn_attaches_visual(tree)
	_test_back_to_map_routing(tree)


func _test_main_boots_into_map_selection(tree: SceneTree) -> void:
	var main: Variant = MAIN_SCENE.instantiate()
	if tree != null and tree.root != null:
		tree.root.add_child(main)
	main._ready()

	_assert(main.current_view != null, "Main should have a current view on boot.")
	_assert(main.current_view is MapSelection, "Main should boot into MapSelection.")

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

	if tree != null and tree.root != null:
		tree.root.remove_child(main)
	main.free()


func _test_battle_arena_initialization_and_waypoints(tree: SceneTree) -> void:
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

	# Waypoints gán cho WaveManager
	_assert(wave_mgr.path_waypoints.size() == 2, "WaveManager should receive waypoints.")
	_assert(wave_mgr.path_waypoints == arena.waypoints, "Waypoints in WaveManager should match arena.")

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

	# Kiểm tra cập nhật vũ khí qua signal weapon_equipped trong runtime
	weapon_sys.set_equipped_weapon("rifle_standard")
	_assert(hero.get("equipped_weapon_id") == "rifle_standard", "MainHero should update equipped weapon on weapon_equipped signal.")

	if tree != null and tree.root != null:
		tree.root.remove_child(arena)
	arena.free()
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
