class_name Bookshelf
extends Control

signal closed
signal request_close

const SLOT_SCENE := preload("res://ui/village/components/altar_card_slot.tscn")
const GRID_COLUMNS := ShelfDefinition.WIDTH

@onready var rune_tab: CategoryTab = %RuneTab
@onready var gem_tab: CategoryTab = %GemTab
@onready var list_host: GridContainer = %ListHost
@onready var grid_hint: Label = %GridHint
@onready var modifier_detail: ModifierDetailPanel = %ModifierDetailPanel
@onready var detail_status: Label = %DetailStatus
@onready var header_label: Label = %HeaderLabel

var _ui_manager: UIManager
var _footer: FooterPrompts
var _footer_connected: bool = false
var _active: bool = false
var _confirming: bool = false
var _seal_kind: String = ""
var _seal_id: String = ""
var _shelf_id: StringName = ShelfDefinition.SHELF_RUNE
var _entries: Array[Dictionary] = []
var _index: int = 0
var _slots: Array[AltarCardSlot] = []
var _rune_catalog := RuneCatalog.new()
var _gem_catalog := GemCatalog.new()


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED
	UIPopupLayout.apply_slot_grid_pad(%ListHostPad)
	if list_host:
		list_host.columns = GRID_COLUMNS
	_wire_tabs()
	LocaleManager.locale_changed.connect(_on_locale_changed)
	_refresh_texts()


func setup(ui_manager: UIManager, footer: FooterPrompts = null) -> void:
	_ui_manager = ui_manager
	if footer:
		_footer = footer
	if _footer and not _footer_connected:
		_footer.prompt_activated.connect(_on_footer_action)
		_footer_connected = true


func activate(_stats: CharacterStats = null, _inventory: InventoryData = null) -> void:
	_active = true
	_confirming = false
	visible = true
	process_mode = Node.PROCESS_MODE_INHERIT
	_rebuild_grid()
	_refresh_texts()
	_sync_footer()


func deactivate() -> void:
	_active = false
	_confirming = false
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED


func refresh() -> void:
	if _active:
		_confirming = false
		_rebuild_grid()
		_refresh_texts()


func close() -> void:
	if not _active:
		return
	request_close.emit()
	closed.emit()


func is_open() -> bool:
	return _active


func _wire_tabs() -> void:
	if rune_tab:
		rune_tab.tab_selected.connect(_on_shelf_tab.bind(ShelfDefinition.SHELF_RUNE))
	if gem_tab:
		gem_tab.tab_selected.connect(_on_shelf_tab.bind(ShelfDefinition.SHELF_GEM))


func _on_shelf_tab(_id: String, shelf: StringName) -> void:
	_shelf_id = shelf
	_index = 0
	_confirming = false
	_rebuild_grid()
	_refresh_texts()


func _on_locale_changed(_locale: String) -> void:
	_refresh_texts()
	if _active:
		_rebuild_grid()


func _meta() -> Dictionary:
	return CardRegistrationService.ensure_meta_seeded(
		SaveManager.get_card_meta(), _rune_catalog, _gem_catalog
	)


func _refresh_texts() -> void:
	if rune_tab:
		rune_tab.setup(String(ShelfDefinition.SHELF_RUNE), "[%s]" % tr("SHELF_RUNE"))
		rune_tab.set_active(_shelf_id == ShelfDefinition.SHELF_RUNE)
	if gem_tab:
		gem_tab.setup(String(ShelfDefinition.SHELF_GEM), "[%s]" % tr("SHELF_GEM"))
		gem_tab.set_active(_shelf_id == ShelfDefinition.SHELF_GEM)
	if header_label:
		header_label.text = tr("SHELF_LABEL")
	if grid_hint:
		grid_hint.text = tr("SHELF_HINT")
	_update_detail()
	_sync_footer()


func _templates_on_shelf(shelf_id: StringName) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for id in _rune_catalog.all_ids():
		var def: RuneData = _rune_catalog.get_rune(str(id))
		if def == null or def.shelf_id != shelf_id:
			continue
		out.append({
			"kind": "rune",
			"id": str(id),
			"card_number": def.card_number,
			"name": def.display_name,
		})
	for id in _gem_catalog.all_ids():
		var gdef: GemData = _gem_catalog.get_gem(str(id))
		if gdef == null or gdef.shelf_id != shelf_id:
			continue
		out.append({
			"kind": "gem",
			"id": str(id),
			"card_number": gdef.card_number,
			"name": gdef.display_name,
		})
	return out


func _entry_icon(entry: Dictionary) -> Texture2D:
	var temps: Array = entry.get("templates", []) as Array
	if temps.is_empty():
		return null
	var t: Dictionary = temps[0] as Dictionary
	var kind := str(t.get("kind", ""))
	var id := str(t.get("id", ""))
	if kind == "rune":
		var rune := _rune_catalog.get_rune(id)
		return rune.icon if rune else null
	if kind == "gem":
		var gem := _gem_catalog.get_gem(id)
		return gem.icon if gem else null
	return null


func _rebuild_grid() -> void:
	_slots.clear()
	_entries.clear()
	if list_host:
		for child in list_host.get_children():
			child.queue_free()

	var templates := _templates_on_shelf(_shelf_id)
	var max_num := 0
	for t in templates:
		max_num = maxi(max_num, int(t.get("card_number", 0)))
	# Fixed square board; grow only if a template is placed past CELL_COUNT.
	var cell_count := maxi(max_num, ShelfDefinition.CELL_COUNT)

	var by_number: Dictionary = {}
	for t in templates:
		var n := int(t.get("card_number", 0))
		if n <= 0:
			continue
		if not by_number.has(n):
			by_number[n] = []
		(by_number[n] as Array).append(t)

	var meta := _meta()
	var shelf_str := String(_shelf_id)
	var unlocked := CardRegistrationService.is_shelf_unlocked(meta, shelf_str)

	for n in range(1, cell_count + 1):
		var temps: Array = by_number.get(n, []) as Array
		var state: int = CardRegistrationService.CellState.EMPTY
		if not unlocked:
			state = CardRegistrationService.CellState.SHELF_LOCKED
		elif temps.is_empty():
			state = CardRegistrationService.CellState.EMPTY
		else:
			var any_registered := false
			for t in temps:
				if CardRegistrationService.is_id_registered(meta, str(t.get("kind", "")), str(t.get("id", ""))):
					any_registered = true
					break
			if any_registered:
				state = CardRegistrationService.CellState.REGISTERED
			elif CardRegistrationService.is_open(meta, shelf_str, n):
				state = CardRegistrationService.CellState.OPEN
			else:
				state = CardRegistrationService.CellState.FOG

		var display := ""
		if (
			state == CardRegistrationService.CellState.OPEN
			or state == CardRegistrationService.CellState.REGISTERED
		):
			var names: PackedStringArray = []
			for t in temps:
				names.append(tr(str(t.get("name", ""))))
			display = ", ".join(names)

		_entries.append({
			"card_number": n,
			"templates": temps,
			"state": state,
			"display": display,
		})

	_index = clampi(_index, 0, maxi(0, _entries.size() - 1))

	for i in _entries.size():
		var e: Dictionary = _entries[i]
		var slot: AltarCardSlot = SLOT_SCENE.instantiate()
		list_host.add_child(slot)
		slot.setup(i)
		slot.set_shelf_cell(
			int(e.get("state", CardRegistrationService.CellState.EMPTY)),
			str(e.get("display", "")),
			ItemData.ItemRarity.COMMON,
			_entry_icon(e)
		)
		slot.slot_pressed.connect(_on_entry_pressed)
		slot.slot_activated.connect(_on_entry_activated)
		_slots.append(slot)

	_apply_focus()
	_update_detail()


func _on_entry_pressed(index: int) -> void:
	if index < 0 or index >= _entries.size():
		return
	_index = index
	_confirming = false
	_apply_focus()
	_update_detail()
	_sync_footer()


func _on_entry_activated(index: int) -> void:
	_on_entry_pressed(index)
	_try_seal()


func _apply_focus() -> void:
	for i in _slots.size():
		_slots[i].set_selected(i == _index)


func _sealable_template(e: Dictionary) -> Dictionary:
	var meta := _meta()
	var inventory: InventoryData = _ui_manager.inventory_data if _ui_manager else null
	if inventory == null:
		return {}
	for t in e.get("templates", []) as Array:
		var kind := str(t.get("kind", ""))
		var id := str(t.get("id", ""))
		if CardRegistrationService.is_id_registered(meta, kind, id):
			continue
		var uid := CardRegistrationService.first_owned_uid(inventory, kind, id)
		if not uid.is_empty():
			return {"kind": kind, "id": id, "uid": uid, "name": str(t.get("name", ""))}
	return {}


func _update_detail() -> void:
	if modifier_detail == null:
		return
	if detail_status:
		detail_status.text = ""
	if _entries.is_empty():
		modifier_detail.clear()
		return
	var e: Dictionary = _entries[_index]
	var state: int = int(e.get("state", CardRegistrationService.CellState.EMPTY))
	match state:
		CardRegistrationService.CellState.SHELF_LOCKED:
			modifier_detail.show_message(tr("SHELF_LOCKED_HINT"))
		CardRegistrationService.CellState.EMPTY:
			modifier_detail.show_message(tr("SHELF_EMPTY"))
		CardRegistrationService.CellState.FOG:
			modifier_detail.show_message(tr("SHELF_FOG"))
		CardRegistrationService.CellState.OPEN, CardRegistrationService.CellState.REGISTERED:
			_show_template_detail(e)
			var status_lines: PackedStringArray = []
			var meta := _meta()
			for t in e.get("templates", []) as Array:
				var kind := str(t.get("kind", ""))
				if CardRegistrationService.is_id_registered(meta, kind, str(t.get("id", ""))):
					status_lines.append(tr("Registered"))
			var seal := _sealable_template(e)
			if not seal.is_empty():
				if _confirming:
					if str(seal.get("kind", "")) == "rune":
						status_lines.append(tr("Confirm register rune"))
					else:
						status_lines.append(tr("Confirm register gem"))
				else:
					status_lines.append(tr("In storage"))
			if detail_status:
				detail_status.text = "\n".join(status_lines)
		_:
			modifier_detail.clear()


func _show_template_detail(e: Dictionary) -> void:
	var temps: Array = e.get("templates", []) as Array
	if temps.is_empty():
		modifier_detail.show_message(tr("SHELF_EMPTY"))
		return
	var t: Dictionary = temps[0]
	var kind := str(t.get("kind", ""))
	var id := str(t.get("id", ""))
	if kind == "rune":
		var rune := _rune_catalog.get_rune(id)
		if rune:
			modifier_detail.set_rune(rune)
		else:
			modifier_detail.show_message(tr(str(t.get("name", ""))))
	elif kind == "gem":
		var gem := _gem_catalog.get_gem(id)
		if gem:
			modifier_detail.set_gem(gem)
		else:
			modifier_detail.show_message(tr(str(t.get("name", ""))))
	else:
		modifier_detail.clear()


func _sync_footer() -> void:
	if _footer == null or not visible:
		return
	var seal := {}
	if not _entries.is_empty():
		seal = _sealable_template(_entries[_index])
	if seal.is_empty():
		_footer.set_prompts([
			{"action": "back", "button": "Esc", "label": tr("BACK")},
		])
	else:
		_footer.set_prompts([
			{"action": "register", "button": "Enter", "label": tr("REGISTER")},
			{"action": "back", "button": "Esc", "label": tr("BACK")},
		])


func _on_footer_action(action: String) -> void:
	if not visible:
		return
	match action:
		"back":
			if _confirming:
				_confirming = false
				_update_detail()
				_sync_footer()
			else:
				close()
		"register":
			_try_seal()


func _try_seal() -> void:
	if _entries.is_empty() or _ui_manager == null or _ui_manager.inventory_data == null:
		return
	var seal := _sealable_template(_entries[_index])
	if seal.is_empty():
		return
	if not _confirming:
		_confirming = true
		_seal_kind = str(seal.get("kind", ""))
		_seal_id = str(seal.get("id", ""))
		_update_detail()
		_sync_footer()
		return
	var meta := _meta()
	var result := CardRegistrationService.register(
		_ui_manager.inventory_data,
		meta,
		str(seal.get("kind", "")),
		str(seal.get("uid", "")),
		_rune_catalog,
		_gem_catalog
	)
	_confirming = false
	if bool(result.get("ok", false)):
		SaveManager.set_card_meta(result["meta"] as Dictionary)
		if SaveManager.current_slot >= 0:
			SaveManager.save_game(
				SaveManager.current_slot,
				_ui_manager.character_stats,
				_ui_manager.inventory_data
			)
		_ui_manager.refresh_character_views()
	_rebuild_grid()
	_refresh_texts()


func _move_selection(delta_x: int, delta_y: int) -> void:
	if _entries.is_empty():
		return
	var cols := GRID_COLUMNS
	var row := int(_index / cols)
	var col := _index % cols
	var rows := int(ceil(float(_entries.size()) / float(cols)))
	col = clampi(col + delta_x, 0, cols - 1)
	row = clampi(row + delta_y, 0, rows - 1)
	var next := row * cols + col
	if next >= _entries.size():
		next = _entries.size() - 1
	_index = next
	_confirming = false
	_apply_focus()
	_update_detail()
	_sync_footer()


func _cycle_shelf(direction: int) -> void:
	var ids: Array[StringName] = ShelfDefinition.ALL_SHELF_IDS
	var idx := ids.find(_shelf_id)
	if idx < 0:
		idx = 0
	idx = (idx + direction + ids.size()) % ids.size()
	_shelf_id = ids[idx]
	_index = 0
	_confirming = false
	_rebuild_grid()
	_refresh_texts()


func _unhandled_input(event: InputEvent) -> void:
	if not _active or event.is_echo():
		return
	if event.is_action_pressed("ui_cancel"):
		if _confirming:
			_confirming = false
			_update_detail()
			_sync_footer()
		else:
			close()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("inventory_category_prev"):
		_cycle_shelf(-1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("inventory_category_next"):
		_cycle_shelf(1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_left"):
		_move_selection(-1, 0)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_right"):
		_move_selection(1, 0)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_up"):
		_move_selection(0, -1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_down"):
		_move_selection(0, 1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept"):
		_try_seal()
		get_viewport().set_input_as_handled()
