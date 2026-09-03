class_name MapSelection
extends Control

signal map_selected(stage_id: int)
signal back_pressed

var energy_label: Label
var status_label: Label
var back_button: Button

var energy_system: Node


func _ready() -> void:
	_cache_nodes()
	if is_inside_tree() and energy_system == null:
		energy_system = get_node_or_null("/root/EnergySystem")
	_update_energy_display()

	if energy_system != null and not energy_system.energy_changed.is_connected(_on_energy_changed):
		energy_system.energy_changed.connect(_on_energy_changed)

	if back_button != null and not back_button.pressed.is_connected(_on_back_button_pressed):
		back_button.pressed.connect(_on_back_button_pressed)

	_setup_map_buttons()


func _cache_nodes() -> void:
	if energy_label == null:
		energy_label = get_node_or_null("Header/MarginContainer/HBoxContainer/EnergyLabel") as Label
	if status_label == null:
		status_label = get_node_or_null("Footer/MarginContainer/VBoxContainer/StatusLabel") as Label
	if back_button == null:
		back_button = get_node_or_null("Footer/MarginContainer/VBoxContainer/BackButton") as Button


func _exit_tree() -> void:
	if energy_system != null and is_instance_valid(energy_system) and energy_system.energy_changed.is_connected(_on_energy_changed):
		energy_system.energy_changed.disconnect(_on_energy_changed)


func _on_energy_changed(current: int, max_val: int) -> void:
	if energy_label != null:
		energy_label.text = "⚡ NĂNG LƯỢNG: %d / %d" % [current, max_val]


func _update_energy_display() -> void:
	if energy_label == null:
		return
	if energy_system != null:
		energy_label.text = "⚡ NĂNG LƯỢNG: %d / %d" % [energy_system.current_energy, energy_system.max_energy]
	else:
		energy_label.text = "⚡ NĂNG LƯỢNG: 5 / 5"


func _setup_map_buttons() -> void:
	var stage1_btn: Button = get_node_or_null("ScrollContainer/VBoxContainer/StageCard1/MarginContainer/HBoxContainer/VBoxAction/PlayButton")
	if stage1_btn != null:
		stage1_btn.pressed.connect(_on_stage1_play_pressed)


func _on_stage1_play_pressed() -> void:
	if energy_system != null:
		if not energy_system.can_play():
			if status_label != null:
				status_label.text = "Không đủ năng lượng! Cần ít nhất 1 ⚡ để xuất kích."
			return
		energy_system.spend_energy()

	if status_label != null:
		status_label.text = "Bắt đầu xuất kích Màn 1..."
	map_selected.emit(1)


func _on_back_button_pressed() -> void:
	back_pressed.emit()
