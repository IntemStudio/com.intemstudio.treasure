class_name RoomData
extends RefCounted

enum RoomType { START, NORMAL, BOSS }

const TYPE_NAMES := {
	RoomType.START: "start",
	RoomType.NORMAL: "normal",
	RoomType.BOSS: "boss",
}

var grid_pos: Vector2i = Vector2i.ZERO
var room_type: RoomType = RoomType.NORMAL
## Direction key ("N"/"E"/"S"/"W") -> neighbor Vector2i
var neighbors: Dictionary = {}
var visited: bool = false
var cleared: bool = false


func type_name() -> String:
	return TYPE_NAMES.get(room_type, "normal")
