class_name RegistrationAltar
extends Control

signal closed

const FOOTER_SCENE := preload("res://ui/shared/footer_prompts.tscn")
const SLOT_SCENE := preload("res://ui/village/components/altar_card_slot.tscn")
const GRID_COLUMNS := 4

@onready var title_label: Label = %TitleLabel
@onready var list_host: GridContainer = %ListHost
@onready var empty_label: Label = %EmptyLabel
@onready var grid_hint: Label = %GridHint
@onready var detail_body: Label = %DetailBody
@onready var registered_label: Label = %RegisteredLabel
@onready var footer_host: Control = %FooterHost

var _ui_manager: UIManager
var _footer: FooterPrompts
var _footer_connected: bool = false
var _active: bool = false
var _entries: Array[Dictionary] = []
var _index: int = 0
var _slots: Array[AltarCardSlot] = []
var _rune_catalog := RuneCatalog.new()
var _gem_catalog := GemCatalog.new()
var _confirming: bool = false


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED
	_ensure_footer()
	LocaleManager.locale_changed.connect(_on_locale_changed)
	_refresh_texts()


func setup(ui_manager: UIManager) -> void:
	_ui_manager = ui_manager


func open() -> void:
	_active = true
	_confirming = false
	visible = true
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	get_tree().paused = true
	_rebuild_grid()
	_refresh_texts()
	_sync_footer()
	if _ui_manager:
		_ui_manager.set_challenge_board_open(true)


func close() -> void:
	if not _active:
		return
	_active = false
	_confirming = false
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED
	get_tree().paused = false
	if _ui_manager:
		_ui_manager.set_challenge_board_open(false)
	closed.emit()


func is_open() -> bool:
	return _active


func _ensure_footer() -> void:
	if footer_host == null or _footer != null:
		return
	_footer = FOOTER_SCENE.instantiate() as FooterPrompts
	footer_host.add_child(_footer)
	_footer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _on_locale_changed(_locale: String) -> void:
	_refresh_texts()
	_rebuild_grid()


func _refresh_texts() -> void:
	if title_label:
		title_label.text = tr("Altar")
	if grid_hint:
		grid_hint.text = tr("Select a rune or gem")
	if empty_label:
		empty_label.text = tr("No runes or gems to register")
	_update_detail()
	_update_registered()
	_sync_footer()


func _rebuild_grid() -> void:
	_slots.clear()
	if list_host:
		for child in list_host.get_children():
			child.queue_free()
	_entries.clear()
	if _ui_manager and _ui_manager.inventory_data:
		_entries = CardRegistrationService.list_registerable(_ui_manager.inventory_data)
	_index = clampi(_index, 0, maxi(0, _entries.size() - 1))

	var has_entries := not _entries.is_empty()
	if empty_label:
		empty_label.visible = not has_entries
	if list_host:
		list_host.visible = has_entries
	if grid_hint:
		grid_hint.visible = has_entries

	for i in _entries.size():
		var e: Dictionary = _entries[i]
		var slot: AltarCardSlot = SLOT_SCENE.instantiate()
		list_host.add_child(slot)
		slot.setup(i)
		slot.set_card(
			_entry_display_name(e),
			str(e.get("kind", "")),
			_entry_rarity(e),
			_is_socketed(str(e.get("uid", "")))
		)
		slot.slot_pressed.connect(_on_entry_pressed)
		slot.slot_activated.connect(_on_entry_activated)
		_slots.append(slot)

	_apply_focus()
	_update_detail()


func _entry_display_name(e: Dictionary) -> String:
	var kind := str(e.get("kind", ""))
	var id := str(e.get("id", ""))
	if kind == "rune":
		var def := _rune_catalog.get_rune(id)
		return def.display_name if def else id
	var gdef := _gem_catalog.get_gem(id)
	return gdef.display_name if gdef else id


func _entry_rarity(e: Dictionary) -> ItemData.ItemRarity:
	var kind := str(e.get("kind", ""))
	var id := str(e.get("id", ""))
	if kind == "rune":
		var def := _rune_catalog.get_rune(id)
		return def.rarity if def else ItemData.ItemRarity.COMMON
	var gdef := _gem_catalog.get_gem(id)
	return gdef.rarity if gdef else ItemData.ItemRarity.COMMON


func _is_socketed(uid: String) -> bool:
	if uid.is_empty() or _ui_manager == null or _ui_manager.inventory_data == null:
		return false
	var inventory := _ui_manager.inventory_data
	for slot_id in InventoryData.EQUIP_SLOTS:
		var item: ItemData = inventory.equipped.get(slot_id) as ItemData
		if item == null:
			continue
		for entry in item.socketed:
			if entry is Dictionary and str(entry.get("instance_uid", "")) == uid:
				return true
	return false


func _on_entry_pressed(i: int) -> void:
	_index = i
	_confirming = false
	_apply_focus()
	_update_detail()
	_sync_footer()


func _on_entry_activated(i: int) -> void:
	_index = i
	_apply_focus()
	_try_register()


func _apply_focus() -> void:
	for i in _slots.size():
		_slots[i].set_selected(i == _index)


func _update_detail() -> void:
	if detail_body == null:
		return
	if _entries.is_empty():
		detail_body.text = tr("No runes or gems to register")
		return
	var e: Dictionary = _entries[_index]
	var kind := str(e.get("kind", ""))
	var id := str(e.get("id", ""))
	var uid := str(e.get("uid", ""))
	var lines: PackedStringArray = []
	var kind_label := tr("Rune") if kind == "rune" else tr("Gem")
	lines.append("%s: %s" % [kind_label, _entry_display_name(e)])
	if _is_socketed(uid):
		lines.append(tr("Currently equipped"))
	else:
		lines.append(tr("In storage"))
	if kind == "rune":
		var def := _rune_catalog.get_rune(id)
		if def:
			lines.append("%s: %s #%d" % [tr("Shelf"), String(def.shelf_id), def.card_number])
			lines.append("%s: %s" % [tr("Skill"), def.skill_name])
			lines.append("%s: %d" % [tr("Mana cost"), def.mana_cost])
		if _confirming:
			lines.append("")
			lines.append(tr("Confirm register rune"))
	else:
		var gdef := _gem_catalog.get_gem(id)
		if gdef:
			lines.append("%s: %s #%d" % [tr("Shelf"), String(gdef.shelf_id), gdef.card_number])
			lines.append("%s: %s" % [tr("Type"), String(gdef.gem_type)])
		if _confirming:
			lines.append("")
			lines.append(tr("Confirm register gem"))
	detail_body.text = "\n".join(lines)


func _update_registered() -> void:
	if registered_label == null or _ui_manager == null:
		return
	var meta := CardRegistrationService.ensure_meta(SaveManager.get_card_meta())
	var cards: Array = meta.get("registered_cards", []) as Array
	registered_label.text = "%s: %d" % [tr("Registered cards"), cards.size()]


func _sync_footer() -> void:
	_ensure_footer()
	if _footer == null:
		return
	if _entries.is_empty():
		_footer.set_prompts([
			{"action": "back", "button": "Esc", "label": tr("BACK")},
		])
	else:
		_footer.set_prompts([
			{"action": "register", "button": "Enter", "label": tr("REGISTER")},
			{"action": "back", "button": "Esc", "label": tr("BACK")},
		])
	if not _footer_connected:
		_footer.prompt_activated.connect(_on_footer_action)
		_footer_connected = true


func _on_footer_action(action: String) -> void:
	match action:
		"back":
			if _confirming:
				_confirming = false
				_update_detail()
				_sync_footer()
			else:
				close()
		"register":
			_try_register()


func _try_register() -> void:
	if _entries.is_empty() or _ui_manager == null or _ui_manager.inventory_data == null:
		return
	if not _confirming:
		_confirming = true
		_update_detail()
		_sync_footer()
		return
	var e: Dictionary = _entries[_index]
	var meta := CardRegistrationService.ensure_meta(SaveManager.get_card_meta())
	var result := CardRegistrationService.register(
		_ui_manager.inventory_data,
		meta,
		str(e.get("kind", "")),
		str(e.get("uid", "")),
		_rune_catalog,
		_gem_catalog
	)
	if bool(result.get("ok", false)):
		SaveManager.set_card_meta(result["meta"] as Dictionary)
		if SaveManager.current_slot >= 0:
			SaveManager.save_game(SaveManager.current_slot, _ui_manager.character_stats, _ui_manager.inventory_data)
		_ui_manager.refresh_character_views()
	_confirming = false
	_index = 0
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
	if event.is_action_pressed("ui_left"):
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
		_try_register()
		get_viewport().set_input_as_handled()
