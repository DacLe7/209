extends Node

signal health_changed(current: float, max: float)
signal base_defeated

@export var max_health: float = 100.0:
	set(value):
		max_health = maxf(0.0, value)
		var previous_health := current_health
		current_health = minf(current_health, max_health)
		if current_health != previous_health:
			health_changed.emit(current_health, max_health)

var current_health: float = max_health
var _has_emitted_base_defeated := false


func _ready() -> void:
	current_health = clampf(current_health, 0.0, max_health)


func take_damage(amount: float) -> void:
	if amount <= 0.0 or current_health <= 0.0:
		return

	current_health = maxf(current_health - amount, 0.0)
	health_changed.emit(current_health, max_health)
	if current_health == 0.0 and not _has_emitted_base_defeated:
		_has_emitted_base_defeated = true
		base_defeated.emit()


func reset_health() -> void:
	var previous_health := current_health
	current_health = max_health
	_has_emitted_base_defeated = false
	if current_health != previous_health:
		health_changed.emit(current_health, max_health)
