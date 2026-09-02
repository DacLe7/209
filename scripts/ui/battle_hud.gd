class_name BattleHUD
extends Control

var health_bar: ProgressBar
var health_label: Label
var energy_label: Label
var level_label: Label
var pause_button: Button

var base_health_system: Node
var energy_system: Node
var level_system: Node


func _ready() -> void:
	_cache_nodes()
	if base_health_system == null:
		base_health_system = get_node_or_null("/root/BaseHealthSystem")
	if energy_system == null:
		energy_system = get_node_or_null("/root/EnergySystem")
	if level_system == null:
		level_system = get_node_or_null("/root/LevelSystem")

	_initialize_ui()
	_connect_signals()


func _cache_nodes() -> void:
	if health_bar == null:
		health_bar = get_node_or_null("BottomBar/VBoxContainer/HealthSection/HealthBar") as ProgressBar
	if health_label == null:
		health_label = get_node_or_null("BottomBar/VBoxContainer/HealthSection/HealthLabel") as Label
	if energy_label == null:
		energy_label = get_node_or_null("TopBar/MarginContainer/HBoxContainer/EnergyContainer/EnergyLabel") as Label
	if level_label == null:
		level_label = get_node_or_null("TopBar/MarginContainer/HBoxContainer/LevelContainer/LevelLabel") as Label
	if pause_button == null:
		pause_button = get_node_or_null("TopBar/MarginContainer/HBoxContainer/PauseButton") as Button


func _exit_tree() -> void:
	_disconnect_signals()


func _initialize_ui() -> void:
	if base_health_system != null:
		var cur_hp: float = base_health_system.current_health
		var max_hp: float = base_health_system.max_health
		_update_health(cur_hp, max_hp)
	else:
		_update_health(100.0, 100.0)

	if energy_system != null:
		var cur_en: int = energy_system.current_energy
		var max_en: int = energy_system.max_energy
		_update_energy(cur_en, max_en)
	else:
		_update_energy(5, 5)

	if level_system != null:
		var cur_lvl: int = level_system.current_level
		_update_level(cur_lvl)
	else:
		_update_level(0)


func _connect_signals() -> void:
	if base_health_system != null and not base_health_system.health_changed.is_connected(_on_health_changed):
		base_health_system.health_changed.connect(_on_health_changed)

	if energy_system != null and not energy_system.energy_changed.is_connected(_on_energy_changed):
		energy_system.energy_changed.connect(_on_energy_changed)

	if level_system != null and not level_system.level_up.is_connected(_on_level_up):
		level_system.level_up.connect(_on_level_up)


func _disconnect_signals() -> void:
	if base_health_system != null and is_instance_valid(base_health_system) and base_health_system.health_changed.is_connected(_on_health_changed):
		base_health_system.health_changed.disconnect(_on_health_changed)

	if energy_system != null and is_instance_valid(energy_system) and energy_system.energy_changed.is_connected(_on_energy_changed):
		energy_system.energy_changed.disconnect(_on_energy_changed)

	if level_system != null and is_instance_valid(level_system) and level_system.level_up.is_connected(_on_level_up):
		level_system.level_up.disconnect(_on_level_up)


func _on_health_changed(current: float, max_val: float) -> void:
	_update_health(current, max_val)


func _on_energy_changed(current: int, max_val: int) -> void:
	_update_energy(current, max_val)


func _on_level_up(new_level: int) -> void:
	_update_level(new_level)


func _update_health(current: float, max_val: float) -> void:
	if health_bar != null:
		health_bar.max_value = maxf(1.0, max_val)
		health_bar.value = clampf(current, 0.0, health_bar.max_value)
	if health_label != null:
		health_label.text = "MÁU CĂN CỨ: %d / %d" % [int(current), int(max_val)]


func _update_energy(current: int, max_val: int) -> void:
	if energy_label != null:
		energy_label.text = "⚡ Năng lượng: %d / %d" % [current, max_val]


func _update_level(new_level: int) -> void:
	if level_label != null:
		level_label.text = "CẤP: %d / 30" % new_level
