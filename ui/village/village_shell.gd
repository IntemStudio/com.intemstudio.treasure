class_name VillageShell
extends Control

const HUB_NAV: Array[Dictionary] = [
	{"tab": UIManager.Tab.BOARD, "key": "BOARD_LABEL"},
	{"tab": UIManager.Tab.SHELF, "key": "SHELF_LABEL"},
	{"tab": UIManager.Tab.SMITHY, "key": "SMITHY_LABEL"},
	{"tab": UIManager.Tab.INVENTORY, "key": "Inventory"},
	{"tab": UIManager.Tab.STATS, "key": "Stats"},
	{"tab": UIManager.Tab.SETTINGS, "key": "Settings"},
]

@onready var top_bar: TopBar = %TopBar
@onready var hub_nav: HBoxContainer = %HubNav
@onready var game_log_view: GameLogView = %GameLogView
@onready var content_bg: ColorRect = %ContentBg
@onready var content_vbox: VBoxContainer = %ContentVBox
@onready var content_host: Control = %ContentHost
@onready var footer: FooterPrompts = %Footer

var _ui_manager: UIManager
var _hub_buttons: Array[Button] = []
var _hub_style: StyleBoxEmpty


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if content_bg:
		content_bg.visible = false
	if content_vbox:
		content_vbox.visible = false
	if content_host:
		content_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if footer:
		footer.visible = false
	if top_bar:
		top_bar.set_tabs([])
	_build_hub_nav()
	LocaleManager.locale_changed.connect(_on_locale_changed)


func setup(ui_manager: UIManager) -> void:
	_ui_manager = ui_manager
	if game_log_view and _ui_manager and _ui_manager.game_log:
		game_log_view.bind_log(_ui_manager.game_log)
	if _ui_manager and not _ui_manager.popup_visibility_changed.is_connected(_on_popup_visibility):
		_ui_manager.popup_visibility_changed.connect(_on_popup_visibility)
	_sync_chrome()
	_sync_hub_nav()


func refresh_bookshelf() -> void:
	if _ui_manager and _ui_manager.has_method("refresh_bookshelf"):
		_ui_manager.refresh_bookshelf()


func _sync_chrome() -> void:
	if top_bar == null or _ui_manager == null:
		return
	top_bar.set_location(_ui_manager.location_id)
	if _ui_manager.character_stats:
		top_bar.set_player_stats(_ui_manager.character_stats)
	if _ui_manager.inventory_data:
		top_bar.set_currencies(_ui_manager.inventory_data.currencies)


func _build_hub_nav() -> void:
	if hub_nav == null:
		return
	_hub_style = StyleBoxEmpty.new()
	for child in hub_nav.get_children():
		child.queue_free()
	_hub_buttons.clear()
	for def in HUB_NAV:
		var button := Button.new()
		button.flat = true
		button.focus_mode = Control.FOCUS_NONE
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.add_theme_stylebox_override("normal", _hub_style)
		button.add_theme_stylebox_override("hover", _hub_style)
		button.add_theme_stylebox_override("pressed", _hub_style)
		button.add_theme_stylebox_override("focus", _hub_style)
		button.add_theme_font_size_override("font_size", 18)
		button.pressed.connect(_on_hub_pressed.bind(int(def.get("tab", -1))))
		hub_nav.add_child(button)
		_hub_buttons.append(button)
	_refresh_hub_nav_labels()
	_sync_hub_nav()


func _refresh_hub_nav_labels() -> void:
	for i in range(_hub_buttons.size()):
		var key := str(HUB_NAV[i].get("key", ""))
		_hub_buttons[i].text = "[%s]" % tr(key)


func _sync_hub_nav() -> void:
	var active := _ui_manager.get_active_tab() if _ui_manager else -1
	var menu_open := _ui_manager != null and _ui_manager.is_menu_open()
	for i in range(_hub_buttons.size()):
		var tab := int(HUB_NAV[i].get("tab", -1))
		var is_active := menu_open and tab == active
		_hub_buttons[i].add_theme_color_override(
			"font_color", UIColors.GOLD if is_active else UIColors.TEXT_MUTED
		)
		_hub_buttons[i].add_theme_color_override("font_hover_color", UIColors.GOLD)
		_hub_buttons[i].add_theme_color_override("font_pressed_color", UIColors.GOLD)


func _on_hub_pressed(tab: int) -> void:
	if _ui_manager == null:
		return
	if _ui_manager.is_menu_open() and _ui_manager.get_active_tab() == tab:
		_ui_manager.close_all()
		return
	_ui_manager.open_tab(tab)


func _on_popup_visibility(_is_open: bool) -> void:
	_sync_chrome()
	_sync_hub_nav()


func _on_locale_changed(_locale: String) -> void:
	_refresh_hub_nav_labels()
	_sync_chrome()
