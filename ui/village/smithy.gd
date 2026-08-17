class_name Smithy
extends Control

signal request_close

const SLOT_SCENE := preload("res://ui/inventory/components/inventory_slot.tscn")
const EQUIPMENT_SLOT_SCENE := preload("res://ui/inventory/components/equipment_slot.tscn")

const FOCUS_EQUIP := "equip"
const FOCUS_BAG := "bag"
const FOCUS_SOCKETS := "sockets"
const FOCUS_MOD := "mod"

const GRID_COLUMNS := 5
const BAG_COUNT := InventoryData.GRID_SIZE * 2
const EQUIP_SLOT_ROWS: Array = [
	["main_hand", "off_hand"],
	["head", "chest", "legs"],
	["ring_1", "ring_2"],
	["tool_1", "tool_2"],
]

@onready var hint_label: Label = %HintLabel
@onready var npc_name: Label = %NpcName
@onready var npc_line: Label = %NpcLine
@onready var equipment_title: Label = %EquipmentTitle
@onready var bag_title: Label = %BagTitle
@onready var mod_title: Label = %ModTitle
@onready var item_grid: GridContainer = %ItemGrid
@onready var mod_grid: GridContainer = %ModGrid
@onready var equipment_layout: VBoxContainer = %EquipmentLayout
@onready var item_slot: InventorySlot = %ItemSlot
@onready var mod_slot: InventorySlot = %ModSlot
@onready var detail_panel: ItemDetailPanel = %ItemDetailPanel
@onready var modifier_detail: ModifierDetailPanel = %ModifierDetailPanel

var _ui_manager: UIManager
var _footer: FooterPrompts
var _footer_connected: bool = false
var _active: bool = false
var _inventory: InventoryData
var _rune_catalog := RuneCatalog.new()
var _gem_catalog := GemCatalog.new()
var _resonance := ResonanceService.new()

var _bag_slots: Array[InventorySlot] = []
var _mod_slots: Array[InventorySlot] = []
var _equipment_slots: Dictionary = {}
var _detail_wired: bool = false

var _focus_zone: String = FOCUS_EQUIP
var _item_source: String = FOCUS_EQUIP
var _selected_equip_slot: String = "main_hand"
var _selected_bag_index: int = 0
var _selected_mod_index: int = 0
var _socket_item: ItemData
var _socket_kind: String = ""
var _socket_index: int = -1
var _selected_socket_row: int = 0
var _staged_mod_uid: String = ""


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED
	UIPopupLayout.apply_column_panels([$Main/Body/LeftColumn, $Main/Body/CenterColumn, $Main/Body/RightColumn])
	UIPopupLayout.flatten_inner_panel(detail_panel)
	UIPopupLayout.flatten_inner_panel(modifier_detail)
	UIPopupLayout.apply_slot_grid_pad(%EquipmentLayoutPad)
	UIPopupLayout.apply_slot_grid_pad(%ItemGridPad)
	UIPopupLayout.apply_slot_grid_pad(%ModGridPad)
	_apply_right_scroll_gutter()
	_build_equipment_slots()
	_build_bag_grid()
	_build_mod_grid()
	_wire_bench_slots()
	LocaleManager.locale_changed.connect(_on_locale_changed)
	_refresh_texts()


func setup(ui_manager: UIManager, footer: FooterPrompts = null) -> void:
	_ui_manager = ui_manager
	if footer:
		_footer = footer
	if _ui_manager and not _ui_manager.input_device_changed.is_connected(_on_input_device_changed):
		_ui_manager.input_device_changed.connect(_on_input_device_changed)
	if _footer and not _footer_connected:
		_footer.prompt_activated.connect(_on_footer_action)
		_footer_connected = true
	_wire_detail_panel()


func activate(_stats: CharacterStats = null, inventory: InventoryData = null) -> void:
	_inventory = inventory
	_active = true
	visible = true
	process_mode = Node.PROCESS_MODE_INHERIT
	_wire_detail_panel()
	_focus_zone = FOCUS_EQUIP
	_item_source = FOCUS_EQUIP
	_selected_equip_slot = "main_hand"
	_selected_bag_index = 0
	_selected_mod_index = 0
	_clear_bench()
	_refresh_all()


func deactivate() -> void:
	_active = false
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED


func _wire_detail_panel() -> void:
	if detail_panel == null or _detail_wired:
		return
	detail_panel.socket_row_pressed.connect(_on_socket_row_pressed)
	detail_panel.socket_row_activated.connect(_on_socket_row_pressed)
	_detail_wired = true


func _wire_bench_slots() -> void:
	if item_slot:
		item_slot.setup(0)
		item_slot.slot_pressed.connect(_on_bench_item_pressed)
		item_slot.slot_activated.connect(_on_bench_item_activated)
	if mod_slot:
		mod_slot.setup(1)
		mod_slot.slot_activated.connect(_on_bench_mod_activated)


func _is_using_gamepad() -> bool:
	return _ui_manager.using_gamepad if _ui_manager else false


func _on_input_device_changed(_using_gamepad: bool) -> void:
	if _active:
		_update_footer()


func _on_locale_changed(_locale: String) -> void:
	_refresh_texts()
	if _active:
		_refresh_all()


func _refresh_texts() -> void:
	if npc_name:
		npc_name.text = tr("NPC_BRAM")
		npc_name.add_theme_color_override("font_color", UIColors.TEXT_LORE)
	if npc_line:
		npc_line.text = tr("NPC_BRAM_LINE")
		npc_line.add_theme_color_override("font_color", UIColors.TEXT_MUTED)
	if hint_label:
		hint_label.text = tr("SMITHY_HINT")
	if equipment_title:
		equipment_title.text = tr("INV_EQUIPPED_TITLE")
	if bag_title:
		bag_title.text = tr("Equipment")
	if mod_title:
		mod_title.text = tr("MOD_BAG_CAPACITY") % (
			_inventory.modifier_count() if _inventory else 0
		)


func _apply_right_scroll_gutter() -> void:
	var bar: VScrollBar = %RightScroll.get_v_scroll_bar()
	var width := 12
	if bar:
		width = maxi(int(ceili(bar.get_combined_minimum_size().x)), 12)
	%RightScrollGutter.add_theme_constant_override("margin_right", width)


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
			slot.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
			row.add_child(slot)
			slot.setup(id)
			slot.slot_pressed.connect(_on_equipment_pressed)
			slot.slot_activated.connect(_on_equipment_activated)
			_equipment_slots[id] = slot


func _build_bag_grid() -> void:
	for child in item_grid.get_children():
		child.queue_free()
	_bag_slots.clear()
	item_grid.columns = GRID_COLUMNS
	for i in range(BAG_COUNT):
		var slot: InventorySlot = SLOT_SCENE.instantiate()
		slot.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		slot.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		item_grid.add_child(slot)
		slot.setup(i)
		slot.slot_pressed.connect(_on_bag_pressed)
		slot.slot_activated.connect(_on_bag_activated)
		_bag_slots.append(slot)


func _build_mod_grid() -> void:
	for child in mod_grid.get_children():
		child.queue_free()
	_mod_slots.clear()
	mod_grid.columns = GRID_COLUMNS
	for i in range(InventoryData.GRID_SIZE):
		var slot: InventorySlot = SLOT_SCENE.instantiate()
		slot.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		slot.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		mod_grid.add_child(slot)
		slot.setup(i)
		slot.slot_pressed.connect(_on_mod_pressed)
		slot.slot_activated.connect(_on_mod_activated)
		_mod_slots.append(slot)


func _refresh_all() -> void:
	if _inventory == null:
		return
	_inventory.ensure_grid_size()
	if detail_panel:
		detail_panel.bind_socket_context(_inventory, _rune_catalog, _gem_catalog)
	_sync_staged_mod()
	_refresh_texts()
	_refresh_equipment()
	_refresh_bag()
	_refresh_mods()
	_refresh_bench()
	_refresh_detail()
	_update_footer()


func _bag_item_at(index: int) -> ItemData:
	if _inventory == null or index < 0 or index >= BAG_COUNT:
		return null
	if index < InventoryData.GRID_SIZE:
		return _inventory.get_item(InventoryData.BAG_EQUIPMENT, index)
	return _inventory.get_item(InventoryData.BAG_TOOL, index - InventoryData.GRID_SIZE)


func _selected_gear() -> ItemData:
	if _focus_zone == FOCUS_BAG:
		return _bag_item_at(_selected_bag_index)
	if _inventory == null:
		return null
	return _inventory.equipped.get(_selected_equip_slot) as ItemData


func _detail_item() -> ItemData:
	if _socket_item:
		return _socket_item
	if _focus_zone == FOCUS_EQUIP or _focus_zone == FOCUS_BAG:
		return _selected_gear()
	return null


func _item_has_sockets(item: ItemData) -> bool:
	if item == null or _inventory == null:
		return false
	return not _inventory.list_socket_rows(item).is_empty()


func _clear_bench() -> void:
	_socket_item = null
	_socket_kind = ""
	_socket_index = -1
	_selected_socket_row = 0
	_staged_mod_uid = ""


func _clear_staged_mod() -> void:
	_staged_mod_uid = ""


func _select_place_socket() -> void:
	if _socket_item == null or _inventory == null:
		_socket_kind = ""
		_socket_index = -1
		_selected_socket_row = 0
		return
	var rows := _inventory.list_socket_rows(_socket_item)
	if rows.is_empty():
		_socket_kind = ""
		_socket_index = -1
		_selected_socket_row = 0
		return
	for i in range(rows.size()):
		var row: Dictionary = rows[i]
		if str(row.get("instance_uid", "")).is_empty():
			_socket_kind = str(row.get("kind", ""))
			_socket_index = int(row.get("index", 0))
			_selected_socket_row = i
			return
	var first: Dictionary = rows[0]
	_socket_kind = str(first.get("kind", ""))
	_socket_index = int(first.get("index", 0))
	_selected_socket_row = 0


func _ensure_socket_selection() -> void:
	if _socket_item == null or _inventory == null:
		_socket_kind = ""
		_socket_index = -1
		return
	var rows := _inventory.list_socket_rows(_socket_item)
	if rows.is_empty():
		_socket_kind = ""
		_socket_index = -1
		return
	for i in range(rows.size()):
		var row: Dictionary = rows[i]
		if str(row.get("kind", "")) == _socket_kind and int(row.get("index", -1)) == _socket_index:
			_selected_socket_row = i
			return
	var first: Dictionary = rows[0]
	_socket_kind = str(first.get("kind", ""))
	_socket_index = int(first.get("index", 0))
	_selected_socket_row = 0


func _selected_socket_filled() -> bool:
	if _socket_item == null or _socket_kind.is_empty() or _inventory == null:
		return false
	for row in _inventory.list_socket_rows(_socket_item):
		if str(row.get("kind", "")) == _socket_kind and int(row.get("index", -1)) == _socket_index:
			return not str(row.get("instance_uid", "")).is_empty()
	return false


func _modifier_entries() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if _inventory == null:
		return out
	for i in range(_inventory.runes.size()):
		var ri: RuneInstance = _inventory.runes[i] as RuneInstance
		if ri == null:
			continue
		var data: RuneData = _rune_catalog.get_rune(ri.rune_id)
		out.append({
			"kind": "rune",
			"rune": data,
			"uid": ri.instance_uid,
			"registered": ri.registered,
			"display_name": tr(data.display_name) if data else ri.rune_id,
		})
	for i in range(_inventory.gems.size()):
		var gi: GemInstance = _inventory.gems[i] as GemInstance
		if gi == null:
			continue
		var gdata: GemData = _gem_catalog.get_gem(gi.gem_id)
		out.append({
			"kind": "gem",
			"gem": gdata,
			"uid": gi.instance_uid,
			"registered": gi.registered,
			"display_name": tr(gdata.display_name) if gdata else gi.gem_id,
		})
	return out


func _modifier_icon(entry: Dictionary) -> Texture2D:
	if str(entry.get("kind", "")) == "rune":
		var rune: RuneData = entry.get("rune") as RuneData
		return rune.icon if rune else null
	var gem: GemData = entry.get("gem") as GemData
	return gem.icon if gem else null


func _staged_mod_entry() -> Dictionary:
	if _staged_mod_uid.is_empty():
		return {}
	for entry in _modifier_entries():
		if str(entry.get("uid", "")) == _staged_mod_uid:
			return entry
	return {}


func _sync_staged_mod() -> void:
	if _staged_mod_uid.is_empty():
		return
	if _staged_mod_entry().is_empty():
		_staged_mod_uid = ""


func _modifier_matches_socket(entry: Dictionary) -> bool:
	if _socket_item == null or bool(entry.get("registered", false)):
		return false
	var uid := str(entry.get("uid", ""))
	if uid.is_empty() or _inventory.is_uid_socketed(uid):
		return false
	var kind := str(entry.get("kind", ""))
	if _socket_kind == "rune":
		if kind != "rune":
			return false
		return _resonance.can_socket_rune(_socket_item, entry.get("rune") as RuneData)
	if _socket_kind in ["core_gem", "aux_gem"]:
		if kind != "gem":
			return false
		return _resonance.can_socket_gem(_socket_item, entry.get("gem") as GemData)
	return false


func _can_place_mod(entry: Dictionary) -> bool:
	if _inventory == null or bool(entry.get("registered", false)):
		return false
	var uid := str(entry.get("uid", ""))
	return not uid.is_empty() and not _inventory.is_uid_socketed(uid)


func _modifier_usable(entry: Dictionary) -> bool:
	if _selected_socket_filled():
		return false
	return _modifier_matches_socket(entry)


func _usable_modifier_indices() -> Array[int]:
	var out: Array[int] = []
	var entries := _modifier_entries()
	for i in range(entries.size()):
		if _modifier_usable(entries[i]):
			out.append(i)
	return out


func _can_inject() -> bool:
	if _socket_item == null or _socket_kind.is_empty() or _selected_socket_filled():
		return false
	var entry := _staged_mod_entry()
	return not entry.is_empty() and _modifier_usable(entry)


func _refresh_equipment() -> void:
	for slot_id in _equipment_slots.keys():
		var slot: EquipmentSlot = _equipment_slots[slot_id]
		var item: ItemData = _inventory.equipped.get(slot_id) as ItemData
		slot.set_item(item)
		var blocked: bool = str(slot_id) == "off_hand" and _inventory.is_two_handed_equipped()
		slot.set_blocked(blocked)
		var dim := item != null and not _item_has_sockets(item)
		slot.modulate = UIColors.DIM if dim else Color.WHITE
		slot.set_selected(slot_id == _selected_equip_slot and _focus_zone == FOCUS_EQUIP)


func _refresh_bag() -> void:
	for i in range(_bag_slots.size()):
		var slot := _bag_slots[i]
		slot.setup(i)
		var item := _bag_item_at(i)
		slot.set_item(item)
		var dim := item != null and not _item_has_sockets(item)
		slot.modulate = UIColors.DIM if dim else Color.WHITE
		slot.set_selected(i == _selected_bag_index and _focus_zone == FOCUS_BAG)


func _refresh_mods() -> void:
	var entries := _modifier_entries()
	for i in range(_mod_slots.size()):
		var slot := _mod_slots[i]
		slot.setup(i)
		if i < entries.size():
			var entry: Dictionary = entries[i]
			var uid := str(entry.get("uid", ""))
			slot.set_modifier_entry(
				str(entry.get("display_name", "")),
				ItemData.ItemRarity.COMMON,
				_inventory.is_uid_socketed(uid),
				_modifier_icon(entry)
			)
			slot.modulate = UIColors.DIM if not _modifier_usable(entry) else Color.WHITE
		else:
			slot.clear_entry()
			slot.modulate = Color.WHITE
		slot.set_selected(i == _selected_mod_index and _focus_zone == FOCUS_MOD)


func _refresh_bench() -> void:
	if item_slot:
		item_slot.set_item(_socket_item)
		item_slot.set_selected(false)
	if mod_slot == null:
		return
	var entry := _staged_mod_entry()
	if entry.is_empty():
		mod_slot.clear_entry()
	else:
		mod_slot.set_modifier_entry(
			str(entry.get("display_name", "")),
			ItemData.ItemRarity.COMMON,
			false,
			_modifier_icon(entry)
		)
	mod_slot.set_selected(false)


func _refresh_detail() -> void:
	if _focus_zone == FOCUS_MOD:
		_show_modifier_detail()
		return
	_show_item_detail()


func _show_item_detail() -> void:
	if modifier_detail:
		modifier_detail.visible = false
		modifier_detail.clear()
	if detail_panel == null:
		return
	detail_panel.visible = true
	detail_panel.bind_socket_context(_inventory, _rune_catalog, _gem_catalog)
	var item := _detail_item()
	detail_panel.set_item(item)
	var equipped_main: ItemData = _inventory.equipped.get("main_hand") as ItemData if _inventory else null
	if item != null and item == equipped_main:
		var result := _resonance.rebuild_main_hand_skills(_inventory, _rune_catalog, _gem_catalog)
		detail_panel.set_item(item)
		detail_panel.set_resonance_state(result.state_key())
	else:
		detail_panel.set_resonance_state("")
	if _socket_item != null and _socket_kind != "":
		detail_panel.set_selected_socket(_socket_kind, _socket_index)
	else:
		detail_panel.set_selected_socket("", -1)


func _show_modifier_detail() -> void:
	if detail_panel:
		detail_panel.visible = false
		detail_panel.set_item(null)
	if modifier_detail == null:
		return
	modifier_detail.visible = true
	var entries := _modifier_entries()
	if _selected_mod_index < 0 or _selected_mod_index >= entries.size():
		modifier_detail.show_message(tr("SOCKET_PICK_MOD"))
		return
	var entry: Dictionary = entries[_selected_mod_index]
	if str(entry.get("kind", "")) == "rune":
		modifier_detail.set_rune(entry.get("rune") as RuneData)
	else:
		modifier_detail.set_gem(entry.get("gem") as GemData)


func _update_footer() -> void:
	if _footer == null:
		return
	var using_gamepad := _is_using_gamepad()
	var prompts: Array = []
	if _socket_item != null and _selected_socket_filled():
		prompts.append({
			"action": "inject",
			"button": "A" if using_gamepad else "Enter",
			"label": tr("UNSOCKET"),
		})
	elif _can_inject():
		prompts.append({
			"action": "inject",
			"button": "A" if using_gamepad else "Enter",
			"label": tr("SMITHY_INJECT"),
		})
	prompts.append({"action": "close", "button": "B" if using_gamepad else "Esc", "label": tr("CLOSE")})
	_footer.set_prompts(prompts)


func _on_footer_action(action: String) -> void:
	if not _active:
		return
	match action:
		"inject":
			_inject()
		"close":
			request_close.emit()


func _on_equipment_pressed(slot_id: String) -> void:
	_focus_zone = FOCUS_EQUIP
	_item_source = FOCUS_EQUIP
	_selected_equip_slot = slot_id
	_refresh_all()


func _on_equipment_activated(slot_id: String) -> void:
	_on_equipment_pressed(slot_id)
	_place_item()


func _on_bag_pressed(index: int) -> void:
	_focus_zone = FOCUS_BAG
	_item_source = FOCUS_BAG
	_selected_bag_index = clampi(index, 0, BAG_COUNT - 1)
	_refresh_all()


func _on_bag_activated(index: int) -> void:
	_on_bag_pressed(index)
	_place_item()


func _on_mod_pressed(index: int) -> void:
	_focus_zone = FOCUS_MOD
	_selected_mod_index = clampi(index, 0, InventoryData.GRID_SIZE - 1)
	_refresh_all()


func _on_mod_activated(index: int) -> void:
	_on_mod_pressed(index)
	_place_mod()


func _on_bench_item_pressed(_index: int) -> void:
	if _socket_item == null:
		return
	_focus_sockets()


func _on_bench_item_activated(_index: int) -> void:
	_socket_item = null
	_socket_kind = ""
	_socket_index = -1
	_selected_socket_row = 0
	_refresh_all()


func _on_bench_mod_activated(_index: int) -> void:
	_clear_staged_mod()
	_refresh_all()


func _on_socket_row_pressed(kind: String, index: int) -> void:
	if _socket_item == null:
		return
	_focus_zone = FOCUS_SOCKETS
	_socket_kind = kind
	_socket_index = index
	_selected_socket_row = detail_panel.find_socket_row_index(kind, index) if detail_panel else 0
	_refresh_all()


func _focus_sockets() -> void:
	if not _item_has_sockets(_socket_item):
		return
	_focus_zone = FOCUS_SOCKETS
	_ensure_socket_selection()
	_refresh_all()


func _place_item() -> void:
	var item := _selected_gear()
	if not _item_has_sockets(item):
		return
	_socket_item = item
	_clear_staged_mod()
	_select_place_socket()
	_focus_sockets()


func _place_mod() -> void:
	var entries := _modifier_entries()
	if _selected_mod_index < 0 or _selected_mod_index >= entries.size():
		return
	var entry: Dictionary = entries[_selected_mod_index]
	if not _can_place_mod(entry):
		return
	_staged_mod_uid = str(entry.get("uid", ""))
	if _item_has_sockets(_socket_item):
		_focus_sockets()
	else:
		_refresh_all()


func _confirm() -> void:
	if _inventory == null:
		return
	if _focus_zone == FOCUS_EQUIP or _focus_zone == FOCUS_BAG:
		_place_item()
		return
	if _focus_zone == FOCUS_MOD:
		_place_mod()


func _inject() -> void:
	if _inventory == null or _socket_item == null:
		return
	if _selected_socket_filled():
		_unsocket_selected()
		return
	if not _can_inject():
		return
	var entry := _staged_mod_entry()
	var uid := str(entry.get("uid", ""))
	var ok := false
	if _socket_kind == "rune" and str(entry.get("kind", "")) == "rune":
		ok = _inventory.socket_rune_on_item(_socket_item, uid, _socket_index)
	elif _socket_kind in ["core_gem", "aux_gem"] and str(entry.get("kind", "")) == "gem":
		ok = _inventory.socket_gem_on_item(_socket_item, uid, _socket_kind, _socket_index)
	if not ok:
		return
	_clear_staged_mod()
	_focus_zone = FOCUS_SOCKETS
	_rebuild_resonance()
	_refresh_all()


func _unsocket_selected() -> void:
	if _socket_item == null or _socket_kind.is_empty():
		return
	if not _inventory.unsocket(_socket_item, _socket_kind, _socket_index):
		return
	_rebuild_resonance()
	_refresh_all()


func _rebuild_resonance() -> void:
	if _inventory == null:
		return
	_resonance.rebuild_main_hand_skills(_inventory, _rune_catalog, _gem_catalog)
	if _ui_manager:
		_ui_manager.refresh_hud()


func _equip_slot_pos(slot_id: String) -> Vector2i:
	for r in EQUIP_SLOT_ROWS.size():
		var row: Array = EQUIP_SLOT_ROWS[r]
		var c := row.find(slot_id)
		if c >= 0:
			return Vector2i(c, r)
	return Vector2i.ZERO


func _move_focus(dx: int, dy: int) -> void:
	match _focus_zone:
		FOCUS_EQUIP:
			_move_equip(dx, dy)
		FOCUS_BAG:
			_move_bag(dx, dy)
		FOCUS_SOCKETS:
			_move_sockets(dx, dy)
		FOCUS_MOD:
			_move_mod(dx, dy)


func _move_equip(dx: int, dy: int) -> void:
	var pos := _equip_slot_pos(_selected_equip_slot)
	var row: Array = EQUIP_SLOT_ROWS[pos.y]
	if dx > 0 and pos.x == row.size() - 1:
		_focus_sockets_or_mod()
		return
	if dy > 0 and pos.y == EQUIP_SLOT_ROWS.size() - 1:
		_focus_zone = FOCUS_BAG
		_item_source = FOCUS_BAG
		_selected_bag_index = mini(pos.x, GRID_COLUMNS - 1)
		_refresh_all()
		return
	if dx != 0:
		var next_col := clampi(pos.x + dx, 0, row.size() - 1)
		_selected_equip_slot = str(row[next_col])
	else:
		var next_row := clampi(pos.y + dy, 0, EQUIP_SLOT_ROWS.size() - 1)
		var next_slots: Array = EQUIP_SLOT_ROWS[next_row]
		_selected_equip_slot = str(next_slots[clampi(pos.x, 0, next_slots.size() - 1)])
	_refresh_all()


func _move_bag(dx: int, dy: int) -> void:
	if dx > 0 and (_selected_bag_index % GRID_COLUMNS) == GRID_COLUMNS - 1:
		_focus_sockets_or_mod()
		return
	if dy < 0 and _selected_bag_index < GRID_COLUMNS:
		_focus_zone = FOCUS_EQUIP
		_item_source = FOCUS_EQUIP
		_refresh_all()
		return
	_selected_bag_index = clampi(_selected_bag_index + dx + dy * GRID_COLUMNS, 0, BAG_COUNT - 1)
	_refresh_all()


func _focus_sockets_or_mod() -> void:
	if _item_has_sockets(_socket_item):
		_focus_sockets()
	else:
		_focus_zone = FOCUS_MOD
		_refresh_all()


func _move_sockets(dx: int, dy: int) -> void:
	if dx < 0:
		_focus_zone = _item_source
		_refresh_all()
		return
	if dx > 0:
		_focus_first_usable_mod()
		return
	if detail_panel == null:
		return
	var count := detail_panel.get_socket_row_count()
	if count <= 0:
		return
	_selected_socket_row = clampi(_selected_socket_row + dy, 0, count - 1)
	var row := detail_panel.get_socket_row_at(_selected_socket_row)
	_socket_kind = str(row.get("kind", ""))
	_socket_index = int(row.get("index", 0))
	_refresh_all()


func _focus_first_usable_mod() -> void:
	var usable := _usable_modifier_indices()
	_focus_zone = FOCUS_MOD
	_selected_mod_index = usable[0] if not usable.is_empty() else 0
	_refresh_all()


func _move_mod(dx: int, dy: int) -> void:
	if dx < 0:
		if _item_has_sockets(_socket_item):
			_focus_sockets()
		else:
			_focus_zone = _item_source
			_refresh_all()
		return
	_selected_mod_index = clampi(
		_selected_mod_index + dx + dy * GRID_COLUMNS, 0, InventoryData.GRID_SIZE - 1
	)
	_refresh_all()


func _unhandled_input(event: InputEvent) -> void:
	if not _active:
		return
	if event.is_action_pressed("ui_cancel"):
		request_close.emit()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("inventory_equip"):
		if _focus_zone == FOCUS_SOCKETS:
			_inject()
		else:
			_confirm()
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
