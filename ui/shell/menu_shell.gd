extends CanvasLayer

signal closed
signal tab_changed(tab: int)

enum Tab { INVENTORY = 0, MAP = 1, STATS = 2, SETTINGS = 3, BOARD = 4, SHELF = 5, SMITHY = 6, ALTAR = 7 }

const INVENTORY_CONTENT_PATH := "res://ui/inventory/inventory_content.tscn"
const MAP_CONTENT_PATH := "res://ui/map/map_content.tscn"
const STATS_CONTENT_PATH := "res://ui/stats/stats_content.tscn"
const SETTINGS_CONTENT_PATH := "res://ui/settings/settings_content.tscn"
const BOARD_CONTENT_PATH := "res://ui/village/challenge_board.tscn"
const SHELF_CONTENT_PATH := "res://ui/village/bookshelf.tscn"
const SMITHY_CONTENT_PATH := "res://ui/village/smithy.tscn"
const ALTAR_CONTENT_PATH := "res://ui/village/altar.tscn"

const TITLE_KEYS := {
	Tab.INVENTORY: "Inventory",
	Tab.MAP: "Map",
	Tab.STATS: "Stats",
	Tab.SETTINGS: "Settings",
	Tab.BOARD: "BOARD_LABEL",
	Tab.SHELF: "SHELF_LABEL",
	Tab.SMITHY: "SMITHY_LABEL",
	Tab.ALTAR: "ALTAR_LABEL",
}
const PLAYER_TAB_KEYS: Array[String] = ["Inventory", "Map", "Stats", "Settings"]
const VILLAGE_TAB_KEYS: Array[String] = ["BOARD_LABEL", "ALTAR_LABEL", "SHELF_LABEL", "SMITHY_LABEL"]
const VILLAGE_TAB_SHORTCUTS: Array[String] = ["Q", "W", "E", "R"]
const VILLAGE_TABS: Array[int] = [Tab.BOARD, Tab.ALTAR, Tab.SHELF, Tab.SMITHY]

enum Chrome { NONE, PLAYER, VILLAGE }

@onready var overlay: ColorRect = $Overlay
@onready var safe: MarginContainer = $Overlay/Safe
@onready var top_bar: TopBar = %TopBar
@onready var footer: FooterPrompts = %Footer
@onready var body_host: Control = %BodyHost
@onready var sheet: PanelContainer = %Sheet
@onready var top_band: Control = %TopBand
@onready var mid_band: Control = %MidBand
@onready var bottom_band: Control = %BottomBand

var _ui_manager: UIManager
var _character_stats: CharacterStats
var _inventory_data: InventoryData
var _active_tab: int = -1
var _inventory_content: Control
var _map_content: Control
var _stats_content: Control
var _settings_content: Control
var _board_content: Control
var _shelf_content: Control
var _smithy_content: Control
var _altar_content: Control
var _contents: Dictionary = {}
var _wired: bool = false
var _chrome: int = Chrome.NONE


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	if sheet:
		UIPopupLayout.apply_sheet_panel(sheet)
	UIPopupLayout.apply_sheet_bands(top_band, mid_band, bottom_band)
	if top_bar:
		top_bar.set_tabs([])
		top_bar.custom_minimum_size = Vector2(0, 0)
		top_bar.size_flags_vertical = Control.SIZE_EXPAND_FILL
	if footer:
		footer.custom_minimum_size = Vector2(0, 0)
		footer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_mount_contents()
	if overlay and not overlay.resized.is_connected(_on_overlay_resized):
		overlay.resized.connect(_on_overlay_resized)
	if top_bar and not top_bar.tab_changed.is_connected(_on_top_bar_tab_changed):
		top_bar.tab_changed.connect(_on_top_bar_tab_changed)
	LocaleManager.locale_changed.connect(_on_locale_changed)


func setup(ui_manager: UIManager) -> void:
	_ui_manager = ui_manager
	if not is_node_ready():
		ready.connect(_wire_contents, CONNECT_ONE_SHOT)
		return
	_wire_contents()


func set_hub_mode(_enabled: bool) -> void:
	pass


func refresh_bookshelf() -> void:
	if _shelf_content and _shelf_content.has_method("refresh"):
		_shelf_content.refresh()


func _mount_contents() -> void:
	if body_host == null:
		push_error("MenuShell: BodyHost missing")
		return

	# load() at mount time avoids UIManager ↔ menu_shell ↔ settings preload cycles
	# that can yield an empty PackedScene (node count 0).
	_inventory_content = _instantiate_content(load(INVENTORY_CONTENT_PATH) as PackedScene)
	_map_content = _instantiate_content(load(MAP_CONTENT_PATH) as PackedScene)
	_stats_content = _instantiate_content(load(STATS_CONTENT_PATH) as PackedScene)
	_settings_content = _instantiate_content(load(SETTINGS_CONTENT_PATH) as PackedScene)
	_board_content = _instantiate_content(load(BOARD_CONTENT_PATH) as PackedScene)
	_shelf_content = _instantiate_content(load(SHELF_CONTENT_PATH) as PackedScene)
	_smithy_content = _instantiate_content(load(SMITHY_CONTENT_PATH) as PackedScene)
	_altar_content = _instantiate_content(load(ALTAR_CONTENT_PATH) as PackedScene)

	for content in [
		_inventory_content,
		_map_content,
		_stats_content,
		_settings_content,
		_board_content,
		_shelf_content,
		_smithy_content,
		_altar_content,
	]:
		if content == null:
			continue
		body_host.add_child(content)
		_fit_content(content)
		if content.has_signal("request_close"):
			content.request_close.connect(close)

	_contents = {
		Tab.INVENTORY: _inventory_content,
		Tab.MAP: _map_content,
		Tab.STATS: _stats_content,
		Tab.SETTINGS: _settings_content,
		Tab.BOARD: _board_content,
		Tab.SHELF: _shelf_content,
		Tab.SMITHY: _smithy_content,
		Tab.ALTAR: _altar_content,
	}


func _instantiate_content(scene: PackedScene) -> Control:
	if scene == null:
		push_error("MenuShell: content scene is null")
		return null
	var node := scene.instantiate()
	if node == null or not (node is Control):
		push_error("MenuShell: failed to instantiate content Control")
		if node:
			node.queue_free()
		return null
	return node as Control


func _fit_content(content: Control) -> void:
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.clip_contents = true
	if body_host:
		body_host.clip_contents = true
	if mid_band:
		mid_band.clip_contents = true


func _wire_contents() -> void:
	if _wired or _ui_manager == null:
		return
	if (
		_inventory_content == null
		or _map_content == null
		or _stats_content == null
		or _settings_content == null
		or _board_content == null
		or _shelf_content == null
		or _smithy_content == null
		or _altar_content == null
	):
		return
	if footer == null:
		push_error("MenuShell: Footer missing")
		return
	_inventory_content.setup(_ui_manager, footer)
	_map_content.setup(_ui_manager, footer)
	_stats_content.setup(_ui_manager, footer)
	_settings_content.setup(_ui_manager, footer)
	_board_content.setup(_ui_manager, footer)
	_shelf_content.setup(_ui_manager, footer)
	_smithy_content.setup(_ui_manager, footer)
	_altar_content.setup(_ui_manager, footer)
	_wired = true


func open_tab(tab: int, stats: CharacterStats, inventory: InventoryData) -> void:
	if not _contents.has(tab):
		return
	_character_stats = stats
	_inventory_data = inventory
	_active_tab = tab
	visible = true
	get_tree().paused = true
	_show_content(tab)
	_sync_chrome(tab)
	tab_changed.emit(tab)


func close() -> void:
	_deactivate_all()
	visible = false
	get_tree().paused = false
	_active_tab = -1
	closed.emit()


func get_active_tab() -> int:
	return _active_tab


func _show_content(tab: int) -> void:
	_deactivate_all()
	var content: Control = _contents.get(tab)
	if content and content.has_method("activate"):
		content.activate(_character_stats, _inventory_data)


func _deactivate_all() -> void:
	for content in _contents.values():
		if content and content.has_method("deactivate"):
			content.deactivate()


func _is_player_tab(tab: int) -> bool:
	return (
		tab == Tab.INVENTORY
		or tab == Tab.MAP
		or tab == Tab.STATS
		or tab == Tab.SETTINGS
	)


func _is_village_tab(tab: int) -> bool:
	return tab == Tab.BOARD or tab == Tab.ALTAR or tab == Tab.SHELF or tab == Tab.SMITHY


func _chrome_for(tab: int) -> int:
	if _is_player_tab(tab):
		return Chrome.PLAYER
	if _is_village_tab(tab):
		return Chrome.VILLAGE
	return Chrome.NONE


func _tab_from_chrome_index(index: int) -> int:
	match _chrome:
		Chrome.PLAYER:
			if _is_player_tab(index):
				return index
		Chrome.VILLAGE:
			if index >= 0 and index < VILLAGE_TABS.size():
				return VILLAGE_TABS[index]
	return -1


func _sync_chrome(tab: int) -> void:
	if top_bar == null:
		return
	var chrome := _chrome_for(tab)
	_apply_layout(chrome == Chrome.PLAYER)
	if chrome != _chrome:
		_chrome = chrome
		match chrome:
			Chrome.PLAYER:
				top_bar.set_tabs(PLAYER_TAB_KEYS)
			Chrome.VILLAGE:
				top_bar.set_tabs(VILLAGE_TAB_KEYS, VILLAGE_TAB_SHORTCUTS)
			_:
				top_bar.set_tabs([])
	match chrome:
		Chrome.PLAYER:
			top_bar.set_active_tab(tab)
			top_bar.set_status_visible(true)
			if _character_stats:
				top_bar.set_player_stats(_character_stats)
			if _inventory_data:
				top_bar.set_currencies(_inventory_data.currencies)
		Chrome.VILLAGE:
			var idx := VILLAGE_TABS.find(tab)
			if idx >= 0:
				top_bar.set_active_tab(idx)
			top_bar.set_status_visible(false)
		_:
			var title_key := str(TITLE_KEYS.get(tab, ""))
			top_bar.set_location(title_key if not title_key.is_empty() else "LOCATION_UNKNOWN")
			top_bar.set_status_visible(false)


func _apply_layout(fullscreen: bool) -> void:
	if sheet == null or safe == null:
		return
	if fullscreen:
		safe.add_theme_constant_override("margin_left", 0)
		safe.add_theme_constant_override("margin_top", 0)
		safe.add_theme_constant_override("margin_right", 0)
		safe.add_theme_constant_override("margin_bottom", 0)
		var sz := overlay.size if overlay else Vector2.ZERO
		if sz.x < 1.0 or sz.y < 1.0:
			sz = get_viewport().get_visible_rect().size
		sheet.custom_minimum_size = sz
	else:
		UIPopupLayout.apply_outer_margin(safe)
		UIPopupLayout.apply_sheet_size(sheet)


func _on_overlay_resized() -> void:
	if _chrome == Chrome.PLAYER:
		_apply_layout(true)


func _on_top_bar_tab_changed(index: int) -> void:
	var tab := _tab_from_chrome_index(index)
	if tab < 0 or tab == _active_tab:
		return
	open_tab(tab, _character_stats, _inventory_data)


func _on_locale_changed(_locale: String) -> void:
	if _active_tab >= 0:
		_sync_chrome(_active_tab)
