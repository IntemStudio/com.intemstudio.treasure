extends Control

const SETTINGS_CONTENT_PATH := "res://ui/settings/settings_content.tscn"
const FOOTER_SCENE := preload("res://ui/shared/footer_prompts.tscn")
const PROFILE_SELECT_SCENE := preload("res://scenes/title/profile_select.tscn")

@onready var start_button: Button = %StartButton
@onready var settings_button: Button = %SettingsButton
@onready var quit_button: Button = %QuitButton
@onready var brand_label: Label = %BrandLabel
@onready var menu_anchor: MarginContainer = %MenuAnchor
@onready var settings_host: CanvasLayer = $SettingsHost
@onready var settings_body_host: Control = $SettingsHost/SettingsRoot/SettingsColumn/SettingsBodyHost
@onready var settings_footer_host: Control = $SettingsHost/SettingsRoot/SettingsColumn/SettingsFooterHost
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
	# Text layout uses normal/hover/pressed styleboxes — not focus.
	# Focus is only drawn as an overlay, so padding must live on StyleBoxEmpty.
	var padded := StyleBoxEmpty.new()
	padded.content_margin_left = 16
	padded.content_margin_top = 4
	padded.content_margin_bottom = 4
	padded.content_margin_right = 4
	for button in _menu_buttons:
		button.flat = true
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.focus_mode = Control.FOCUS_ALL
		for state_name in ["normal", "hover", "pressed", "disabled"]:
			button.add_theme_stylebox_override(state_name, padded)
		var focus_style := StyleBoxFlat.new()
		focus_style.bg_color = Color(0, 0, 0, 0)
		focus_style.border_color = UIColors.SELECT_BORDER
		focus_style.border_width_left = 3
		# Match layout margins so focus overlay aligns with text padding
		focus_style.content_margin_left = 16
		focus_style.content_margin_top = 4
		focus_style.content_margin_bottom = 4
		focus_style.content_margin_right = 4
		button.add_theme_stylebox_override("focus", focus_style)
		button.add_theme_color_override("font_color", UIColors.TEXT_MAIN)
		button.add_theme_color_override("font_hover_color", UIColors.GOLD)
		button.add_theme_color_override("font_focus_color", UIColors.GOLD)
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
	settings_host.visible = true
	_settings_content.activate(null, null)


func _close_settings() -> void:
	if _settings_content:
		_settings_content.deactivate()
	settings_host.visible = false
	if not _profile_select.visible:
		start_button.grab_focus()


func _on_profile_back() -> void:
	menu_anchor.visible = true
	brand_label.visible = true
	start_button.grab_focus()


func _on_quit() -> void:
	get_tree().quit()
