class_name UpgradeChoiceOverlay
extends Control

signal upgrade_chosen(option_index: int)

var dim_background: ColorRect
var cards_container: HBoxContainer
var title_label: Label
var subtitle_label: Label

var hero_system: Node
var game_state: Node
var _current_options: Array[Dictionary] = []
var _is_run_finished: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_cache_nodes()
	if is_inside_tree():
		if hero_system == null:
			hero_system = get_node_or_null("/root/HeroSystem")
		if game_state == null:
			game_state = get_node_or_null("/root/GameState")

	_connect_signals()
	visible = false


func _cache_nodes() -> void:
	if dim_background == null:
		dim_background = get_node_or_null("DimBackground") as ColorRect
	if cards_container == null:
		cards_container = get_node_or_null("CenterContainer/MainPanel/CardsContainer") as HBoxContainer
	if title_label == null:
		title_label = get_node_or_null("CenterContainer/MainPanel/TitleLabel") as Label
	if subtitle_label == null:
		subtitle_label = get_node_or_null("CenterContainer/MainPanel/SubtitleLabel") as Label


func _exit_tree() -> void:
	_unpause_game()
	_disconnect_signals()


func set_hero_system(p_hero_system: Node) -> void:
	if hero_system == p_hero_system:
		return
	_disconnect_signals()
	hero_system = p_hero_system
	_connect_signals()


func set_game_state(p_game_state: Node) -> void:
	if game_state == p_game_state:
		return
	_disconnect_signals()
	game_state = p_game_state
	_connect_signals()


func _connect_signals() -> void:
	if hero_system != null:
		if hero_system.has_signal("upgrade_choices_ready") and not hero_system.upgrade_choices_ready.is_connected(_on_upgrade_choices_ready):
			hero_system.upgrade_choices_ready.connect(_on_upgrade_choices_ready)
		if hero_system.has_signal("run_reset") and not hero_system.run_reset.is_connected(_on_run_reset):
			hero_system.run_reset.connect(_on_run_reset)

	if game_state != null:
		if game_state.has_signal("run_failed") and not game_state.run_failed.is_connected(_on_run_finished):
			game_state.run_failed.connect(_on_run_finished)
		if game_state.has_signal("run_completed") and not game_state.run_completed.is_connected(_on_run_finished):
			game_state.run_completed.connect(_on_run_finished)


func _disconnect_signals() -> void:
	if hero_system != null and is_instance_valid(hero_system):
		if hero_system.has_signal("upgrade_choices_ready") and hero_system.upgrade_choices_ready.is_connected(_on_upgrade_choices_ready):
			hero_system.upgrade_choices_ready.disconnect(_on_upgrade_choices_ready)
		if hero_system.has_signal("run_reset") and hero_system.run_reset.is_connected(_on_run_reset):
			hero_system.run_reset.disconnect(_on_run_reset)

	if game_state != null and is_instance_valid(game_state):
		if game_state.has_signal("run_failed") and game_state.run_failed.is_connected(_on_run_finished):
			game_state.run_failed.disconnect(_on_run_finished)
		if game_state.has_signal("run_completed") and game_state.run_completed.is_connected(_on_run_finished):
			game_state.run_completed.disconnect(_on_run_finished)


func _on_upgrade_choices_ready(options: Array[Dictionary]) -> void:
	show_choices(options)


func show_choices(options: Array[Dictionary]) -> void:
	if _is_run_finished:
		hide_overlay()
		return

	_cache_nodes()
	_current_options = options
	_clear_cards()

	if options.is_empty():
		hide_overlay()
		return

	for i in range(options.size()):
		var option: Dictionary = options[i]
		var card: Control = _create_card(i, option)
		if cards_container != null:
			cards_container.add_child(card)

	visible = true
	_pause_game()


func hide_overlay() -> void:
	_clear_cards()
	visible = false
	_unpause_game()


func _on_run_finished() -> void:
	_is_run_finished = true
	hide_overlay()


func _on_run_reset() -> void:
	_is_run_finished = false
	hide_overlay()


func _pause_game() -> void:
	if is_inside_tree():
		get_tree().paused = true


func _unpause_game() -> void:
	if is_inside_tree() and get_tree().paused:
		get_tree().paused = false


func _clear_cards() -> void:
	if cards_container != null:
		for child in cards_container.get_children():
			child.queue_free()


func _create_card(index: int, option: Dictionary) -> Control:
	var action: String = str(option.get("action", "upgrade"))
	var display_name: String = str(option.get("display_name", "Hero"))
	var current_level: int = int(option.get("current_level", 0))
	var next_level: int = int(option.get("next_level", 1))
	var max_level: int = int(option.get("max_level", 15))

	var is_activate: bool = (action == "activate")

	var card_panel := PanelContainer.new()
	card_panel.name = "Card_%d" % index
	card_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card_panel.custom_minimum_size = Vector2(180, 280)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	card_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(vbox)

	# 1. Action Tag
	var action_label := Label.new()
	action_label.name = "ActionLabel"
	action_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if is_activate:
		action_label.text = "🆕 MỞ MỚI"
		action_label.add_theme_color_override("font_color", Color(0.2, 0.9, 0.4, 1.0))
	else:
		action_label.text = "⬆ NÂNG CẤP"
		action_label.add_theme_color_override("font_color", Color(1.0, 0.75, 0.2, 1.0))
	action_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(action_label)

	# 2. Hero Name
	var name_label := Label.new()
	name_label.name = "NameLabel"
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.text = display_name
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.add_theme_font_size_override("font_size", 20)
	vbox.add_child(name_label)

	# 3. Level Info
	var level_label := Label.new()
	level_label.name = "LevelLabel"
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if is_activate:
		level_label.text = "Cấp 1\n(Tối đa %d)" % max_level
	else:
		level_label.text = "Cấp %d ➔ Cấp %d\n(Tối đa %d)" % [current_level, next_level, max_level]
	level_label.add_theme_color_override("font_color", Color(0.8, 0.85, 0.9, 1.0))
	level_label.add_theme_font_size_override("font_size", 15)
	vbox.add_child(level_label)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	# 4. Select Button
	var button := Button.new()
	button.name = "SelectButton"
	button.custom_minimum_size = Vector2(0, 44)
	button.text = "CHỌN"
	button.pressed.connect(_on_card_selected.bind(index))
	vbox.add_child(button)

	return card_panel


func select_choice(index: int) -> void:
	_on_card_selected(index)


func _on_card_selected(index: int) -> void:
	if hero_system != null and hero_system.has_method("choose_upgrade"):
		hero_system.choose_upgrade(index)

	upgrade_chosen.emit(index)

	if hero_system != null and ("pending_upgrade_options" in hero_system):
		if hero_system.pending_upgrade_options.is_empty():
			hide_overlay()
	else:
		hide_overlay()
