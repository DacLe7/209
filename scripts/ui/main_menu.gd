class_name MainMenu
extends Control

signal play_pressed

var title_label: Label
var play_button: Button
var settings_button: Button


func _enter_tree() -> void:
	_cache_nodes()


func _ready() -> void:
	_cache_nodes()
	if play_button != null and not play_button.pressed.is_connected(_on_play_pressed):
		play_button.pressed.connect(_on_play_pressed)


func _cache_nodes() -> void:
	if title_label == null:
		title_label = get_node_or_null("CenterContainer/VBoxContainer/TitleLabel") as Label
	if play_button == null:
		play_button = get_node_or_null("CenterContainer/VBoxContainer/PlayButton") as Button
	if settings_button == null:
		settings_button = get_node_or_null("CenterContainer/VBoxContainer/SettingsButton") as Button


func _on_play_pressed() -> void:
	play_pressed.emit()
