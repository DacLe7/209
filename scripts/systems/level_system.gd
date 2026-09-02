extends Node

signal level_up(new_level: int)
signal stage_cleared

const MAX_LEVEL := 30

@export var exp_per_level: int = 15

var current_level := 0
var current_exp := 0
var wave_manager: Node
var base_health_system: Node
var _has_emitted_stage_cleared := false


func _ready() -> void:
	wave_manager = get_node_or_null("/root/WaveManager")
	base_health_system = get_node_or_null("/root/BaseHealthSystem")
	_connect_dependencies()


func add_exp(amount: int) -> void:
	if amount <= 0 or current_level >= MAX_LEVEL or exp_per_level <= 0:
		return

	current_exp += amount
	while current_exp >= exp_per_level and current_level < MAX_LEVEL:
		current_exp -= exp_per_level
		current_level += 1
		level_up.emit(current_level)
		if current_level == MAX_LEVEL and not _has_emitted_stage_cleared:
			_has_emitted_stage_cleared = true
			stage_cleared.emit()


func reset_progress() -> void:
	current_level = 0
	current_exp = 0
	_has_emitted_stage_cleared = false


func _connect_dependencies() -> void:
	if wave_manager != null and not wave_manager.enemy_killed.is_connected(_on_enemy_killed):
		wave_manager.enemy_killed.connect(_on_enemy_killed)
	if base_health_system != null and not base_health_system.base_defeated.is_connected(reset_progress):
		base_health_system.base_defeated.connect(reset_progress)


func _on_enemy_killed(_exp_value: int) -> void:
	add_exp(1)
