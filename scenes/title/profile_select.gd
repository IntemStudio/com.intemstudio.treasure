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
		_slots.append(slot_ui)


func _refresh_slots() -> void:
	var infos := SaveManager.list_slots()
	for i in range(_slots.size()):
		var info: Dictionary = infos[i] if i < infos.size() else {"status": "empty", "meta": {}}
		_slots[i].apply_info(info)


func _refresh_texts() -> void:
	title_label.text = tr("Select Profile")
	back_button.text = tr("Back")


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


func _focus_current() -> void:
	if _focus_index < 0 or _focus_index >= _slots.size():
		return
	_slots[_focus_index].grab_slot_focus()


func _unhandled_input(event: InputEvent) -> void:
	if not _active or not visible:
		return

	var confirming := _slots[_focus_index] if _focus_index >= 0 and _focus_index < _slots.size() else null
	if confirming and confirming.is_confirming():
		if confirming.handle_ui_input(event):
			get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("ui_left"):
		_focus_index = (_focus_index - 1 + _slots.size()) % _slots.size()
		_focus_current()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_right"):
		_focus_index = (_focus_index + 1) % _slots.size()
		_focus_current()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_down"):
		back_button.grab_focus()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_up"):
		_focus_current()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept"):
		if confirming:
			confirming.handle_ui_input(event)
			get_viewport().set_input_as_handled()
