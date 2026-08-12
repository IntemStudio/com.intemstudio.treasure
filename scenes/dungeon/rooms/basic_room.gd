extends Node2D

const TYPE_COLORS := {
	RoomData.RoomType.START: Color(0.22, 0.32, 0.28, 1),
	RoomData.RoomType.NORMAL: Color(0.16, 0.18, 0.22, 1),
	RoomData.RoomType.BOSS: Color(0.32, 0.16, 0.18, 1),
}

@onready var floor_rect: ColorRect = %Floor
@onready var spawn_marker: Marker2D = %SpawnMarker
@onready var room_label: Label = %RoomLabel


func apply_room(room: RoomData) -> void:
	if room == null:
		return
	floor_rect.color = TYPE_COLORS.get(room.room_type, TYPE_COLORS[RoomData.RoomType.NORMAL])
	room_label.text = "%s (%d, %d)" % [tr("ROOM_TYPE_%s" % room.type_name().to_upper()), room.grid_pos.x, room.grid_pos.y]


func get_spawn_global() -> Vector2:
	return spawn_marker.global_position
