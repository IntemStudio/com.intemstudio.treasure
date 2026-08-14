extends Node2D

const ROOM_COUNT := 12
const COMBAT_HUD_SCENE := preload("res://ui/combat/combat_hud.tscn")
const RegionEncountersScript := preload("res://data/combat/region_encounters.gd")

@onready var floor_map: FloorMap = $FloorMap
@onready var room_host: RoomHost = $RoomHost
@onready var player: Node2D = $Player
@onready var ui_manager: UIManager = $UIManager
@onready var camera: Camera2D = $Camera2D

var encounter_director: EncounterDirector
var combat_session: CombatSession
var combat_arena: CombatArena
var combat_hud: CombatHud
var _run_state: Dictionary = {}


func _ready() -> void:
	combat_session = CombatSession.new()
	combat_session.name = "CombatSession"
	add_child(combat_session)

	combat_arena = CombatArena.new()
	combat_arena.name = "CombatArena"
	add_child(combat_arena)
	combat_arena.setup(player)

	combat_hud = COMBAT_HUD_SCENE.instantiate() as CombatHud
	add_child(combat_hud)

	encounter_director = EncounterDirector.new()
	encounter_director.name = "EncounterDirector"
	add_child(encounter_director)

	var run := SaveManager.take_pending_run()
	var seed_value: int
	var room_count: int
	var dungeon_id: String = str(RegionEncountersScript.DEFAULT_REGION)
	if not run.is_empty():
		seed_value = int(run.get("seed", randi()))
		room_count = int(run.get("room_count", ROOM_COUNT))
		dungeon_id = str(run.get("dungeon_id", RegionEncountersScript.DEFAULT_REGION))
	else:
		# Editor direct-run fallback (no village challenge).
		seed_value = randi()
		room_count = ROOM_COUNT
	_run_state = run.duplicate(true)
	_run_state["seed"] = seed_value
	_run_state["room_count"] = room_count
	_run_state["dungeon_id"] = dungeon_id
	floor_map.generate(seed_value, room_count)
	room_host.setup(floor_map, player)
	ui_manager.bind_dungeon(floor_map, room_host)

	encounter_director.setup(
		ui_manager,
		floor_map,
		room_host,
		combat_session,
		combat_arena,
		combat_hud,
		dungeon_id
	)
	ui_manager.bind_combat(encounter_director)
	if not floor_map.room_changed.is_connected(_on_room_changed):
		floor_map.room_changed.connect(_on_room_changed)

	room_host.enter_room(Vector2i.ZERO)
	persist_run_progress()
	if camera:
		camera.make_current()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	if ui_manager and ui_manager.is_world_input_blocked():
		return
	var dir := _dir_from_event(event)
	if dir.is_empty():
		return
	if room_host and room_host.try_enter_direction(dir):
		get_viewport().set_input_as_handled()


func _dir_from_event(event: InputEvent) -> String:
	if event.is_action_pressed("ui_up"):
		return "N"
	if event.is_action_pressed("ui_right"):
		return "E"
	if event.is_action_pressed("ui_down"):
		return "S"
	if event.is_action_pressed("ui_left"):
		return "W"
	return ""


func _on_room_changed(pos: Vector2i) -> void:
	var room := floor_map.get_room(pos)
	if encounter_director:
		encounter_director.on_room_entered(room)
	persist_run_progress()


func persist_run_progress(slot: int = -1) -> void:
	var target := slot if slot >= 0 else SaveManager.current_slot
	if target < 0:
		return
	_run_state["current"] = {"x": floor_map.get_current().x, "y": floor_map.get_current().y}
	var visited: Array = []
	var cleared: Array = []
	for pos in floor_map.get_rooms().keys():
		var room: RoomData = floor_map.get_rooms()[pos] as RoomData
		if room == null:
			continue
		var key := "%d,%d" % [room.grid_pos.x, room.grid_pos.y]
		if room.visited:
			visited.append(key)
		if room.cleared:
			cleared.append(key)
	_run_state["visited"] = visited
	_run_state["cleared"] = cleared
	if ui_manager and ui_manager.inventory_data:
		_run_state.merge(SaveSerializer.run_equipment_snapshot(ui_manager.inventory_data), true)
	SaveManager.save_run(target, _run_state)
