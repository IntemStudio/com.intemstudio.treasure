class_name ProfileSlot
extends PanelContainer

signal activated(slot: int, is_new: bool)
signal deleted(slot: int)

enum State { EMPTY, OCCUPIED, CONFIRM_DELETE_1, CONFIRM_DELETE_2 }

var slot_index: int = 0
var _status: String = "empty"
var _meta: Dictionary = {}
var _state: State = State.EMPTY
var _confirm_choice: int = 1  # 0 = Yes, 1 = No (default No like reference)

@onready var body_button: Button = %BodyButton
@onready var empty_label: Label = %EmptyLabel
@onready var occupied_block: VBoxContainer = %OccupiedBlock
@onready var name_label: Label = %NameLabel
@onready var level_label: Label = %LevelLabel
@onready var playtime_label: Label = %PlaytimeLabel
@onready var status_label: Label = %StatusLabel
@onready var slot_number_label: Label = %SlotNumberLabel
@onready var delete_button: Button = %DeleteButton
@onready var confirm_block: VBoxContainer = %ConfirmBlock
@onready var confirm_question: Label = %ConfirmQuestion
@onready var yes_label: Label = %YesLabel
@onready var no_label: Label = %NoLabel


func _ready() -> void:
	body_button.pressed.connect(_on_body_pressed)
	delete_button.pressed.connect(_on_delete_pressed)
	yes_label.gui_input.connect(_on_confirm_label_input.bind(0))
	no_label.gui_input.connect(_on_confirm_label_input.bind(1))
	yes_label.mouse_filter = Control.MOUSE_FILTER_STOP
	no_label.mouse_filter = Control.MOUSE_FILTER_STOP
	LocaleManager.locale_changed.connect(_on_locale_changed)
	_apply_style()
	_refresh_visual()


func setup(slot: int, info: Dictionary) -> void:
	slot_index = slot
	apply_info(info)


func apply_info(info: Dictionary) -> void:
	_status = str(info.get("status", "empty"))
	_meta = (info.get("meta", {}) as Dictionary).duplicate(true)
	if _state == State.CONFIRM_DELETE_1 or _state == State.CONFIRM_DELETE_2:
		return
	if _status == "valid":
		_state = State.OCCUPIED
	elif _status == "corrupt" or _status == "incompatible":
		_state = State.OCCUPIED
	else:
		_state = State.EMPTY
	_refresh_visual()


func grab_slot_focus() -> void:
	body_button.grab_focus()


func is_confirming() -> bool:
	return _state == State.CONFIRM_DELETE_1 or _state == State.CONFIRM_DELETE_2


func cancel_confirm() -> void:
	if is_confirming():
		_state = State.OCCUPIED
		_confirm_choice = 1
		_refresh_visual()


func handle_ui_input(event: InputEvent) -> bool:
	if not visible:
		return false
	if is_confirming():
		if event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right"):
			_confirm_choice = 1 - _confirm_choice
			_refresh_confirm_choice()
			return true
		if event.is_action_pressed("ui_accept"):
			_resolve_confirm()
			return true
		if event.is_action_pressed("ui_cancel"):
			cancel_confirm()
			return true
		return false
	if event.is_action_pressed("ui_accept"):
		_on_body_pressed()
		return true
	return false


func _on_locale_changed(_locale: String) -> void:
	_refresh_visual()


func _apply_style() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.06, 0.07, 0.85)
	style.border_color = UIColors.TEXT_MAIN
	style.set_border_width_all(1)
	style.set_corner_radius_all(2)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 16
	style.content_margin_bottom = 12
	add_theme_stylebox_override("panel", style)

	body_button.flat = true
	body_button.focus_mode = Control.FOCUS_ALL
	var empty := StyleBoxEmpty.new()
	for state_name in ["normal", "hover", "pressed", "focus", "disabled"]:
		body_button.add_theme_stylebox_override(state_name, empty)

	delete_button.flat = true
	delete_button.focus_mode = Control.FOCUS_NONE
	delete_button.add_theme_color_override("font_color", UIColors.TEXT_MUTED)
	delete_button.add_theme_color_override("font_hover_color", UIColors.NEGATIVE)


func _on_body_pressed() -> void:
	if is_confirming():
		return
	match _status:
		"empty":
			activated.emit(slot_index, true)
		"valid":
			activated.emit(slot_index, false)
		"corrupt", "incompatible":
			status_label.visible = true
			status_label.text = tr("Cannot load this profile")
		_:
			activated.emit(slot_index, true)


func _on_confirm_label_input(event: InputEvent, choice: int) -> void:
	if not is_confirming():
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_confirm_choice = choice
		_refresh_confirm_choice()
		_resolve_confirm()
		accept_event()


func _on_delete_pressed() -> void:
	if _status != "valid" and _status != "corrupt" and _status != "incompatible":
		return
	_state = State.CONFIRM_DELETE_1
	_confirm_choice = 1
	_refresh_visual()


func _resolve_confirm() -> void:
	if _confirm_choice == 1:
		cancel_confirm()
		return
	if _state == State.CONFIRM_DELETE_1:
		_state = State.CONFIRM_DELETE_2
		_confirm_choice = 1
		_refresh_visual()
		return
	var err := SaveManager.delete_slot(slot_index)
	if err == OK:
		_status = "empty"
		_meta = {}
		_state = State.EMPTY
		_refresh_visual()
		deleted.emit(slot_index)
	else:
		_state = State.OCCUPIED
		status_label.visible = true
		status_label.text = tr("Delete failed")
		_refresh_visual()


func _refresh_visual() -> void:
	slot_number_label.text = "%d." % (slot_index + 1)
	empty_label.visible = false
	occupied_block.visible = false
	confirm_block.visible = false
	delete_button.visible = false
	status_label.visible = false
	body_button.visible = true
	body_button.disabled = false

	match _state:
		State.EMPTY:
			empty_label.visible = true
			empty_label.text = tr("New Game")
			empty_label.add_theme_color_override("font_color", UIColors.TEXT_MUTED)
		State.OCCUPIED:
			occupied_block.visible = true
			delete_button.visible = true
			delete_button.text = "× %s" % tr("Delete")
			_fill_occupied_labels()
		State.CONFIRM_DELETE_1:
			body_button.visible = false
			confirm_block.visible = true
			confirm_question.text = tr("Delete the selected profile?")
			_refresh_confirm_choice()
		State.CONFIRM_DELETE_2:
			body_button.visible = false
			confirm_block.visible = true
			confirm_question.text = tr("Continue?")
			_refresh_confirm_choice()


func _fill_occupied_labels() -> void:
	match _status:
		"valid":
			name_label.text = str(_meta.get("character_name", "?"))
			level_label.text = tr("Level %d") % int(_meta.get("level", 0))
			playtime_label.text = _format_playtime(int(_meta.get("play_time_sec", 0)))
			name_label.add_theme_color_override("font_color", UIColors.TEXT_MAIN)
			level_label.add_theme_color_override("font_color", UIColors.TEXT_MUTED)
			playtime_label.add_theme_color_override("font_color", UIColors.TEXT_MUTED)
		"corrupt":
			name_label.text = tr("Corrupt")
			level_label.text = ""
			playtime_label.text = ""
			name_label.add_theme_color_override("font_color", UIColors.NEGATIVE)
		"incompatible":
			name_label.text = tr("Incompatible")
			level_label.text = ""
			playtime_label.text = ""
			name_label.add_theme_color_override("font_color", UIColors.NEGATIVE)
		_:
			name_label.text = "?"
			level_label.text = ""
			playtime_label.text = ""


func _refresh_confirm_choice() -> void:
	yes_label.text = tr("Yes")
	no_label.text = tr("No")
	if _confirm_choice == 0:
		yes_label.text = "◆ %s ◆" % tr("Yes")
		yes_label.add_theme_color_override("font_color", UIColors.GOLD)
		no_label.add_theme_color_override("font_color", UIColors.TEXT_MUTED)
	else:
		no_label.text = "◆ %s ◆" % tr("No")
		no_label.add_theme_color_override("font_color", UIColors.GOLD)
		yes_label.add_theme_color_override("font_color", UIColors.TEXT_MUTED)


func _format_playtime(sec: int) -> String:
	var hours := sec / 3600
	var minutes := (sec % 3600) / 60
	return tr("%dH %dM") % [hours, minutes]
