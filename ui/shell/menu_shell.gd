extends CanvasLayer

signal closed
signal tab_changed(tab: int)

enum Tab { INVENTORY = 0, MAP = 1, STATS = 2, SETTINGS = 3 }

const INVENTORY_CONTENT_PATH := "res://ui/inventory/inventory_content.tscn"
const MAP_CONTENT_PATH := "res://ui/map/map_content.tscn"
const STATS_CONTENT_PATH := "res://ui/stats/stats_content.tscn"
const SETTINGS_CONTENT_PATH := "res://ui/settings/settings_content.tscn"

@onready var top_bar: TopBar = $Overlay/Root/Main/TopBar
@onready var footer: FooterPrompts = $Overlay/Root/Main/Footer
@onready var body_host: Control = $Overlay/Root/Main/BodyHost

var _ui_manager: UIManager
var _character_stats: CharacterStats
var _inventory_data: InventoryData
var _active_tab: int = -1
var _inventory_content: Control
var _map_content: Control
var _stats_content: Control
var _settings_content: Control
var _contents: Dictionary = {}
var _wired: bool = false


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	_mount_contents()
	if top_bar:
		top_bar.tab_changed.connect(_on_top_bar_tab_changed)


func setup(ui_manager: UIManager) -> void:
	_ui_manager = ui_manager
	if not is_node_ready():
		ready.connect(_wire_contents, CONNECT_ONE_SHOT)
		return
	_wire_contents()


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

	for content in [_inventory_content, _map_content, _stats_content, _settings_content]:
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


func _wire_contents() -> void:
	if _wired or _ui_manager == null:
		return
	if (
		_inventory_content == null
		or _map_content == null
		or _stats_content == null
		or _settings_content == null
	):
		return
	if footer == null:
		push_error("MenuShell: Footer missing")
		return
	_inventory_content.setup(_ui_manager, footer)
	_map_content.setup(_ui_manager, footer)
	_stats_content.setup(_ui_manager, footer)
	_settings_content.setup(_ui_manager, footer)
	_wired = true


func open_tab(tab: int, stats: CharacterStats, inventory: InventoryData) -> void:
	if (
		tab != Tab.INVENTORY
		and tab != Tab.MAP
		and tab != Tab.STATS
		and tab != Tab.SETTINGS
	):
		return
	_character_stats = stats
	_inventory_data = inventory
	_active_tab = tab
	visible = true
	get_tree().paused = true
	_show_content(tab)
	_sync_chrome(tab)


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


func _sync_chrome(tab: int) -> void:
	if top_bar:
		top_bar.set_active_tab(tab)
		if _character_stats:
			top_bar.set_player_stats(_character_stats)
		if _inventory_data:
			top_bar.set_currencies(_inventory_data.currencies)


func _on_top_bar_tab_changed(tab: int) -> void:
	tab_changed.emit(tab)
	if (
		tab == Tab.INVENTORY
		or tab == Tab.MAP
		or tab == Tab.STATS
		or tab == Tab.SETTINGS
	):
		_active_tab = tab
		_show_content(tab)
		_sync_chrome(tab)
	else:
		close()
