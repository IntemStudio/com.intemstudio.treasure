class_name GameHud
extends CanvasLayer

const DEFAULT_LOCATION := "LOCATION_TEST"

@onready var resource_bars: ResourceBars = %ResourceBars
@onready var world_info: WorldInfo = %WorldInfo
@onready var action_bar: ActionBar = %ActionBar

var _stats: CharacterStats
var _inventory: InventoryData
var _location_id: String = DEFAULT_LOCATION


func _ready() -> void:
	layer = 0
	_apply()


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


func _apply() -> void:
	if resource_bars:
		resource_bars.set_stats(_stats)
	if world_info:
		world_info.set_location(_location_id)
	if action_bar:
		action_bar.set_inventory(_inventory)
