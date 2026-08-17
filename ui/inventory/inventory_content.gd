extends Control

signal request_close
signal item_equipped(item: ItemData, slot: String)
signal item_discarded(item: ItemData)

const SLOT_SCENE := preload("res://ui/inventory/components/inventory_slot.tscn")
const CATEGORY_TAB_SCENE := preload("res://ui/inventory/components/category_tab.tscn")
const EQUIPMENT_SLOT_SCENE := preload("res://ui/inventory/components/equipment_slot.tscn")
const STAT_ROW_SCENE := preload("res://ui/stats/components/stat_row.tscn")

const TAB_MODIFIERS := "modifiers"
const TAB_EQUIPMENT := "equipment"
const FOCUS_BAG := "bag"
const FOCUS_EQUIP := "equip"

const CATEGORY_DEFS: Array[Dictionary] = [
	{
		"id": TAB_EQUIPMENT,
		"categories": [ItemData.ItemCategory.WEAPON, ItemData.ItemCategory.ARMOR],
		"label": "Equipment",
		"icon_col": 3,
		"icon_row": 0,
	},
	{
		"id": "consumable",
		"categories": [ItemData.ItemCategory.CONSUMABLE],
		"label": "CON",
		"icon_col": 8,
		"icon_row": 16,
	},
	{
		"id": "material",
		"categories": [ItemData.ItemCategory.MATERIAL],
		"label": "MAT",
		"icon_col": 0,
		"icon_row": 12,
	},
	{
		"id": "tool",
		"categories": [ItemData.ItemCategory.TOOL],
		"label": "TOL",
		"icon_col": 1,
		"icon_row": 96,
	},
	{"id": TAB_MODIFIERS, "label": "MOD", "icon_col": 13, "icon_row": 0},
]

const SORT_MODES: Array[String] = ["time", "name", "weight", "rarity"]
const GRID_COLUMNS := 5
const EQUIP_SLOT_ROWS: Array = [
	["main_hand", "off_hand"],
	["head", "chest", "legs"],
	["ring_1", "ring_2"],
	["tool_1", "tool_2"],
]

var inventory: InventoryData
var character_stats: CharacterStats

@onready var category_tabs: HBoxContainer = %CategoryTabs
@onready var item_grid: GridContainer = %ItemGrid
@onready var bag_capacity_label: Label = %BagCapacityLabel
@onready var detail_panel: ItemDetailPanel = %ItemDetailPanel
@onready var modifier_detail: ModifierDetailPanel = %ModifierDetailPanel
@onready var attribute_list: VBoxContainer = %AttributeList
@onready var load_indicator: Label = %LoadIndicator
@onready var equipment_layout: VBoxContainer = %EquipmentLayout
@onready var equipment_title: Label = %EquipmentTitle
@onready var weight_title: Label = %WeightTitle
@onready var weight_bar: ProgressBar = %WeightBar

var _ui_manager: UIManager
var _footer: FooterPrompts
var _slots: Array[InventorySlot] = []
var _category_tab_nodes: Array[CategoryTab] = []
var _equipment_slots: Dictionary = {}
var _selected_grid_index: int = 0
var _selected_equip_slot: String = ""
var _bag_tab_id: String = TAB_EQUIPMENT
var _footer_connected: bool = false
var _rune_catalog: RuneCatalog = RuneCatalog.new()
var _gem_catalog: GemCatalog = GemCatalog.new()
var _resonance_service: ResonanceService = ResonanceService.new()

var _focus_zone: String = FOCUS_BAG


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED
	UIPopupLayout.apply_column_panels([$Body/LeftColumn, $Body/CenterColumn, $Body/RightColumn])
	UIPopupLayout.flatten_inner_panel(detail_panel)
	UIPopupLayout.flatten_inner_panel(modifier_detail)
	UIPopupLayout.apply_slot_grid_pad(%ItemGridPad)
	UIPopupLayout.apply_slot_grid_pad(%EquipmentLayoutPad)
	_apply_right_scroll_gutter()
	_build_category_tabs()
	_build_grid()
	_build_equipment_slots()
	_build_attribute_list()
	_setup_weight_bar()
	_refresh_equipment_title()
	_refresh_weight_title()
	LocaleManager.locale_changed.connect(_on_locale_changed)


func setup(ui_manager: UIManager, footer: FooterPrompts) -> void:
	_ui_manager = ui_manager
	_footer = footer
	if _ui_manager and not _ui_manager.input_device_changed.is_connected(_on_input_device_changed):
		_ui_manager.input_device_changed.connect(_on_input_device_changed)
	if _footer and not _footer_connected:
		_footer.prompt_activated.connect(_on_footer_prompt)
		_footer_connected = true


func activate(stats: CharacterStats, inventory_data: InventoryData) -> void:
	character_stats = stats
	inventory = inventory_data
	_bag_tab_id = _tab_id_from_category(inventory.current_category)
	_focus_zone = FOCUS_BAG
	visible = true
	process_mode = Node.PROCESS_MODE_INHERIT
	_refresh_all()


func deactivate() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED


func _is_using_gamepad() -> bool:
	return _ui_manager.using_gamepad if _ui_manager else false


func _is_modifier_tab() -> bool:
	return _bag_tab_id == TAB_MODIFIERS


func _on_input_device_changed(_using_gamepad: bool) -> void:
	if visible:
		_update_footer.call_deferred()


func _on_locale_changed(_locale: String) -> void:
	_refresh_category_tab_labels()
	_refresh_equipment_title()
	_refresh_weight_title()
	if inventory:
		_refresh_all()
	elif visible:
		_update_footer()


func _update_footer() -> void:
	if not _footer:
		return
	var using_gamepad := _is_using_gamepad()
	if _is_modifier_tab():
		_footer.set_prompts([
			{"action": "discard", "button": "X" if using_gamepad else "X", "label": tr("DISCARD")},
			{"action": "close", "button": "B" if using_gamepad else "Esc", "label": tr("CLOSE")},
		])
		return
	var sort_key := inventory.sort_mode.to_upper() if inventory else "TIME"
	_footer.set_prompts([
		{"action": "sort", "button": "L3" if using_gamepad else "S", "label": tr("SORT: %s") % tr(sort_key)},
		{"action": "equip", "button": "A" if using_gamepad else "Enter", "label": tr("EQUIP / UNEQUIP")},
		{"action": "discard", "button": "X" if using_gamepad else "X", "label": tr("DISCARD")},
		{"action": "close", "button": "B" if using_gamepad else "Esc", "label": tr("CLOSE")},
	])


func _apply_right_scroll_gutter() -> void:
	var bar: VScrollBar = %RightScroll.get_v_scroll_bar()
	var width := 12
	if bar:
		width = maxi(int(ceili(bar.get_combined_minimum_size().x)), 12)
	%RightScrollGutter.add_theme_constant_override("margin_right", width)


func _build_category_tabs() -> void:
	for child in category_tabs.get_children():
		child.queue_free()
	_category_tab_nodes.clear()
	for def in CATEGORY_DEFS:
		var tab: CategoryTab = CATEGORY_TAB_SCENE.instantiate()
		category_tabs.add_child(tab)
		tab.setup(
			str(def["id"]),
			tr(str(def["label"])),
			ItemData.sheet_icon(int(def.get("icon_col", 5)), int(def.get("icon_row", 0)))
		)
		tab.tab_selected.connect(_on_tab_selected)
		_category_tab_nodes.append(tab)


func _build_grid() -> void:
	for child in item_grid.get_children():
		child.queue_free()
	_slots.clear()
	for i in range(InventoryData.GRID_SIZE):
		var slot: InventorySlot = SLOT_SCENE.instantiate()
		# Keep 80px — FILL stretches grid cells and eats 1px borders.
		slot.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		slot.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		item_grid.add_child(slot)
		slot.setup(i)
		slot.slot_pressed.connect(_on_slot_pressed)
		slot.slot_activated.connect(_on_slot_activated)
		_slots.append(slot)


func _build_equipment_slots() -> void:
	for child in equipment_layout.get_children():
		child.queue_free()
	_equipment_slots.clear()
	for row_ids in EQUIP_SLOT_ROWS:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		equipment_layout.add_child(row)
		for slot_id in row_ids:
			var id := str(slot_id)
			var slot: EquipmentSlot = EQUIPMENT_SLOT_SCENE.instantiate()
			# Keep 80px — FILL stretches the 3-slot row into Scroll clip.
			slot.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
			row.add_child(slot)
			slot.setup(id)
			slot.slot_pressed.connect(_on_equipment_pressed)
			slot.slot_activated.connect(_on_equipment_activated)
			_equipment_slots[id] = slot


func _build_attribute_list() -> void:
	for child in attribute_list.get_children():
		child.queue_free()
	for attr_id in CharacterStats.ATTRIBUTE_IDS:
		if attr_id == "health" or attr_id == "equip_load":
			continue
		var row: StatRow = STAT_ROW_SCENE.instantiate()
		attribute_list.add_child(row)
		row.name = "Attr_%s" % attr_id


func _refresh_all() -> void:
	if not inventory:
		return
	inventory.ensure_grid_size()
	_selected_grid_index = clampi(_selected_grid_index, 0, InventoryData.GRID_SIZE - 1)
	if detail_panel:
		detail_panel.bind_socket_context(inventory, _rune_catalog, _gem_catalog)
	if character_stats:
		_refresh_attributes()
		_refresh_load_indicator()
	_update_category_tabs()
	_refresh_bag_capacity()
	_refresh_grid()
	_refresh_equipment()
	_update_footer()


func _refresh_attributes() -> void:
	if not character_stats:
		return
	for attr_id in CharacterStats.ATTRIBUTE_IDS:
		if attr_id == "health" or attr_id == "equip_load":
			continue
		if not attribute_list.has_node("Attr_%s" % attr_id):
			continue
		var row: StatRow = attribute_list.get_node("Attr_%s" % attr_id)
		row.setup(
			attr_id,
			CharacterStats.get_attribute_label(attr_id),
			character_stats.attributes.get(attr_id, 0)
		)


func _refresh_load_indicator() -> void:
	if character_stats and inventory:
		CombatStatsBuilder.build(character_stats, inventory)
	if character_stats == null:
		if load_indicator:
			load_indicator.text = tr("Normal")
		if weight_bar:
			weight_bar.max_value = 1.0
			weight_bar.value = 0.0
		return
	if load_indicator:
		load_indicator.text = character_stats.get_weight_class_label()
	if weight_bar:
		weight_bar.max_value = maxf(character_stats.weight_max, 0.001)
		weight_bar.value = clampf(character_stats.weight_current, 0.0, weight_bar.max_value)


func _setup_weight_bar() -> void:
	if weight_bar == null:
		return
	var bg := StyleBoxFlat.new()
	bg.bg_color = UIColors.SLOT_BG_SOLID
	bg.set_corner_radius_all(1)
	var fill := StyleBoxFlat.new()
	fill.bg_color = UIColors.GOLD
	fill.set_corner_radius_all(1)
	weight_bar.add_theme_stylebox_override("background", bg)
	weight_bar.add_theme_stylebox_override("fill", fill)


func _refresh_equipment_title() -> void:
	if equipment_title:
		equipment_title.text = tr("INV_EQUIPPED_TITLE")


func _refresh_weight_title() -> void:
	if weight_title:
		weight_title.text = tr("WEIGHT")


func _update_category_tabs() -> void:
	_refresh_category_tab_labels()
	if not inventory:
		return
	for tab in _category_tab_nodes:
		tab.set_active(tab.tab_id == _bag_tab_id)


func _refresh_category_tab_labels() -> void:
	for i in range(_category_tab_nodes.size()):
		if i >= CATEGORY_DEFS.size():
			break
		_category_tab_nodes[i].text = tr(str(CATEGORY_DEFS[i]["label"]))


func _refresh_bag_capacity() -> void:
	if bag_capacity_label == null or inventory == null:
		return
	if _is_modifier_tab():
		bag_capacity_label.text = tr("BAG_CAPACITY") % [inventory.modifier_count(), InventoryData.GRID_SIZE]
		return
	var key := _active_bag_key()
	bag_capacity_label.text = tr("BAG_CAPACITY") % [inventory.bag_used_count(key), InventoryData.GRID_SIZE]


func _modifier_entries() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if inventory == null:
		return out
	for i in range(inventory.runes.size()):
		var ri: RuneInstance = inventory.runes[i] as RuneInstance
		if ri == null:
			continue
		var data: RuneData = _rune_catalog.get_rune(ri.rune_id)
		out.append({
			"kind": "rune",
			"bag_index": i,
			"instance": ri,
			"rune": data,
			"uid": ri.instance_uid,
			"registered": ri.registered,
			"display_name": tr(data.display_name) if data else ri.rune_id,
			"rarity": ItemData.ItemRarity.COMMON,
		})
	for i in range(inventory.gems.size()):
		var gi: GemInstance = inventory.gems[i] as GemInstance
		if gi == null:
			continue
		var gdata: GemData = _gem_catalog.get_gem(gi.gem_id)
		out.append({
			"kind": "gem",
			"bag_index": i,
			"instance": gi,
			"gem": gdata,
			"uid": gi.instance_uid,
			"registered": gi.registered,
			"display_name": tr(gdata.display_name) if gdata else gi.gem_id,
			"rarity": ItemData.ItemRarity.COMMON,
		})
	return out


func _modifier_icon(entry: Dictionary) -> Texture2D:
	if str(entry.get("kind", "")) == "rune":
		var rune: RuneData = entry.get("rune") as RuneData
		return rune.icon if rune else null
	var gem: GemData = entry.get("gem") as GemData
	return gem.icon if gem else null


func _refresh_grid() -> void:
	inventory.ensure_grid_size()
	if _is_modifier_tab():
		_refresh_modifier_grid()
		return
	var bag := inventory.get_bag(_active_bag_key())
	for i in range(_slots.size()):
		var slot := _slots[i]
		slot.visible = true
		slot.setup(i)
		var item: ItemData = null
		if i < bag.size():
			item = bag[i] as ItemData
		slot.set_item(item)
		slot.modulate = Color.WHITE
		slot.set_selected(
			i == _selected_grid_index
			and _focus_zone == FOCUS_BAG
			and _selected_equip_slot == ""
		)
	_refresh_detail_panel()


func _refresh_modifier_grid() -> void:
	var entries := _modifier_entries()
	for i in range(_slots.size()):
		var slot := _slots[i]
		slot.visible = true
		slot.setup(i)
		if i < entries.size():
			var entry: Dictionary = entries[i]
			var uid := str(entry.get("uid", ""))
			slot.set_modifier_entry(
				str(entry.get("display_name", "")),
				entry.get("rarity", ItemData.ItemRarity.COMMON) as ItemData.ItemRarity,
				inventory.is_uid_socketed(uid),
				_modifier_icon(entry)
			)
			slot.modulate = Color.WHITE
		else:
			slot.clear_entry()
			slot.modulate = Color.WHITE
		slot.set_selected(
			i == _selected_grid_index
			and _focus_zone == FOCUS_BAG
			and _selected_equip_slot == ""
		)
	_refresh_detail_panel()


func _refresh_detail_panel() -> void:
	if _selected_equip_slot != "":
		_show_item_detail(inventory.equipped.get(_selected_equip_slot) as ItemData)
		return
	if _is_modifier_tab():
		var entries := _modifier_entries()
		if _selected_grid_index < 0 or _selected_grid_index >= entries.size():
			_show_modifier_detail(null, "")
			return
		var entry: Dictionary = entries[_selected_grid_index]
		_show_modifier_detail(entry, str(entry.get("kind", "")))
		return
	_show_item_detail(_get_selected_item())


func _show_item_detail(item: ItemData) -> void:
	if detail_panel:
		detail_panel.visible = true
		detail_panel.bind_socket_context(inventory, _rune_catalog, _gem_catalog)
		var compare_with: ItemData = inventory.equipped_in_same_slot(item) if inventory else null
		detail_panel.set_item(item, compare_with)
		var equipped_main: ItemData = inventory.equipped.get("main_hand") as ItemData if inventory else null
		if item != null and item == equipped_main:
			var result := _resonance_service.rebuild_main_hand_skills(
				inventory, _rune_catalog, _gem_catalog
			)
			detail_panel.set_item(item, compare_with)
			detail_panel.set_resonance_state(result.state_key())
		else:
			detail_panel.set_resonance_state("")
	if modifier_detail:
		modifier_detail.visible = false
		modifier_detail.clear()


func _show_modifier_detail(entry: Variant, kind: String) -> void:
	if detail_panel:
		detail_panel.visible = false
		detail_panel.set_item(null)
	if modifier_detail == null:
		return
	modifier_detail.visible = true
	if entry == null or kind.is_empty():
		modifier_detail.show_message(tr("Select an item"))
		return
	var data: Dictionary = entry as Dictionary
	if kind == "rune":
		modifier_detail.set_rune(data.get("rune") as RuneData)
	elif kind == "gem":
		modifier_detail.set_gem(data.get("gem") as GemData)
	else:
		modifier_detail.clear()


func _get_selected_grid_index() -> int:
	if inventory == null:
		return -1
	if _is_modifier_tab():
		return _selected_grid_index
	if _selected_grid_index < 0 or _selected_grid_index >= InventoryData.GRID_SIZE:
		return -1
	return _selected_grid_index


func _get_selected_item() -> ItemData:
	if _is_modifier_tab():
		return null
	var index := _get_selected_grid_index()
	if index < 0:
		return null
	return inventory.get_item(_active_bag_key(), index)


func _refresh_equipment() -> void:
	for slot_id in _equipment_slots.keys():
		var slot: EquipmentSlot = _equipment_slots[slot_id]
		var item: ItemData = inventory.equipped.get(slot_id)
		slot.set_item(item)
		var blocked := false
		if slot_id == "off_hand" and inventory.is_two_handed_equipped():
			blocked = true
		slot.set_blocked(blocked)
		slot.modulate = Color.WHITE
		slot.set_selected(slot_id == _selected_equip_slot and _focus_zone == FOCUS_EQUIP)


func _select_grid_index(grid_index: int) -> void:
	_selected_grid_index = clampi(grid_index, 0, InventoryData.GRID_SIZE - 1)
	_focus_zone = FOCUS_BAG
	if _selected_equip_slot != "":
		_selected_equip_slot = ""
		_refresh_equipment()
	_refresh_grid()
	_update_footer()


func _on_tab_selected(tab_id: String) -> void:
	_bag_tab_id = tab_id
	_focus_zone = FOCUS_BAG
	if _is_modifier_tab():
		_selected_grid_index = 0
	else:
		inventory.current_category = _primary_category_for_tab(tab_id)
		_selected_grid_index = 0
	_refresh_all()


func _active_bag_key() -> String:
	if _is_modifier_tab():
		return ""
	if InventoryData.BAG_KEYS.has(_bag_tab_id):
		return _bag_tab_id
	return InventoryData.BAG_EQUIPMENT


func _categories_for_tab(tab_id: String) -> Array:
	for def in CATEGORY_DEFS:
		if str(def["id"]) == tab_id and def.has("categories"):
			return def["categories"] as Array
	return [ItemData.ItemCategory.WEAPON]


func _primary_category_for_tab(tab_id: String) -> ItemData.ItemCategory:
	var cats := _categories_for_tab(tab_id)
	if cats.is_empty():
		return ItemData.ItemCategory.WEAPON
	return cats[0] as ItemData.ItemCategory


func _tab_id_from_category(category: ItemData.ItemCategory) -> String:
	for def in CATEGORY_DEFS:
		if not def.has("categories"):
			continue
		if (def["categories"] as Array).has(category):
			return str(def["id"])
	return TAB_EQUIPMENT


func _on_slot_pressed(index: int) -> void:
	if index < 0:
		return
	_selected_equip_slot = ""
	_refresh_equipment()
	_select_grid_index(index)


func _on_slot_activated(index: int) -> void:
	_on_slot_pressed(index)
	if not _is_modifier_tab():
		_try_equip()


func _on_equipment_pressed(slot_id: String) -> void:
	_focus_equipment_slot(slot_id)


func _on_equipment_activated(slot_id: String) -> void:
	_unequip_slot(slot_id)


func _on_footer_prompt(action: String) -> void:
	if not visible:
		return
	match action:
		"sort":
			if not _is_modifier_tab():
				_cycle_sort()
		"equip":
			if not _is_modifier_tab():
				_try_equip()
		"discard":
			_try_discard()
		"close":
			request_close.emit()


func _try_equip() -> void:
	if _is_modifier_tab():
		return
	if _selected_equip_slot != "":
		_unequip_slot(_selected_equip_slot)
		return
	var item := _get_selected_item()
	if not item:
		return
	for slot_id in inventory.equipped.keys():
		if inventory.equipped[slot_id] == item:
			_unequip_slot(slot_id)
			return
	var slot_id := inventory.get_slot_for_equip(item)
	if slot_id == "":
		return
	var grid_index := _get_selected_grid_index()
	if not inventory.equip_from_bag(_active_bag_key(), grid_index):
		return
	item_equipped.emit(item, slot_id)
	_rebuild_resonance()
	_refresh_all()


func _unequip_slot(slot_id: String) -> void:
	var item: ItemData = inventory.equipped.get(slot_id)
	if not item:
		return
	if inventory.try_place_item(item) < 0:
		return
	inventory.equipped[slot_id] = null
	item_equipped.emit(item, slot_id)
	_rebuild_resonance()
	_refresh_all()


func _rebuild_resonance() -> void:
	if inventory == null:
		return
	_resonance_service.rebuild_main_hand_skills(inventory, _rune_catalog, _gem_catalog)
	if _ui_manager:
		_ui_manager.refresh_hud()


func _try_discard() -> void:
	if _is_modifier_tab():
		_try_discard_modifier()
		return
	var grid_index := _get_selected_grid_index()
	if grid_index < 0:
		return
	var bag_key := _active_bag_key()
	var item: ItemData = inventory.get_item(bag_key, grid_index)
	if not item:
		return
	inventory.set_item(bag_key, grid_index, null)
	item_discarded.emit(item)
	_refresh_all()


func _try_discard_modifier() -> void:
	var entries := _modifier_entries()
	if _selected_grid_index < 0 or _selected_grid_index >= entries.size():
		return
	var entry: Dictionary = entries[_selected_grid_index]
	var kind := str(entry.get("kind", ""))
	var uid := str(entry.get("uid", ""))
	if uid.is_empty():
		return
	if kind == "rune":
		inventory.remove_rune_uid(uid)
	elif kind == "gem":
		inventory.remove_gem_uid(uid)
	else:
		return
	_selected_grid_index = clampi(_selected_grid_index, 0, maxi(entries.size() - 2, 0))
	_rebuild_resonance()
	_refresh_all()


func _cycle_sort() -> void:
	if _is_modifier_tab():
		return
	var current := SORT_MODES.find(inventory.sort_mode)
	var next := (current + 1) % SORT_MODES.size()
	inventory.sort_mode = SORT_MODES[next]
	inventory.sort_bag(_active_bag_key())
	_refresh_all()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		request_close.emit()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("inventory_equip"):
		if not _is_modifier_tab():
			_try_equip()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("inventory_discard"):
		_try_discard()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("inventory_sort"):
		_cycle_sort()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("inventory_category_prev"):
		_cycle_tab(-1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("inventory_category_next"):
		_cycle_tab(1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_left"):
		_move_focus(-1, 0)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_right"):
		_move_focus(1, 0)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_up"):
		_move_focus(0, -1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_down"):
		_move_focus(0, 1)
		get_viewport().set_input_as_handled()


func _move_focus(delta_x: int, delta_y: int) -> void:
	if _focus_zone == FOCUS_EQUIP or _selected_equip_slot != "":
		_move_equipment_focus(delta_x, delta_y)
	else:
		_move_bag_focus(delta_x, delta_y)


func _move_bag_focus(delta_x: int, delta_y: int) -> void:
	if delta_x > 0 and _is_bag_right_edge():
		_focus_equipment_from_bag()
		return
	var next := _selected_grid_index + delta_x + delta_y * GRID_COLUMNS
	_select_grid_index(clampi(next, 0, InventoryData.GRID_SIZE - 1))


func _is_bag_right_edge() -> bool:
	var column := _selected_grid_index % GRID_COLUMNS
	return column == GRID_COLUMNS - 1


func _focus_equipment_from_bag() -> void:
	var bag_row := _selected_grid_index / GRID_COLUMNS
	var equip_row := clampi(int(bag_row * EQUIP_SLOT_ROWS.size() / 5), 0, EQUIP_SLOT_ROWS.size() - 1)
	_focus_equipment_slot(str(EQUIP_SLOT_ROWS[equip_row][0]))


func _focus_equipment_slot(slot_id: String) -> void:
	_selected_equip_slot = slot_id
	_focus_zone = FOCUS_EQUIP
	_refresh_equipment()
	_refresh_grid()
	_update_footer()


func _focus_bag_from_equipment() -> void:
	var pos := _equip_slot_pos(_selected_equip_slot)
	var bag_row := clampi(pos.y * 2, 0, 4)
	var target := bag_row * GRID_COLUMNS + GRID_COLUMNS - 1
	target = clampi(target, 0, InventoryData.GRID_SIZE - 1)
	_selected_equip_slot = ""
	_focus_zone = FOCUS_BAG
	_refresh_equipment()
	_select_grid_index(target)


func _equip_slot_pos(slot_id: String) -> Vector2i:
	for r in EQUIP_SLOT_ROWS.size():
		var row: Array = EQUIP_SLOT_ROWS[r]
		var c := row.find(slot_id)
		if c >= 0:
			return Vector2i(c, r)
	return Vector2i.ZERO


func _move_equipment_focus(delta_x: int, delta_y: int) -> void:
	var pos := _equip_slot_pos(_selected_equip_slot)
	var row: Array = EQUIP_SLOT_ROWS[pos.y]
	if delta_x < 0 and pos.x == 0:
		_focus_bag_from_equipment()
		return
	if delta_x != 0:
		var next_col := clampi(pos.x + delta_x, 0, row.size() - 1)
		_focus_equipment_slot(str(row[next_col]))
		return
	var next_row := clampi(pos.y + delta_y, 0, EQUIP_SLOT_ROWS.size() - 1)
	var next_slots: Array = EQUIP_SLOT_ROWS[next_row]
	var next_col2 := clampi(pos.x, 0, next_slots.size() - 1)
	_focus_equipment_slot(str(next_slots[next_col2]))


func _cycle_tab(direction: int) -> void:
	var current_index := 0
	for i in range(CATEGORY_DEFS.size()):
		if str(CATEGORY_DEFS[i]["id"]) == _bag_tab_id:
			current_index = i
			break
	var next_index := (current_index + direction) % CATEGORY_DEFS.size()
	_on_tab_selected(str(CATEGORY_DEFS[next_index]["id"]))
