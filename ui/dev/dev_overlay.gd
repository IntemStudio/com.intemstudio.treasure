extends CanvasLayer

enum Tab { SAVE = 0, CHARACTER = 1 }

@onready var panel: PanelContainer = %Panel
@onready var title_label: Label = %TitleLabel
@onready var save_tab_button: Button = %SaveTabButton
@onready var character_tab_button: Button = %CharacterTabButton
@onready var save_panel: VBoxContainer = %SavePanel
@onready var character_panel: VBoxContainer = %CharacterPanel
@onready var path_label: Label = %PathLabel
@onready var open_folder_button: Button = %OpenFolderButton
@onready var level_info_label: Label = %LevelInfoLabel
@onready var level_down_button: Button = %LevelDownButton
@onready var level_up_button: Button = %LevelUpButton
@onready var status_label: Label = %StatusLabel
@onready var close_hint_label: Label = %CloseHintLabel

var _ui_manager: UIManager
var _active_tab: int = Tab.SAVE
var _empty_style: StyleBoxEmpty


func _ready() -> void:
	layer = 100
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	_empty_style = StyleBoxEmpty.new()
	_empty_style.content_margin_left = 0
	_empty_style.content_margin_top = 0
	_empty_style.content_margin_right = 0
	_empty_style.content_margin_bottom = 0
	_style_tab_button(save_tab_button)
	_style_tab_button(character_tab_button)
	save_tab_button.pressed.connect(_on_tab_pressed.bind(Tab.SAVE))
	character_tab_button.pressed.connect(_on_tab_pressed.bind(Tab.CHARACTER))
	open_folder_button.pressed.connect(_on_open_folder_pressed)
	level_up_button.pressed.connect(_on_level_up_pressed)
	level_down_button.pressed.connect(_on_level_down_pressed)
	LocaleManager.locale_changed.connect(_on_locale_changed)
	_refresh_texts()
	_apply_tab()


func setup(ui_manager: UIManager) -> void:
	_ui_manager = ui_manager


func toggle() -> void:
	if visible:
		close()
	else:
		open()


func open() -> void:
	visible = true
	_refresh_texts()
	_apply_tab()
	status_label.text = ""


func close() -> void:
	visible = false
	status_label.text = ""


func is_open() -> bool:
	return visible


func _on_locale_changed(_locale: String) -> void:
	_refresh_texts()
	if visible:
		_apply_tab()


func _refresh_texts() -> void:
	title_label.text = tr("Developer")
	save_tab_button.text = tr("Save Data")
	character_tab_button.text = tr("Character")
	open_folder_button.text = tr("Open Save Folder")
	level_up_button.text = tr("Force Level Up")
	level_down_button.text = tr("Force Level Down")
	close_hint_label.text = tr("` / Esc: Close")
	_refresh_tab_colors()


func _style_tab_button(button: Button) -> void:
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_stylebox_override("normal", _empty_style)
	button.add_theme_stylebox_override("hover", _empty_style)
	button.add_theme_stylebox_override("pressed", _empty_style)
	button.add_theme_stylebox_override("focus", _empty_style)
	button.add_theme_font_size_override("font_size", 18)


func _on_tab_pressed(tab: int) -> void:
	if _active_tab == tab:
		return
	_active_tab = tab
	status_label.text = ""
	_apply_tab()


func _apply_tab() -> void:
	var show_save := _active_tab == Tab.SAVE
	save_panel.visible = show_save
	character_panel.visible = not show_save
	_refresh_tab_colors()
	if show_save:
		_refresh_path()
	else:
		_refresh_level()


func _refresh_tab_colors() -> void:
	_set_tab_color(save_tab_button, _active_tab == Tab.SAVE)
	_set_tab_color(character_tab_button, _active_tab == Tab.CHARACTER)


func _set_tab_color(button: Button, active: bool) -> void:
	button.add_theme_color_override(
		"font_color",
		UIColors.GOLD if active else UIColors.TEXT_MUTED
	)


func _refresh_path() -> void:
	path_label.text = SaveManager.get_save_dir_global_path()


func _refresh_level() -> void:
	var stats := _character_stats()
	if stats == null:
		level_info_label.text = tr("No character")
		level_up_button.disabled = true
		level_down_button.disabled = true
		return
	stats.sync_xp_to_next()
	level_info_label.text = tr("Level %d  (%d / %d XP)") % [
		stats.level, stats.xp, stats.xp_to_next
	]
	level_up_button.disabled = LevelProgression.is_max_level(stats.level)
	level_down_button.disabled = stats.level <= CharacterStats.MIN_LEVEL


func _character_stats() -> CharacterStats:
	if _ui_manager == null:
		return null
	return _ui_manager.character_stats


func _on_open_folder_pressed() -> void:
	_refresh_path()
	var err := SaveManager.open_save_folder()
	if err == OK:
		status_label.text = tr("Opened save folder")
	else:
		status_label.text = tr("Failed to open save folder")


func _on_level_up_pressed() -> void:
	var stats := _character_stats()
	if stats == null:
		status_label.text = tr("No character")
		return
	if not stats.force_level_up():
		status_label.text = tr("Already max level")
		_refresh_level()
		return
	_ui_manager.refresh_character_views()
	_refresh_level()
	status_label.text = tr("Forced level up → %d") % stats.level


func _on_level_down_pressed() -> void:
	var stats := _character_stats()
	if stats == null:
		status_label.text = tr("No character")
		return
	if not stats.force_level_down():
		status_label.text = tr("Already min level")
		_refresh_level()
		return
	_ui_manager.refresh_character_views()
	_refresh_level()
	status_label.text = tr("Forced level down → %d") % stats.level
