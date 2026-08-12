class_name TopBar
extends HBoxContainer

signal tab_changed(index: int)

const TAB_NAMES: Array[String] = ["Inventory", "Map", "Stats", "Settings"]
const CYCLEABLE_TABS: Array[int] = [0, 1, 2, 3]

@onready var currency_display: CurrencyDisplay = %CurrencyDisplay
@onready var nav_tabs: HBoxContainer = %NavTabs
@onready var player_vitals: PlayerVitals = %PlayerVitals

var _active_tab: int = 2
var _tab_buttons: Array[Button] = []
var _empty_style: StyleBoxEmpty
var _stats: CharacterStats


func _ready() -> void:
	_empty_style = StyleBoxEmpty.new()
	_empty_style.content_margin_left = 0
	_empty_style.content_margin_top = 0
	_empty_style.content_margin_right = 0
	_empty_style.content_margin_bottom = 0
	_build_tab_labels()
	set_active_tab(_active_tab)
	LocaleManager.locale_changed.connect(_on_locale_changed)


func set_active_tab(index: int) -> void:
	_active_tab = clampi(index, 0, TAB_NAMES.size() - 1)
	for i in range(_tab_buttons.size()):
		var button := _tab_buttons[i]
		if i == _active_tab:
			button.add_theme_color_override("font_color", UIColors.GOLD)
		else:
			button.add_theme_color_override("font_color", UIColors.TEXT_MUTED)


func set_player_stats(stats: CharacterStats) -> void:
	_stats = stats
	player_vitals.set_stats(stats)


func set_currencies(currencies: Dictionary) -> void:
	currency_display.set_currencies(currencies)


func get_active_tab() -> int:
	return _active_tab


func _on_locale_changed(_locale: String) -> void:
	_refresh_tab_labels()
	if _stats:
		player_vitals.set_stats(_stats)


func _build_tab_labels() -> void:
	for i in range(TAB_NAMES.size()):
		var button := Button.new()
		button.text = "[%s]" % tr(TAB_NAMES[i])
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
		_tab_buttons[i].text = "[%s]" % tr(TAB_NAMES[i])


func _on_tab_button_pressed(index: int) -> void:
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


func _unhandled_input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event.is_action_pressed("ui_nav_prev_tab"):
		_cycle_tab(-1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_nav_next_tab"):
		_cycle_tab(1)
		get_viewport().set_input_as_handled()


func _cycle_tab(direction: int) -> void:
	var idx := CYCLEABLE_TABS.find(_active_tab)
	if idx < 0:
		idx = 0
	var next_idx := (idx + direction + CYCLEABLE_TABS.size()) % CYCLEABLE_TABS.size()
	var next_tab := CYCLEABLE_TABS[next_idx]
	set_active_tab(next_tab)
	tab_changed.emit(next_tab)
