class_name WeaponData
extends Resource

enum TargetType { SINGLE, MULTI }
enum RangeType { CLOSE, MID }

@export var id: String
@export var display_name: String
@export var target_type: TargetType = TargetType.SINGLE
@export var range_type: RangeType = RangeType.MID
@export var range_distance: float = 450.0
@export var base_damage: float = 5.0
@export var fire_rate: float = 1.0
@export var upgrade_cost_curve: Array[int] = []
