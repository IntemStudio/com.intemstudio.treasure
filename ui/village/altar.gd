class_name VillageAltar
extends Control

signal request_close

const SLOT_SCENE := preload("res://ui/village/components/altar_card_slot.tscn")

@onready var rune_tab: CategoryTab = %RuneTab
@onready var gem_tab: CategoryTab = %GemTab
@onready var hint_label: Label = %HintLabel
@onready var list_host: VBoxContainer = %ListHost
@onready var modifier_detail: ModifierDetailPanel = %ModifierDetailPanel
@onready var detail_status: Label = %DetailStatus

var _ui_manager: UIManager
var _footer: FooterPrompts
var _footer_connected: bool = false
var _active: bool = false
var _confirming: bool = false
var _kind: String = "rune"
var _entries: Array[Dictionary] = []
var _index: int = 0
var _slots: Array[AltarCardSlot] = []
var _rune_catalog := RuneCatalog.new()
var _gem_catalog := GemCatalog.new()


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED
	UIPopupLayout.apply_column_panels([$Main/Split/LeftColumn, $Main/Split/RightColumn])
	UIPopupLayout.flatten_inner_panel(modifier_detail)
	UIPopupLayout.apply_slot_grid_pad(%ListHostPad)
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
	_rebuild_list()
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
		_rebuild_list()
		_refresh_texts()


func close() -> void:
	if not _active:
		return
	request_close.emit()


func _wire_tabs() -> void:
	if rune_tab:
		rune_tab.tab_selected.connect(_on_kind_tab.bind("rune"))
	if gem_tab:
		gem_tab.tab_selected.connect(_on_kind_tab.bind("gem"))


func _on_kind_tab(_id: String, kind: String) -> void:
	_kind = kind
	_index = 0
	_confirming = false
	_rebuild_list()
	_refresh_texts()


func _on_locale_changed(_locale: String) -> void:
	_refresh_texts()
	if _active:
		_rebuild_list()


func _meta() -> Dictionary:
	return CardRegistrationService.ensure_meta_seeded(
		SaveManager.get_card_meta(), _rune_catalog, _gem_catalog
	)


func _refresh_texts() -> void:
	if rune_tab:
		rune_tab.setup("rune", "[%s]" % tr("SHELF_RUNE"))
		rune_tab.set_active(_kind == "rune")
	if gem_tab:
		gem_tab.setup("gem", "[%s]" % tr("SHELF_GEM"))
		gem_tab.set_active(_kind == "gem")
	if hint_label:
		hint_label.text = tr("ALTAR_HINT")
	_update_detail()
	_sync_footer()


func _offerable_entries() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var inventory: InventoryData = _ui_manager.inventory_data if _ui_manager else null
	if inventory == null:
		return out
	var meta := _meta()
	var ids: Array = _rune_catalog.all_ids() if _kind == "rune" else _gem_catalog.all_ids()
	ids.sort()
	for raw_id in ids:
		var id := str(raw_id)
		if CardRegistrationService.is_id_registered(meta, _kind, id):
			continue
		var uid := CardRegistrationService.first_owned_uid(inventory, _kind, id)
		if uid.is_empty():
			continue
		var display_name := id
		var icon: Texture2D = null
		if _kind == "rune":
			var rune := _rune_catalog.get_rune(id)
			if rune:
				display_name = rune.display_name
				icon = rune.icon
		else:
			var gem := _gem_catalog.get_gem(id)
			if gem:
				display_name = gem.display_name
				icon = gem.icon
		out.append({
			"kind": _kind,
			"id": id,
			"uid": uid,
			"name": display_name,
			"icon": icon,
		})
	return out


func _rebuild_list() -> void:
	_slots.clear()
	_entries = _offerable_entries()
	if list_host:
		for child in list_host.get_children():
			child.queue_free()
	_index = clampi(_index, 0, maxi(0, _entries.size() - 1))
	for i in _entries.size():
		var e: Dictionary = _entries[i]
		var slot: AltarCardSlot = SLOT_SCENE.instantiate()
		list_host.add_child(slot)
		slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slot.setup(i)
		slot.set_card(
			tr(str(e.get("name", ""))),
			ItemData.ItemRarity.COMMON,
			false,
			false,
			true,
			e.get("icon") as Texture2D
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


func _current() -> Dictionary:
	if _entries.is_empty() or _index < 0 or _index >= _entries.size():
		return {}
	return _entries[_index]


func _update_detail() -> void:
	if modifier_detail == null:
		return
	if detail_status:
		detail_status.text = ""
	var e := _current()
	if e.is_empty():
		modifier_detail.show_message(tr("No runes or gems to register"))
		return
	var kind := str(e.get("kind", ""))
	var id := str(e.get("id", ""))
	if kind == "rune":
		var rune := _rune_catalog.get_rune(id)
		if rune:
			modifier_detail.set_rune(rune)
		else:
			modifier_detail.show_message(tr(str(e.get("name", ""))))
	elif kind == "gem":
		var gem := _gem_catalog.get_gem(id)
		if gem:
			modifier_detail.set_gem(gem)
		else:
			modifier_detail.show_message(tr(str(e.get("name", ""))))
	else:
		modifier_detail.clear()
	if detail_status:
		if _confirming:
			if kind == "rune":
				detail_status.text = tr("Confirm register rune")
			else:
				detail_status.text = tr("Confirm register gem")
		else:
			detail_status.text = tr("In storage")


func _sync_footer() -> void:
	if _footer == null or not visible:
		return
	if _current().is_empty():
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
	if _ui_manager == null or _ui_manager.inventory_data == null:
		return
	var e := _current()
	if e.is_empty():
		return
	if not _confirming:
		_confirming = true
		_update_detail()
		_sync_footer()
		return
	var result := CardRegistrationService.register(
		_ui_manager.inventory_data,
		_meta(),
		str(e.get("kind", "")),
		str(e.get("uid", "")),
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
		_ui_manager.refresh_bookshelf()
	_rebuild_list()
	_refresh_texts()


func _move_selection(delta: int) -> void:
	if _entries.is_empty():
		return
	_index = clampi(_index + delta, 0, _entries.size() - 1)
	_confirming = false
	_apply_focus()
	_update_detail()
	_sync_footer()


func _cycle_kind(_direction: int) -> void:
	_kind = "gem" if _kind == "rune" else "rune"
	_index = 0
	_confirming = false
	_rebuild_list()
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
		_cycle_kind(-1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("inventory_category_next"):
		_cycle_kind(1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_up"):
		_move_selection(-1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_down"):
		_move_selection(1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept"):
		_try_seal()
		get_viewport().set_input_as_handled()
