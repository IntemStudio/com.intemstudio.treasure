extends Control

signal request_close

enum SubTab { GAMEPLAY = 0, CONTROLS = 1, DISPLAY = 2, AUDIO = 3, EXIT = 4 }

const LANGUAGES: Array[Dictionary] = [
	{"code": "en", "label": "English"},
	{"code": "ko", "label": "한국어"},
]

const SUB_TAB_KEYS: Array[String] = [
	"Gameplay",
	"Controls",
	"Display",
	"Audio",
	"Exit",
]

const TITLE_SCENE := "res://scenes/title/title.tscn"

## Left-row focus → right panel title/description keys (per sub-tab).
const GAMEPLAY_DETAILS: Array[Dictionary] = [
	{"title": "Language", "desc": "SETTINGS_DESC_LANGUAGE"},
	{"title": "Font", "desc": "SETTINGS_DESC_FONT"},
]
const DISPLAY_DETAILS: Array[Dictionary] = [
	{"title": "Resolution", "desc": "SETTINGS_DESC_RESOLUTION"},
	{"title": "Display Mode", "desc": "SETTINGS_DESC_DISPLAY_MODE"},
	{"title": "VSync", "desc": "SETTINGS_DESC_VSYNC"},
	{"title": "Frame Rate", "desc": "SETTINGS_DESC_FRAME_RATE"},
]
const AUDIO_DETAILS: Array[Dictionary] = [
	{"title": "Master", "desc": "SETTINGS_DESC_MASTER"},
	{"title": "Music", "desc": "SETTINGS_DESC_MUSIC"},
	{"title": "Sound Effects", "desc": "SETTINGS_DESC_SFX"},
	{"title": "Background Audio", "desc": "SETTINGS_DESC_BACKGROUND"},
]

@onready var sub_tabs: HBoxContainer = %SubTabs
@onready var sub_tab_prev_hint: PanelContainer = %SubTabPrevHint
@onready var sub_tab_next_hint: PanelContainer = %SubTabNextHint
@onready var settings_split: HBoxContainer = %SettingsSplit
@onready var gameplay_panel: VBoxContainer = %GameplayPanel
@onready var controls_panel: Control = %ControlsPanel
@onready var display_panel: VBoxContainer = %DisplayPanel
@onready var audio_panel: VBoxContainer = %AudioPanel
@onready var exit_panel: HBoxContainer = %ExitPanel
@onready var ui_section_label: Label = %UISectionLabel
@onready var language_row_host: VBoxContainer = %LanguageRowHost
@onready var controls_placeholder: Label = %ControlsPlaceholder
@onready var detail_title: Label = %DetailTitle
@onready var detail_body: Label = %DetailBody
@onready var exit_list: VBoxContainer = %ExitList
@onready var exit_detail_label: Label = %ExitDetailLabel
@onready var exit_detail_body: Label = %ExitDetailBody
@onready var exit_confirm_row: HBoxContainer = %ExitConfirmRow
@onready var exit_yes_button: Button = %ExitYesButton
@onready var exit_no_button: Button = %ExitNoButton

var _ui_manager: UIManager
var _footer: FooterPrompts
var _footer_connected: bool = false
var _empty_style: StyleBoxEmpty

var _active_sub_tab: int = SubTab.GAMEPLAY
var _sub_tab_buttons: Array[Button] = []
var _row_focus: int = 0
var _confirming_exit: bool = false
var _exit_action: String = ""
var _exit_focus: int = 0

var _language_row: SettingsCycleRow
var _font_row: SettingsCycleRow
var _resolution_row: SettingsCycleRow
var _mode_row: SettingsCycleRow
var _vsync_row: SettingsToggleRow
var _fps_row: SettingsCycleRow
var _master_row: SettingsSliderRow
var _music_row: SettingsSliderRow
var _sfx_row: SettingsSliderRow
var _background_row: SettingsToggleRow

var _resolution_options: Array[Vector2i] = []
var _exit_buttons: Array[Button] = []
var _exit_actions: Array[String] = []
var _confirm_yes_selected: bool = true


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED
	_empty_style = StyleBoxEmpty.new()
	_style_sub_tab_keycaps()
	_build_sub_tabs()
	_build_gameplay()
	_build_display()
	_build_audio()
	_build_exit()
	LocaleManager.locale_changed.connect(_on_locale_changed)
	exit_yes_button.pressed.connect(_on_exit_yes)
	exit_no_button.pressed.connect(_on_exit_no)
	_style_flat_button(exit_yes_button)
	_style_flat_button(exit_no_button)
	_refresh_texts()
	_show_sub_tab(_active_sub_tab)


func _style_sub_tab_keycaps() -> void:
	var keycap := StyleBoxFlat.new()
	keycap.content_margin_left = 8
	keycap.content_margin_top = 3
	keycap.content_margin_right = 8
	keycap.content_margin_bottom = 3
	keycap.bg_color = Color(0.06, 0.06, 0.07, 0.92)
	keycap.set_border_width_all(1)
	keycap.border_color = Color(0.88, 0.88, 0.9, 0.95)
	keycap.set_corner_radius_all(3)
	if sub_tab_prev_hint:
		sub_tab_prev_hint.add_theme_stylebox_override("panel", keycap)
	if sub_tab_next_hint:
		sub_tab_next_hint.add_theme_stylebox_override("panel", keycap.duplicate())
	_refresh_sub_tab_key_hints()


func _refresh_sub_tab_key_hints() -> void:
	var keys := _sub_tab_cycle_keys()
	_set_keycap_label(sub_tab_prev_hint, keys["prev"])
	_set_keycap_label(sub_tab_next_hint, keys["next"])


func _sub_tab_cycle_keys() -> Dictionary:
	# Title: Q/E. In-game: 1/3 (Q/E reserved for MenuShell top tabs).
	if _is_in_game():
		return {"prev": "1", "next": "3", "prev_action": "inventory_category_prev", "next_action": "inventory_category_next"}
	return {"prev": "Q", "next": "E", "prev_action": "ui_nav_prev_tab", "next_action": "ui_nav_next_tab"}


func _set_keycap_label(hint: PanelContainer, text: String) -> void:
	if hint == null:
		return
	var label := hint.get_node_or_null("KeyLabel") as Label
	if label:
		label.text = text


func setup(ui_manager: UIManager, footer: FooterPrompts) -> void:
	_ui_manager = ui_manager
	_footer = footer
	if _ui_manager and not _ui_manager.input_device_changed.is_connected(_on_input_device_changed):
		_ui_manager.input_device_changed.connect(_on_input_device_changed)
	if _footer and not _footer_connected:
		_footer.prompt_activated.connect(_on_footer_prompt)
		_footer_connected = true
	_rebuild_exit_list()
	_refresh_sub_tab_key_hints()


func activate(_stats: CharacterStats, _inventory: InventoryData) -> void:
	visible = true
	process_mode = Node.PROCESS_MODE_INHERIT
	_confirming_exit = false
	_exit_action = ""
	_row_focus = 0
	_exit_focus = 0
	_rebuild_exit_list()
	_sync_rows_from_settings()
	_refresh_texts()
	_refresh_sub_tab_key_hints()
	_show_sub_tab(_active_sub_tab)
	_refresh_footer()
	_update_row_selection()


func deactivate() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED
	_confirming_exit = false


func _is_using_gamepad() -> bool:
	return _ui_manager.using_gamepad if _ui_manager else false


func _is_in_game() -> bool:
	return _ui_manager != null


func _on_input_device_changed(_using_gamepad: bool) -> void:
	if visible:
		_refresh_footer.call_deferred()


func _on_locale_changed(_locale: String) -> void:
	_refresh_texts()
	if visible:
		_refresh_footer()
		_update_row_selection()


func _refresh_footer() -> void:
	if not _footer:
		return
	var using_gamepad := _is_using_gamepad()
	_footer.set_prompts([
		{"action": "close", "button": "B" if using_gamepad else "Esc", "label": tr("BACK")},
	])


func _on_footer_prompt(action: String) -> void:
	if not visible:
		return
	if action == "close":
		_handle_back()


func _build_sub_tabs() -> void:
	for child in sub_tabs.get_children():
		child.queue_free()
	_sub_tab_buttons.clear()
	for i in range(SUB_TAB_KEYS.size()):
		var button := Button.new()
		button.flat = true
		button.focus_mode = Control.FOCUS_NONE
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.add_theme_stylebox_override("normal", _empty_style)
		button.add_theme_stylebox_override("hover", _empty_style)
		button.add_theme_stylebox_override("pressed", _empty_style)
		button.add_theme_stylebox_override("focus", _empty_style)
		button.pressed.connect(_on_sub_tab_pressed.bind(i))
		sub_tabs.add_child(button)
		_sub_tab_buttons.append(button)


func _build_gameplay() -> void:
	_language_row = SettingsCycleRow.new()
	_font_row = SettingsCycleRow.new()
	language_row_host.add_child(_language_row)
	language_row_host.add_child(_font_row)
	_language_row.value_changed.connect(_on_language_changed)
	_font_row.value_changed.connect(_on_font_changed)
	_language_row.focused.connect(_on_row_focused.bind(0))
	_font_row.focused.connect(_on_row_focused.bind(1))


func _build_display() -> void:
	_resolution_row = SettingsCycleRow.new()
	_mode_row = SettingsCycleRow.new()
	_vsync_row = SettingsToggleRow.new()
	_fps_row = SettingsCycleRow.new()
	display_panel.add_child(_resolution_row)
	display_panel.add_child(_mode_row)
	display_panel.add_child(_vsync_row)
	display_panel.add_child(_fps_row)
	_resolution_row.value_changed.connect(_on_resolution_changed)
	_mode_row.value_changed.connect(_on_mode_changed)
	_vsync_row.value_changed.connect(_on_vsync_changed)
	_fps_row.value_changed.connect(_on_fps_changed)
	_resolution_row.focused.connect(_on_row_focused.bind(0))
	_mode_row.focused.connect(_on_row_focused.bind(1))
	_vsync_row.focused.connect(_on_row_focused.bind(2))
	_fps_row.focused.connect(_on_row_focused.bind(3))


func _build_audio() -> void:
	_master_row = SettingsSliderRow.new()
	_music_row = SettingsSliderRow.new()
	_sfx_row = SettingsSliderRow.new()
	_background_row = SettingsToggleRow.new()
	audio_panel.add_child(_master_row)
	audio_panel.add_child(_music_row)
	audio_panel.add_child(_sfx_row)
	audio_panel.add_child(_background_row)
	_master_row.value_changed.connect(_on_master_changed)
	_music_row.value_changed.connect(_on_music_changed)
	_sfx_row.value_changed.connect(_on_sfx_changed)
	_background_row.value_changed.connect(_on_background_changed)
	_master_row.focused.connect(_on_row_focused.bind(0))
	_music_row.focused.connect(_on_row_focused.bind(1))
	_sfx_row.focused.connect(_on_row_focused.bind(2))
	_background_row.focused.connect(_on_row_focused.bind(3))


func _build_exit() -> void:
	_rebuild_exit_list()


func _rebuild_exit_list() -> void:
	if exit_list == null:
		return
	for child in exit_list.get_children():
		child.queue_free()
	_exit_buttons.clear()
	_exit_actions.clear()
	if _is_in_game():
		_add_exit_option("return_title", tr("Return to Main Menu"))
	_add_exit_option("quit_desktop", tr("Exit to Desktop"))
	_exit_focus = clampi(_exit_focus, 0, maxi(_exit_buttons.size() - 1, 0))
	_update_exit_selection()
	_update_exit_detail()


func _add_exit_option(action_id: String, label_text: String) -> void:
	var button := Button.new()
	button.text = label_text
	button.flat = true
	button.focus_mode = Control.FOCUS_NONE
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_style_flat_button(button)
	var index := _exit_buttons.size()
	button.pressed.connect(_on_exit_option_pressed.bind(index))
	exit_list.add_child(button)
	_exit_buttons.append(button)
	_exit_actions.append(action_id)


func _style_flat_button(button: Button) -> void:
	if _empty_style == null:
		_empty_style = StyleBoxEmpty.new()
	button.add_theme_stylebox_override("normal", _empty_style)
	button.add_theme_stylebox_override("hover", _empty_style)
	button.add_theme_stylebox_override("pressed", _empty_style)
	button.add_theme_stylebox_override("focus", _empty_style)


func _sync_rows_from_settings() -> void:
	var lang_labels: Array = []
	var lang_index := 0
	for i in range(LANGUAGES.size()):
		lang_labels.append(tr(str(LANGUAGES[i]["label"])))
		if LANGUAGES[i]["code"] == LocaleManager.current_locale:
			lang_index = i
	_language_row.setup(tr("Language"), lang_labels, lang_index)

	var font_labels: Array = [tr("Sans"), tr("Serif")]
	var font_index := SettingsManager.FONT_FAMILIES.find(SettingsManager.font_family)
	if font_index < 0:
		font_index = 0
	_font_row.setup(tr("Font"), font_labels, font_index)

	_resolution_options = SettingsManager.get_available_resolutions()
	var current_res := Vector2i(SettingsManager.width, SettingsManager.height)
	if not _resolution_options.has(current_res):
		_resolution_options.insert(0, current_res)
	var res_labels: Array = []
	var res_index := 0
	for i in range(_resolution_options.size()):
		var res := _resolution_options[i]
		res_labels.append("%dx%d" % [res.x, res.y])
		if res == current_res:
			res_index = i
	_resolution_row.setup(tr("Resolution"), res_labels, res_index)

	var mode_labels: Array = [
		tr("Windowed"),
		tr("Fullscreen"),
		tr("Borderless"),
	]
	var mode_index := SettingsManager.DISPLAY_MODES.find(SettingsManager.mode)
	if mode_index < 0:
		mode_index = 0
	_mode_row.setup(tr("Display Mode"), mode_labels, mode_index)

	_vsync_row.setup(tr("VSync"), SettingsManager.vsync)

	var fps_labels: Array = []
	var fps_index := 0
	for i in range(SettingsManager.MAX_FPS_OPTIONS.size()):
		var fps: int = SettingsManager.MAX_FPS_OPTIONS[i]
		fps_labels.append(tr("Unlimited") if fps == 0 else str(fps))
		if fps == SettingsManager.max_fps:
			fps_index = i
	_fps_row.setup(tr("Frame Rate"), fps_labels, fps_index)

	_master_row.setup(tr("Master"), SettingsManager.master_volume)
	_music_row.setup(tr("Music"), SettingsManager.music_volume)
	_sfx_row.setup(tr("Sound Effects"), SettingsManager.sfx_volume)
	_background_row.setup(tr("Background Audio"), SettingsManager.background_audio)


func _refresh_texts() -> void:
	for i in range(_sub_tab_buttons.size()):
		_sub_tab_buttons[i].text = tr(SUB_TAB_KEYS[i])
	ui_section_label.text = tr("User Interface")
	controls_placeholder.text = tr("Coming soon")
	exit_yes_button.text = tr("Yes")
	exit_no_button.text = tr("No")
	_sync_rows_from_settings()
	_rebuild_exit_list()
	_apply_sub_tab_styles()
	_update_detail_panel()
	_update_exit_detail()


func _show_sub_tab(tab: int) -> void:
	_active_sub_tab = clampi(tab, 0, SUB_TAB_KEYS.size() - 1)
	_confirming_exit = false
	_exit_action = ""
	_row_focus = 0
	var is_exit := _active_sub_tab == SubTab.EXIT
	settings_split.visible = not is_exit
	exit_panel.visible = is_exit
	gameplay_panel.visible = _active_sub_tab == SubTab.GAMEPLAY
	controls_panel.visible = _active_sub_tab == SubTab.CONTROLS
	display_panel.visible = _active_sub_tab == SubTab.DISPLAY
	audio_panel.visible = _active_sub_tab == SubTab.AUDIO
	exit_confirm_row.visible = false
	_apply_sub_tab_styles()
	_update_row_selection()
	_update_detail_panel()
	_update_exit_selection()
	_update_exit_detail()


func _apply_sub_tab_styles() -> void:
	for i in range(_sub_tab_buttons.size()):
		var color := UIColors.GOLD if i == _active_sub_tab else UIColors.TEXT_MUTED
		_sub_tab_buttons[i].add_theme_color_override("font_color", color)


func _on_sub_tab_pressed(index: int) -> void:
	_show_sub_tab(index)


func _cycle_sub_tab(direction: int) -> void:
	var next := (_active_sub_tab + direction + SUB_TAB_KEYS.size()) % SUB_TAB_KEYS.size()
	_show_sub_tab(next)


func _current_rows() -> Array:
	match _active_sub_tab:
		SubTab.GAMEPLAY:
			return [_language_row, _font_row]
		SubTab.DISPLAY:
			return [_resolution_row, _mode_row, _vsync_row, _fps_row]
		SubTab.AUDIO:
			return [_master_row, _music_row, _sfx_row, _background_row]
		_:
			return []


func _current_details() -> Array[Dictionary]:
	match _active_sub_tab:
		SubTab.GAMEPLAY:
			return GAMEPLAY_DETAILS
		SubTab.DISPLAY:
			return DISPLAY_DETAILS
		SubTab.AUDIO:
			return AUDIO_DETAILS
		_:
			return []


func _on_row_focused(index: int) -> void:
	_row_focus = index
	_update_row_selection()


func _update_row_selection() -> void:
	var rows := _current_rows()
	if rows.is_empty():
		_update_detail_panel()
		return
	_row_focus = clampi(_row_focus, 0, rows.size() - 1)
	for i in range(rows.size()):
		var row = rows[i]
		if row.has_method("set_selected"):
			row.set_selected(i == _row_focus)
	_update_detail_panel()


func _update_detail_panel() -> void:
	if detail_title == null or detail_body == null:
		return
	if _active_sub_tab == SubTab.CONTROLS:
		detail_title.text = tr("Controls")
		detail_body.text = tr("SETTINGS_DESC_CONTROLS")
		return
	var details := _current_details()
	if details.is_empty():
		detail_title.text = ""
		detail_body.text = ""
		return
	var index := clampi(_row_focus, 0, details.size() - 1)
	detail_title.text = tr(str(details[index]["title"]))
	detail_body.text = tr(str(details[index]["desc"]))


func _move_row_focus(direction: int) -> void:
	var rows := _current_rows()
	if rows.is_empty():
		return
	_row_focus = clampi(_row_focus + direction, 0, rows.size() - 1)
	_update_row_selection()


func _adjust_focused_row(direction: int) -> void:
	var rows := _current_rows()
	if rows.is_empty() or _row_focus < 0 or _row_focus >= rows.size():
		return
	var row = rows[_row_focus]
	if row is SettingsCycleRow:
		(row as SettingsCycleRow).cycle(direction)
	elif row is SettingsToggleRow:
		(row as SettingsToggleRow).toggle()
	elif row is SettingsSliderRow:
		(row as SettingsSliderRow).nudge(direction)


func _activate_focused_row() -> void:
	var rows := _current_rows()
	if rows.is_empty() or _row_focus < 0 or _row_focus >= rows.size():
		return
	var row = rows[_row_focus]
	if row is SettingsCycleRow:
		(row as SettingsCycleRow).cycle(1)
	elif row is SettingsToggleRow:
		(row as SettingsToggleRow).toggle()


func _on_language_changed(index: int) -> void:
	var code := str(LANGUAGES[clampi(index, 0, LANGUAGES.size() - 1)]["code"])
	LocaleManager.set_language(code)


func _on_font_changed(index: int) -> void:
	var family := SettingsManager.FONT_FAMILIES[clampi(index, 0, SettingsManager.FONT_FAMILIES.size() - 1)]
	SettingsManager.set_font_family(family)


func _on_resolution_changed(index: int) -> void:
	if index < 0 or index >= _resolution_options.size():
		return
	var res := _resolution_options[index]
	SettingsManager.set_resolution(res.x, res.y)


func _on_mode_changed(index: int) -> void:
	var mode := SettingsManager.DISPLAY_MODES[clampi(index, 0, SettingsManager.DISPLAY_MODES.size() - 1)]
	SettingsManager.set_display_mode(mode)


func _on_vsync_changed(enabled: bool) -> void:
	SettingsManager.set_vsync(enabled)


func _on_fps_changed(index: int) -> void:
	var fps: int = SettingsManager.MAX_FPS_OPTIONS[clampi(index, 0, SettingsManager.MAX_FPS_OPTIONS.size() - 1)]
	SettingsManager.set_max_fps(fps)


func _on_master_changed(value: float) -> void:
	SettingsManager.set_master_volume(value)


func _on_music_changed(value: float) -> void:
	SettingsManager.set_music_volume(value)


func _on_sfx_changed(value: float) -> void:
	SettingsManager.set_sfx_volume(value)


func _on_background_changed(enabled: bool) -> void:
	SettingsManager.set_background_audio(enabled)


func _on_exit_option_pressed(index: int) -> void:
	_exit_focus = index
	_update_exit_selection()
	_begin_exit_confirm()


func _begin_exit_confirm() -> void:
	if _exit_actions.is_empty():
		return
	_exit_focus = clampi(_exit_focus, 0, _exit_actions.size() - 1)
	_exit_action = _exit_actions[_exit_focus]
	_confirming_exit = true
	_confirm_yes_selected = true
	exit_confirm_row.visible = true
	_update_exit_detail()
	_update_exit_confirm_style()


func _cancel_exit_confirm() -> void:
	_confirming_exit = false
	_exit_action = ""
	exit_confirm_row.visible = false
	_update_exit_detail()


func _update_exit_selection() -> void:
	for i in range(_exit_buttons.size()):
		var color := UIColors.GOLD if i == _exit_focus else UIColors.TEXT_MAIN
		_exit_buttons[i].add_theme_color_override("font_color", color)


func _update_exit_detail() -> void:
	if exit_detail_label == null:
		return
	if _exit_actions.is_empty():
		exit_detail_label.text = ""
		if exit_detail_body:
			exit_detail_body.text = ""
		return
	var action := _exit_actions[clampi(_exit_focus, 0, _exit_actions.size() - 1)]
	if _confirming_exit:
		exit_detail_label.text = tr("Are you sure?")
		if exit_detail_body:
			exit_detail_body.text = tr("SETTINGS_DESC_EXIT_CONFIRM")
		return
	match action:
		"return_title":
			exit_detail_label.text = tr("Return to Main Menu")
			if exit_detail_body:
				exit_detail_body.text = tr("SETTINGS_DESC_RETURN_TITLE")
		"quit_desktop":
			exit_detail_label.text = tr("Exit to Desktop")
			if exit_detail_body:
				exit_detail_body.text = tr("SETTINGS_DESC_QUIT_DESKTOP")
		_:
			exit_detail_label.text = ""
			if exit_detail_body:
				exit_detail_body.text = ""


func _update_exit_confirm_style() -> void:
	exit_yes_button.add_theme_color_override(
		"font_color", UIColors.GOLD if _confirm_yes_selected else UIColors.TEXT_MUTED
	)
	exit_no_button.add_theme_color_override(
		"font_color", UIColors.TEXT_MUTED if _confirm_yes_selected else UIColors.GOLD
	)


func _on_exit_yes() -> void:
	_execute_exit()


func _on_exit_no() -> void:
	_cancel_exit_confirm()


func _execute_exit() -> void:
	var action := _exit_action
	_cancel_exit_confirm()
	match action:
		"return_title":
			if _ui_manager:
				_ui_manager.return_to_title()
			else:
				get_tree().change_scene_to_file(TITLE_SCENE)
		"quit_desktop":
			get_tree().quit()


func _handle_back() -> void:
	if _confirming_exit:
		_cancel_exit_confirm()
		return
	request_close.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		_handle_back()
		get_viewport().set_input_as_handled()
		return
	var tab_keys := _sub_tab_cycle_keys()
	if event.is_action_pressed(str(tab_keys["prev_action"])):
		_cycle_sub_tab(-1)
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed(str(tab_keys["next_action"])):
		_cycle_sub_tab(1)
		get_viewport().set_input_as_handled()
		return

	if _active_sub_tab == SubTab.EXIT:
		_handle_exit_input(event)
		return

	if _active_sub_tab == SubTab.CONTROLS:
		return

	if event.is_action_pressed("ui_up"):
		_move_row_focus(-1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_down"):
		_move_row_focus(1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_left"):
		_adjust_focused_row(-1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_right"):
		_adjust_focused_row(1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept"):
		_activate_focused_row()
		get_viewport().set_input_as_handled()


func _handle_exit_input(event: InputEvent) -> void:
	if _confirming_exit:
		if event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right"):
			_confirm_yes_selected = not _confirm_yes_selected
			_update_exit_confirm_style()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_accept"):
			if _confirm_yes_selected:
				_execute_exit()
			else:
				_cancel_exit_confirm()
			get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("ui_up"):
		if not _exit_buttons.is_empty():
			_exit_focus = clampi(_exit_focus - 1, 0, _exit_buttons.size() - 1)
			_update_exit_selection()
			_update_exit_detail()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_down"):
		if not _exit_buttons.is_empty():
			_exit_focus = clampi(_exit_focus + 1, 0, _exit_buttons.size() - 1)
			_update_exit_selection()
			_update_exit_detail()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept"):
		_begin_exit_confirm()
		get_viewport().set_input_as_handled()
