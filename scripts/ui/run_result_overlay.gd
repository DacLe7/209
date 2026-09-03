class_name RunResultOverlay
extends Control

signal back_to_map_requested
signal retry_requested

var title_label: Label
var subtitle_label: Label
var retry_button: Button
var back_to_map_button: Button
var result_panel: PanelContainer

var game_state: Node


func _ready() -> void:
	_cache_nodes()
	if is_inside_tree() and game_state == null:
		game_state = get_node_or_null("/root/GameState")

	_connect_signals()
	visible = false


func _cache_nodes() -> void:
	if result_panel == null:
		result_panel = get_node_or_null("CenterContainer/ResultPanel") as PanelContainer
	if title_label == null:
		title_label = get_node_or_null("CenterContainer/ResultPanel/MarginContainer/VBoxContainer/TitleLabel") as Label
	if subtitle_label == null:
		subtitle_label = get_node_or_null("CenterContainer/ResultPanel/MarginContainer/VBoxContainer/SubtitleLabel") as Label
	if retry_button == null:
		retry_button = get_node_or_null("CenterContainer/ResultPanel/MarginContainer/VBoxContainer/ActionsContainer/RetryButton") as Button
	if back_to_map_button == null:
		back_to_map_button = get_node_or_null("CenterContainer/ResultPanel/MarginContainer/VBoxContainer/ActionsContainer/BackToMapButton") as Button

	if retry_button != null and not retry_button.pressed.is_connected(_on_retry_pressed):
		retry_button.pressed.connect(_on_retry_pressed)
	if back_to_map_button != null and not back_to_map_button.pressed.is_connected(_on_back_to_map_pressed):
		back_to_map_button.pressed.connect(_on_back_to_map_pressed)


func _exit_tree() -> void:
	_disconnect_signals()


func _connect_signals() -> void:
	if game_state != null:
		if not game_state.run_failed.is_connected(_on_run_failed):
			game_state.run_failed.connect(_on_run_failed)
		if not game_state.run_completed.is_connected(_on_run_completed):
			game_state.run_completed.connect(_on_run_completed)


func _disconnect_signals() -> void:
	if game_state != null and is_instance_valid(game_state):
		if game_state.run_failed.is_connected(_on_run_failed):
			game_state.run_failed.disconnect(_on_run_failed)
		if game_state.run_completed.is_connected(_on_run_completed):
			game_state.run_completed.disconnect(_on_run_completed)


func _on_run_failed() -> void:
	show_defeat()


func _on_run_completed() -> void:
	show_victory()


func show_defeat(message: String = "Căn cứ đã bị quái vật phá hủy!\nHãy nâng cấp vũ khí và chuẩn bị chiến thuật tốt hơn.") -> void:
	_cache_nodes()
	if title_label != null:
		title_label.text = "THẤT BẠI"
	if subtitle_label != null:
		subtitle_label.text = message
	if retry_button != null:
		retry_button.visible = true
	if back_to_map_button != null:
		back_to_map_button.visible = false
	visible = true


func show_victory(message: String = "Xuất sắc! Bạn đã bảo vệ an toàn căn cứ\nqua toàn bộ các đợt tấn công hiểm ác.") -> void:
	_cache_nodes()
	if title_label != null:
		title_label.text = "HOÀN THÀNH MÀN"
	if subtitle_label != null:
		subtitle_label.text = message
	if retry_button != null:
		retry_button.visible = false
	if back_to_map_button != null:
		back_to_map_button.visible = true
	visible = true


func hide_overlay() -> void:
	visible = false


func _on_retry_pressed() -> void:
	hide_overlay()
	if game_state != null and game_state.has_method("retry_stage"):
		game_state.retry_stage()
	retry_requested.emit()


func _on_back_to_map_pressed() -> void:
	hide_overlay()
	back_to_map_requested.emit()
