extends Control

const SETTINGS_CONTENT_PATH := "res://ui/settings/settings_content.tscn"
const FOOTER_SCENE := preload("res://ui/shared/footer_prompts.tscn")
const PROFILE_SELECT_SCENE := preload("res://scenes/title/profile_select.tscn")

@onready var background: ColorRect = $Background
@onready var start_button: Button = %StartButton
@onready var settings_button: Button = %SettingsButton
@onready var quit_button: Button = %QuitButton
@onready var brand_label: Label = %BrandLabel
@onready var menu_anchor: MarginContainer = %MenuAnchor
@onready var settings_host: CanvasLayer = $SettingsHost
@onready var settings_body_host: Control = %SettingsBodyHost
@onready var settings_footer_host: Control = %SettingsFooterHost
@onready var profile_host: Control = %ProfileHost

var _settings_content: Control
var _settings_footer: FooterPrompts
var _profile_select: Control
var _menu_buttons: Array[Button] = []


func _ready() -> void:
	_menu_buttons = [start_button, settings_button, quit_button]
	start_button.pressed.connect(_on_start)
	settings_button.pressed.connect(_on_settings)
	quit_button.pressed.connect(_on_quit)
	LocaleManager.locale_changed.connect(_on_locale_changed)

	background.color = UIColors.TEXT_INVERSE
	brand_label.add_theme_color_override("font_color", UIColors.TEXT_MAIN)
	_setup_settings_host()
	_setup_profile_select()
	_refresh_texts()
	_style_menu_buttons()
	settings_host.visible = false
	start_button.grab_focus()


func _setup_settings_host() -> void:
	if settings_body_host == null or settings_footer_host == null:
		push_error("Title: Settings hosts missing")
		return
	var sheet := get_node_or_null("%Sheet") as PanelContainer
	if sheet:
		UIPopupLayout.apply_sheet_panel(sheet)
	UIPopupLayout.apply_sheet_bands(
		get_node_or_null("%TopBand") as Control,
		get_node_or_null("%MidBand") as Control,
		get_node_or_null("%BottomBand") as Control
	)
	var title_label := get_node_or_null("SettingsHost/Safe/Center/Sheet/SettingsColumn/TopBand/TitleLabel") as Label
	if title_label:
		title_label.text = tr("Settings")
	var settings_scene := load(SETTINGS_CONTENT_PATH) as PackedScene
	if settings_scene == null:
		push_error("Title: failed to load settings content")
		return
	_settings_content = settings_scene.instantiate()
	if _settings_content == null:
		push_error("Title: failed to instantiate settings content")
		return
	settings_body_host.add_child(_settings_content)
	_settings_content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_settings_footer = FOOTER_SCENE.instantiate()
	settings_footer_host.add_child(_settings_footer)
	_settings_content.setup(null, _settings_footer)
	_settings_content.request_close.connect(_close_settings)


func _setup_profile_select() -> void:
	if profile_host == null:
		push_error("Title: ProfileHost missing")
		return
	_profile_select = PROFILE_SELECT_SCENE.instantiate()
	if _profile_select == null:
		push_error("Title: failed to instantiate profile select")
		return
	profile_host.add_child(_profile_select)
	_profile_select.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_profile_select.back_pressed.connect(_on_profile_back)


func _style_menu_buttons() -> void:
	for button in _menu_buttons:
		UISelectStyle.apply_button_focus_bar(button, UIColors.TEXT_MAIN)
		button.add_theme_font_size_override("font_size", 22)


func _refresh_texts() -> void:
	brand_label.text = tr("Treasure Hunter")
	start_button.text = tr("Start Game")
	settings_button.text = tr("Settings")
	quit_button.text = tr("Quit")


func _on_locale_changed(_locale: String) -> void:
	_refresh_texts()


func _on_start() -> void:
	_close_settings()
	menu_anchor.visible = false
	brand_label.visible = false
	_profile_select.open()


func _on_settings() -> void:
	if _profile_select.visible:
		return
	_set_menu_interactive(false)
	settings_host.visible = true
	_settings_content.activate(null, null)


func _close_settings() -> void:
	if _settings_content:
		_settings_content.deactivate()
	settings_host.visible = false
	_set_menu_interactive(true)
	if not _profile_select.visible:
		start_button.grab_focus()


func _set_menu_interactive(active: bool) -> void:
	for button in _menu_buttons:
		button.focus_mode = Control.FOCUS_ALL if active else Control.FOCUS_NONE
		button.mouse_filter = Control.MOUSE_FILTER_STOP if active else Control.MOUSE_FILTER_IGNORE
	if active:
		return
	var focused := get_viewport().gui_get_focus_owner()
	if focused != null and _menu_buttons.has(focused):
		focused.release_focus()


func _on_profile_back() -> void:
	menu_anchor.visible = true
	brand_label.visible = true
	start_button.grab_focus()


func _on_quit() -> void:
	get_tree().quit()
