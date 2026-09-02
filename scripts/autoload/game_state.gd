extends Node

signal run_failed
signal run_completed

var base_health_system: Node
var wave_manager: Node
var level_system: Node
var hero_system: Node


func _ready() -> void:
	base_health_system = get_node_or_null("/root/BaseHealthSystem")
	wave_manager = get_node_or_null("/root/WaveManager")
	level_system = get_node_or_null("/root/LevelSystem")
	hero_system = get_node_or_null("/root/HeroSystem")
	_connect_dependencies()


func start_stage() -> void:
	_reset_and_start_stage()


func retry_stage() -> void:
	_reset_and_start_stage()


func _on_base_defeated() -> void:
	if wave_manager != null:
		wave_manager.clear_wave()
	run_failed.emit()


func _on_stage_cleared() -> void:
	if wave_manager != null:
		wave_manager.clear_wave()
	run_completed.emit()


func _reset_and_start_stage() -> void:
	if base_health_system != null:
		base_health_system.reset_health()
	if level_system != null:
		level_system.reset_progress()
	if hero_system != null:
		hero_system.reset_run()
	if wave_manager != null:
		wave_manager.start_wave()


func _connect_dependencies() -> void:
	if base_health_system != null and not base_health_system.base_defeated.is_connected(_on_base_defeated):
		base_health_system.base_defeated.connect(_on_base_defeated)
	if level_system != null and not level_system.stage_cleared.is_connected(_on_stage_cleared):
		level_system.stage_cleared.connect(_on_stage_cleared)
