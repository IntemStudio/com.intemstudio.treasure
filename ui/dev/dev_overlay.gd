extends CanvasLayer

enum Tab { CHARACTER = 0, ITEM = 1, SAVE = 2 }

@onready var panel: PanelContainer = %Panel
@onready var title_label: Label = %TitleLabel
@onready var character_tab_button: Button = %CharacterTabButton
@onready var item_tab_button: Button = %ItemTabButton
@onready var save_tab_button: Button = %SaveTabButton
@onready var character_panel: VBoxContainer = %CharacterPanel
@onready var item_panel: VBoxContainer = %ItemPanel
@onready var save_panel: VBoxContainer = %SavePanel
@onready var path_label: Label = %PathLabel
@onready var open_folder_button: Button = %OpenFolderButton
@onready var level_info_label: Label = %LevelInfoLabel
@onready var level_down_button: Button = %LevelDownButton
@onready var level_up_button: Button = %LevelUpButton
@onready var force_encounter_button: Button = %ForceEncounterButton
@onready var force_win_button: Button = %ForceWinButton
@onready var force_lose_button: Button = %ForceLoseButton
@onready var force_retreat_button: Button = %ForceRetreatButton
@onready var equip_label: Label = %EquipLabel
@onready var equip_option: OptionButton = %EquipOption
@onready var equip_grant_button: Button = %EquipGrantButton
@onready var gem_label: Label = %GemLabel
@onready var gem_option: OptionButton = %GemOption
@onready var gem_grant_button: Button = %GemGrantButton
@onready var rune_label: Label = %RuneLabel
@onready var rune_option: OptionButton = %RuneOption
@onready var rune_grant_button: Button = %RuneGrantButton
@onready var status_label: Label = %StatusLabel
@onready var close_hint_label: Label = %CloseHintLabel

var _ui_manager: UIManager
var _active_tab: int = Tab.CHARACTER
var _empty_style: StyleBoxEmpty
var _item_catalog: ItemCatalog
var _gem_catalog: GemCatalog
var _rune_catalog: RuneCatalog
var _equip_ids: Array[String] = []
var _gem_ids: Array[String] = []
var _rune_ids: Array[String] = []


func _ready() -> void:
	layer = 100
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	_item_catalog = ItemCatalog.new()
	_gem_catalog = GemCatalog.new()
	_rune_catalog = RuneCatalog.new()
	_empty_style = StyleBoxEmpty.new()
	_empty_style.content_margin_left = 0
	_empty_style.content_margin_top = 0
	_empty_style.content_margin_right = 0
	_empty_style.content_margin_bottom = 0
	_style_tab_button(character_tab_button)
	_style_tab_button(item_tab_button)
	_style_tab_button(save_tab_button)
	character_tab_button.pressed.connect(_on_tab_pressed.bind(Tab.CHARACTER))
	item_tab_button.pressed.connect(_on_tab_pressed.bind(Tab.ITEM))
	save_tab_button.pressed.connect(_on_tab_pressed.bind(Tab.SAVE))
	open_folder_button.pressed.connect(_on_open_folder_pressed)
	level_up_button.pressed.connect(_on_level_up_pressed)
	level_down_button.pressed.connect(_on_level_down_pressed)
	force_encounter_button.pressed.connect(_on_force_encounter_pressed)
	force_win_button.pressed.connect(_on_force_win_pressed)
	force_lose_button.pressed.connect(_on_force_lose_pressed)
	force_retreat_button.pressed.connect(_on_force_retreat_pressed)
	equip_grant_button.pressed.connect(_on_equip_grant_pressed)
	gem_grant_button.pressed.connect(_on_gem_grant_pressed)
	rune_grant_button.pressed.connect(_on_rune_grant_pressed)
	LocaleManager.locale_changed.connect(_on_locale_changed)
	_populate_item_options()
	_refresh_texts()
	_apply_tab()


func setup(ui_manager: UIManager) -> void:
	_ui_manager = ui_manager


func toggle() -> void:
	if visible:
		close()
	else:
		open()


func open() -> void:
	visible = true
	_refresh_texts()
	_apply_tab()
	status_label.text = ""


func close() -> void:
	visible = false
	status_label.text = ""


func is_open() -> bool:
	return visible


func _on_locale_changed(_locale: String) -> void:
	_refresh_texts()
	_populate_item_options()
	if visible:
		_apply_tab()


func _refresh_texts() -> void:
	title_label.text = "[%s]" % tr("Developer")
	character_tab_button.text = "[%s]" % tr("Character")
	item_tab_button.text = "[%s]" % tr("Items")
	save_tab_button.text = "[%s]" % tr("Save Data")
	open_folder_button.text = tr("Open Save Folder")
	level_up_button.text = tr("Force Level Up")
	level_down_button.text = tr("Force Level Down")
	force_encounter_button.text = tr("DEV_FORCE_ENCOUNTER")
	force_win_button.text = tr("DEV_FORCE_WIN")
	force_lose_button.text = tr("DEV_FORCE_LOSE")
	force_retreat_button.text = tr("DEV_FORCE_RETREAT")
	equip_label.text = tr("Equipment")
	gem_label.text = tr("Gem")
	rune_label.text = tr("Rune")
	equip_grant_button.text = tr("DEV_GRANT")
	gem_grant_button.text = tr("DEV_GRANT")
	rune_grant_button.text = tr("DEV_GRANT")
	close_hint_label.text = tr("` / Esc: Close")
	_refresh_tab_colors()


func _style_tab_button(button: Button) -> void:
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_stylebox_override("normal", _empty_style)
	button.add_theme_stylebox_override("hover", _empty_style)
	button.add_theme_stylebox_override("pressed", _empty_style)
	button.add_theme_stylebox_override("focus", _empty_style)
	button.add_theme_font_size_override("font_size", 18)


func _on_tab_pressed(tab: int) -> void:
	if _active_tab == tab:
		return
	_active_tab = tab
	status_label.text = ""
	_apply_tab()


func _apply_tab() -> void:
	character_panel.visible = _active_tab == Tab.CHARACTER
	item_panel.visible = _active_tab == Tab.ITEM
	save_panel.visible = _active_tab == Tab.SAVE
	_refresh_tab_colors()
	match _active_tab:
		Tab.CHARACTER:
			_refresh_level()
		Tab.ITEM:
			pass
		Tab.SAVE:
			_refresh_path()


func _refresh_tab_colors() -> void:
	_set_tab_color(character_tab_button, _active_tab == Tab.CHARACTER)
	_set_tab_color(item_tab_button, _active_tab == Tab.ITEM)
	_set_tab_color(save_tab_button, _active_tab == Tab.SAVE)


func _set_tab_color(button: Button, active: bool) -> void:
	button.add_theme_color_override(
		"font_color",
		UIColors.GOLD if active else UIColors.TEXT_MUTED
	)


func _refresh_path() -> void:
	path_label.text = SaveManager.get_save_dir_global_path()


func _refresh_level() -> void:
	var stats := _character_stats()
	if stats == null:
		level_info_label.text = tr("No character")
		level_up_button.disabled = true
		level_down_button.disabled = true
		return
	stats.sync_xp_to_next()
	level_info_label.text = tr("Level %d  (%d / %d XP)") % [
		stats.level, stats.xp, stats.xp_to_next
	]
	level_up_button.disabled = LevelProgression.is_max_level(stats.level)
	level_down_button.disabled = stats.level <= CharacterStats.MIN_LEVEL


func _character_stats() -> CharacterStats:
	if _ui_manager == null:
		return null
	return _ui_manager.character_stats


func _inventory() -> InventoryData:
	if _ui_manager == null:
		return null
	return _ui_manager.inventory_data


func _populate_item_options() -> void:
	_equip_ids = _item_catalog.ids_for_categories([
		ItemData.ItemCategory.WEAPON,
		ItemData.ItemCategory.ARMOR,
	])
	_gem_ids.clear()
	for gem_id in _gem_catalog.all_ids():
		_gem_ids.append(str(gem_id))
	_gem_ids.sort()
	_rune_ids.clear()
	for rune_id in _rune_catalog.all_ids():
		_rune_ids.append(str(rune_id))
	_rune_ids.sort()

	_fill_option(equip_option, _equip_ids, func(id: String) -> String:
		var item := _item_catalog.get_item(id)
		return item.display_name if item else id
	)
	_fill_option(gem_option, _gem_ids, func(id: String) -> String:
		var gem := _gem_catalog.get_gem(id)
		return gem.display_name if gem else id
	)
	_fill_option(rune_option, _rune_ids, func(id: String) -> String:
		var rune := _rune_catalog.get_rune(id)
		return rune.display_name if rune else id
	)


func _fill_option(option: OptionButton, ids: Array[String], label_fn: Callable) -> void:
	var prev := option.selected
	option.clear()
	for i in ids.size():
		option.add_item(str(label_fn.call(ids[i])), i)
	if ids.is_empty():
		option.disabled = true
		return
	option.disabled = false
	if prev >= 0 and prev < ids.size():
		option.select(prev)
	else:
		option.select(0)


func _on_equip_grant_pressed() -> void:
	var inventory := _inventory()
	if inventory == null:
		status_label.text = tr("No character")
		return
	var idx := equip_option.selected
	if idx < 0 or idx >= _equip_ids.size():
		return
	var item_id := _equip_ids[idx]
	var item := _item_catalog.get_item(item_id)
	if item == null:
		return
	var slot := inventory.find_empty_slot()
	if slot < 0:
		status_label.text = tr("LOOT_INVENTORY_FULL")
		return
	inventory.slots[slot] = item
	_ui_manager.refresh_character_views()
	status_label.text = tr("LOOT_GOT") % item.display_name


func _on_gem_grant_pressed() -> void:
	var inventory := _inventory()
	if inventory == null:
		status_label.text = tr("No character")
		return
	var idx := gem_option.selected
	if idx < 0 or idx >= _gem_ids.size():
		return
	var gem_id := _gem_ids[idx]
	var gem := _gem_catalog.get_gem(gem_id)
	if gem == null:
		return
	inventory.gems.append(GemInstance.create(gem_id))
	_ui_manager.refresh_character_views()
	status_label.text = tr("LOOT_GOT") % gem.display_name


func _on_rune_grant_pressed() -> void:
	var inventory := _inventory()
	if inventory == null:
		status_label.text = tr("No character")
		return
	var idx := rune_option.selected
	if idx < 0 or idx >= _rune_ids.size():
		return
	var rune_id := _rune_ids[idx]
	var rune := _rune_catalog.get_rune(rune_id)
	if rune == null:
		return
	inventory.runes.append(RuneInstance.create(rune_id))
	_ui_manager.refresh_character_views()
	status_label.text = tr("LOOT_GOT") % rune.display_name

func _on_open_folder_pressed() -> void:
	_refresh_path()
	var err := SaveManager.open_save_folder()
	if err == OK:
		status_label.text = tr("Opened save folder")
	else:
		status_label.text = tr("Failed to open save folder")


func _on_level_up_pressed() -> void:
	var stats := _character_stats()
	if stats == null:
		status_label.text = tr("No character")
		return
	if not stats.force_level_up():
		status_label.text = tr("Already max level")
		_refresh_level()
		return
	_ui_manager.refresh_character_views()
	_refresh_level()
	status_label.text = tr("Forced level up → %d") % stats.level


func _on_level_down_pressed() -> void:
	var stats := _character_stats()
	if stats == null:
		status_label.text = tr("No character")
		return
	if not stats.force_level_down():
		status_label.text = tr("Already min level")
		_refresh_level()
		return
	_ui_manager.refresh_character_views()
	_refresh_level()
	status_label.text = tr("Forced level down → %d") % stats.level


func _director() -> EncounterDirector:
	if _ui_manager == null:
		return null
	return _ui_manager.encounter_director


func _on_force_encounter_pressed() -> void:
	var director := _director()
	if director == null:
		status_label.text = tr("DEV_NO_COMBAT")
		return
	close()
	if director.is_active():
		status_label.text = tr("DEV_COMBAT_ACTIVE")
		open()
		return
	if director.force_start_current():
		status_label.text = tr("DEV_ENCOUNTER_STARTED")
	else:
		status_label.text = tr("DEV_ENCOUNTER_FAILED")
		open()


func _on_force_win_pressed() -> void:
	var director := _director()
	if director == null or not director.is_active():
		status_label.text = tr("DEV_NO_COMBAT")
		return
	close()
	director.force_result(CombatSession.RESULT_WIN)
	status_label.text = tr("DEV_FORCED_WIN")


func _on_force_lose_pressed() -> void:
	var director := _director()
	if director == null or not director.is_active():
		status_label.text = tr("DEV_NO_COMBAT")
		return
	close()
	director.force_result(CombatSession.RESULT_LOSE)


func _on_force_retreat_pressed() -> void:
	var director := _director()
	if director == null or not director.is_active():
		status_label.text = tr("DEV_NO_COMBAT")
		return
	close()
	director.force_result(CombatSession.RESULT_RETREAT)
	status_label.text = tr("DEV_FORCED_RETREAT")
