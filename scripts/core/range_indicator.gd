class_name RangeIndicator
extends Node2D

@export var half_width: float = 0.0:
	set(value):
		half_width = value
		queue_redraw()

@export var half_height: float = 0.0:
	set(value):
		half_height = value
		queue_redraw()

@export var fill_color: Color = Color(0.18, 0.8, 0.35, 0.12)
@export var outline_color: Color = Color(0.18, 0.8, 0.35, 0.45)
@export var outline_width: float = 2.0


func _draw() -> void:
	if half_width <= 0.0 or half_height <= 0.0:
		return

	var rect := Rect2(-half_width, -half_height, half_width * 2.0, half_height * 2.0)
	draw_rect(rect, fill_color, true)
	draw_rect(rect, outline_color, false, outline_width)
