class_name UIManager
extends Node

const MENU_SHELL_PATH := "res://ui/shell/menu_shell.tscn"
const DEV_OVERLAY_SCENE := preload("res://ui/dev/dev_overlay.tscn")
const GAME_HUD_SCENE := preload("res://ui/hud/game_hud.tscn")

enum Tab { INVENTORY = 0, MAP = 1, STATS = 2, SETTINGS = 3 }

signal input_device_changed(using_gamepad: bool)
signal popup_visibility_changed(is_open: bool)

var character_stats: CharacterStats
var inventory_data: InventoryData
var location_id: String = "LOCATION_TEST"
var using_gamepad: bool = false
var floor_map: FloorMap
var room_host: RoomHost

var _shell: CanvasLayer
var _hud: GameHud
var _dev_overlay: CanvasLayer
var _active_tab: int = -1
var _last_tab: int = Tab.STATS
var _room_changed_connected: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if SaveManager.current_slot >= 0 and SaveManager.has_save(SaveManager.current_slot):
		var sg := SaveManager.load_game(SaveManager.current_slot)
		if sg != null and not sg.is_empty():
			character_stats = sg.character
			inventory_data = sg.inventory
		else:
			character_stats = load("res://ui/stats/resources/character_stats.tres").duplicate(true)
			inventory_data = ItemBootstrap.create_sample_inventory()
	else:
		character_stats = load("res://ui/stats/resources/character_stats.tres").duplicate(true)
		inventory_data = ItemBootstrap.create_sample_inventory()

	if character_stats:
		character_stats.recalculate_derived()

	_hud = GAME_HUD_SCENE.instantiate()
	add_child(_hud)
	_hud.setup(character_stats, inventory_data, location_id)

	var menu_shell_scene := load(MENU_SHELL_PATH) as PackedScene
	if menu_shell_scene == null:
		push_error("UIManager: failed to load menu shell")
		return
	_shell = menu_shell_scene.instantiate()
	_shell.layer = 10
	add_child(_shell)
	_shell.setup(self)
	_shell.closed.connect(_on_shell_closed)
	_shell.tab_changed.connect(_on_tab_changed)

	_dev_overlay = DEV_OVERLAY_SCENE.instantiate()
	add_child(_dev_overlay)
	_dev_overlay.setup(self)

	popup_visibility_changed.connect(_on_popup_visibility_changed)


func _input(event: InputEvent) -> void:
	var next_gamepad := using_gamepad
	if event is InputEventJoypadButton:
		next_gamepad = true
	elif event is InputEventJoypadMotion:
		if absf((event as InputEventJoypadMotion).axis_value) < 0.5:
			return
		next_gamepad = true
	elif event is InputEventKey or event is InputEventMouseButton:
		next_gamepad = false
	else:
		return
	if next_gamepad == using_gamepad:
		return
	using_gamepad = next_gamepad
	input_device_changed.emit(using_gamepad)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("dev_overlay_toggle"):
		_dev_overlay.toggle()
		get_viewport().set_input_as_handled()
		return
	if _dev_overlay and _dev_overlay.is_open():
		if event.is_action_pressed("ui_cancel"):
			_dev_overlay.close()
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("stats_toggle") or event.is_action_pressed("inventory_toggle"):
		if _active_tab >= 0:
			close_all()
		else:
			open_tab(_last_tab)
		get_viewport().set_input_as_handled()


func bind_dungeon(p_floor_map: FloorMap, p_room_host: RoomHost) -> void:
	unbind_dungeon()
	floor_map = p_floor_map
	room_host = p_room_host
	if floor_map and not floor_map.room_changed.is_connected(_on_floor_room_changed):
		floor_map.room_changed.connect(_on_floor_room_changed)
		_room_changed_connected = true
	if floor_map and floor_map.has_room(floor_map.get_current()):
		_on_floor_room_changed(floor_map.get_current())


func unbind_dungeon() -> void:
	if floor_map and _room_changed_connected and floor_map.room_changed.is_connected(_on_floor_room_changed):
		floor_map.room_changed.disconnect(_on_floor_room_changed)
	_room_changed_connected = false
	floor_map = null
	room_host = null


func _on_floor_room_changed(pos: Vector2i) -> void:
	if floor_map == null:
		return
	var room := floor_map.get_room(pos)
	if room == null:
		set_location("LOCATION_DUNGEON")
		return
	match room.room_type:
		RoomData.RoomType.START:
			set_location("LOCATION_ROOM_START")
		RoomData.RoomType.BOSS:
			set_location("LOCATION_ROOM_BOSS")
		_:
			set_location("LOCATION_DUNGEON")


func open_tab(tab: int) -> void:
	if (
		tab != Tab.INVENTORY
		and tab != Tab.MAP
		and tab != Tab.STATS
		and tab != Tab.SETTINGS
	):
		return
	_active_tab = tab
	_last_tab = tab
	_shell.open_tab(tab, character_stats, inventory_data)
	popup_visibility_changed.emit(true)


func close_all() -> void:
	if _shell.visible:
		_shell.close()
	else:
		_active_tab = -1


func _on_shell_closed() -> void:
	_active_tab = -1
	popup_visibility_changed.emit(false)


func _on_tab_changed(tab: int) -> void:
	if (
		tab == Tab.STATS
		or tab == Tab.INVENTORY
		or tab == Tab.MAP
		or tab == Tab.SETTINGS
	):
		_active_tab = tab
		_last_tab = tab


func apply_save_game(sg: SaveGame) -> void:
	if sg == null or sg.is_empty():
		return
	character_stats = sg.character
	inventory_data = sg.inventory
	if _hud:
		_hud.refresh(character_stats, inventory_data)
	if _shell and _shell.visible and _active_tab >= 0:
		_shell.open_tab(_active_tab, character_stats, inventory_data)


func set_location(id: String) -> void:
	location_id = id if not id.is_empty() else "LOCATION_UNKNOWN"
	if _hud:
		_hud.set_location(location_id)


func refresh_character_views() -> void:
	if _hud:
		_hud.refresh(character_stats, inventory_data)
	if _shell and _shell.visible and _active_tab >= 0:
		_shell.open_tab(_active_tab, character_stats, inventory_data)


func _on_popup_visibility_changed(is_open: bool) -> void:
	if _hud:
		_hud.set_menu_open(is_open)
		if not is_open:
			_hud.refresh(character_stats, inventory_data)


func save_to_slot(slot: int) -> Error:
	return SaveManager.save_game(slot, character_stats, inventory_data)


func load_from_slot(slot: int) -> bool:
	var sg := SaveManager.load_game(slot)
	if sg == null or sg.is_empty():
		return false
	apply_save_game(sg)
	return true


func start_new_game(slot: int) -> bool:
	var sg := SaveManager.new_game(slot)
	if sg == null or sg.is_empty():
		return false
	apply_save_game(sg)
	return true


func return_to_title() -> void:
	close_all()
	unbind_dungeon()
	get_tree().paused = false
	SaveManager.current_slot = -1
	SaveManager.play_time_sec = 0.0
	get_tree().change_scene_to_file("res://scenes/title/title.tscn")
