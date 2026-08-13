extends Node2D

const ROOM_COUNT := 12

@onready var floor_map: FloorMap = $FloorMap
@onready var room_host: RoomHost = $RoomHost
@onready var player: Node2D = $Player
@onready var ui_manager: UIManager = $UIManager
@onready var camera: Camera2D = $Camera2D


func _ready() -> void:
	var seed_value := randi()
	floor_map.generate(seed_value, ROOM_COUNT)
	room_host.setup(floor_map, player)
	ui_manager.bind_dungeon(floor_map, room_host)
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
