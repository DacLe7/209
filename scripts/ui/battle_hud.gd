class_name BattleHUD
extends Control

var health_bar: ProgressBar
var health_label: Label
var energy_label: Label
var level_label: Label
var pause_button: Button
var hero_slot_labels: Array[Label] = []

var base_health_system: Node
var energy_system: Node
var level_system: Node
var hero_system: Node

var active_hero_order: Array[String] = []


func _ready() -> void:
	_cache_nodes()
	if is_inside_tree():
		if base_health_system == null:
			base_health_system = get_node_or_null("/root/BaseHealthSystem")
		if energy_system == null:
			energy_system = get_node_or_null("/root/EnergySystem")
		if level_system == null:
			level_system = get_node_or_null("/root/LevelSystem")
		if hero_system == null:
			hero_system = get_node_or_null("/root/HeroSystem")

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

	hero_slot_labels.clear()
	for i in range(1, 5):
		var slot_label: Label = get_node_or_null("BottomBar/VBoxContainer/HeroSlotsContainer/Slot%d/Label" % i) as Label
		if slot_label != null:
			hero_slot_labels.append(slot_label)


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

	_initialize_hero_slots()


func _connect_signals() -> void:
	if base_health_system != null and not base_health_system.health_changed.is_connected(_on_health_changed):
		base_health_system.health_changed.connect(_on_health_changed)

	if energy_system != null and not energy_system.energy_changed.is_connected(_on_energy_changed):
		energy_system.energy_changed.connect(_on_energy_changed)

	if level_system != null and not level_system.level_up.is_connected(_on_level_up):
		level_system.level_up.connect(_on_level_up)

	if hero_system != null and not hero_system.hero_activated.is_connected(_on_hero_activated):
		hero_system.hero_activated.connect(_on_hero_activated)

	if hero_system != null and not hero_system.hero_upgraded.is_connected(_on_hero_upgraded):
		hero_system.hero_upgraded.connect(_on_hero_upgraded)

	if hero_system != null and not hero_system.run_reset.is_connected(reset_hero_slots):
		hero_system.run_reset.connect(reset_hero_slots)


func _disconnect_signals() -> void:
	if base_health_system != null and is_instance_valid(base_health_system) and base_health_system.health_changed.is_connected(_on_health_changed):
		base_health_system.health_changed.disconnect(_on_health_changed)

	if energy_system != null and is_instance_valid(energy_system) and energy_system.energy_changed.is_connected(_on_energy_changed):
		energy_system.energy_changed.disconnect(_on_energy_changed)

	if level_system != null and is_instance_valid(level_system) and level_system.level_up.is_connected(_on_level_up):
		level_system.level_up.disconnect(_on_level_up)

	if hero_system != null and is_instance_valid(hero_system) and hero_system.hero_activated.is_connected(_on_hero_activated):
		hero_system.hero_activated.disconnect(_on_hero_activated)

	if hero_system != null and is_instance_valid(hero_system) and hero_system.hero_upgraded.is_connected(_on_hero_upgraded):
		hero_system.hero_upgraded.disconnect(_on_hero_upgraded)

	if hero_system != null and is_instance_valid(hero_system) and hero_system.run_reset.is_connected(reset_hero_slots):
		hero_system.run_reset.disconnect(reset_hero_slots)


func _on_health_changed(current: float, max_val: float) -> void:
	_update_health(current, max_val)


func _on_energy_changed(current: int, max_val: int) -> void:
	_update_energy(current, max_val)


func _on_level_up(new_level: int) -> void:
	_update_level(new_level)


func _on_hero_activated(hero_id: String, _level: int) -> void:
	if not active_hero_order.has(hero_id) and active_hero_order.size() < hero_slot_labels.size():
		active_hero_order.append(hero_id)
	_update_hero_slots()


func _on_hero_upgraded(_hero_id: String, _new_level: int) -> void:
	_update_hero_slots()


func reset_hero_slots() -> void:
	active_hero_order.clear()
	_update_hero_slots()


func _initialize_hero_slots() -> void:
	active_hero_order.clear()
	if hero_system != null and "active_heroes" in hero_system:
		for hero_id in hero_system.active_heroes.keys():
			active_hero_order.append(str(hero_id))
	_update_hero_slots()


func _update_hero_slots() -> void:
	for i in range(hero_slot_labels.size()):
		var label: Label = hero_slot_labels[i]
		if label == null:
			continue
		if i < active_hero_order.size():
			var hero_id: String = active_hero_order[i]
			var level: int = 1
			if hero_system != null and "active_heroes" in hero_system and hero_system.active_heroes.has(hero_id):
				level = int(hero_system.active_heroes[hero_id])
			var display_name: String = _get_hero_display_name(hero_id)
			label.text = "%s\nLv.%d" % [display_name, level]
		else:
			label.text = "[Trống]"


func _get_hero_display_name(hero_id: String) -> String:
	if hero_system != null and "roster" in hero_system:
		for hero in hero_system.roster:
			if hero != null and "id" in hero and hero.id == hero_id and not str(hero.display_name).is_empty():
				return hero.display_name
	return hero_id.capitalize()


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
