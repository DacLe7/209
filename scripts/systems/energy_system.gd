extends Node

signal energy_changed(current: int, max: int)

@export var max_energy: int = 5:
	set(value):
		max_energy = maxi(0, value)
		current_energy = mini(current_energy, max_energy)

@export var recharge_interval_seconds: int = 20 * 60

var current_energy: int = max_energy
var _last_energy_update_unix_seconds: int = 0


func _ready() -> void:
	current_energy = clampi(current_energy, 0, max_energy)
	_last_energy_update_unix_seconds = _get_current_unix_time()
	energy_changed.emit(current_energy, max_energy)


func _process(_delta: float) -> void:
	refresh_energy()


func can_play() -> bool:
	refresh_energy()
	return current_energy > 0


func spend_energy() -> bool:
	refresh_energy()
	if current_energy <= 0:
		return false

	current_energy -= 1
	_last_energy_update_unix_seconds = _get_current_unix_time()
	energy_changed.emit(current_energy, max_energy)
	return true


func refresh_energy(now_unix_seconds: int = -1) -> void:
	if now_unix_seconds < 0:
		now_unix_seconds = _get_current_unix_time()

	if current_energy >= max_energy:
		_last_energy_update_unix_seconds = now_unix_seconds
		return

	if recharge_interval_seconds <= 0:
		return

	var elapsed_seconds: int = maxi(0, now_unix_seconds - _last_energy_update_unix_seconds)
	var restored_energy: int = elapsed_seconds / recharge_interval_seconds
	if restored_energy <= 0:
		return

	var previous_energy := current_energy
	current_energy = mini(current_energy + restored_energy, max_energy)
	_last_energy_update_unix_seconds += restored_energy * recharge_interval_seconds
	if current_energy != previous_energy:
		energy_changed.emit(current_energy, max_energy)


func _get_current_unix_time() -> int:
	return int(Time.get_unix_time_from_system())
