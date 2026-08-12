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
