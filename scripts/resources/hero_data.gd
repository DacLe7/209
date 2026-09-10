class_name HeroData
extends Resource

@export var id: String
@export var display_name: String
@export var max_level_per_run: int = 15
@export var stat_growth_per_level: float = 1.1
@export var base_damage: float = 5.0
@export var fire_rate: float = 1.0
@export var range_half_width: float = 220.0
@export var range_half_height: float = 300.0
@export var target_type: int = WeaponData.TargetType.SINGLE
@export var model_scene: PackedScene
