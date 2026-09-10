class_name BattleArena
extends Node2D

signal back_to_map_requested

const ENEMY_VIEW_SCENE := preload("res://scenes/entities/enemy_view.tscn")
const BASE_VIEW_SCENE := preload("res://scenes/core/base_view.tscn")
const BATTLE_HUD_SCENE := preload("res://scenes/ui/battle_hud.tscn")
const RUN_RESULT_OVERLAY_SCENE := preload("res://scenes/ui/run_result_overlay.tscn")
const UPGRADE_CHOICE_OVERLAY_SCENE := preload("res://scenes/ui/upgrade_choice_overlay.tscn")

const STAGE_PATHS: Dictionary = {
	1: [
		Vector2(360.0, 80.0),
		Vector2(180.0, 260.0),
		Vector2(540.0, 480.0),
		Vector2(160.0, 700.0),
		Vector2(520.0, 890.0),
		Vector2(360.0, 1060.0)
	],
	2: [
		Vector2(360.0, 80.0),
		Vector2(360.0, 1060.0)
	],
	3: [
		Vector2(360.0, 80.0),
		Vector2(360.0, 1060.0)
	],
	4: [
		Vector2(360.0, 80.0),
		Vector2(360.0, 1060.0)
	]
}

static func get_stage_waypoints(target_stage_id: int) -> PackedVector2Array:
	if STAGE_PATHS.has(target_stage_id):
		return PackedVector2Array(STAGE_PATHS[target_stage_id])
	return PackedVector2Array(STAGE_PATHS.get(1, []))

@export var stage_id: int = 1:
	set(value):
		stage_id = value
		waypoints = get_stage_waypoints(stage_id)

@export var waypoints: PackedVector2Array = [
	Vector2(360.0, 80.0),
	Vector2(180.0, 260.0),
	Vector2(540.0, 480.0),
	Vector2(160.0, 700.0),
	Vector2(520.0, 890.0),
	Vector2(360.0, 1060.0)
]

const BULLET_TRACER_COLOR: Color = Color(0.65, 1.0, 0.75, 0.9)
const BULLET_TRACER_WIDTH: float = 4.5
const BULLET_TRACER_LIFETIME: float = 0.25

const SECONDARY_HERO_SCRIPT := preload("res://scripts/entities/secondary_hero.gd")
const SECONDARY_HERO_SLOT_OFFSETS: Array[Vector2] = [
	Vector2(-80.0, -45.0),
	Vector2(80.0, -45.0),
	Vector2(-45.0, -90.0),
	Vector2(45.0, -90.0)
]
const SECONDARY_HERO_BODY_COLOR: Color = Color(0.95, 0.65, 0.15, 1.0)
const SECONDARY_HERO_CORE_COLOR: Color = Color(1.0, 0.92, 0.45, 1.0)

var path_line: Line2D
var base_view: Node2D
var main_hero: Node2D
var range_indicator: Node2D
var tracers_container: Node2D
var hud: BattleHUD
var result_overlay: RunResultOverlay
var upgrade_overlay: UpgradeChoiceOverlay

var wave_manager: Node
var game_state: Node
var weapon_system: Node
var hero_system: Node

var _active_tracers: Array[Dictionary] = []
var secondary_heroes: Dictionary = {}
var _secondary_hero_order: Array[String] = []


func _ready() -> void:
	_cache_nodes()

	if is_inside_tree():
		if wave_manager == null:
			wave_manager = get_node_or_null("/root/WaveManager")
		if game_state == null:
			game_state = get_node_or_null("/root/GameState")
		if weapon_system == null:
			weapon_system = get_node_or_null("/root/WeaponSystem")
		if hero_system == null:
			hero_system = get_node_or_null("/root/HeroSystem")

	_setup_path_and_base()
	_sync_equipped_weapon()
	_sync_active_secondary_heroes()
	_connect_signals()

	if game_state != null and game_state.has_method("start_stage"):
		game_state.start_stage()


func _process(delta: float) -> void:
	_update_tracers(delta)


func _exit_tree() -> void:
	_clear_tracers()
	_on_hero_run_reset()
	_disconnect_signals()


func _cache_nodes() -> void:
	if path_line == null:
		path_line = get_node_or_null("PathLine") as Line2D
	if base_view == null:
		base_view = get_node_or_null("BaseView") as Node2D
	if tracers_container == null:
		tracers_container = get_node_or_null("Tracers") as Node2D
	if main_hero == null:
		main_hero = get_node_or_null("MainHero") as Node2D
	if range_indicator == null:
		range_indicator = get_node_or_null("MainHero/RangeIndicator") as Node2D
	if hud == null:
		hud = get_node_or_null("UILayer/BattleHUD") as BattleHUD
	if result_overlay == null:
		result_overlay = get_node_or_null("UILayer/RunResultOverlay") as RunResultOverlay
	if upgrade_overlay == null:
		upgrade_overlay = get_node_or_null("UILayer/UpgradeChoiceOverlay") as UpgradeChoiceOverlay


func _setup_path_and_base() -> void:
	if waypoints.is_empty():
		waypoints = get_stage_waypoints(stage_id)

	if path_line != null:
		# Enemy lanes are independent, so the former shared zigzag cannot remain visible.
		path_line.clear_points()

	if base_view != null and not waypoints.is_empty():
		base_view.position = waypoints[waypoints.size() - 1]


func _connect_signals() -> void:
	if result_overlay != null and not result_overlay.back_to_map_requested.is_connected(_on_back_to_map_pressed):
		result_overlay.back_to_map_requested.connect(_on_back_to_map_pressed)

	if upgrade_overlay != null:
		if hero_system != null and upgrade_overlay.has_method("set_hero_system"):
			upgrade_overlay.set_hero_system(hero_system)
		if not upgrade_overlay.upgrade_chosen.is_connected(_on_upgrade_chosen):
			upgrade_overlay.upgrade_chosen.connect(_on_upgrade_chosen)

	if wave_manager != null and not wave_manager.enemy_spawned.is_connected(_on_enemy_spawned):
		wave_manager.enemy_spawned.connect(_on_enemy_spawned)

	if weapon_system != null and weapon_system.has_signal("weapon_equipped") and not weapon_system.weapon_equipped.is_connected(_on_weapon_equipped):
		weapon_system.weapon_equipped.connect(_on_weapon_equipped)

	if main_hero != null and main_hero.has_signal("weapon_fired") and not main_hero.weapon_fired.is_connected(_on_main_hero_weapon_fired):
		main_hero.weapon_fired.connect(_on_main_hero_weapon_fired)

	if hero_system != null:
		if hero_system.has_signal("hero_activated") and not hero_system.hero_activated.is_connected(_on_hero_activated):
			hero_system.hero_activated.connect(_on_hero_activated)
		if hero_system.has_signal("hero_upgraded") and not hero_system.hero_upgraded.is_connected(_on_hero_upgraded):
			hero_system.hero_upgraded.connect(_on_hero_upgraded)
		if hero_system.has_signal("run_reset") and not hero_system.run_reset.is_connected(_on_hero_run_reset):
			hero_system.run_reset.connect(_on_hero_run_reset)


func _disconnect_signals() -> void:
	if result_overlay != null and is_instance_valid(result_overlay) and result_overlay.back_to_map_requested.is_connected(_on_back_to_map_pressed):
		result_overlay.back_to_map_requested.disconnect(_on_back_to_map_pressed)

	if upgrade_overlay != null and is_instance_valid(upgrade_overlay) and upgrade_overlay.upgrade_chosen.is_connected(_on_upgrade_chosen):
		upgrade_overlay.upgrade_chosen.disconnect(_on_upgrade_chosen)

	if wave_manager != null and is_instance_valid(wave_manager) and wave_manager.enemy_spawned.is_connected(_on_enemy_spawned):
		wave_manager.enemy_spawned.disconnect(_on_enemy_spawned)

	if weapon_system != null and is_instance_valid(weapon_system) and weapon_system.has_signal("weapon_equipped") and weapon_system.weapon_equipped.is_connected(_on_weapon_equipped):
		weapon_system.weapon_equipped.disconnect(_on_weapon_equipped)

	if main_hero != null and is_instance_valid(main_hero) and main_hero.has_signal("weapon_fired") and main_hero.weapon_fired.is_connected(_on_main_hero_weapon_fired):
		main_hero.weapon_fired.disconnect(_on_main_hero_weapon_fired)

	if hero_system != null and is_instance_valid(hero_system):
		if hero_system.has_signal("hero_activated") and hero_system.hero_activated.is_connected(_on_hero_activated):
			hero_system.hero_activated.disconnect(_on_hero_activated)
		if hero_system.has_signal("hero_upgraded") and hero_system.hero_upgraded.is_connected(_on_hero_upgraded):
			hero_system.hero_upgraded.disconnect(_on_hero_upgraded)
		if hero_system.has_signal("run_reset") and hero_system.run_reset.is_connected(_on_hero_run_reset):
			hero_system.run_reset.disconnect(_on_hero_run_reset)


func _sync_equipped_weapon() -> void:
	if main_hero != null and weapon_system != null and "equipped_weapon_id" in weapon_system:
		var eq_id: String = str(weapon_system.equipped_weapon_id)
		if not eq_id.is_empty() and main_hero.has_method("equip"):
			main_hero.equip(eq_id)
		_update_range_indicator(eq_id)


func _on_weapon_equipped(weapon_id: String) -> void:
	if main_hero != null and main_hero.has_method("equip"):
		main_hero.equip(weapon_id)
	_update_range_indicator(weapon_id)


func _update_range_indicator(weapon_id: String = "") -> void:
	if range_indicator == null or weapon_system == null:
		return

	var target_id := weapon_id
	if target_id.is_empty() and "equipped_weapon_id" in weapon_system:
		target_id = str(weapon_system.equipped_weapon_id)

	if target_id.is_empty() or not weapon_system.has_method("get_weapon_stats"):
		return

	var stats: Dictionary = weapon_system.get_weapon_stats(target_id)
	var half_w: float = stats.get("range_half_width", 0.0)
	var half_h: float = stats.get("range_half_height", 0.0)
	if "half_width" in range_indicator:
		range_indicator.half_width = half_w
	if "half_height" in range_indicator:
		range_indicator.half_height = half_h


func _on_enemy_spawned(enemy: Node) -> void:
	if enemy == null or not is_instance_valid(enemy):
		return

	# Gắn visual con enemy_view vào node enemy do WaveManager tạo ra
	var visual: Node2D = ENEMY_VIEW_SCENE.instantiate()
	enemy.add_child(visual)


func _on_back_to_map_pressed() -> void:
	back_to_map_requested.emit()


func _on_upgrade_chosen(_option_index: int) -> void:
	pass


func _on_main_hero_weapon_fired(from: Vector2, to: Vector2) -> void:
	var container: Node2D = tracers_container if tracers_container != null else self
	var line := Line2D.new()
	line.width = BULLET_TRACER_WIDTH
	line.default_color = BULLET_TRACER_COLOR
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	var local_from: Vector2 = container.to_local(from) if container.is_inside_tree() else from
	var local_to: Vector2 = container.to_local(to) if container.is_inside_tree() else to
	line.points = PackedVector2Array([local_from, local_to])
	container.add_child(line)
	_active_tracers.append({
		"line": line,
		"ttl": BULLET_TRACER_LIFETIME
	})


func _update_tracers(delta: float) -> void:
	if _active_tracers.is_empty():
		return

	for i in range(_active_tracers.size() - 1, -1, -1):
		var item: Dictionary = _active_tracers[i]
		item["ttl"] -= delta
		if item["ttl"] <= 0.0:
			var line: Line2D = item.get("line")
			if line != null and is_instance_valid(line):
				if line.get_parent() != null:
					line.get_parent().remove_child(line)
				line.queue_free()
			_active_tracers.remove_at(i)


func _clear_tracers() -> void:
	for item in _active_tracers:
		var line: Line2D = item.get("line")
		if line != null and is_instance_valid(line):
			if line.get_parent() != null:
				line.get_parent().remove_child(line)
			line.queue_free()
	_active_tracers.clear()


func _sync_active_secondary_heroes() -> void:
	if hero_system == null or not ("active_heroes" in hero_system):
		return

	for hero_id in hero_system.active_heroes.keys():
		var id_str: String = str(hero_id)
		var lvl: int = int(hero_system.active_heroes[hero_id])
		if not secondary_heroes.has(id_str):
			_spawn_secondary_hero(id_str, lvl)


func _on_hero_activated(hero_id: String, level: int) -> void:
	if secondary_heroes.has(hero_id):
		return
	_spawn_secondary_hero(hero_id, level)


func _spawn_secondary_hero(hero_id: String, level: int) -> Node2D:
	var target_hero_data: HeroData = _get_hero_data(hero_id)
	if target_hero_data == null:
		return null

	var hero_instance: Node2D = SECONDARY_HERO_SCRIPT.new()
	if wave_manager != null:
		hero_instance.set("wave_manager", wave_manager)
	hero_instance.initialize(target_hero_data, level)

	var slot_index: int = _secondary_hero_order.size()
	var offset: Vector2 = SECONDARY_HERO_SLOT_OFFSETS[slot_index % SECONDARY_HERO_SLOT_OFFSETS.size()]
	var base_origin: Vector2 = main_hero.position if main_hero != null else Vector2(360.0, 1060.0)
	hero_instance.position = base_origin + offset
	hero_instance.name = "SecondaryHero_%s" % hero_id

	_attach_secondary_hero_visual(hero_instance)
	if hero_instance.has_signal("weapon_fired") and not hero_instance.weapon_fired.is_connected(_on_main_hero_weapon_fired):
		hero_instance.weapon_fired.connect(_on_main_hero_weapon_fired)
	add_child(hero_instance)

	secondary_heroes[hero_id] = hero_instance
	_secondary_hero_order.append(hero_id)
	return hero_instance


func _get_hero_data(hero_id: String) -> HeroData:
	if hero_system != null and ("roster" in hero_system):
		for data in hero_system.roster:
			if data != null and "id" in data and data.id == hero_id:
				return data
	return null


func _attach_secondary_hero_visual(hero_instance: Node2D) -> void:
	var body := Polygon2D.new()
	body.name = "Body"
	body.color = SECONDARY_HERO_BODY_COLOR
	body.polygon = PackedVector2Array([
		Vector2(0.0, -16.0),
		Vector2(12.0, 0.0),
		Vector2(0.0, 16.0),
		Vector2(-12.0, 0.0)
	])
	hero_instance.add_child(body)

	var core := Polygon2D.new()
	core.name = "Core"
	core.color = SECONDARY_HERO_CORE_COLOR
	core.polygon = PackedVector2Array([
		Vector2(0.0, -8.0),
		Vector2(6.0, 0.0),
		Vector2(0.0, 8.0),
		Vector2(-6.0, 0.0)
	])
	hero_instance.add_child(core)


func _on_hero_upgraded(hero_id: String, new_level: int) -> void:
	if secondary_heroes.has(hero_id):
		var hero_instance: Node2D = secondary_heroes[hero_id]
		if is_instance_valid(hero_instance) and hero_instance.has_method("set_level"):
			hero_instance.set_level(new_level)


func _on_hero_run_reset() -> void:
	for hero_id in secondary_heroes:
		var hero_instance: Node2D = secondary_heroes[hero_id]
		if is_instance_valid(hero_instance):
			if hero_instance.has_signal("weapon_fired") and hero_instance.weapon_fired.is_connected(_on_main_hero_weapon_fired):
				hero_instance.weapon_fired.disconnect(_on_main_hero_weapon_fired)
			hero_instance.queue_free()
	secondary_heroes.clear()
	_secondary_hero_order.clear()
