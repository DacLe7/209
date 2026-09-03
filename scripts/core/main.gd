class_name Main
extends Node

const MAP_SELECTION_SCENE := preload("res://scenes/ui/map_selection.tscn")
const BATTLE_ARENA_SCENE := preload("res://scenes/core/battle_arena.tscn")

var current_view: Node = null


func _ready() -> void:
	show_map_selection()


func show_map_selection() -> void:
	_clear_current_view()
	var map_sel: Control = MAP_SELECTION_SCENE.instantiate()
	map_sel.map_selected.connect(_on_map_selected)
	add_child(map_sel)
	current_view = map_sel


func start_battle(_stage_id: int = 1) -> void:
	_clear_current_view()
	var arena: Node2D = BATTLE_ARENA_SCENE.instantiate()
	arena.back_to_map_requested.connect(_on_back_to_map_requested)
	add_child(arena)
	current_view = arena


func _on_map_selected(stage_id: int) -> void:
	start_battle(stage_id)


func _on_back_to_map_requested() -> void:
	show_map_selection()


func _clear_current_view() -> void:
	if current_view != null and is_instance_valid(current_view):
		remove_child(current_view)
		current_view.queue_free()
		current_view = null
