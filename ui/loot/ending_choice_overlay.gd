class_name EndingChoiceOverlay
extends Control

signal closed

@onready var title_label: Label = %TitleLabel
@onready var hint_label: Label = %HintLabel
@onready var take_button: Button = %TakeButton
@onready var seal_button: Button = %SealButton
@onready var empty_button: Button = %EmptyButton

var _ui_manager: UIManager
var _active: bool = false
var _on_done: Callable = Callable()
var _allow_seal: bool = true
var _allow_empty: bool = false
var _index: int = 0
var _buttons: Array[Button] = []


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED
	mouse_filter = Control.MOUSE_FILTER_STOP
	var sheet := get_node_or_null("%Sheet") as PanelContainer
	if sheet:
		UIPopupLayout.apply_dialog_panel(sheet)
	if take_button:
		take_button.pressed.connect(_choose.bind(BasinProgress.ENDING_TAKE))
	if seal_button:
		seal_button.pressed.connect(_choose.bind(BasinProgress.ENDING_SEAL))
	if empty_button:
		empty_button.pressed.connect(_choose.bind(BasinProgress.ENDING_EMPTY))
	if LocaleManager:
		LocaleManager.locale_changed.connect(_on_locale_changed)
	_refresh_texts()


func setup(ui_manager: UIManager) -> void:
	_ui_manager = ui_manager


func open(allow_seal: bool, allow_empty: bool, on_done: Callable) -> void:
	_allow_seal = allow_seal
	_allow_empty = allow_empty
	_on_done = on_done
	_active = true
	visible = true
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	get_tree().paused = true
	if _ui_manager:
		_ui_manager.set_challenge_board_open(true)
	_refresh_texts()
	_rebuild_buttons()
	_index = 0
	_apply_focus()


func close() -> void:
	if not _active:
		return
	_active = false
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED
	get_tree().paused = false
	if _ui_manager:
		_ui_manager.set_challenge_board_open(false)
	closed.emit()


func is_open() -> bool:
	return _active


func _rebuild_buttons() -> void:
	_buttons.clear()
	if take_button:
		take_button.visible = true
		_buttons.append(take_button)
	if seal_button:
		seal_button.visible = _allow_seal
		if _allow_seal:
			_buttons.append(seal_button)
	if empty_button:
		empty_button.visible = _allow_empty
		if _allow_empty:
			_buttons.append(empty_button)


func _refresh_texts() -> void:
	if title_label:
		title_label.text = tr("ENDING_TITLE")
	if hint_label:
		hint_label.text = tr("ENDING_HINT")
	if take_button:
		take_button.text = tr("ENDING_TAKE")
	if seal_button:
		seal_button.text = tr("ENDING_SEAL")
	if empty_button:
		empty_button.text = tr("ENDING_EMPTY")


func _on_locale_changed(_locale: String) -> void:
	_refresh_texts()


func _apply_focus() -> void:
	if _buttons.is_empty():
		return
	_index = clampi(_index, 0, _buttons.size() - 1)
	_buttons[_index].grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if not _active:
		return
	if event.is_action_pressed("ui_left") or event.is_action_pressed("ui_up"):
		if not _buttons.is_empty():
			_index = (_index - 1 + _buttons.size()) % _buttons.size()
			_apply_focus()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_right") or event.is_action_pressed("ui_down"):
		if not _buttons.is_empty():
			_index = (_index + 1) % _buttons.size()
			_apply_focus()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept"):
		if _index >= 0 and _index < _buttons.size():
			_buttons[_index].emit_signal("pressed")
		get_viewport().set_input_as_handled()


func _choose(ending_id: String) -> void:
	if not _active:
		return
	var cb := _on_done
	close()
	if cb.is_valid():
		cb.call(ending_id)
