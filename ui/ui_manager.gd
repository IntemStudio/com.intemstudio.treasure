class_name UIManager
extends Node

const MENU_SHELL_PATH := "res://ui/shell/menu_shell.tscn"
const DEV_OVERLAY_SCENE := preload("res://ui/dev/dev_overlay.tscn")
const GAME_HUD_SCENE := preload("res://ui/hud/game_hud.tscn")
const LOOT_CHOICE_SCENE := preload("res://ui/loot/loot_choice_overlay.tscn")
const ENDING_CHOICE_SCENE := preload("res://ui/loot/ending_choice_overlay.tscn")

enum Tab { INVENTORY = 0, MAP = 1, STATS = 2, SETTINGS = 3, BOARD = 4, SHELF = 5, SMITHY = 6 }

signal input_device_changed(using_gamepad: bool)
signal popup_visibility_changed(is_open: bool)

var character_stats: CharacterStats
var inventory_data: InventoryData
var location_id: String = "LOCATION_TEST"
var using_gamepad: bool = false
var floor_map: FloorMap
var room_host: RoomHost
var encounter_director: EncounterDirector
var game_log: GameLog
var in_combat: bool = false
var hub_mode: bool = false
var challenge_board_open: bool = false

var _shell: CanvasLayer
var _hud: GameHud
var _dev_overlay: CanvasLayer
var _loot_choice_layer: CanvasLayer
var _loot_choice: LootChoiceOverlay
var _ending_choice: EndingChoiceOverlay
var _zone_location_key: String = ""
var _active_tab: int = -1
var _last_tab: int = Tab.STATS
var _room_changed_connected: bool = false
var _menu_open: bool = false
var _log_session: CombatSession


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
	game_log = GameLog.new()
	_hud.bind_game_log(game_log)
	_hud.setup(character_stats, inventory_data, location_id)
	_hud.map_open_requested.connect(_on_hud_map_open_requested)
	_hud.menu_tab_requested.connect(open_tab)

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

	_loot_choice_layer = CanvasLayer.new()
	_loot_choice_layer.layer = 20
	_loot_choice_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_loot_choice_layer)
	_loot_choice = LOOT_CHOICE_SCENE.instantiate() as LootChoiceOverlay
	_loot_choice_layer.add_child(_loot_choice)
	_loot_choice.setup(self)
	_ending_choice = ENDING_CHOICE_SCENE.instantiate() as EndingChoiceOverlay
	_loot_choice_layer.add_child(_ending_choice)
	_ending_choice.setup(self)

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
		if challenge_board_open:
			get_viewport().set_input_as_handled()
			return
		if _active_tab >= 0:
			close_all()
		else:
			var tab := _last_tab
			if hub_mode and tab == Tab.MAP:
				tab = Tab.STATS
			open_tab(tab)
		get_viewport().set_input_as_handled()


func set_hub_mode(enabled: bool) -> void:
	hub_mode = enabled
	unbind_dungeon()
	if enabled:
		set_location("LOCATION_VILLAGE")
		if character_stats:
			character_stats.hp = character_stats.hp_max
			refresh_character_views()
	if _shell and _shell.has_method("set_hub_mode"):
		_shell.set_hub_mode(enabled)
	if _hud:
		_hud.set_hub_mode(enabled)


func set_challenge_board_open(open: bool) -> void:
	challenge_board_open = open
	_menu_open = open or (_shell != null and _shell.visible)
	popup_visibility_changed.emit(_menu_open)


func bind_dungeon(p_floor_map: FloorMap, p_room_host: RoomHost, location_key: String = "") -> void:
	hub_mode = false
	if _shell and _shell.has_method("set_hub_mode"):
		_shell.set_hub_mode(false)
	if _hud:
		_hud.set_hub_mode(false)
	unbind_dungeon()
	_zone_location_key = location_key
	floor_map = p_floor_map
	room_host = p_room_host
	if floor_map and not floor_map.room_changed.is_connected(_on_floor_room_changed):
		floor_map.room_changed.connect(_on_floor_room_changed)
		_room_changed_connected = true
	if _hud:
		_hud.bind_floor_map(floor_map)
	if floor_map and floor_map.has_room(floor_map.get_current()):
		_on_floor_room_changed(floor_map.get_current())


func bind_combat(p_director: EncounterDirector) -> void:
	_disconnect_combat_log()
	encounter_director = p_director
	_connect_combat_log()


func unbind_dungeon() -> void:
	_disconnect_combat_log()
	if floor_map and _room_changed_connected and floor_map.room_changed.is_connected(_on_floor_room_changed):
		floor_map.room_changed.disconnect(_on_floor_room_changed)
	_room_changed_connected = false
	if _hud:
		_hud.unbind_floor_map()
	floor_map = null
	room_host = null
	encounter_director = null
	_zone_location_key = ""
	clear_log()
	set_combat_active(false)


func set_combat_active(active: bool) -> void:
	in_combat = active
	_refresh_hud_visibility()
	if not active:
		unbind_skill_gauge()


func bind_skill_gauge(session: CombatSession) -> void:
	if _hud:
		_hud.bind_skill_session(session)


func unbind_skill_gauge() -> void:
	if _hud:
		_hud.unbind_skill_session()


func is_combat_active() -> bool:
	return in_combat or (encounter_director != null and encounter_director.is_active())


func is_menu_open() -> bool:
	return _menu_open


func is_world_input_blocked() -> bool:
	if challenge_board_open:
		return true
	if _menu_open or is_combat_active():
		return true
	if _dev_overlay and _dev_overlay.is_open():
		return true
	return false


func _refresh_hud_visibility() -> void:
	if _hud:
		_hud.set_menu_open(_menu_open or challenge_board_open)

func _on_floor_room_changed(pos: Vector2i) -> void:
	if floor_map == null:
		return
	if not _zone_location_key.is_empty():
		set_location(_zone_location_key)
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
	if challenge_board_open:
		return
	if (
		tab != Tab.INVENTORY
		and tab != Tab.MAP
		and tab != Tab.STATS
		and tab != Tab.SETTINGS
		and tab != Tab.BOARD
		and tab != Tab.SHELF
		and tab != Tab.SMITHY
	):
		return
	if hub_mode and tab == Tab.MAP:
		return
	if not hub_mode and tab == Tab.SMITHY:
		return
	_active_tab = tab
	if tab != Tab.BOARD and tab != Tab.SHELF and tab != Tab.SMITHY:
		_last_tab = tab
	_shell.open_tab(tab, character_stats, inventory_data)
	_menu_open = true
	popup_visibility_changed.emit(true)


func get_active_tab() -> int:
	return _active_tab


func refresh_bookshelf() -> void:
	if _shell and _shell.has_method("refresh_bookshelf"):
		_shell.refresh_bookshelf()


func _on_hud_map_open_requested() -> void:
	if hub_mode or is_combat_active():
		return
	open_tab(Tab.MAP)


func close_all() -> void:
	if _shell.visible:
		_shell.close()
	else:
		_active_tab = -1


func _on_shell_closed() -> void:
	_active_tab = -1
	_menu_open = false
	popup_visibility_changed.emit(false)

func _on_tab_changed(tab: int) -> void:
	if (
		tab == Tab.STATS
		or tab == Tab.INVENTORY
		or tab == Tab.MAP
		or tab == Tab.SETTINGS
		or tab == Tab.BOARD
		or tab == Tab.SHELF
		or tab == Tab.SMITHY
	):
		_active_tab = tab
		if tab != Tab.BOARD and tab != Tab.SHELF and tab != Tab.SMITHY:
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


func refresh_hud() -> void:
	if _hud:
		_hud.refresh(character_stats, inventory_data)


func push_log(payload: Dictionary) -> void:
	if game_log:
		game_log.push(payload)


func show_loot_toast(result: Dictionary) -> void:
	if _hud and _hud.has_method("show_loot_toast"):
		_hud.show_loot_toast(result)


func show_loot_choice(offers: Array, reward_type: int, on_done: Callable) -> void:
	if _loot_choice == null:
		if on_done.is_valid():
			on_done.call({})
		return
	_loot_choice.open(offers, reward_type, on_done)


func show_ending_choice(allow_seal: bool, allow_empty: bool, on_done: Callable) -> void:
	if _ending_choice == null:
		if on_done.is_valid():
			on_done.call(BasinProgress.ENDING_TAKE)
		return
	_ending_choice.open(allow_seal, allow_empty, on_done)


func clear_log() -> void:
	if game_log:
		game_log.clear()


func _connect_combat_log() -> void:
	if encounter_director == null:
		return
	if not encounter_director.combat_started.is_connected(_on_log_combat_started):
		encounter_director.combat_started.connect(_on_log_combat_started)
	if not encounter_director.combat_finished.is_connected(_on_log_combat_finished):
		encounter_director.combat_finished.connect(_on_log_combat_finished)
	_connect_session_log()


func _connect_session_log() -> void:
	if encounter_director == null or encounter_director.session == null:
		return
	var session := encounter_director.session
	if _log_session != null and _log_session != session:
		if _log_session.action_resolved.is_connected(_on_action_resolved):
			_log_session.action_resolved.disconnect(_on_action_resolved)
	_log_session = session
	if not session.action_resolved.is_connected(_on_action_resolved):
		session.action_resolved.connect(_on_action_resolved)


func _disconnect_combat_log() -> void:
	if encounter_director:
		if encounter_director.combat_started.is_connected(_on_log_combat_started):
			encounter_director.combat_started.disconnect(_on_log_combat_started)
		if encounter_director.combat_finished.is_connected(_on_log_combat_finished):
			encounter_director.combat_finished.disconnect(_on_log_combat_finished)
	if _log_session and _log_session.action_resolved.is_connected(_on_action_resolved):
		_log_session.action_resolved.disconnect(_on_action_resolved)
	_log_session = null


func _on_log_combat_started() -> void:
	_connect_session_log()
	var names: PackedStringArray = PackedStringArray()
	if encounter_director and encounter_director.session and encounter_director.session.encounter:
		for def in encounter_director.session.encounter.enemies:
			if def == null:
				continue
			var n := def.display_name if not def.display_name.is_empty() else def.id
			names.append(n)
	push_log({
		"category": "combat",
		"kind": "combat.start",
		"actor_name": ", ".join(names),
	})


func _on_log_combat_finished(result: String) -> void:
	push_log({
		"category": "combat",
		"kind": "combat.end",
		"result": result,
	})


func _on_action_resolved(payload: Dictionary) -> void:
	push_log(payload)


func _on_popup_visibility_changed(is_open: bool) -> void:
	_menu_open = is_open
	_refresh_hud_visibility()
	if not is_open and _hud:
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
	in_combat = false
	_menu_open = false
	challenge_board_open = false
	hub_mode = false
	if _shell:
		_shell.visible = false
	unbind_dungeon()
	SaveManager.clear_pending_run()
	SaveManager.current_slot = -1
	SaveManager.play_time_sec = 0.0
	var tree := get_tree()
	if tree == null:
		return
	# MenuShell is WHEN_PAUSED. Changing scenes from that stack while paused
	# can leave the title frozen or skip the switch. Unpause, then defer.
	tree.paused = false
	tree.change_scene_to_file.call_deferred("res://scenes/title/title.tscn")


func return_to_village() -> void:
	in_combat = false
	_menu_open = false
	challenge_board_open = false
	if _shell:
		_shell.visible = false
	unbind_dungeon()
	SaveManager.clear_pending_run()
	if SaveManager.current_slot >= 0:
		SaveManager.clear_run(SaveManager.current_slot)
	# Hub heals to full; persist before scene change so the next dungeon load
	# does not restore pre-defeat HP from disk.
	if character_stats:
		character_stats.hp = character_stats.hp_max
	if SaveManager.current_slot >= 0 and character_stats != null and inventory_data != null:
		save_to_slot(SaveManager.current_slot)
	var tree := get_tree()
	if tree == null:
		return
	tree.paused = false
	tree.change_scene_to_file.call_deferred("res://scenes/village/village.tscn")
