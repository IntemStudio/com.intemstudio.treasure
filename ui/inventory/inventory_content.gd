extends Control

signal request_close
signal item_equipped(item: ItemData, slot: String)
signal item_discarded(item: ItemData)

const SLOT_SCENE := preload("res://ui/inventory/components/inventory_slot.tscn")
const CATEGORY_TAB_SCENE := preload("res://ui/inventory/components/category_tab.tscn")
const EQUIPMENT_SLOT_SCENE := preload("res://ui/inventory/components/equipment_slot.tscn")
const STAT_ROW_SCENE := preload("res://ui/stats/components/stat_row.tscn")

const TAB_MODIFIERS := "modifiers"
const MODE_NONE := ""
const MODE_PICK_MODIFIER := "pick_modifier"
const MODE_PICK_SLOT := "pick_slot"
const FOCUS_BAG := "bag"
const FOCUS_EQUIP := "equip"
const FOCUS_SOCKETS := "sockets"

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
var _resonance_service: ResonanceService = ResonanceService.new()

var _focus_zone: String = FOCUS_BAG
var _mode: String = MODE_NONE
var _socket_item: ItemData
var _socket_kind: String = ""
var _socket_index: int = -1
var _selected_socket_row: int = 0
var _pick_mod_kind: String = ""
var _pick_mod_uid: String = ""
var _detail_wired: bool = false


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
	_wire_detail_panel()


func activate(stats: CharacterStats, inventory_data: InventoryData) -> void:
	character_stats = stats
	inventory = inventory_data
	_bag_tab_id = _tab_id_from_category(inventory.current_category)
	_cancel_pick_mode()
	_focus_zone = FOCUS_BAG
	visible = true
	process_mode = Node.PROCESS_MODE_INHERIT
	_wire_detail_panel()
	_refresh_all()


func deactivate() -> void:
	_cancel_pick_mode()
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED
	_refresh_character_preview()


func _wire_detail_panel() -> void:
	if detail_panel == null or _detail_wired:
		return
	detail_panel.socket_row_pressed.connect(_on_socket_row_pressed)
	detail_panel.socket_row_activated.connect(_on_socket_row_activated)
	_detail_wired = true


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
	if _mode == MODE_PICK_MODIFIER or _mode == MODE_PICK_SLOT:
		_footer.set_prompts([
			{"action": "socket", "button": "A" if using_gamepad else "Enter", "label": tr("SOCKET")},
			{"action": "back", "button": "B" if using_gamepad else "Esc", "label": tr("BACK")},
		])
		return
	if _focus_zone == FOCUS_SOCKETS:
		var filled := _selected_socket_filled()
		_footer.set_prompts([
			{
				"action": "socket",
				"button": "A" if using_gamepad else "Enter",
				"label": tr("UNSOCKET") if filled else tr("SOCKET"),
			},
			{"action": "equip", "button": "Y" if using_gamepad else "E", "label": tr("EQUIP / UNEQUIP")},
			{"action": "discard", "button": "X" if using_gamepad else "X", "label": tr("DISCARD")},
			{"action": "close", "button": "B" if using_gamepad else "Esc", "label": tr("CLOSE")},
		])
		return
	if _is_modifier_tab():
		_footer.set_prompts([
			{"action": "socket", "button": "A" if using_gamepad else "Enter", "label": tr("SOCKET")},
			{"action": "discard", "button": "X" if using_gamepad else "X", "label": tr("DISCARD")},
			{"action": "close", "button": "B" if using_gamepad else "Esc", "label": tr("CLOSE")},
		])
		return
	var sort_key := inventory.sort_mode.to_upper() if inventory else "TIME"
	var prompts: Array = [
		{"action": "sort", "button": "L3" if using_gamepad else "S", "label": tr("SORT: %s") % tr(sort_key)},
		{"action": "equip", "button": "A" if using_gamepad else "Enter", "label": tr("EQUIP / UNEQUIP")},
	]
	if _current_item_has_sockets():
		prompts.append({
			"action": "socket",
			"button": "Y" if using_gamepad else "F",
			"label": tr("SOCKET"),
		})
	prompts.append({"action": "discard", "button": "X" if using_gamepad else "X", "label": tr("DISCARD")})
	prompts.append({"action": "close", "button": "B" if using_gamepad else "Esc", "label": tr("CLOSE")})
	_footer.set_prompts(prompts)


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
	if detail_panel:
		detail_panel.bind_socket_context(inventory, _rune_catalog, _gem_catalog)
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
			"uid": ri.instance_uid,
			"registered": ri.registered,
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
			"uid": gi.instance_uid,
			"registered": gi.registered,
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
		var dim := false
		if item and item.category != inventory.current_category:
			dim = true
		if _mode == MODE_PICK_SLOT and item != null:
			dim = not _item_accepts_pick_modifier(item)
		elif _mode == MODE_PICK_SLOT and item == null:
			dim = true
		slot.modulate = Color(1, 1, 1, 0.38) if dim else Color(1, 1, 1, 1)
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
				inventory.is_uid_socketed(uid)
			)
			var dim := false
			if _mode == MODE_PICK_MODIFIER:
				dim = not _modifier_compatible_for_pick(entry)
			slot.modulate = Color(1, 1, 1, 0.38) if dim else Color(1, 1, 1, 1)
		else:
			slot.clear_entry()
			slot.modulate = Color(1, 1, 1, 1)
		slot.set_selected(
			i == _selected_grid_index
			and _focus_zone == FOCUS_BAG
			and _selected_equip_slot == ""
		)
	_refresh_detail_panel()


func _refresh_detail_panel() -> void:
	if _focus_zone == FOCUS_SOCKETS and _socket_item != null:
		_show_item_detail(_socket_item)
		return
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
		if _focus_zone == FOCUS_SOCKETS and _socket_kind != "":
			detail_panel.set_selected_socket(_socket_kind, _socket_index)
		elif detail_panel.get_socket_row_count() > 0:
			var row := detail_panel.get_socket_row_at(
				clampi(_selected_socket_row, 0, detail_panel.get_socket_row_count() - 1)
			)
			if not row.is_empty():
				detail_panel.set_selected_socket(str(row.get("kind", "")), int(row.get("index", 0)))
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


func _current_detail_item() -> ItemData:
	if _socket_item != null and (_focus_zone == FOCUS_SOCKETS or _mode == MODE_PICK_MODIFIER):
		return _socket_item
	if _selected_equip_slot != "":
		return inventory.equipped.get(_selected_equip_slot) as ItemData
	return _get_selected_item()


func _current_item_has_sockets() -> bool:
	var item := _current_detail_item()
	if item == null or inventory == null:
		return false
	return not inventory.list_socket_rows(item).is_empty()


func _selected_socket_filled() -> bool:
	var item := _socket_item if _socket_item else _current_detail_item()
	if item == null or _socket_kind.is_empty() or inventory == null:
		return false
	for row in inventory.list_socket_rows(item):
		if str(row.get("kind", "")) == _socket_kind and int(row.get("index", -1)) == _socket_index:
			return not str(row.get("instance_uid", "")).is_empty()
	return false


func _refresh_equipment() -> void:
	for slot_id in _equipment_slots.keys():
		var slot: EquipmentSlot = _equipment_slots[slot_id]
		var item: ItemData = inventory.equipped.get(slot_id)
		slot.set_item(item)
		var blocked := false
		if slot_id == "off_hand" and inventory.is_two_handed_equipped():
			blocked = true
		slot.set_blocked(blocked)
		var dim := false
		if _mode == MODE_PICK_SLOT and item != null:
			dim = not _item_accepts_pick_modifier(item)
		elif _mode == MODE_PICK_SLOT and item == null:
			dim = true
		slot.modulate = Color(1, 1, 1, 0.38) if dim else Color(1, 1, 1, 1)
		slot.set_selected(slot_id == _selected_equip_slot and _focus_zone == FOCUS_EQUIP)


func _refresh_character_preview() -> void:
	character_preview.visible = visible


func _select_grid_index(grid_index: int) -> void:
	_selected_grid_index = clampi(grid_index, 0, InventoryData.GRID_SIZE - 1)
	_focus_zone = FOCUS_BAG
	if _selected_equip_slot != "":
		_selected_equip_slot = ""
		_refresh_equipment()
	if _mode != MODE_PICK_MODIFIER and _mode != MODE_PICK_SLOT:
		_socket_item = null
	_refresh_grid()
	_update_footer()


func _on_tab_selected(tab_id: String) -> void:
	if _mode == MODE_PICK_MODIFIER and tab_id != TAB_MODIFIERS:
		return
	if _mode == MODE_PICK_SLOT and tab_id == TAB_MODIFIERS:
		return
	_bag_tab_id = tab_id
	_focus_zone = FOCUS_BAG
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
	if _mode == MODE_PICK_SLOT:
		_select_grid_index(index)
		var item := _get_selected_item()
		if item and _item_accepts_pick_modifier(item):
			_try_socket_picked_modifier_on(item)
		return
	if _mode == MODE_PICK_MODIFIER:
		_select_grid_index(index)
		return
	_selected_equip_slot = ""
	_refresh_equipment()
	_select_grid_index(index)


func _on_slot_activated(index: int) -> void:
	_on_slot_pressed(index)
	if _mode == MODE_PICK_MODIFIER:
		_confirm_pick_modifier()
		return
	if _mode == MODE_PICK_SLOT:
		return
	if _is_modifier_tab():
		_begin_pick_slot()
	else:
		_try_equip()


func _on_equipment_pressed(slot_id: String) -> void:
	if _mode == MODE_PICK_SLOT:
		_focus_equipment_slot(slot_id)
		var item: ItemData = inventory.equipped.get(slot_id) as ItemData
		if item and _item_accepts_pick_modifier(item):
			_try_socket_picked_modifier_on(item)
		return
	if _mode == MODE_PICK_MODIFIER:
		return
	_focus_equipment_slot(slot_id)


func _on_equipment_activated(slot_id: String) -> void:
	if _mode != MODE_NONE:
		_on_equipment_pressed(slot_id)
		return
	_unequip_slot(slot_id)


func _on_footer_prompt(action: String) -> void:
	if not visible:
		return
	match action:
		"sort":
			if not _is_modifier_tab() and _mode == MODE_NONE:
				_cycle_sort()
		"equip":
			if _mode == MODE_NONE and not _is_modifier_tab():
				_try_equip()
		"socket":
			_on_socket_action()
		"back":
			_cancel_pick_mode()
			_refresh_all()
		"discard":
			if _mode == MODE_NONE:
				_try_discard()
		"close":
			if _mode != MODE_NONE:
				_cancel_pick_mode()
				_refresh_all()
			else:
				request_close.emit()


func _on_socket_action() -> void:
	if _mode == MODE_PICK_MODIFIER:
		_confirm_pick_modifier()
		return
	if _mode == MODE_PICK_SLOT:
		var item := _current_detail_item()
		if item:
			_try_socket_picked_modifier_on(item)
		return
	if _focus_zone == FOCUS_SOCKETS:
		_activate_selected_socket()
		return
	if _is_modifier_tab():
		_begin_pick_slot()
		return
	_focus_sockets_on_current_item()


func _try_equip() -> void:
	if _is_modifier_tab() or _mode != MODE_NONE:
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
	if _is_modifier_tab() or _mode != MODE_NONE:
		return
	var current := SORT_MODES.find(inventory.sort_mode)
	var next := (current + 1) % SORT_MODES.size()
	inventory.sort_mode = SORT_MODES[next]
	inventory.sort_slots()
	_refresh_all()


func _focus_sockets_on_current_item() -> void:
	var item := _current_detail_item()
	if item == null or inventory == null:
		return
	var rows := inventory.list_socket_rows(item)
	if rows.is_empty():
		return
	_socket_item = item
	_focus_zone = FOCUS_SOCKETS
	_selected_socket_row = 0
	var first: Dictionary = rows[0]
	_socket_kind = str(first.get("kind", ""))
	_socket_index = int(first.get("index", 0))
	_refresh_all()


func _on_socket_row_pressed(kind: String, index: int) -> void:
	var item := _current_detail_item()
	if item == null:
		return
	_socket_item = item
	_focus_zone = FOCUS_SOCKETS
	_socket_kind = kind
	_socket_index = index
	_selected_socket_row = detail_panel.find_socket_row_index(kind, index)
	if detail_panel:
		detail_panel.set_selected_socket(kind, index)
	_update_footer()


func _on_socket_row_activated(kind: String, index: int) -> void:
	_on_socket_row_pressed(kind, index)
	_activate_selected_socket()


func _activate_selected_socket() -> void:
	if _socket_item == null or _socket_kind.is_empty():
		return
	# Pending MOD → equipment with multiple empty sockets: confirm into selected row.
	if _mode == MODE_PICK_SLOT and not _pick_mod_uid.is_empty():
		if _selected_socket_filled():
			return
		var ok := false
		if _pick_mod_kind == "rune" and _socket_kind == "rune":
			ok = inventory.socket_rune_on_item(_socket_item, _pick_mod_uid, _socket_index)
		elif _pick_mod_kind == "gem" and _socket_kind in ["core_gem", "aux_gem"]:
			ok = inventory.socket_gem_on_item(
				_socket_item, _pick_mod_uid, _socket_kind, _socket_index
			)
		if ok:
			_mode = MODE_NONE
			_pick_mod_kind = ""
			_pick_mod_uid = ""
			_focus_zone = FOCUS_SOCKETS
			_rebuild_resonance()
			_refresh_all()
		return
	if _selected_socket_filled():
		inventory.unsocket(_socket_item, _socket_kind, _socket_index)
		_rebuild_resonance()
		_refresh_all()
		return
	_begin_pick_modifier()


func _begin_pick_modifier() -> void:
	if _socket_item == null or _socket_kind.is_empty():
		return
	_mode = MODE_PICK_MODIFIER
	_bag_tab_id = TAB_MODIFIERS
	_focus_zone = FOCUS_BAG
	_selected_equip_slot = ""
	_selected_grid_index = _first_compatible_modifier_index()
	_refresh_all()


func _begin_pick_slot() -> void:
	var entries := _modifier_entries()
	if _selected_grid_index < 0 or _selected_grid_index >= entries.size():
		return
	var entry: Dictionary = entries[_selected_grid_index]
	if bool(entry.get("registered", false)):
		return
	_pick_mod_kind = str(entry.get("kind", ""))
	_pick_mod_uid = str(entry.get("uid", ""))
	if _pick_mod_uid.is_empty():
		return
	_mode = MODE_PICK_SLOT
	# Prefer weapon tab for runes, else keep current non-mod tab or weapon.
	if _pick_mod_kind == "rune":
		_bag_tab_id = "weapon"
		inventory.current_category = ItemData.ItemCategory.WEAPON
	elif _bag_tab_id == TAB_MODIFIERS:
		_bag_tab_id = "weapon"
		inventory.current_category = ItemData.ItemCategory.WEAPON
	_focus_zone = FOCUS_BAG
	_selected_grid_index = _first_compatible_item_index()
	_refresh_all()


func _cancel_pick_mode() -> void:
	var was := _mode
	_mode = MODE_NONE
	_pick_mod_kind = ""
	_pick_mod_uid = ""
	if was == MODE_PICK_MODIFIER and _socket_item != null:
		_focus_zone = FOCUS_SOCKETS
		if _socket_item.category == ItemData.ItemCategory.WEAPON:
			_bag_tab_id = "weapon"
		elif _socket_item.category == ItemData.ItemCategory.ARMOR:
			_bag_tab_id = "armor"
		elif _socket_item.category == ItemData.ItemCategory.TOOL:
			_bag_tab_id = "tool"
		else:
			_bag_tab_id = "weapon"
		inventory.current_category = _socket_item.category
	elif was == MODE_PICK_SLOT:
		_bag_tab_id = TAB_MODIFIERS
		_focus_zone = FOCUS_BAG


func _confirm_pick_modifier() -> void:
	if _mode != MODE_PICK_MODIFIER or _socket_item == null:
		return
	var entries := _modifier_entries()
	if _selected_grid_index < 0 or _selected_grid_index >= entries.size():
		return
	var entry: Dictionary = entries[_selected_grid_index]
	if not _modifier_compatible_for_pick(entry):
		return
	var uid := str(entry.get("uid", ""))
	var ok := false
	if _socket_kind == "rune" and str(entry.get("kind", "")) == "rune":
		ok = inventory.socket_rune_on_item(_socket_item, uid, _socket_index)
	elif _socket_kind in ["core_gem", "aux_gem"] and str(entry.get("kind", "")) == "gem":
		ok = inventory.socket_gem_on_item(_socket_item, uid, _socket_kind, _socket_index)
	if not ok:
		return
	_mode = MODE_NONE
	_pick_mod_kind = ""
	_pick_mod_uid = ""
	_focus_zone = FOCUS_SOCKETS
	_rebuild_resonance()
	# Restore bag tab to the item's category if possible.
	if _socket_item.category == ItemData.ItemCategory.WEAPON:
		_bag_tab_id = "weapon"
	elif _socket_item.category == ItemData.ItemCategory.ARMOR:
		_bag_tab_id = "armor"
	elif _socket_item.category == ItemData.ItemCategory.TOOL:
		_bag_tab_id = "tool"
	inventory.current_category = _socket_item.category
	_refresh_all()


func _try_socket_picked_modifier_on(item: ItemData) -> void:
	if _mode != MODE_PICK_SLOT or item == null:
		return
	if not _item_accepts_pick_modifier(item):
		return
	var empties: Array[Dictionary] = []
	if _pick_mod_kind == "rune":
		empties = inventory.empty_socket_rows(item, "rune")
	else:
		for row in inventory.empty_socket_rows(item):
			var k := str(row.get("kind", ""))
			if k == "core_gem" or k == "aux_gem":
				empties.append(row)
	if empties.is_empty():
		return
	if empties.size() == 1:
		var row: Dictionary = empties[0]
		var ok := false
		if _pick_mod_kind == "rune":
			ok = inventory.socket_rune_on_item(item, _pick_mod_uid, int(row.get("index", 0)))
		else:
			ok = inventory.socket_gem_on_item(
				item, _pick_mod_uid, str(row.get("kind", "")), int(row.get("index", 0))
			)
		if ok:
			_mode = MODE_NONE
			_pick_mod_kind = ""
			_pick_mod_uid = ""
			_socket_item = item
			_focus_zone = FOCUS_SOCKETS
			_socket_kind = str(row.get("kind", ""))
			_socket_index = int(row.get("index", 0))
			_rebuild_resonance()
			_refresh_all()
		return
	_socket_item = item
	_focus_zone = FOCUS_SOCKETS
	var first: Dictionary = empties[0]
	_socket_kind = str(first.get("kind", ""))
	_socket_index = int(first.get("index", 0))
	_selected_socket_row = 0
	_refresh_all()


func _modifier_compatible_for_pick(entry: Dictionary) -> bool:
	if _socket_item == null:
		return false
	if bool(entry.get("registered", false)):
		return false
	var kind := str(entry.get("kind", ""))
	if _socket_kind == "rune":
		if kind != "rune":
			return false
		return _resonance_service.can_socket_rune(_socket_item, entry.get("rune") as RuneData)
	if _socket_kind in ["core_gem", "aux_gem"]:
		if kind != "gem":
			return false
		return _resonance_service.can_socket_gem(_socket_item, entry.get("gem") as GemData)
	return false


func _item_accepts_pick_modifier(item: ItemData) -> bool:
	if item == null or _pick_mod_uid.is_empty():
		return false
	if _pick_mod_kind == "rune":
		var ri := inventory.find_rune(_pick_mod_uid)
		if ri == null or ri.registered:
			return false
		var rd := _rune_catalog.get_rune(ri.rune_id)
		if not _resonance_service.can_socket_rune(item, rd):
			return false
		return not inventory.empty_socket_rows(item, "rune").is_empty()
	if _pick_mod_kind == "gem":
		var gi := inventory.find_gem(_pick_mod_uid)
		if gi == null or gi.registered:
			return false
		var gd := _gem_catalog.get_gem(gi.gem_id)
		if not _resonance_service.can_socket_gem(item, gd):
			return false
		for row in inventory.empty_socket_rows(item):
			var k := str(row.get("kind", ""))
			if k == "core_gem" or k == "aux_gem":
				return true
		return false
	return false


func _first_compatible_modifier_index() -> int:
	var entries := _modifier_entries()
	for i in range(entries.size()):
		if _modifier_compatible_for_pick(entries[i]):
			return i
	return 0


func _first_compatible_item_index() -> int:
	inventory.ensure_grid_size()
	for i in range(inventory.slots.size()):
		var item: ItemData = inventory.slots[i]
		if item and _item_accepts_pick_modifier(item):
			return i
	return 0


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		if _mode != MODE_NONE:
			_cancel_pick_mode()
			_refresh_all()
		else:
			request_close.emit()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("inventory_equip"):
		if _mode != MODE_NONE or _focus_zone == FOCUS_SOCKETS or _is_modifier_tab():
			_on_socket_action()
		else:
			_try_equip()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("inventory_discard"):
		if _mode == MODE_NONE:
			_try_discard()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("inventory_sort"):
		_cycle_sort()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("inventory_category_prev"):
		if _mode == MODE_NONE:
			_cycle_tab(-1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("inventory_category_next"):
		if _mode == MODE_NONE:
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
	if _focus_zone == FOCUS_SOCKETS:
		_move_socket_focus(delta_x, delta_y)
	elif _focus_zone == FOCUS_EQUIP or _selected_equip_slot != "":
		_move_equipment_focus(delta_x, delta_y)
	else:
		_move_bag_focus(delta_x, delta_y)


func _move_bag_focus(delta_x: int, delta_y: int) -> void:
	if delta_x > 0 and _is_bag_right_edge() and _mode != MODE_PICK_MODIFIER:
		_focus_equipment_from_bag()
		return
	if delta_y > 0 and _mode == MODE_NONE and _current_item_has_sockets() and not _is_modifier_tab():
		# Optional: down from bag does not enter sockets; only from equip / SOCKET.
		pass
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
	_focus_zone = FOCUS_EQUIP
	if _mode != MODE_PICK_SLOT:
		_socket_item = inventory.equipped.get(slot_id) as ItemData
	_refresh_equipment()
	_refresh_grid()
	_update_footer()


func _focus_bag_from_equipment() -> void:
	var equip_index := InventoryData.EQUIP_SLOTS.find(_selected_equip_slot)
	var equip_row := maxi(equip_index, 0) / EQUIP_COLUMNS
	var bag_row := equip_row * 2
	var target := bag_row * GRID_COLUMNS + GRID_COLUMNS - 1
	target = clampi(target, 0, InventoryData.GRID_SIZE - 1)
	_selected_equip_slot = ""
	_focus_zone = FOCUS_BAG
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
	if delta_y > 0 and _mode == MODE_NONE and _current_item_has_sockets():
		_focus_sockets_on_current_item()
		return
	var next_column := clampi(column + delta_x, 0, EQUIP_COLUMNS - 1)
	var next_row := clampi(row + delta_y, 0, EQUIP_ROWS - 1)
	_focus_equipment_slot(InventoryData.EQUIP_SLOTS[next_row * EQUIP_COLUMNS + next_column])


func _move_socket_focus(delta_x: int, delta_y: int) -> void:
	if detail_panel == null:
		return
	var count := detail_panel.get_socket_row_count()
	if count <= 0:
		return
	if delta_x < 0:
		_focus_zone = FOCUS_BAG
		_selected_equip_slot = ""
		_refresh_all()
		return
	if delta_x > 0:
		var slot := ""
		if _socket_item:
			for sid in InventoryData.EQUIP_SLOTS:
				if inventory.equipped.get(sid) == _socket_item:
					slot = sid
					break
		if slot != "":
			_focus_equipment_slot(slot)
		return
	_selected_socket_row = clampi(_selected_socket_row + delta_y, 0, count - 1)
	var row := detail_panel.get_socket_row_at(_selected_socket_row)
	_socket_kind = str(row.get("kind", ""))
	_socket_index = int(row.get("index", 0))
	detail_panel.set_selected_socket(_socket_kind, _socket_index)
	# When pick_slot with pending uid and user confirms via equip key later.
	if _mode == MODE_PICK_SLOT and not _pick_mod_uid.is_empty() and delta_y == 0:
		pass
	_update_footer()


func _cycle_tab(direction: int) -> void:
	var current_index := 0
	for i in range(CATEGORY_DEFS.size()):
		if str(CATEGORY_DEFS[i]["id"]) == _bag_tab_id:
			current_index = i
			break
	var next_index := (current_index + direction) % CATEGORY_DEFS.size()
	_on_tab_selected(str(CATEGORY_DEFS[next_index]["id"]))
