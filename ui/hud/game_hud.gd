class_name GameHud
extends CanvasLayer

signal map_open_requested
signal menu_tab_requested(tab: int)

const DEFAULT_LOCATION := "LOCATION_TEST"
const MENU_NAV_DEFS: Array[Dictionary] = [
	{"tab": 0, "key": "Inventory"},
	{"tab": 1, "key": "Map"},
	{"tab": 2, "key": "Stats"},
	{"tab": 3, "key": "Settings"},
]

@onready var resource_bars: ResourceBars = %ResourceBars
@onready var world_info: WorldInfo = %WorldInfo
@onready var action_bar: ActionBar = %ActionBar
@onready var mini_map: MiniMap = %MiniMap
@onready var game_log_view: GameLogView = %GameLogView
@onready var loot_toast: Label = %LootToast
@onready var loot_toast_timer: Timer = %LootToastTimer
@onready var menu_nav: VBoxContainer = %MenuNav

var _stats: CharacterStats
var _inventory: InventoryData
var _location_id: String = DEFAULT_LOCATION
var _pending_floor_map: FloorMap
var _pending_game_log: GameLog
var _skill_session: CombatSession
var _hub_mode: bool = false
var _menu_nav_buttons: Dictionary = {}
var _menu_nav_style: StyleBoxEmpty


func _ready() -> void:
	layer = 0
	_apply()
	if loot_toast_timer and not loot_toast_timer.timeout.is_connected(_on_loot_toast_timeout):
		loot_toast_timer.timeout.connect(_on_loot_toast_timeout)
	if mini_map and not mini_map.map_open_requested.is_connected(_on_minimap_open_requested):
		mini_map.map_open_requested.connect(_on_minimap_open_requested)
	_build_menu_nav()
	LocaleManager.locale_changed.connect(_refresh_menu_nav)
	if _pending_floor_map != null:
		mini_map.set_floor_map(_pending_floor_map)
		_pending_floor_map = null
	if _pending_game_log != null and game_log_view:
		game_log_view.bind_log(_pending_game_log)
		_pending_game_log = null


func setup(stats: CharacterStats, inventory: InventoryData, location_id: String = DEFAULT_LOCATION) -> void:
	_stats = stats
	_inventory = inventory
	_location_id = location_id if not location_id.is_empty() else "LOCATION_UNKNOWN"
	if is_node_ready():
		_apply()


func refresh(stats: CharacterStats = null, inventory: InventoryData = null) -> void:
	if stats != null:
		_stats = stats
	if inventory != null:
		_inventory = inventory
	if is_node_ready():
		_apply()


func set_location(location_id: String) -> void:
	_location_id = location_id if not location_id.is_empty() else "LOCATION_UNKNOWN"
	if is_node_ready() and world_info:
		world_info.set_location(_location_id)


func set_hub_mode(enabled: bool) -> void:
	_hub_mode = enabled
	_apply_hub_nav()
	visible = not enabled


func set_menu_open(is_open: bool) -> void:
	visible = not is_open and not _hub_mode


func _build_menu_nav() -> void:
	if menu_nav == null:
		return
	_menu_nav_style = StyleBoxEmpty.new()
	for child in menu_nav.get_children():
		child.queue_free()
	_menu_nav_buttons.clear()
	for def in MENU_NAV_DEFS:
		var button := Button.new()
		var tab := int(def["tab"])
		button.flat = true
		button.focus_mode = Control.FOCUS_NONE
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.add_theme_stylebox_override("normal", _menu_nav_style)
		button.add_theme_stylebox_override("hover", _menu_nav_style)
		button.add_theme_stylebox_override("pressed", _menu_nav_style)
		button.add_theme_stylebox_override("focus", _menu_nav_style)
		button.add_theme_font_size_override("font_size", 16)
		button.add_theme_color_override("font_color", UIColors.TEXT_MAIN)
		button.add_theme_color_override("font_hover_color", UIColors.GOLD)
		button.add_theme_color_override("font_pressed_color", UIColors.GOLD)
		button.pressed.connect(_on_menu_nav_pressed.bind(tab))
		menu_nav.add_child(button)
		_menu_nav_buttons[tab] = button
	_refresh_menu_nav()
	_apply_hub_nav()


func _refresh_menu_nav() -> void:
	for def in MENU_NAV_DEFS:
		var tab := int(def["tab"])
		var button: Button = _menu_nav_buttons.get(tab)
		if button:
			button.text = "[%s]" % tr(str(def["key"]))


func _apply_hub_nav() -> void:
	var map_btn: Button = _menu_nav_buttons.get(1)
	if map_btn:
		map_btn.visible = not _hub_mode


func _on_menu_nav_pressed(tab: int) -> void:
	if _hub_mode and tab == 1:
		return
	menu_tab_requested.emit(tab)


func bind_floor_map(floor_map: FloorMap) -> void:
	if mini_map:
		mini_map.set_floor_map(floor_map)
	else:
		_pending_floor_map = floor_map


func unbind_floor_map() -> void:
	_pending_floor_map = null
	if mini_map:
		mini_map.clear_floor_map()


func bind_game_log(log: GameLog) -> void:
	if game_log_view:
		game_log_view.bind_log(log)
	else:
		_pending_game_log = log


func show_loot_toast(result: Dictionary) -> void:
	if loot_toast == null:
		return
	var granted: Array = result.get("granted", [])
	var skipped := int(result.get("skipped", 0))
	var granted_name := str(result.get("granted_name", "")).strip_edges()
	var parts: PackedStringArray = PackedStringArray()
	if not granted.is_empty():
		var names: PackedStringArray = PackedStringArray()
		for item in granted:
			if item is ItemData:
				var data := item as ItemData
				var n := data.display_name if not data.display_name.is_empty() else data.id
				names.append(tr(n))
		parts.append(tr("LOOT_GOT") % ", ".join(names))
	elif not granted_name.is_empty():
		parts.append(tr("LOOT_GOT") % tr(granted_name))
	if skipped > 0:
		parts.append(tr("LOOT_INVENTORY_FULL"))
	if parts.is_empty():
		return
	loot_toast.text = "\n".join(parts)
	loot_toast.visible = true
	if loot_toast_timer:
		loot_toast_timer.start()


func _on_loot_toast_timeout() -> void:
	if loot_toast:
		loot_toast.visible = false
		loot_toast.text = ""


func bind_skill_session(session: CombatSession) -> void:
	unbind_skill_session()
	_skill_session = session
	if _skill_session and not _skill_session.state_changed.is_connected(_on_skill_state_changed):
		_skill_session.state_changed.connect(_on_skill_state_changed)
	_on_skill_state_changed()


func unbind_skill_session() -> void:
	if _skill_session and _skill_session.state_changed.is_connected(_on_skill_state_changed):
		_skill_session.state_changed.disconnect(_on_skill_state_changed)
	_skill_session = null
	if action_bar:
		action_bar.clear_skill_charge()


func _on_skill_state_changed() -> void:
	if action_bar == null or _skill_session == null or not _skill_session.active:
		if action_bar:
			action_bar.clear_skill_charge()
		return
	var state := _skill_session.get_state()
	var full := float(state.get("skill_atb_full", 1.0))
	if full <= 0.0:
		full = 1.0
	var ratio := 0.0
	var active_index := -1
	var hero_mana := -1
	var hero_mana_max := -1
	var hero_hp := -1
	var hero_hp_max := -1
	for unit in state.get("units", []):
		if not unit is Dictionary:
			continue
		var u: Dictionary = unit
		if not bool(u.get("is_hero", false)):
			continue
		ratio = float(u.get("skill_atb", 0.0)) / full
		active_index = int(u.get("last_skill_index", -1))
		hero_mana = int(u.get("mana", 0))
		hero_mana_max = int(u.get("mana_max", 0))
		hero_hp = int(u.get("hp", 0))
		hero_hp_max = int(u.get("max_hp", 0))
		break
	action_bar.set_skill_charge(ratio, active_index)
	if resource_bars:
		resource_bars.set_combat_resources(hero_mana, hero_mana_max, hero_hp, hero_hp_max)


func _on_minimap_open_requested() -> void:
	map_open_requested.emit()


func _apply() -> void:
	if resource_bars:
		resource_bars.set_stats(_stats)
	if world_info:
		world_info.set_location(_location_id)
	if action_bar:
		action_bar.set_inventory(_inventory)
