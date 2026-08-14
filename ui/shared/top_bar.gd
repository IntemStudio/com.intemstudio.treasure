class_name TopBar
extends HBoxContainer

signal tab_changed(index: int)

var _tab_names: Array[String] = ["Inventory", "Map", "Stats", "Settings"]
var CYCLEABLE_TABS: Array[int] = [0, 1, 2, 3]

@onready var currency_display: CurrencyDisplay = %CurrencyDisplay
@onready var nav_tabs: HBoxContainer = %NavTabs
@onready var nav_prev_hint: Control = %NavPrevHint
@onready var nav_next_hint: Control = %NavNextHint
@onready var location_label: Label = %LocationLabel
@onready var player_vitals: PlayerVitals = %PlayerVitals
@onready var left_slot: Control = $LeftSlot
@onready var right_slot: Control = $RightSlot

var _active_tab: int = 2
var _tab_buttons: Array[Button] = []
var _empty_style: StyleBoxEmpty
var _stats: CharacterStats
var _hub_mode: bool = false
var _location_id: String = ""
var _status_visible: bool = true


func _ready() -> void:
	_empty_style = StyleBoxEmpty.new()
	_empty_style.content_margin_left = 0
	_empty_style.content_margin_top = 0
	_empty_style.content_margin_right = 0
	_empty_style.content_margin_bottom = 0
	_rebuild_tab_labels()
	set_active_tab(_active_tab)
	_sync_center_mode()
	LocaleManager.locale_changed.connect(_on_locale_changed)


func set_tabs(names: Array[String]) -> void:
	_tab_names = names.duplicate()
	CYCLEABLE_TABS.clear()
	for i in _tab_names.size():
		CYCLEABLE_TABS.append(i)
	_rebuild_tab_labels()
	if not _tab_names.is_empty():
		set_active_tab(clampi(_active_tab, 0, _tab_names.size() - 1))
	_sync_center_mode()


func set_location(location_id: String) -> void:
	_location_id = location_id if not location_id.is_empty() else "LOCATION_UNKNOWN"
	_refresh_location_label()


func set_hub_mode(enabled: bool) -> void:
	_hub_mode = enabled
	if enabled:
		CYCLEABLE_TABS = [0, 2, 3]
		if _tab_buttons.size() > 1:
			_tab_buttons[1].visible = false
		if _active_tab == 1:
			set_active_tab(2)
			tab_changed.emit(2)
	else:
		CYCLEABLE_TABS.clear()
		for i in _tab_names.size():
			CYCLEABLE_TABS.append(i)
		if _tab_buttons.size() > 1:
			_tab_buttons[1].visible = true


func set_active_tab(index: int) -> void:
	_active_tab = clampi(index, 0, maxi(_tab_names.size() - 1, 0))
	for i in range(_tab_buttons.size()):
		var button := _tab_buttons[i]
		if i == _active_tab:
			button.add_theme_color_override("font_color", UIColors.GOLD)
		else:
			button.add_theme_color_override("font_color", UIColors.TEXT_MUTED)


func set_player_stats(stats: CharacterStats) -> void:
	_stats = stats
	if player_vitals and _status_visible:
		player_vitals.set_stats(stats)


func set_currencies(currencies: Dictionary) -> void:
	if currency_display and _status_visible:
		currency_display.set_currencies(currencies)


func set_status_visible(visible_status: bool) -> void:
	_status_visible = visible_status
	if left_slot:
		left_slot.visible = visible_status
	if right_slot:
		right_slot.visible = visible_status
	if currency_display:
		currency_display.visible = visible_status
	if player_vitals:
		player_vitals.visible = visible_status


func get_active_tab() -> int:
	return _active_tab


func _on_locale_changed(_locale: String) -> void:
	_refresh_tab_labels()
	_refresh_location_label()
	if _stats and _status_visible and player_vitals:
		player_vitals.set_stats(_stats)


func _rebuild_tab_labels() -> void:
	if nav_tabs == null:
		return
	for button in _tab_buttons:
		button.queue_free()
	_tab_buttons.clear()
	_build_tab_labels()


func _build_tab_labels() -> void:
	if nav_tabs == null or _empty_style == null:
		return
	for i in range(_tab_names.size()):
		var button := Button.new()
		button.text = "[%s]" % tr(_tab_names[i])
		button.flat = true
		button.focus_mode = Control.FOCUS_NONE
		button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.add_theme_stylebox_override("normal", _empty_style)
		button.add_theme_stylebox_override("hover", _empty_style)
		button.add_theme_stylebox_override("pressed", _empty_style)
		button.add_theme_stylebox_override("focus", _empty_style)
		button.add_theme_constant_override("outline_size", 0)
		button.pressed.connect(_on_tab_button_pressed.bind(i))
		button.mouse_entered.connect(_on_tab_hovered.bind(i, true))
		button.mouse_exited.connect(_on_tab_hovered.bind(i, false))
		nav_tabs.add_child(button)
		_tab_buttons.append(button)


func _refresh_tab_labels() -> void:
	for i in range(_tab_buttons.size()):
		_tab_buttons[i].text = "[%s]" % tr(_tab_names[i])


func _on_tab_button_pressed(index: int) -> void:
	if _hub_mode and index == 1:
		return
	set_active_tab(index)
	tab_changed.emit(index)


func _on_tab_hovered(index: int, hovered: bool) -> void:
	if index == _active_tab:
		return
	var button := _tab_buttons[index]
	if hovered:
		button.add_theme_color_override("font_color", UIColors.TEXT_MAIN)
	else:
		button.add_theme_color_override("font_color", UIColors.TEXT_MUTED)


func _sync_center_mode() -> void:
	var show_tabs := not _tab_names.is_empty()
	if nav_prev_hint:
		nav_prev_hint.visible = show_tabs
	if nav_tabs:
		nav_tabs.visible = show_tabs
	if nav_next_hint:
		nav_next_hint.visible = show_tabs
	if location_label:
		location_label.visible = not show_tabs
		if not show_tabs:
			_refresh_location_label()


func _refresh_location_label() -> void:
	if location_label == null or not location_label.visible:
		return
	if _location_id.is_empty():
		location_label.text = ""
		return
	location_label.text = tr(_location_id)


func _unhandled_input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if CYCLEABLE_TABS.is_empty():
		return
	if event.is_action_pressed("ui_nav_prev_tab"):
		_cycle_tab(-1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_nav_next_tab"):
		_cycle_tab(1)
		get_viewport().set_input_as_handled()


func _cycle_tab(direction: int) -> void:
	if CYCLEABLE_TABS.is_empty():
		return
	var idx := CYCLEABLE_TABS.find(_active_tab)
	if idx < 0:
		idx = 0
	var next_idx := (idx + direction + CYCLEABLE_TABS.size()) % CYCLEABLE_TABS.size()
	var next_tab := CYCLEABLE_TABS[next_idx]
	set_active_tab(next_tab)
	tab_changed.emit(next_tab)
