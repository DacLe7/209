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
var level_progress_bar: ProgressBar
var upgrade_button: Button
var equip_button: Button
var notice_label: Label
var back_button: Button

var rifle_tab_btn: Button
var shotgun_tab_btn: Button

var weapon_system: Node
var current_selected_index := 0


func _ready() -> void:
	_cache_nodes()
	if is_inside_tree() and weapon_system == null:
		weapon_system = get_node_or_null("/root/WeaponSystem")

	if weapon_system != null:
		if weapon_system.current_gold == 0:
			weapon_system.current_gold = 1000 # Tạm gán giá trị test vì SaveSystem chưa nối
		if not weapon_system.weapon_upgraded.is_connected(_on_weapon_upgraded):
			weapon_system.weapon_upgraded.connect(_on_weapon_upgraded)

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


func _exit_tree() -> void:
	if weapon_system != null and is_instance_valid(weapon_system) and weapon_system.weapon_upgraded.is_connected(_on_weapon_upgraded):
		weapon_system.weapon_upgraded.disconnect(_on_weapon_upgraded)


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
	if level_progress_bar == null:
		level_progress_bar = get_node_or_null("Content/MarginContainer/VBoxContainer/DetailCard/MarginContainer/VBoxContainer/LevelProgressBar") as ProgressBar
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


func _get_current_weapon_resource() -> Variant:
	return RIFLE_DATA if current_selected_index == 0 else SHOTGUN_DATA


func _show_weapon(index: int) -> void:
	current_selected_index = index
	var weapon: Variant = _get_current_weapon_resource()
	if weapon == null:
		return

	if gold_label != null:
		var gold_amount: int = weapon_system.current_gold if weapon_system != null else 1000
		gold_label.text = "💰 VÀNG: %d" % gold_amount

	if weapon_title != null:
		weapon_title.text = weapon.display_name

	if type_label != null:
		type_label.text = "Đơn mục tiêu (Single)" if weapon.target_type == 0 else "Đa mục tiêu (AOE)"

	if range_label != null:
		range_label.text = "Tầm gần (Close)" if weapon.range_type == 0 else "Tầm trung (Mid)"

	var cur_level := 0
	var cur_damage: float = weapon.base_damage
	var cur_fire_rate: float = weapon.fire_rate
	var max_level: int = weapon.upgrade_cost_curve.size()

	if weapon_system != null and weapon_system.has_method("get_weapon_stats"):
		var stats: Dictionary = weapon_system.get_weapon_stats(weapon.id)
		if not stats.is_empty():
			cur_level = int(stats.get("level", 0))
			cur_damage = float(stats.get("damage", weapon.base_damage))
			cur_fire_rate = float(stats.get("fire_rate", weapon.fire_rate))

	if damage_label != null:
		damage_label.text = "%.1f (+%.1f cấp tiếp)" % [cur_damage, weapon.base_damage * 0.10]

	if fire_rate_label != null:
		fire_rate_label.text = "%.2f viên/giây (+%.2f cấp tiếp)" % [cur_fire_rate, weapon.fire_rate * 0.05]

	if level_label != null:
		level_label.text = "CẤP ĐỘ: %d / %d" % [cur_level, max_level]

	if level_progress_bar != null:
		level_progress_bar.max_value = max_level
		level_progress_bar.value = cur_level

	if equip_button != null:
		equip_button.text = "ĐANG TRANG BỊ" if index == 0 else "TRANG BỊ"

	# Cập nhật nút nâng cấp và thông báo theo trạng thái
	if upgrade_button != null:
		if cur_level >= max_level:
			upgrade_button.disabled = true
			upgrade_button.text = "MAX CẤP"
			if notice_label != null:
				notice_label.text = "Vũ khí đã đạt cấp tối đa (%d/%d)." % [cur_level, max_level]
		else:
			var cost: int = weapon.upgrade_cost_curve[cur_level]
			var gold: int = weapon_system.current_gold if weapon_system != null else 0
			if gold < cost:
				upgrade_button.disabled = true
				upgrade_button.text = "KHÔNG ĐỦ VÀNG (%d)" % cost
				if notice_label != null:
					notice_label.text = "Thiếu vàng: cần %d vàng nhưng chỉ có %d." % [cost, gold]
			else:
				upgrade_button.disabled = false
				upgrade_button.text = "NÂNG CẤP (%d VÀNG)" % cost
				if notice_label != null:
					notice_label.text = "Sẵn sàng nâng cấp lên Cấp %d." % (cur_level + 1)


func _on_upgrade_pressed() -> void:
	var weapon: Variant = _get_current_weapon_resource()
	if weapon == null:
		return

	if weapon_system != null and weapon_system.has_method("upgrade_weapon"):
		var success: bool = weapon_system.upgrade_weapon(weapon.id)
		if success:
			if notice_label != null:
				notice_label.text = "Nâng cấp %s thành công!" % weapon.display_name
		else:
			if notice_label != null:
				notice_label.text = "Nâng cấp thất bại (không đủ vàng hoặc đã max cấp)!"

	_show_weapon(current_selected_index)


func _on_weapon_upgraded(_weapon_id: String, _new_level: int) -> void:
	_show_weapon(current_selected_index)


func _on_equip_pressed() -> void:
	if equip_button != null:
		equip_button.text = "ĐANG TRANG BỊ"


func _on_back_pressed() -> void:
	back_pressed.emit()
