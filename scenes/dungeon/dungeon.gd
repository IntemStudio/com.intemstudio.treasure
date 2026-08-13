extends Node2D

const ROOM_COUNT := 12
const COMBAT_HUD_SCENE := preload("res://ui/combat/combat_hud.tscn")

@onready var floor_map: FloorMap = $FloorMap
@onready var room_host: RoomHost = $RoomHost
@onready var player: Node2D = $Player
@onready var ui_manager: UIManager = $UIManager
@onready var camera: Camera2D = $Camera2D

var encounter_director: EncounterDirector
var combat_session: CombatSession
var combat_arena: CombatArena
var combat_hud: CombatHud


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
	if not run.is_empty():
		seed_value = int(run.get("seed", randi()))
		room_count = int(run.get("room_count", ROOM_COUNT))
	else:
		# Editor direct-run fallback (no village challenge).
		seed_value = randi()
		room_count = ROOM_COUNT
	floor_map.generate(seed_value, room_count)
	room_host.setup(floor_map, player)
	ui_manager.bind_dungeon(floor_map, room_host)
	ui_manager.bind_combat(encounter_director)

	encounter_director.setup(
		ui_manager, floor_map, room_host, combat_session, combat_arena, combat_hud
	)
	if not floor_map.room_changed.is_connected(_on_room_changed):
		floor_map.room_changed.connect(_on_room_changed)

	room_host.enter_room(Vector2i.ZERO)
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
