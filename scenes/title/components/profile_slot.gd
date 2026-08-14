class_name ProfileSlot
extends VBoxContainer

signal activated(slot: int, is_new: bool)
signal deleted(slot: int)

enum State { EMPTY, OCCUPIED, CONFIRM_DELETE_1, CONFIRM_DELETE_2 }

var slot_index: int = 0
var _status: String = "empty"
var _meta: Dictionary = {}
var _state: State = State.EMPTY
var _confirm_choice: int = 1  # 0 = Yes, 1 = No (default No like reference)
var _highlighted: bool = false

@onready var card_panel: PanelContainer = %CardPanel
@onready var body_button: Button = %BodyButton
@onready var empty_label: Label = %EmptyLabel
@onready var occupied_block: VBoxContainer = %OccupiedBlock
@onready var name_label: Label = %NameLabel
@onready var level_label: Label = %LevelLabel
@onready var playtime_label: Label = %PlaytimeLabel
@onready var status_label: Label = %StatusLabel
@onready var slot_number_label: Label = %SlotNumberLabel
@onready var delete_panel: PanelContainer = %DeletePanel
@onready var delete_button: Button = %DeleteButton
@onready var confirm_block: VBoxContainer = %ConfirmBlock
@onready var confirm_question: Label = %ConfirmQuestion
@onready var yes_label: Label = %YesLabel
@onready var no_label: Label = %NoLabel


func _ready() -> void:
	body_button.pressed.connect(_on_body_pressed)
	body_button.focus_entered.connect(_on_body_focus_entered)
	body_button.focus_exited.connect(_on_body_focus_exited)
	body_button.mouse_entered.connect(_on_body_mouse_entered)
	delete_button.pressed.connect(_on_delete_pressed)
	delete_button.focus_entered.connect(_on_delete_focus_entered)
	delete_button.focus_exited.connect(_on_delete_focus_exited)
	delete_button.mouse_entered.connect(_on_delete_mouse_entered)
	delete_panel.mouse_entered.connect(_on_delete_mouse_entered)
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


func can_focus_delete() -> bool:
	return _state == State.OCCUPIED


func is_delete_focused() -> bool:
	return can_focus_delete() and delete_button.has_focus()


func grab_delete_focus() -> void:
	if not can_focus_delete():
		return
	_highlighted = true
	delete_button.grab_focus()
	_apply_panel_style()


func is_confirming() -> bool:
	return _state == State.CONFIRM_DELETE_1 or _state == State.CONFIRM_DELETE_2


func cancel_confirm() -> void:
	if is_confirming():
		_state = State.OCCUPIED
		_confirm_choice = 1
		_refresh_visual()
		_apply_panel_style()
		if _highlighted:
			body_button.grab_focus()


func handle_ui_input(event: InputEvent) -> bool:
	if not visible:
		return false
	if is_confirming():
		if event.is_action_pressed("ui_up"):
			_confirm_choice = 0
			_refresh_confirm_choice()
			return true
		if event.is_action_pressed("ui_down"):
			_confirm_choice = 1
			_refresh_confirm_choice()
			return true
		if event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right"):
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
	_apply_panel_style()

	body_button.flat = true
	body_button.focus_mode = Control.FOCUS_ALL
	var empty := StyleBoxEmpty.new()
	for state_name in ["normal", "hover", "pressed", "focus", "disabled"]:
		body_button.add_theme_stylebox_override(state_name, empty)

	delete_button.flat = true
	delete_button.focus_mode = Control.FOCUS_CLICK
	delete_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	delete_button.add_theme_font_size_override("font_size", 18)
	var delete_empty := StyleBoxEmpty.new()
	for state_name in ["normal", "hover", "pressed", "focus", "disabled"]:
		delete_button.add_theme_stylebox_override(state_name, delete_empty)
	delete_button.add_theme_color_override("font_color", UIColors.TEXT_MUTED)
	delete_button.add_theme_color_override("font_hover_color", UIColors.NEGATIVE)
	delete_button.add_theme_color_override("font_focus_color", UIColors.NEGATIVE)
	delete_button.add_theme_color_override("font_pressed_color", UIColors.NEGATIVE)


func _on_body_focus_entered() -> void:
	_highlighted = true
	_apply_panel_style()


func _on_body_focus_exited() -> void:
	call_deferred("_refresh_highlight_from_focus")


func _on_delete_focus_entered() -> void:
	_highlighted = true
	_apply_panel_style()


func _on_delete_focus_exited() -> void:
	call_deferred("_refresh_highlight_from_focus")


func _on_delete_mouse_entered() -> void:
	if is_confirming() or not can_focus_delete():
		return
	if not delete_button.has_focus():
		grab_delete_focus()


func _refresh_highlight_from_focus() -> void:
	if is_confirming():
		return
	_highlighted = body_button.has_focus() or delete_button.has_focus()
	_apply_panel_style()


func _on_body_mouse_entered() -> void:
	if is_confirming():
		return
	if not body_button.has_focus():
		body_button.grab_focus()


func _apply_panel_style() -> void:
	_apply_box_style(card_panel, (_highlighted and not is_delete_focused()) or is_confirming(), 16, 12)
	_apply_box_style(delete_panel, is_delete_focused(), 6, 6)


func _apply_box_style(panel: PanelContainer, selected: bool, margin_top: int, margin_bottom: int) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = UIColors.with_alpha(UIColors.SLOT_BG_SOLID, 0.85)
	if selected:
		style.border_color = UIColors.SELECT_BORDER
		style.set_border_width_all(2)
	else:
		style.border_color = UIColors.SLOT_BORDER
		style.set_border_width_all(1)
	style.set_corner_radius_all(2)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = margin_top
	style.content_margin_bottom = margin_bottom
	panel.add_theme_stylebox_override("panel", style)


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
	status_label.visible = false
	body_button.visible = true
	body_button.disabled = false
	_set_delete_box_active(false)

	match _state:
		State.EMPTY:
			empty_label.visible = true
			empty_label.text = tr("New Game")
			empty_label.add_theme_color_override("font_color", UIColors.TEXT_MUTED)
		State.OCCUPIED:
			occupied_block.visible = true
			_set_delete_box_active(true)
			delete_button.text = tr("Delete")
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
	_apply_panel_style()


func _set_delete_box_active(active: bool) -> void:
	# Keep the panel in layout so the profile card Y does not jump.
	delete_panel.visible = true
	delete_panel.modulate = Color.WHITE if active else UIColors.CLEAR
	delete_panel.mouse_filter = Control.MOUSE_FILTER_STOP if active else Control.MOUSE_FILTER_IGNORE
	delete_button.mouse_filter = Control.MOUSE_FILTER_STOP if active else Control.MOUSE_FILTER_IGNORE
	delete_button.focus_mode = Control.FOCUS_CLICK if active else Control.FOCUS_NONE


func _fill_occupied_labels() -> void:
	match _status:
		"valid":
			name_label.visible = false
			name_label.text = ""
			level_label.text = tr("Level %d") % int(_meta.get("level", 0))
			playtime_label.text = _format_playtime(int(_meta.get("play_time_sec", 0)))
			level_label.add_theme_color_override("font_color", UIColors.TEXT_MAIN)
			playtime_label.add_theme_color_override("font_color", UIColors.TEXT_MUTED)
		"corrupt":
			name_label.visible = true
			name_label.text = tr("Corrupt")
			level_label.text = ""
			playtime_label.text = ""
			name_label.add_theme_color_override("font_color", UIColors.NEGATIVE)
		"incompatible":
			name_label.visible = true
			name_label.text = tr("Incompatible")
			level_label.text = ""
			playtime_label.text = ""
			name_label.add_theme_color_override("font_color", UIColors.NEGATIVE)
		_:
			name_label.visible = true
			name_label.text = "?"
			level_label.text = ""
			playtime_label.text = ""


func _refresh_confirm_choice() -> void:
	yes_label.text = tr("Yes")
	no_label.text = tr("No")
	_apply_choice_style(yes_label, _confirm_choice == 0)
	_apply_choice_style(no_label, _confirm_choice == 1)


func _apply_choice_style(label: Label, selected: bool) -> void:
	UISelectStyle.apply_label(label, selected, UIColors.TEXT_MUTED)


func _format_playtime(sec: int) -> String:
	var hours := sec / 3600
	var minutes := (sec % 3600) / 60
	return tr("%dH %dM") % [hours, minutes]
