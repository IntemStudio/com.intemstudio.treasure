extends CanvasLayer

enum Tab { CHARACTER = 0, ITEM = 1, SHELF = 2, SAVE = 3 }

const _RARITY_KEYS: Array[String] = [
	"COMMON",
	"UNCOMMON",
	"RARE",
	"LEGENDARY",
]
const _SLOT_GROUPS: Array[String] = [
	"head",
	"chest",
	"legs",
	"main_hand",
	"off_hand",
	"ring",
	"tool",
]
const _SLOT_KEYS: Array[String] = [
	"SLOT_HELMETS",
	"SLOT_BODY",
	"SLOT_PANTS",
	"SLOT_WEAPONS",
	"SLOT_OFF_HANDS",
	"SLOT_RINGS",
	"SLOT_TOOLS",
]


@onready var dim: ColorRect = %Dim
@onready var panel: PanelContainer = %Panel
@onready var title_label: Label = %TitleLabel
@onready var character_tab_button: Button = %CharacterTabButton
@onready var item_tab_button: Button = %ItemTabButton
@onready var shelf_tab_button: Button = %ShelfTabButton
@onready var save_tab_button: Button = %SaveTabButton
@onready var character_panel: VBoxContainer = %CharacterPanel
@onready var item_panel: VBoxContainer = %ItemPanel
@onready var shelf_panel: VBoxContainer = %ShelfPanel
@onready var save_panel: VBoxContainer = %SavePanel
@onready var path_label: Label = %PathLabel
@onready var open_folder_button: Button = %OpenFolderButton
@onready var save_slot_label: Label = %SaveSlotLabel
@onready var save_slot_option: OptionButton = %SaveSlotOption
@onready var meta_label: Label = %MetaLabel
@onready var save_meta_button: Button = %SaveMetaButton
@onready var delete_meta_button: Button = %DeleteMetaButton
@onready var run_label: Label = %RunLabel
@onready var save_run_button: Button = %SaveRunButton
@onready var delete_run_button: Button = %DeleteRunButton
@onready var settings_layer_label: Label = %SettingsLayerLabel
@onready var save_settings_button: Button = %SaveSettingsButton
@onready var delete_settings_button: Button = %DeleteSettingsButton
@onready var all_label: Label = %AllLabel
@onready var save_all_button: Button = %SaveAllButton
@onready var delete_all_button: Button = %DeleteAllButton
@onready var level_info_label: Label = %LevelInfoLabel
@onready var level_down_button: Button = %LevelDownButton
@onready var level_up_button: Button = %LevelUpButton
@onready var force_encounter_button: Button = %ForceEncounterButton
@onready var force_win_button: Button = %ForceWinButton
@onready var force_lose_button: Button = %ForceLoseButton
@onready var force_retreat_button: Button = %ForceRetreatButton
@onready var equip_label: Label = %EquipLabel
@onready var equip_slot_option: OptionButton = %EquipSlotOption
@onready var equip_option: OptionButton = %EquipOption
@onready var equip_rarity_option: OptionButton = %EquipRarityOption
@onready var equip_grant_button: Button = %EquipGrantButton
@onready var gem_label: Label = %GemLabel
@onready var gem_option: OptionButton = %GemOption
@onready var gem_grant_button: Button = %GemGrantButton
@onready var rune_label: Label = %RuneLabel
@onready var rune_option: OptionButton = %RuneOption
@onready var rune_grant_button: Button = %RuneGrantButton
@onready var unlock_all_runes_button: Button = %UnlockAllRunesButton
@onready var unlock_all_gems_button: Button = %UnlockAllGemsButton
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
	if panel:
		UIPopupLayout.apply_dialog_panel(panel)
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
	_style_tab_button(shelf_tab_button)
	_style_tab_button(save_tab_button)
	character_tab_button.pressed.connect(_on_tab_pressed.bind(Tab.CHARACTER))
	item_tab_button.pressed.connect(_on_tab_pressed.bind(Tab.ITEM))
	shelf_tab_button.pressed.connect(_on_tab_pressed.bind(Tab.SHELF))
	save_tab_button.pressed.connect(_on_tab_pressed.bind(Tab.SAVE))
	open_folder_button.pressed.connect(_on_open_folder_pressed)
	save_meta_button.pressed.connect(_on_save_meta_pressed)
	delete_meta_button.pressed.connect(_on_delete_meta_pressed)
	save_run_button.pressed.connect(_on_save_run_pressed)
	delete_run_button.pressed.connect(_on_delete_run_pressed)
	save_settings_button.pressed.connect(_on_save_settings_pressed)
	delete_settings_button.pressed.connect(_on_delete_settings_pressed)
	save_all_button.pressed.connect(_on_save_all_pressed)
	delete_all_button.pressed.connect(_on_delete_all_pressed)
	level_up_button.pressed.connect(_on_level_up_pressed)
	level_down_button.pressed.connect(_on_level_down_pressed)
	force_encounter_button.pressed.connect(_on_force_encounter_pressed)
	force_win_button.pressed.connect(_on_force_win_pressed)
	force_lose_button.pressed.connect(_on_force_lose_pressed)
	force_retreat_button.pressed.connect(_on_force_retreat_pressed)
	equip_grant_button.pressed.connect(_on_equip_grant_pressed)
	gem_grant_button.pressed.connect(_on_gem_grant_pressed)
	rune_grant_button.pressed.connect(_on_rune_grant_pressed)
	unlock_all_runes_button.pressed.connect(_on_unlock_all_runes_pressed)
	unlock_all_gems_button.pressed.connect(_on_unlock_all_gems_pressed)
	equip_slot_option.item_selected.connect(_on_equip_slot_selected)
	equip_option.item_selected.connect(_on_equip_option_selected)
	LocaleManager.locale_changed.connect(_on_locale_changed)
	_setup_rarity_option()
	_setup_slot_option()
	_populate_item_options()
	_sync_equip_rarity_from_selection()
	_apply_chrome()
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
	_refresh_rarity_option_texts()
	_refresh_slot_option_texts()
	_refresh_save_slot_option()
	if visible:
		_apply_tab()


func _refresh_texts() -> void:
	title_label.text = "[%s]" % tr("Developer")
	character_tab_button.text = "[%s]" % tr("Character")
	item_tab_button.text = "[%s]" % tr("Items")
	shelf_tab_button.text = "[%s]" % tr("SHELF_LABEL")
	save_tab_button.text = "[%s]" % tr("Save Data")
	open_folder_button.text = tr("Open Save Folder")
	save_slot_label.text = tr("Save Slots")
	meta_label.text = tr("DEV_LAYER_META")
	run_label.text = tr("DEV_LAYER_RUN")
	settings_layer_label.text = tr("Settings")
	all_label.text = tr("DEV_LAYER_ALL")
	var save_text := tr("Save")
	var delete_text := tr("Delete")
	save_meta_button.text = save_text
	delete_meta_button.text = delete_text
	save_run_button.text = save_text
	delete_run_button.text = delete_text
	save_settings_button.text = save_text
	delete_settings_button.text = delete_text
	save_all_button.text = save_text
	delete_all_button.text = delete_text
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
	unlock_all_runes_button.text = tr("DEV_UNLOCK_ALL_RUNES")
	unlock_all_gems_button.text = tr("DEV_UNLOCK_ALL_GEMS")
	close_hint_label.text = tr("` / Esc: Close")
	_refresh_tab_colors()


func _apply_chrome() -> void:
	dim.color = UIColors.with_alpha(UIColors.MAP_START, 0.45)
	var style := StyleBoxFlat.new()
	style.bg_color = UIColors.SLOT_BG_SOLID
	style.border_color = UIColors.MAP_START
	style.set_border_width_all(2)
	panel.add_theme_stylebox_override("panel", style)
	title_label.add_theme_color_override("font_color", UIColors.MAP_START)
	close_hint_label.add_theme_color_override("font_color", UIColors.TEXT_MUTED)


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
	shelf_panel.visible = _active_tab == Tab.SHELF
	save_panel.visible = _active_tab == Tab.SAVE
	_refresh_tab_colors()
	match _active_tab:
		Tab.CHARACTER:
			_refresh_level()
		Tab.ITEM:
			pass
		Tab.SHELF:
			pass
		Tab.SAVE:
			_refresh_path()
			_refresh_save_slot_option()


func _refresh_tab_colors() -> void:
	_set_tab_color(character_tab_button, _active_tab == Tab.CHARACTER)
	_set_tab_color(item_tab_button, _active_tab == Tab.ITEM)
	_set_tab_color(shelf_tab_button, _active_tab == Tab.SHELF)
	_set_tab_color(save_tab_button, _active_tab == Tab.SAVE)


func _set_tab_color(button: Button, active: bool) -> void:
	button.add_theme_color_override(
		"font_color",
		UIColors.GOLD if active else UIColors.TEXT_MUTED
	)


func _refresh_path() -> void:
	path_label.text = SaveManager.get_save_dir_global_path()


func _refresh_save_slot_option() -> void:
	var keep := _selected_save_slot()
	if keep < 0 and SaveManager.current_slot >= 0:
		keep = SaveManager.current_slot
	save_slot_option.clear()
	var infos := SaveManager.list_slots()
	for i in range(SaveManager.SLOT_COUNT):
		var info: Dictionary = infos[i] if i < infos.size() else {"status": "empty", "meta": {}}
		save_slot_option.add_item(_save_slot_label(i, info), i)
	if SaveManager.SLOT_COUNT <= 0:
		save_slot_option.disabled = true
		return
	save_slot_option.disabled = false
	if keep < 0 or keep >= SaveManager.SLOT_COUNT:
		keep = 0
	save_slot_option.select(keep)


func _save_slot_label(slot: int, info: Dictionary) -> String:
	var status := str(info.get("status", "empty"))
	match status:
		"valid":
			var meta: Dictionary = info.get("meta", {})
			var level := int(meta.get("level", 1))
			return tr("Slot %d: Level %d") % [slot, level]
		"corrupt":
			return tr("Slot %d: Corrupt") % slot
		"incompatible":
			return tr("Slot %d: Incompatible") % slot
		_:
			return tr("Slot %d: Empty") % slot


func _selected_save_slot() -> int:
	if save_slot_option == null or save_slot_option.item_count <= 0:
		return -1
	var idx := save_slot_option.selected
	if idx < 0 or idx >= SaveManager.SLOT_COUNT:
		return -1
	return idx


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
	_populate_equip_options(true)
	var prev_gem := _selected_id(gem_option, _gem_ids)
	var prev_rune := _selected_id(rune_option, _rune_ids)
	_gem_ids.clear()
	for gem_id in _gem_catalog.all_ids():
		_gem_ids.append(str(gem_id))
	_gem_ids.sort()
	_rune_ids.clear()
	for rune_id in _rune_catalog.all_ids():
		_rune_ids.append(str(rune_id))
	_rune_ids.sort()
	_fill_option(gem_option, _gem_ids, func(id: String) -> String:
		var gem := _gem_catalog.get_gem(id)
		return tr(gem.display_name) if gem else id
	, prev_gem)
	_fill_option(rune_option, _rune_ids, func(id: String) -> String:
		var rune := _rune_catalog.get_rune(id)
		return tr(rune.display_name) if rune else id
	, prev_rune)


func _populate_equip_options(keep_item: bool) -> void:
	var keep_id := _selected_id(equip_option, _equip_ids) if keep_item else ""
	_equip_ids = _equip_ids_for_selected_slot()
	_fill_option(equip_option, _equip_ids, func(id: String) -> String:
		var item := _item_catalog.get_item(id)
		return tr(item.display_name) if item else id
	, keep_id)
	equip_grant_button.disabled = _equip_ids.is_empty()


func _equip_ids_for_selected_slot() -> Array[String]:
	var group := _selected_slot_group()
	var out: Array[String] = []
	var all_ids := _item_catalog.ids_for_categories([
		ItemData.ItemCategory.WEAPON,
		ItemData.ItemCategory.ARMOR,
		ItemData.ItemCategory.TOOL,
	])
	for item_id in all_ids:
		var item := _item_catalog.get_item(item_id)
		if item and _item_matches_slot_group(item, group):
			out.append(item_id)
	return out


func _item_matches_slot_group(item: ItemData, group: String) -> bool:
	match group:
		"ring":
			return item.equip_slot.begins_with("ring")
		"tool":
			return item.equip_slot.begins_with("tool")
		_:
			return item.equip_slot == group


func _selected_slot_group() -> String:
	var idx := equip_slot_option.selected
	if idx < 0 or idx >= _SLOT_GROUPS.size():
		return _SLOT_GROUPS[0]
	return _SLOT_GROUPS[idx]


func _selected_id(option: OptionButton, ids: Array[String]) -> String:
	var idx := option.selected
	if idx < 0 or idx >= ids.size():
		return ""
	return ids[idx]


func _fill_option(
	option: OptionButton,
	ids: Array[String],
	label_fn: Callable,
	keep_id: String = ""
) -> void:
	option.clear()
	for i in ids.size():
		option.add_item(str(label_fn.call(ids[i])), i)
	if ids.is_empty():
		option.disabled = true
		return
	option.disabled = false
	var keep_idx := ids.find(keep_id)
	if keep_idx >= 0:
		option.select(keep_idx)
	else:
		option.select(0)


func _setup_rarity_option() -> void:
	equip_rarity_option.clear()
	for i in _RARITY_KEYS.size():
		equip_rarity_option.add_item(tr(_RARITY_KEYS[i]), i)


func _setup_slot_option() -> void:
	equip_slot_option.clear()
	for i in _SLOT_KEYS.size():
		equip_slot_option.add_item(tr(_SLOT_KEYS[i]), i)
	if _SLOT_KEYS.is_empty():
		equip_slot_option.disabled = true
		return
	equip_slot_option.disabled = false
	equip_slot_option.select(0)


func _refresh_rarity_option_texts() -> void:
	_refresh_option_texts(equip_rarity_option, _RARITY_KEYS)


func _refresh_slot_option_texts() -> void:
	_refresh_option_texts(equip_slot_option, _SLOT_KEYS)


func _refresh_option_texts(option: OptionButton, keys: Array[String]) -> void:
	for i in option.item_count:
		var id := option.get_item_id(i)
		if id >= 0 and id < keys.size():
			option.set_item_text(i, tr(keys[id]))


func _on_equip_slot_selected(_index: int) -> void:
	_populate_equip_options(false)
	_sync_equip_rarity_from_selection()


func _on_equip_option_selected(_index: int) -> void:
	_sync_equip_rarity_from_selection()


func _sync_equip_rarity_from_selection() -> void:
	var idx := equip_option.selected
	if idx < 0 or idx >= _equip_ids.size():
		return
	var item := _item_catalog.get_item(_equip_ids[idx])
	if item == null:
		return
	var rarity_idx := int(item.rarity)
	if rarity_idx < 0 or rarity_idx >= equip_rarity_option.item_count:
		return
	equip_rarity_option.select(rarity_idx)


func _selected_equip_rarity() -> ItemData.ItemRarity:
	var idx := equip_rarity_option.selected
	if idx < 0 or idx >= _RARITY_KEYS.size():
		return ItemData.ItemRarity.COMMON
	return idx as ItemData.ItemRarity


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
	item.apply_rarity(_selected_equip_rarity())
	if inventory.try_place_item(item) < 0:
		status_label.text = tr("LOOT_INVENTORY_FULL")
		return
	_ui_manager.refresh_character_views()
	status_label.text = tr("LOOT_GOT") % tr(item.display_name)


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
	if not inventory.try_add_gem(GemInstance.create(gem_id)):
		status_label.text = tr("LOOT_INVENTORY_FULL")
		return
	_ui_manager.refresh_character_views()
	status_label.text = tr("LOOT_GOT") % tr(gem.display_name)


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
	if not inventory.try_add_rune(RuneInstance.create(rune_id)):
		status_label.text = tr("LOOT_INVENTORY_FULL")
		return
	_ui_manager.refresh_character_views()
	status_label.text = tr("LOOT_GOT") % tr(rune.display_name)


func _on_unlock_all_runes_pressed() -> void:
	_unlock_shelf(String(ShelfDefinition.SHELF_RUNE), "DEV_UNLOCKED_ALL_RUNES")


func _on_unlock_all_gems_pressed() -> void:
	_unlock_shelf(String(ShelfDefinition.SHELF_GEM), "DEV_UNLOCKED_ALL_GEMS")


func _unlock_shelf(shelf_id: String, ok_key: String) -> void:
	if SaveManager.current_slot < 0:
		status_label.text = tr("No character")
		return
	var meta := CardRegistrationService.open_all_on_shelf(
		SaveManager.get_card_meta(),
		shelf_id
	)
	SaveManager.set_card_meta(meta)
	if _ui_manager != null and _ui_manager.character_stats != null and _ui_manager.inventory_data != null:
		SaveManager.save_game(
			SaveManager.current_slot,
			_ui_manager.character_stats,
			_ui_manager.inventory_data
		)
	_refresh_open_bookshelves()
	status_label.text = tr(ok_key)


func _refresh_open_bookshelves() -> void:
	var root := get_tree().root
	if root == null:
		return
	for node in root.find_children("*", "Bookshelf", true, false):
		if node.has_method("refresh"):
			node.refresh()


func _on_open_folder_pressed() -> void:
	_refresh_path()
	var err := SaveManager.open_save_folder()
	if err == OK:
		status_label.text = tr("Opened save folder")
	else:
		status_label.text = tr("Failed to open save folder")


func _require_slot() -> int:
	var slot := _selected_save_slot()
	if slot < 0:
		status_label.text = tr("DEV_NO_SLOT")
		return -1
	return slot


func _on_save_meta_pressed() -> void:
	var slot := _require_slot()
	if slot < 0:
		return
	if _ui_manager == null or _character_stats() == null or _inventory() == null:
		status_label.text = tr("No character")
		return
	var err := _ui_manager.save_to_slot(slot)
	if err == OK:
		status_label.text = tr("DEV_SAVED_LAYER") % tr("DEV_LAYER_META")
		_refresh_save_slot_option()
	else:
		status_label.text = tr("Save failed")


func _on_delete_meta_pressed() -> void:
	var slot := _require_slot()
	if slot < 0:
		return
	var err := SaveManager.clear_meta(slot)
	if err == OK:
		status_label.text = tr("DEV_DELETED_LAYER") % tr("DEV_LAYER_META")
		_refresh_save_slot_option()
	else:
		status_label.text = tr("Delete failed")


func _on_save_run_pressed() -> void:
	var slot := _require_slot()
	if slot < 0:
		return
	var err := _persist_run_now(slot)
	if err == OK:
		status_label.text = tr("DEV_SAVED_LAYER") % tr("DEV_LAYER_RUN")
	elif err == ERR_DOES_NOT_EXIST:
		status_label.text = tr("DEV_NO_RUN")
	else:
		status_label.text = tr("Save failed")


func _on_delete_run_pressed() -> void:
	var slot := _require_slot()
	if slot < 0:
		return
	var err := SaveManager.clear_run(slot)
	if err == OK:
		status_label.text = tr("DEV_DELETED_LAYER") % tr("DEV_LAYER_RUN")
	else:
		status_label.text = tr("Delete failed")


func _on_save_settings_pressed() -> void:
	SettingsManager.save_settings()
	status_label.text = tr("DEV_SAVED_LAYER") % tr("Settings")


func _on_delete_settings_pressed() -> void:
	SettingsManager.reset_settings()
	LocaleManager.set_language(SettingsManager.get_locale(), false)
	_refresh_texts()
	status_label.text = tr("DEV_DELETED_LAYER") % tr("Settings")


func _on_save_all_pressed() -> void:
	var parts: Array[String] = []
	var failed := false
	var slot := _selected_save_slot()
	if slot >= 0 and _ui_manager != null and _character_stats() != null and _inventory() != null:
		if _ui_manager.save_to_slot(slot) == OK:
			parts.append(tr("DEV_LAYER_META"))
			_refresh_save_slot_option()
		else:
			failed = true
	var run_err := OK
	if slot >= 0:
		run_err = _persist_run_now(slot)
		if run_err == OK:
			parts.append(tr("DEV_LAYER_RUN"))
		elif run_err != ERR_DOES_NOT_EXIST:
			failed = true
	SettingsManager.save_settings()
	parts.append(tr("Settings"))
	if failed:
		status_label.text = tr("Save failed")
	elif parts.is_empty():
		status_label.text = tr("DEV_NO_SLOT")
	else:
		status_label.text = tr("DEV_SAVED_LAYER") % ", ".join(PackedStringArray(parts))


func _on_delete_all_pressed() -> void:
	var parts: Array[String] = []
	var failed := false
	var slot := _selected_save_slot()
	if slot >= 0:
		if SaveManager.clear_meta(slot) == OK:
			parts.append(tr("DEV_LAYER_META"))
		else:
			failed = true
		if SaveManager.clear_run(slot) == OK:
			parts.append(tr("DEV_LAYER_RUN"))
		else:
			failed = true
		_refresh_save_slot_option()
	SettingsManager.reset_settings()
	LocaleManager.set_language(SettingsManager.get_locale(), false)
	_refresh_texts()
	parts.append(tr("Settings"))
	if failed:
		status_label.text = tr("Delete failed")
	else:
		status_label.text = tr("DEV_DELETED_LAYER") % ", ".join(PackedStringArray(parts))


func _persist_run_now(slot: int) -> Error:
	var scene := get_tree().current_scene
	if scene != null and scene.has_method("persist_run_progress"):
		scene.persist_run_progress(slot)
		if SaveManager.has_run(slot):
			return OK
		return ERR_DOES_NOT_EXIST
	if not SaveManager.has_run(slot):
		return ERR_DOES_NOT_EXIST
	var run := SaveManager.load_run(slot)
	var inv := _inventory()
	if inv != null:
		run.merge(SaveSerializer.run_equipment_snapshot(inv), true)
	return SaveManager.save_run(slot, run)


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
