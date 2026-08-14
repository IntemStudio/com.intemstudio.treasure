extends Control

signal request_close
signal item_equipped(item: ItemData, slot: String)
signal item_discarded(item: ItemData)

const SLOT_SCENE := preload("res://ui/inventory/components/inventory_slot.tscn")
const CATEGORY_TAB_SCENE := preload("res://ui/inventory/components/category_tab.tscn")
const EQUIPMENT_SLOT_SCENE := preload("res://ui/inventory/components/equipment_slot.tscn")
const STAT_ROW_SCENE := preload("res://ui/stats/components/stat_row.tscn")

const TAB_MODIFIERS := "modifiers"

const CATEGORY_DEFS: Array[Dictionary] = [
	{"id": "weapon", "category": ItemData.ItemCategory.WEAPON, "label": "WPN"},
	{"id": "armor", "category": ItemData.ItemCategory.ARMOR, "label": "ARM"},
	{"id": "consumable", "category": ItemData.ItemCategory.CONSUMABLE, "label": "CON"},
	{"id": "material", "category": ItemData.ItemCategory.MATERIAL, "label": "MAT"},
	{"id": "tool", "category": ItemData.ItemCategory.TOOL, "label": "TOL"},
	{"id": TAB_MODIFIERS, "label": "MOD"},
]

const SORT_MODES: Array[String] = ["time", "name", "weight", "rarity"]
const GRID_COLUMNS := 5
const EQUIP_COLUMNS := 3
const EQUIP_ROWS := 3

var inventory: InventoryData
var character_stats: CharacterStats

@onready var category_tabs: HBoxContainer = %CategoryTabs
@onready var item_grid: GridContainer = %ItemGrid
@onready var bag_capacity_label: Label = %BagCapacityLabel
@onready var detail_panel: ItemDetailPanel = %ItemDetailPanel
@onready var modifier_detail: ModifierDetailPanel = %ModifierDetailPanel
@onready var attribute_list: VBoxContainer = %AttributeList
@onready var load_indicator: Label = %LoadIndicator
@onready var character_preview: SubViewportContainer = %CharacterPreview
@onready var equipment_layout: GridContainer = %EquipmentLayout

var _ui_manager: UIManager
var _footer: FooterPrompts
var _slots: Array[InventorySlot] = []
var _category_tab_nodes: Array[CategoryTab] = []
var _equipment_slots: Dictionary = {}
var _selected_grid_index: int = 0
var _selected_equip_slot: String = ""
var _bag_tab_id: String = "weapon"
var _preview_root: Node3D
var _footer_connected: bool = false
var _rune_catalog: RuneCatalog = RuneCatalog.new()
var _gem_catalog: GemCatalog = GemCatalog.new()


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED
	_build_category_tabs()
	_build_grid()
	_build_equipment_slots()
	_build_attribute_list()
	_setup_character_preview()
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
	visible = true
	process_mode = Node.PROCESS_MODE_INHERIT
	_refresh_all()


func deactivate() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED
	_refresh_character_preview()


func _is_using_gamepad() -> bool:
	return _ui_manager.using_gamepad if _ui_manager else false


func _is_modifier_tab() -> bool:
	return _bag_tab_id == TAB_MODIFIERS


func _on_input_device_changed(_using_gamepad: bool) -> void:
	if visible:
		_update_footer.call_deferred()


func _on_locale_changed(_locale: String) -> void:
	_refresh_category_tab_labels()
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


func _build_category_tabs() -> void:
	for child in category_tabs.get_children():
		child.queue_free()
	_category_tab_nodes.clear()
	for def in CATEGORY_DEFS:
		var tab: CategoryTab = CATEGORY_TAB_SCENE.instantiate()
		category_tabs.add_child(tab)
		tab.setup(str(def["id"]), tr(str(def["label"])))
		tab.tab_selected.connect(_on_tab_selected)
		_category_tab_nodes.append(tab)


func _build_grid() -> void:
	for child in item_grid.get_children():
		child.queue_free()
	_slots.clear()
	for i in range(InventoryData.GRID_SIZE):
		var slot: InventorySlot = SLOT_SCENE.instantiate()
		item_grid.add_child(slot)
		slot.setup(i)
		slot.slot_pressed.connect(_on_slot_pressed)
		slot.slot_activated.connect(_on_slot_activated)
		slot.slot_discard_requested.connect(_on_slot_discard_requested)
		_slots.append(slot)


func _build_equipment_slots() -> void:
	for child in equipment_layout.get_children():
		child.queue_free()
	_equipment_slots.clear()
	for slot_id in InventoryData.EQUIP_SLOTS:
		var slot: EquipmentSlot = EQUIPMENT_SLOT_SCENE.instantiate()
		equipment_layout.add_child(slot)
		slot.setup(slot_id)
		slot.slot_pressed.connect(_on_equipment_pressed)
		slot.slot_activated.connect(_on_equipment_activated)
		_equipment_slots[slot_id] = slot


func _build_attribute_list() -> void:
	for child in attribute_list.get_children():
		child.queue_free()
	for attr_id in CharacterStats.ATTRIBUTE_IDS:
		if attr_id == "health" or attr_id == "equip_load":
			continue
		var row: StatRow = STAT_ROW_SCENE.instantiate()
		attribute_list.add_child(row)
		row.name = "Attr_%s" % attr_id


func _setup_character_preview() -> void:
	var viewport := character_preview.get_node("SubViewport") as SubViewport
	_preview_root = Node3D.new()
	_preview_root.name = "PreviewRoot"
	viewport.add_child(_preview_root)

	var camera := Camera3D.new()
	camera.position = Vector3(0, 1.2, 2.5)
	_preview_root.add_child(camera)
	camera.look_at(Vector3(0, 1, 0))

	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45, 30, 0)
	_preview_root.add_child(light)

	var body := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.height = 1.6
	capsule.radius = 0.35
	body.mesh = capsule
	body.position = Vector3(0, 0.9, 0)
	_preview_root.add_child(body)

	var shield := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.6, 0.8, 0.08)
	shield.mesh = box
	shield.position = Vector3(-0.55, 1.0, 0.2)
	_preview_root.add_child(shield)


func _refresh_all() -> void:
	if not inventory:
		return
	inventory.ensure_grid_size()
	_selected_grid_index = clampi(_selected_grid_index, 0, InventoryData.GRID_SIZE - 1)
	if character_stats:
		_refresh_attributes()
		_refresh_load_indicator()
	_update_category_tabs()
	_refresh_bag_capacity()
	_refresh_grid()
	_refresh_equipment()
	_refresh_character_preview()
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
			CharacterStats.get_attribute_label(attr_id),
			character_stats.attributes.get(attr_id, 0)
		)


func _refresh_load_indicator() -> void:
	if character_stats and inventory:
		CombatStatsBuilder.build(character_stats, inventory)
	if character_stats:
		load_indicator.text = character_stats.get_weight_class_label()
	elif inventory:
		load_indicator.text = tr("Normal")


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
		var count := inventory.runes.size() + inventory.gems.size()
		bag_capacity_label.text = tr("MOD_BAG_CAPACITY") % count
		return
	inventory.ensure_grid_size()
	var used := 0
	for item in inventory.slots:
		if item:
			used += 1
	bag_capacity_label.text = tr("BAG_CAPACITY") % [used, InventoryData.GRID_SIZE]


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
			"display_name": tr(data.display_name) if data else ri.rune_id,
			"rarity": data.rarity if data else ItemData.ItemRarity.COMMON,
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
			"display_name": tr(gdata.display_name) if gdata else gi.gem_id,
			"rarity": gdata.rarity if gdata else ItemData.ItemRarity.COMMON,
		})
	return out


func _refresh_grid() -> void:
	inventory.ensure_grid_size()
	if _is_modifier_tab():
		_refresh_modifier_grid()
		return
	for i in range(_slots.size()):
		var slot := _slots[i]
		slot.visible = true
		slot.setup(i)
		var item: ItemData = inventory.slots[i] if i < inventory.slots.size() else null
		slot.set_item(item)
		if item and item.category != inventory.current_category:
			slot.modulate = Color(1, 1, 1, 0.38)
		else:
			slot.modulate = Color(1, 1, 1, 1)
		slot.set_selected(i == _selected_grid_index and _selected_equip_slot == "")
	_refresh_detail_panel()


func _refresh_modifier_grid() -> void:
	var entries := _modifier_entries()
	for i in range(_slots.size()):
		var slot := _slots[i]
		slot.visible = true
		slot.setup(i)
		slot.modulate = Color(1, 1, 1, 1)
		if i < entries.size():
			var entry: Dictionary = entries[i]
			slot.set_modifier_entry(
				str(entry.get("display_name", "")),
				entry.get("rarity", ItemData.ItemRarity.COMMON) as ItemData.ItemRarity
			)
		else:
			slot.clear_entry()
		slot.set_selected(i == _selected_grid_index and _selected_equip_slot == "")
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
		var compare_with: ItemData = inventory.equipped_in_same_slot(item) if inventory else null
		detail_panel.set_item(item, compare_with)
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
	inventory.ensure_grid_size()
	if _selected_grid_index < 0 or _selected_grid_index >= inventory.slots.size():
		return -1
	return _selected_grid_index


func _get_selected_item() -> ItemData:
	if _is_modifier_tab():
		return null
	var index := _get_selected_grid_index()
	if index < 0:
		return null
	return inventory.slots[index]


func _refresh_equipment() -> void:
	for slot_id in _equipment_slots.keys():
		var slot: EquipmentSlot = _equipment_slots[slot_id]
		slot.set_item(inventory.equipped.get(slot_id))
		var blocked := slot_id == "off_hand" and inventory.is_two_handed_equipped()
		slot.set_blocked(blocked)
		slot.set_selected(slot_id == _selected_equip_slot)


func _refresh_character_preview() -> void:
	character_preview.visible = visible


func _select_grid_index(grid_index: int) -> void:
	_selected_grid_index = clampi(grid_index, 0, InventoryData.GRID_SIZE - 1)
	if _selected_equip_slot != "":
		_selected_equip_slot = ""
		_refresh_equipment()
	_refresh_grid()


func _on_tab_selected(tab_id: String) -> void:
	_bag_tab_id = tab_id
	if _is_modifier_tab():
		_selected_grid_index = 0
	else:
		var category := _category_from_tab_id(tab_id)
		inventory.current_category = category
		_selected_grid_index = _first_index_for_category(category)
	_refresh_all()


func _tab_id_from_category(category: ItemData.ItemCategory) -> String:
	for def in CATEGORY_DEFS:
		if def.has("category") and def["category"] == category:
			return str(def["id"])
	return "weapon"


func _category_from_tab_id(tab_id: String) -> ItemData.ItemCategory:
	for def in CATEGORY_DEFS:
		if str(def["id"]) == tab_id and def.has("category"):
			return def["category"] as ItemData.ItemCategory
	return ItemData.ItemCategory.WEAPON


func _first_index_for_category(category: ItemData.ItemCategory) -> int:
	if inventory == null:
		return 0
	inventory.ensure_grid_size()
	for i in range(inventory.slots.size()):
		var item: ItemData = inventory.slots[i]
		if item and item.category == category:
			return i
	return 0


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


func _on_slot_discard_requested(index: int) -> void:
	_on_slot_pressed(index)
	_try_discard()


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
	if not inventory.equip_from_bag(grid_index):
		return
	item_equipped.emit(item, slot_id)
	_rebuild_resonance()
	_refresh_all()


func _unequip_slot(slot_id: String) -> void:
	var item: ItemData = inventory.equipped.get(slot_id)
	if not item:
		return
	inventory.equipped[slot_id] = null
	var empty_index := inventory.find_empty_slot()
	if empty_index >= 0:
		inventory.slots[empty_index] = item
	item_equipped.emit(item, slot_id)
	_rebuild_resonance()
	_refresh_all()


func _rebuild_resonance() -> void:
	if inventory == null:
		return
	var service := ResonanceService.new()
	service.rebuild_main_hand_skills(inventory, _rune_catalog, _gem_catalog)
	if _ui_manager:
		_ui_manager.refresh_character_views()


func _try_discard() -> void:
	if _is_modifier_tab():
		_try_discard_modifier()
		return
	var grid_index := _get_selected_grid_index()
	if grid_index < 0:
		return
	var item: ItemData = inventory.slots[grid_index]
	if not item:
		return
	inventory.slots[grid_index] = null
	item_discarded.emit(item)
	_refresh_all()


func _try_discard_modifier() -> void:
	var entries := _modifier_entries()
	if _selected_grid_index < 0 or _selected_grid_index >= entries.size():
		return
	var entry: Dictionary = entries[_selected_grid_index]
	var kind := str(entry.get("kind", ""))
	var bag_index: int = int(entry.get("bag_index", -1))
	if bag_index < 0:
		return
	if kind == "rune":
		if bag_index < inventory.runes.size():
			inventory.runes.remove_at(bag_index)
	elif kind == "gem":
		if bag_index < inventory.gems.size():
			inventory.gems.remove_at(bag_index)
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
	inventory.sort_slots()
	_refresh_all()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		request_close.emit()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("inventory_equip"):
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
	if _selected_equip_slot != "":
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
	var equip_row := clampi(bag_row / 2, 0, EQUIP_ROWS - 1)
	_focus_equipment_slot(InventoryData.EQUIP_SLOTS[equip_row * EQUIP_COLUMNS])


func _focus_equipment_slot(slot_id: String) -> void:
	_selected_equip_slot = slot_id
	_refresh_equipment()
	_refresh_grid()


func _focus_bag_from_equipment() -> void:
	var equip_index := InventoryData.EQUIP_SLOTS.find(_selected_equip_slot)
	var equip_row := maxi(equip_index, 0) / EQUIP_COLUMNS
	var bag_row := equip_row * 2
	var target := bag_row * GRID_COLUMNS + GRID_COLUMNS - 1
	target = clampi(target, 0, InventoryData.GRID_SIZE - 1)
	_selected_equip_slot = ""
	_refresh_equipment()
	_select_grid_index(target)


func _move_equipment_focus(delta_x: int, delta_y: int) -> void:
	var index := InventoryData.EQUIP_SLOTS.find(_selected_equip_slot)
	if index < 0:
		index = 0
	var column := index % EQUIP_COLUMNS
	var row := index / EQUIP_COLUMNS
	if delta_x < 0 and column == 0:
		_focus_bag_from_equipment()
		return
	var next_column := clampi(column + delta_x, 0, EQUIP_COLUMNS - 1)
	var next_row := clampi(row + delta_y, 0, EQUIP_ROWS - 1)
	_focus_equipment_slot(InventoryData.EQUIP_SLOTS[next_row * EQUIP_COLUMNS + next_column])


func _cycle_tab(direction: int) -> void:
	var current_index := 0
	for i in range(CATEGORY_DEFS.size()):
		if str(CATEGORY_DEFS[i]["id"]) == _bag_tab_id:
			current_index = i
			break
	var next_index := (current_index + direction) % CATEGORY_DEFS.size()
	_on_tab_selected(str(CATEGORY_DEFS[next_index]["id"]))
