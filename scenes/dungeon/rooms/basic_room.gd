extends Node2D

const TYPE_COLORS := {
	RoomData.RoomType.START: Color(0.22, 0.32, 0.28, 1),
	RoomData.RoomType.NORMAL: Color(0.16, 0.18, 0.22, 1),
	RoomData.RoomType.BOSS: Color(0.32, 0.16, 0.18, 1),
}

const FLOOR_HALF := Vector2(480, 270)
const WALL_THICK := 48.0
const DOOR_LENGTH := 128.0
const WALL_COLOR := Color(0.06, 0.06, 0.08, 1)
const DOOR_FRAME := Color(0.78, 0.66, 0.30, 1)
const DOOR_OPENING := Color(0.10, 0.10, 0.12, 1)
const DIR_KEYS: Array[String] = ["N", "E", "S", "W"]
const DIR_INPUT: Dictionary = {
	"N": "W",
	"E": "D",
	"S": "S",
	"W": "A",
}
const SPAWN_INSET := 56.0
const ALLY_SLOTS: Array[Vector2] = [
	Vector2(-200, 24),
	Vector2(-248, -80),
	Vector2(-248, 128),
]

@onready var floor_rect: ColorRect = %Floor
@onready var spawn_marker: Marker2D = %SpawnMarker
@onready var room_label: Label = %RoomLabel

var _doors: Dictionary = {}


func _ready() -> void:
	_ensure_geometry()


func apply_room(room: RoomData) -> void:
	if room == null:
		return
	_ensure_geometry()
	floor_rect.color = TYPE_COLORS.get(room.room_type, TYPE_COLORS[RoomData.RoomType.NORMAL])
	room_label.text = "%s (%d, %d)" % [tr("ROOM_TYPE_%s" % room.type_name().to_upper()), room.grid_pos.x, room.grid_pos.y]
	_refresh_doors(room)


func get_spawn_global() -> Vector2:
	return spawn_marker.global_position


func get_door_spawn_global(dir: String) -> Vector2:
	return to_global(_door_spawn_local(dir))


func get_ally_slot_global(index: int) -> Vector2:
	if index >= 0 and index < ALLY_SLOTS.size():
		return to_global(ALLY_SLOTS[index])
	return to_global(Vector2(-200, 24 + index * 104))


func get_enemy_slot_global(index: int, enemy_count: int = 1) -> Vector2:
	var formation := _enemy_formation(enemy_count)
	if index >= 0 and index < formation.size():
		return to_global(formation[index])
	var overflow := maxi(0, index - formation.size() + 1)
	return to_global(Vector2(260 + overflow * 48, 24 + overflow * 120))


func _enemy_formation(count: int) -> Array[Vector2]:
	var slots: Array[Vector2] = []
	match clampi(count, 1, 4):
		1:
			slots.assign([Vector2(160, 24)])
		2:
			slots.assign([Vector2(140, -80), Vector2(200, 128)])
		3:
			slots.assign([Vector2(200, -96), Vector2(120, 24), Vector2(200, 148)])
		_:
			slots.assign([
				Vector2(180, -100),
				Vector2(120, 24),
				Vector2(180, 148),
				Vector2(260, 24),
			])
	return slots


func _ensure_geometry() -> void:
	if not _doors.is_empty():
		return
	_build_walls()
	_build_doors()


func _build_walls() -> void:
	var walls := Node2D.new()
	walls.name = "Walls"
	add_child(walls)
	var wide := FLOOR_HALF.x * 2.0 + WALL_THICK * 2.0
	var tall := FLOOR_HALF.y * 2.0
	_add_rect(walls, "WallN", Rect2(-FLOOR_HALF.x - WALL_THICK, -FLOOR_HALF.y - WALL_THICK, wide, WALL_THICK), WALL_COLOR)
	_add_rect(walls, "WallS", Rect2(-FLOOR_HALF.x - WALL_THICK, FLOOR_HALF.y, wide, WALL_THICK), WALL_COLOR)
	_add_rect(walls, "WallW", Rect2(-FLOOR_HALF.x - WALL_THICK, -FLOOR_HALF.y, WALL_THICK, tall), WALL_COLOR)
	_add_rect(walls, "WallE", Rect2(FLOOR_HALF.x, -FLOOR_HALF.y, WALL_THICK, tall), WALL_COLOR)


func _build_doors() -> void:
	var host := Node2D.new()
	host.name = "Doors"
	host.z_index = 1
	add_child(host)
	for key in DIR_KEYS:
		var door := Node2D.new()
		door.name = "Door%s" % key
		var frame := _door_rect(key)
		_add_rect(door, "Frame", frame, DOOR_FRAME)
		_add_rect(door, "Opening", _inset(frame, 8.0), DOOR_OPENING)
		_add_key_label(door, frame, str(DIR_INPUT.get(key, "")))
		door.visible = false
		host.add_child(door)
		_doors[key] = door


func _refresh_doors(room: RoomData) -> void:
	for key in DIR_KEYS:
		var door: Node2D = _doors.get(key)
		if door:
			door.visible = room.neighbors.has(key)


func _door_rect(dir: String) -> Rect2:
	match dir:
		"N":
			return Rect2(-DOOR_LENGTH * 0.5, -FLOOR_HALF.y - WALL_THICK, DOOR_LENGTH, WALL_THICK)
		"S":
			return Rect2(-DOOR_LENGTH * 0.5, FLOOR_HALF.y, DOOR_LENGTH, WALL_THICK)
		"W":
			return Rect2(-FLOOR_HALF.x - WALL_THICK, -DOOR_LENGTH * 0.5, WALL_THICK, DOOR_LENGTH)
		"E":
			return Rect2(FLOOR_HALF.x, -DOOR_LENGTH * 0.5, WALL_THICK, DOOR_LENGTH)
	return Rect2()


func _inset(rect: Rect2, pad: float) -> Rect2:
	return Rect2(rect.position + Vector2(pad, pad), rect.size - Vector2(pad, pad) * 2.0)


func _door_spawn_local(dir: String) -> Vector2:
	match dir:
		"N":
			return Vector2(0.0, -FLOOR_HALF.y + SPAWN_INSET)
		"S":
			return Vector2(0.0, FLOOR_HALF.y - SPAWN_INSET)
		"W":
			return Vector2(-FLOOR_HALF.x + SPAWN_INSET, 0.0)
		"E":
			return Vector2(FLOOR_HALF.x - SPAWN_INSET, 0.0)
	return Vector2.ZERO


func _add_key_label(parent: Node, rect: Rect2, text: String) -> void:
	var label := Label.new()
	label.name = "KeyLabel"
	label.text = text
	label.position = rect.position
	label.size = rect.size
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", Color(0.96, 0.95, 0.92, 1))
	label.add_theme_color_override("font_outline_color", Color(0.04, 0.04, 0.05, 0.92))
	label.add_theme_constant_override("outline_size", 4)
	parent.add_child(label)


func _add_rect(parent: Node, node_name: String, rect: Rect2, color: Color) -> ColorRect:
	var node := ColorRect.new()
	node.name = node_name
	node.position = rect.position
	node.size = rect.size
	node.color = color
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	return node
