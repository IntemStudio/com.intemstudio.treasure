extends Control

signal back_pressed
signal profile_chosen(slot: int, is_new: bool)

const PROFILE_SLOT_SCENE := preload("res://scenes/title/components/profile_slot.tscn")
const GAME_SCENE := "res://scenes/dungeon/dungeon.tscn"

@onready var title_label: Label = %TitleLabel
@onready var slot_row: HBoxContainer = %SlotRow
@onready var back_button: Button = %BackButton

var _slots: Array[ProfileSlot] = []
var _focus_index: int = 0
var _active: bool = false


func _ready() -> void:
	visible = false
	back_button.pressed.connect(_on_back_pressed)
	LocaleManager.locale_changed.connect(_on_locale_changed)
	_style_back_button()
	_build_slots()
	_refresh_texts()


func open() -> void:
	visible = true
	_active = true
	_refresh_slots()
	_focus_index = 0
	_focus_current()


func close() -> void:
	_cancel_all_confirms()
	_active = false
	visible = false


func _build_slots() -> void:
	for child in slot_row.get_children():
		child.queue_free()
	_slots.clear()
	for i in range(SaveManager.SLOT_COUNT):
		var slot_ui: ProfileSlot = PROFILE_SLOT_SCENE.instantiate()
		slot_row.add_child(slot_ui)
		slot_ui.setup(i, {"status": "empty", "meta": {}})
		slot_ui.activated.connect(_on_slot_activated)
		slot_ui.deleted.connect(_on_slot_deleted)
		slot_ui.body_button.focus_entered.connect(_on_slot_focus_entered.bind(i))
		slot_ui.delete_button.focus_entered.connect(_on_slot_focus_entered.bind(i))
		_slots.append(slot_ui)


func _refresh_slots() -> void:
	var infos := SaveManager.list_slots()
	for i in range(_slots.size()):
		var info: Dictionary = infos[i] if i < infos.size() else {"status": "empty", "meta": {}}
		_slots[i].apply_info(info)


func _refresh_texts() -> void:
	title_label.text = tr("Select Profile")
	back_button.text = tr("Back")


func _style_back_button() -> void:
	var padded := StyleBoxEmpty.new()
	padded.content_margin_left = 16
	padded.content_margin_top = 4
	padded.content_margin_bottom = 4
	padded.content_margin_right = 4
	back_button.flat = true
	back_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	back_button.focus_mode = Control.FOCUS_ALL
	for state_name in ["normal", "hover", "pressed", "disabled"]:
		back_button.add_theme_stylebox_override(state_name, padded)
	var focus_style := StyleBoxFlat.new()
	focus_style.bg_color = Color(0, 0, 0, 0)
	focus_style.border_color = UIColors.SELECT_BORDER
	focus_style.border_width_left = 3
	focus_style.content_margin_left = 16
	focus_style.content_margin_top = 4
	focus_style.content_margin_bottom = 4
	focus_style.content_margin_right = 4
	back_button.add_theme_stylebox_override("focus", focus_style)
	back_button.add_theme_color_override("font_color", UIColors.TEXT_MAIN)
	back_button.add_theme_color_override("font_hover_color", UIColors.GOLD)
	back_button.add_theme_color_override("font_focus_color", UIColors.GOLD)


func _on_locale_changed(_locale: String) -> void:
	_refresh_texts()
	_refresh_slots()


func _on_back_pressed() -> void:
	if _any_confirming():
		_cancel_all_confirms()
		return
	close()
	back_pressed.emit()


func _on_slot_activated(slot: int, is_new: bool) -> void:
	if not _active:
		return
	var save: SaveGame = null
	if is_new:
		save = SaveManager.new_game(slot)
	else:
		save = SaveManager.load_game(slot)
	if save == null or save.is_empty():
		_refresh_slots()
		return
	profile_chosen.emit(slot, is_new)
	_active = false
	get_tree().change_scene_to_file(GAME_SCENE)


func _on_slot_deleted(_slot: int) -> void:
	_refresh_slots()
	_focus_current()


func _on_slot_focus_entered(index: int) -> void:
	_focus_index = index


func _any_confirming() -> bool:
	for slot_ui in _slots:
		if slot_ui.is_confirming():
			return true
	return false


func _cancel_all_confirms() -> void:
	for slot_ui in _slots:
		slot_ui.cancel_confirm()


func _current_slot() -> ProfileSlot:
	if _focus_index < 0 or _focus_index >= _slots.size():
		return null
	return _slots[_focus_index]


func _focus_current() -> void:
	var slot := _current_slot()
	if slot == null:
		return
	slot.grab_slot_focus()


func _move_slot(delta: int) -> void:
	_focus_index = (_focus_index + delta + _slots.size()) % _slots.size()
	_focus_current()


func _move_down() -> void:
	var slot := _current_slot()
	if back_button.has_focus():
		return
	if slot and slot.can_focus_delete() and not slot.is_delete_focused():
		slot.grab_delete_focus()
		return
	back_button.grab_focus()


func _move_up() -> void:
	var slot := _current_slot()
	if back_button.has_focus():
		if slot and slot.can_focus_delete():
			slot.grab_delete_focus()
		else:
			_focus_current()
		return
	if slot and slot.is_delete_focused():
		_focus_current()


func _mark_handled() -> void:
	var vp := get_viewport()
	if vp:
		vp.set_input_as_handled()


func _input(event: InputEvent) -> void:
	if not _active or not visible:
		return
	if event.is_echo():
		return

	var slot := _current_slot()
	if slot and slot.is_confirming():
		if slot.handle_ui_input(event):
			_mark_handled()
		return

	if event.is_action_pressed("ui_cancel"):
		_mark_handled()
		_on_back_pressed()
		return

	if event.is_action_pressed("ui_left"):
		_move_slot(-1)
		_mark_handled()
	elif event.is_action_pressed("ui_right"):
		_move_slot(1)
		_mark_handled()
	elif event.is_action_pressed("ui_down"):
		_move_down()
		_mark_handled()
	elif event.is_action_pressed("ui_up"):
		_move_up()
		_mark_handled()


func _unhandled_input(event: InputEvent) -> void:
	if not _active or not visible:
		return
	if event.is_echo():
		return

	var slot := _current_slot()
	if event.is_action_pressed("ui_accept"):
		if slot == null or slot.is_confirming() or slot.is_delete_focused():
			return
		# Mark before activate — scene change frees this node / nulls viewport.
		_mark_handled()
		slot.handle_ui_input(event)
