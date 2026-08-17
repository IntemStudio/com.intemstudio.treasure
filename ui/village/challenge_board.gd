class_name ChallengeBoard
extends Control

signal closed
signal request_close
signal challenge_confirmed(params: Dictionary)

enum FocusColumn { COMPASS = 0, ZONE = 1 }

const DUNGEON_SCENE := "res://scenes/dungeon/dungeon.tscn"

@onready var zone_section_label: Label = %ZoneSectionLabel
@onready var zone_list: VBoxContainer = %ZoneList
@onready var detail_title: Label = %DetailTitle
@onready var detail_body: Label = %DetailBody
@onready var verse_label: Label = %VerseLabel
@onready var cemetery_button: Button = %CemeteryButton
@onready var grove_button: Button = %GroveButton
@onready var mansion_button: Button = %MansionButton
@onready var battlefield_button: Button = %BattlefieldButton
@onready var center_button: Button = %CenterButton
@onready var npc_name: Label = %NpcName
@onready var npc_line: Label = %NpcLine

var _ui_manager: UIManager
var _footer: FooterPrompts
var _footer_connected: bool = false
var _active: bool = false
var _focus_column: int = FocusColumn.COMPASS
var _dungeon_id: String = ChallengeDef.DUNGEON_ID_DEFAULT
var _zone_index: int = 0
var _open_zones: Array[Dictionary] = []
var _zone_buttons: Array[Button] = []


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED
	UIPopupLayout.apply_column_panels([$Main/Split/Lists, $Main/Split/Detail])
	_wire_compass()
	LocaleManager.locale_changed.connect(_on_locale_changed)
	_refresh_texts()


func setup(ui_manager: UIManager, footer: FooterPrompts = null) -> void:
	_ui_manager = ui_manager
	if footer:
		_footer = footer
	if _footer and not _footer_connected:
		_footer.prompt_activated.connect(_on_footer_prompt)
		_footer_connected = true


func activate(_stats: CharacterStats = null, _inventory: InventoryData = null) -> void:
	_active = true
	visible = true
	process_mode = Node.PROCESS_MODE_INHERIT
	_focus_column = FocusColumn.COMPASS
	_dungeon_id = ChallengeDef.DUNGEON_ID_DEFAULT
	_zone_index = 0
	_rebuild_zones()
	_refresh_texts()
	_apply_focus()
	_sync_footer()


func deactivate() -> void:
	_active = false
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED


func open() -> void:
	activate()


func close() -> void:
	if not _active:
		return
	request_close.emit()
	closed.emit()


func is_open() -> bool:
	return _active


func _meta() -> Dictionary:
	return SaveManager.get_card_meta()


func _wire_compass() -> void:
	if cemetery_button:
		cemetery_button.pressed.connect(_on_compass_pressed.bind("cemetery"))
	if grove_button:
		grove_button.pressed.connect(_on_compass_pressed.bind("grove"))
	if mansion_button:
		mansion_button.pressed.connect(_on_compass_pressed.bind("mansion"))
	if battlefield_button:
		battlefield_button.pressed.connect(_on_compass_pressed.bind("battlefield"))
	if center_button:
		center_button.pressed.connect(_on_center_pressed)


func _on_compass_pressed(dungeon_id: String) -> void:
	_focus_column = FocusColumn.COMPASS
	_dungeon_id = dungeon_id
	_zone_index = 0
	_rebuild_zones()
	_apply_focus()


func _on_center_pressed() -> void:
	_focus_column = FocusColumn.COMPASS
	if BasinProgress.can_open_altar(_meta()):
		_dungeon_id = ChallengeDef.DUNGEON_ALTAR
		_zone_index = 0
		_rebuild_zones()
	_apply_focus()


func _make_list_button(label_key: String) -> Button:
	var button := Button.new()
	button.flat = true
	button.focus_mode = Control.FOCUS_ALL
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_size_override("font_size", 22)
	button.text = tr(label_key)
	return button


func _rebuild_zones() -> void:
	_open_zones = BasinProgress.list_open_zones_for(_meta(), _dungeon_id)
	if zone_list == null:
		return
	for child in zone_list.get_children():
		child.queue_free()
	_zone_buttons.clear()
	for i in range(_open_zones.size()):
		var zone: Dictionary = _open_zones[i]
		var button := _make_list_button(str(zone.get("title_key", "")))
		button.pressed.connect(_on_zone_pressed.bind(i))
		button.focus_entered.connect(_on_zone_focus_entered.bind(i))
		zone_list.add_child(button)
		_zone_buttons.append(button)
	_zone_index = clampi(_zone_index, 0, maxi(_open_zones.size() - 1, 0))


func _refresh_texts() -> void:
	if npc_name:
		npc_name.text = tr("NPC_PELL")
		npc_name.add_theme_color_override("font_color", UIColors.TEXT_LORE)
	if npc_line:
		npc_line.text = tr("NPC_PELL_LINE")
		npc_line.add_theme_color_override("font_color", UIColors.TEXT_MUTED)
	if zone_section_label:
		zone_section_label.text = tr("STONE_LABEL")
		zone_section_label.add_theme_color_override("font_color", UIColors.TEXT_MUTED)
	if cemetery_button:
		cemetery_button.text = tr("REGION_CEMETERY")
	if grove_button:
		grove_button.text = tr("REGION_GROVE")
	if mansion_button:
		mansion_button.text = tr("REGION_MANSION")
	if battlefield_button:
		battlefield_button.text = tr("REGION_BATTLEFIELD")
	if center_button:
		if BasinProgress.can_open_altar(_meta()):
			center_button.text = tr("LOCATION_ALTAR_BELOW")
			center_button.disabled = false
		else:
			center_button.text = tr("SHELTER_LABEL")
			center_button.disabled = true
	if detail_title:
		detail_title.add_theme_color_override("font_color", UIColors.GOLD)
	if detail_body:
		detail_body.add_theme_color_override("font_color", UIColors.TEXT_LORE)
	if verse_label:
		verse_label.add_theme_color_override("font_color", UIColors.TEXT_MUTED)
	for i in range(_zone_buttons.size()):
		if i < _open_zones.size():
			_zone_buttons[i].text = tr(str(_open_zones[i].get("title_key", "")))
	_refresh_detail()
	if _active:
		_sync_footer()


func _refresh_detail() -> void:
	var meta := _meta()
	var verses: Array = meta.get("verses_read", []) as Array
	if _open_zones.is_empty():
		if detail_title:
			detail_title.text = tr("SHELTER_LABEL")
		if detail_body:
			detail_body.text = tr("QUESTION_FOG")
		_refresh_verses(verses)
		return
	var zone: Dictionary = _open_zones[_zone_index]
	var zone_id := str(zone.get("id", ""))
	if detail_title:
		detail_title.text = tr(str(zone.get("title_key", "")))
	var desc_key := ChallengeDef.desc_key_for(_dungeon_id, zone_id, verses)
	if detail_body:
		detail_body.text = tr(desc_key) if not desc_key.is_empty() else tr("QUESTION_FOG")
	_refresh_verses(verses)


func _refresh_verses(verses: Array) -> void:
	if verse_label == null:
		return
	var lines: PackedStringArray = PackedStringArray()
	for dungeon_id in ["cemetery", "grove", "mansion", "battlefield"]:
		var key := ChallengeDef.verse_line_key(dungeon_id)
		if verses.has(dungeon_id):
			lines.append(tr(key))
		else:
			lines.append("…")
	verse_label.text = "\n".join(lines)


func _style_button(button: Button, selected: bool, column_active: bool) -> void:
	var focused := selected and column_active
	UISelectStyle.apply_button(button, focused, UIColors.TEXT_MUTED, true)
	if selected and not focused:
		button.add_theme_color_override("font_color", UIColors.GOLD)
		button.add_theme_color_override("font_focus_color", UIColors.GOLD)


func _compass_button_for(dungeon_id: String) -> Button:
	match dungeon_id:
		"cemetery":
			return cemetery_button
		"grove":
			return grove_button
		"mansion":
			return mansion_button
		"battlefield":
			return battlefield_button
		ChallengeDef.DUNGEON_ALTAR:
			return center_button
		_:
			return null


func _apply_focus() -> void:
	_zone_index = clampi(_zone_index, 0, maxi(_zone_buttons.size() - 1, 0))
	var compass_ids: Array[String] = [
		"cemetery", "grove", "mansion", "battlefield", ChallengeDef.DUNGEON_ALTAR
	]
	for dungeon_id in compass_ids:
		var btn := _compass_button_for(dungeon_id)
		if btn == null:
			continue
		var selected: bool = _dungeon_id == dungeon_id
		_style_button(btn, selected, _focus_column == FocusColumn.COMPASS)
	for i in range(_zone_buttons.size()):
		_style_button(
			_zone_buttons[i],
			i == _zone_index,
			_focus_column == FocusColumn.ZONE
		)
	var focus_btn: Button = null
	if _focus_column == FocusColumn.ZONE and not _zone_buttons.is_empty():
		focus_btn = _zone_buttons[_zone_index]
	else:
		focus_btn = _compass_button_for(_dungeon_id)
		if focus_btn and focus_btn.disabled:
			focus_btn = cemetery_button
	if focus_btn:
		focus_btn.grab_focus()
	_refresh_detail()


func _sync_footer() -> void:
	if _footer == null:
		return
	_footer.set_prompts([
		{"button": "Esc", "label": tr("Back"), "action": "back"},
		{"button": "Enter", "label": tr("Challenge"), "action": "challenge"},
	])


func _on_footer_prompt(action: String) -> void:
	if not visible:
		return
	match action:
		"back":
			close()
		"challenge":
			_confirm_challenge()


func _on_zone_pressed(index: int) -> void:
	_focus_column = FocusColumn.ZONE
	_zone_index = index
	_apply_focus()


func _on_zone_focus_entered(index: int) -> void:
	_focus_column = FocusColumn.ZONE
	_zone_index = index
	_apply_focus()


func _on_locale_changed(_locale: String) -> void:
	_refresh_texts()


func _confirm_challenge() -> void:
	if _open_zones.is_empty():
		return
	var zone: Dictionary = _open_zones[_zone_index]
	var zone_id := str(zone.get("id", ""))
	if not BasinProgress.is_stone_open(_meta(), _dungeon_id, zone_id):
		return
	var params := ChallengeDef.build_run_params(_dungeon_id, zone_id)
	if params.is_empty():
		return
	SaveManager.set_pending_run(params)
	if SaveManager.current_slot >= 0:
		var run := params.duplicate(true)
		if _ui_manager and _ui_manager.inventory_data:
			run.merge(SaveSerializer.run_equipment_snapshot(_ui_manager.inventory_data), true)
		SaveManager.save_run(SaveManager.current_slot, run)
	challenge_confirmed.emit(params)
	request_close.emit()
	get_tree().change_scene_to_file.call_deferred(DUNGEON_SCENE)


func _unhandled_input(event: InputEvent) -> void:
	if not _active or not visible:
		return
	if event.is_echo():
		return
	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_accept"):
		_confirm_challenge()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_left"):
		_focus_column = FocusColumn.COMPASS
		_apply_focus()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_right"):
		if not _zone_buttons.is_empty():
			_focus_column = FocusColumn.ZONE
			_apply_focus()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_up"):
		if _focus_column == FocusColumn.ZONE:
			if not _zone_buttons.is_empty():
				_zone_index = (_zone_index - 1 + _zone_buttons.size()) % _zone_buttons.size()
		else:
			_step_compass(-1)
		_apply_focus()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_down"):
		if _focus_column == FocusColumn.ZONE:
			if not _zone_buttons.is_empty():
				_zone_index = (_zone_index + 1) % _zone_buttons.size()
		else:
			_step_compass(1)
		_apply_focus()
		get_viewport().set_input_as_handled()


func _step_compass(delta: int) -> void:
	var order: Array[String] = ["cemetery", "grove", "mansion", "battlefield"]
	if BasinProgress.can_open_altar(_meta()):
		order.insert(0, ChallengeDef.DUNGEON_ALTAR)
	var idx := order.find(_dungeon_id)
	if idx < 0:
		idx = 0
	_dungeon_id = order[(idx + delta + order.size()) % order.size()]
	_zone_index = 0
	_rebuild_zones()
