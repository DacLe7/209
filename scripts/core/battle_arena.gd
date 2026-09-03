class_name BattleArena
extends Node2D

signal back_to_map_requested

const ENEMY_VIEW_SCENE := preload("res://scenes/entities/enemy_view.tscn")
const BASE_VIEW_SCENE := preload("res://scenes/core/base_view.tscn")
const BATTLE_HUD_SCENE := preload("res://scenes/ui/battle_hud.tscn")
const RUN_RESULT_OVERLAY_SCENE := preload("res://scenes/ui/run_result_overlay.tscn")

@export var waypoints: PackedVector2Array = [
	Vector2(360.0, 80.0),
	Vector2(360.0, 1060.0)
]

var path_line: Line2D
var base_view: Node2D
var hud: BattleHUD
var result_overlay: RunResultOverlay

var wave_manager: Node
var game_state: Node


func _ready() -> void:
	_cache_nodes()

	if is_inside_tree():
		if wave_manager == null:
			wave_manager = get_node_or_null("/root/WaveManager")
		if game_state == null:
			game_state = get_node_or_null("/root/GameState")

	_setup_path_and_base()
	_connect_signals()

	if game_state != null and game_state.has_method("start_stage"):
		game_state.start_stage()


func _exit_tree() -> void:
	_disconnect_signals()


func _cache_nodes() -> void:
	if path_line == null:
		path_line = get_node_or_null("PathLine") as Line2D
	if base_view == null:
		base_view = get_node_or_null("BaseView") as Node2D
	if hud == null:
		hud = get_node_or_null("UILayer/BattleHUD") as BattleHUD
	if result_overlay == null:
		result_overlay = get_node_or_null("UILayer/RunResultOverlay") as RunResultOverlay


func _setup_path_and_base() -> void:
	if path_line != null:
		path_line.points = waypoints

	if base_view != null and not waypoints.is_empty():
		base_view.position = waypoints[waypoints.size() - 1]

	if wave_manager != null:
		wave_manager.path_waypoints = waypoints


func _connect_signals() -> void:
	if result_overlay != null and not result_overlay.back_to_map_requested.is_connected(_on_back_to_map_pressed):
		result_overlay.back_to_map_requested.connect(_on_back_to_map_pressed)

	if wave_manager != null and not wave_manager.enemy_spawned.is_connected(_on_enemy_spawned):
		wave_manager.enemy_spawned.connect(_on_enemy_spawned)


func _disconnect_signals() -> void:
	if result_overlay != null and is_instance_valid(result_overlay) and result_overlay.back_to_map_requested.is_connected(_on_back_to_map_pressed):
		result_overlay.back_to_map_requested.disconnect(_on_back_to_map_pressed)

	if wave_manager != null and is_instance_valid(wave_manager) and wave_manager.enemy_spawned.is_connected(_on_enemy_spawned):
		wave_manager.enemy_spawned.disconnect(_on_enemy_spawned)


func _on_enemy_spawned(enemy: Node) -> void:
	if enemy == null or not is_instance_valid(enemy):
		return

	# Gắn visual con enemy_view vào node enemy do WaveManager tạo ra
	var visual: Node2D = ENEMY_VIEW_SCENE.instantiate()
	enemy.add_child(visual)


func _on_back_to_map_pressed() -> void:
	back_to_map_requested.emit()
