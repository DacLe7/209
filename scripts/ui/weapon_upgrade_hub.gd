class_name WeaponUpgradeHub
extends Control

signal back_pressed

const RIFLE_DATA := preload("res://data/weapons/weapon_rifle_single_mid.tres")
const SHOTGUN_DATA := preload("res://data/weapons/weapon_shotgun_multi_close.tres")

var gold_label: Label
var weapon_title: Label
var type_label: Label
var range_label: Label
var damage_label: Label
var fire_rate_label: Label
var level_label: Label
var upgrade_button: Button
var equip_button: Button
var notice_label: Label
var back_button: Button

var rifle_tab_btn: Button
var shotgun_tab_btn: Button

var current_selected_index := 0


func _ready() -> void:
	_cache_nodes()
	if rifle_tab_btn != null and not rifle_tab_btn.pressed.is_connected(_select_rifle):
		rifle_tab_btn.pressed.connect(_select_rifle)
	if shotgun_tab_btn != null and not shotgun_tab_btn.pressed.is_connected(_select_shotgun):
		shotgun_tab_btn.pressed.connect(_select_shotgun)
	if back_button != null and not back_button.pressed.is_connected(_on_back_pressed):
		back_button.pressed.connect(_on_back_pressed)
	if upgrade_button != null and not upgrade_button.pressed.is_connected(_on_upgrade_pressed):
		upgrade_button.pressed.connect(_on_upgrade_pressed)
	if equip_button != null and not equip_button.pressed.is_connected(_on_equip_pressed):
		equip_button.pressed.connect(_on_equip_pressed)

	_show_weapon(0)


func _cache_nodes() -> void:
	if gold_label == null:
		gold_label = get_node_or_null("Header/MarginContainer/HBoxContainer/GoldLabel") as Label
	if weapon_title == null:
		weapon_title = get_node_or_null("Content/MarginContainer/VBoxContainer/DetailCard/MarginContainer/VBoxContainer/WeaponName") as Label
	if type_label == null:
		type_label = get_node_or_null("Content/MarginContainer/VBoxContainer/DetailCard/MarginContainer/VBoxContainer/GridStats/TypeVal") as Label
	if range_label == null:
		range_label = get_node_or_null("Content/MarginContainer/VBoxContainer/DetailCard/MarginContainer/VBoxContainer/GridStats/RangeVal") as Label
	if damage_label == null:
		damage_label = get_node_or_null("Content/MarginContainer/VBoxContainer/DetailCard/MarginContainer/VBoxContainer/GridStats/DamageVal") as Label
	if fire_rate_label == null:
		fire_rate_label = get_node_or_null("Content/MarginContainer/VBoxContainer/DetailCard/MarginContainer/VBoxContainer/GridStats/FireRateVal") as Label
	if level_label == null:
		level_label = get_node_or_null("Content/MarginContainer/VBoxContainer/DetailCard/MarginContainer/VBoxContainer/LevelLabel") as Label
	if upgrade_button == null:
		upgrade_button = get_node_or_null("Content/MarginContainer/VBoxContainer/ActionContainer/UpgradeButton") as Button
	if equip_button == null:
		equip_button = get_node_or_null("Content/MarginContainer/VBoxContainer/ActionContainer/EquipButton") as Button
	if notice_label == null:
		notice_label = get_node_or_null("Content/MarginContainer/VBoxContainer/NoticeLabel") as Label
	if back_button == null:
		back_button = get_node_or_null("Footer/MarginContainer/BackButton") as Button
	if rifle_tab_btn == null:
		rifle_tab_btn = get_node_or_null("Content/MarginContainer/VBoxContainer/TabBar/RifleBtn") as Button
	if shotgun_tab_btn == null:
		shotgun_tab_btn = get_node_or_null("Content/MarginContainer/VBoxContainer/TabBar/ShotgunBtn") as Button


func _select_rifle() -> void:
	_show_weapon(0)


func _select_shotgun() -> void:
	_show_weapon(1)


func _show_weapon(index: int) -> void:
	current_selected_index = index
	var weapon: Variant = RIFLE_DATA if index == 0 else SHOTGUN_DATA
	if weapon == null:
		return

	if weapon_title != null:
		weapon_title.text = weapon.display_name

	if type_label != null:
		type_label.text = "Đơn mục tiêu (Single)" if weapon.target_type == 0 else "Đa mục tiêu (AOE)"

	if range_label != null:
		range_label.text = "Tầm gần (Close)" if weapon.range_type == 0 else "Tầm trung (Mid)"

	if damage_label != null:
		damage_label.text = "%.1f (+1.5 cấp tiếp)" % weapon.base_damage

	if fire_rate_label != null:
		fire_rate_label.text = "%.1f viên/giây (+0.1 cấp tiếp)" % weapon.fire_rate

	if level_label != null:
		level_label.text = "CẤP ĐỘ: 1 / 10"

	var cost := 100
	if not weapon.upgrade_cost_curve.is_empty():
		cost = weapon.upgrade_cost_curve[0]

	if upgrade_button != null:
		upgrade_button.text = "NÂNG CẤP (%d VÀNG)" % cost

	if equip_button != null:
		equip_button.text = "ĐANG TRANG BỊ" if index == 0 else "TRANG BỊ"

	if notice_label != null:
		notice_label.text = "WeaponSystem chưa hoàn thành — đây là giao diện mockup tĩnh để review layout."


func _on_upgrade_pressed() -> void:
	if notice_label != null:
		notice_label.text = "Chờ WeaponSystem hoàn thiện để áp dụng logic nâng cấp thật."


func _on_equip_pressed() -> void:
	if equip_button != null:
		equip_button.text = "ĐANG TRANG BỊ"


func _on_back_pressed() -> void:
	back_pressed.emit()
