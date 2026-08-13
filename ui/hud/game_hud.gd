class_name GameHud
extends CanvasLayer

signal map_open_requested

const DEFAULT_LOCATION := "LOCATION_TEST"

@onready var resource_bars: ResourceBars = %ResourceBars
@onready var world_info: WorldInfo = %WorldInfo
@onready var action_bar: ActionBar = %ActionBar
@onready var mini_map: MiniMap = %MiniMap
@onready var game_log_view: GameLogView = %GameLogView

var _stats: CharacterStats
var _inventory: InventoryData
var _location_id: String = DEFAULT_LOCATION
var _pending_floor_map: FloorMap
var _pending_game_log: GameLog


func _ready() -> void:
	layer = 0
	_apply()
	if mini_map and not mini_map.map_open_requested.is_connected(_on_minimap_open_requested):
		mini_map.map_open_requested.connect(_on_minimap_open_requested)
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


func set_menu_open(is_open: bool) -> void:
	visible = not is_open


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


func _on_minimap_open_requested() -> void:
	map_open_requested.emit()


func _apply() -> void:
	if resource_bars:
		resource_bars.set_stats(_stats)
	if world_info:
		world_info.set_location(_location_id)
	if action_bar:
		action_bar.set_inventory(_inventory)
