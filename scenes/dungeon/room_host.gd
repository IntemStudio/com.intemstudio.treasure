class_name RoomHost
extends Node2D

const BASIC_ROOM_SCENE := preload("res://scenes/dungeon/rooms/basic_room.tscn")
const OPPOSITE_DIR := {
	"N": "S",
	"E": "W",
	"S": "N",
	"W": "E",
}

var _floor_map: FloorMap
var _player: Node2D
var _current_room: Node2D


func setup(floor_map: FloorMap, player: Node2D) -> void:
	_floor_map = floor_map
	_player = player


func try_enter_direction(dir: String) -> bool:
	if _floor_map == null:
		return false
	var here := _floor_map.get_room(_floor_map.get_current())
	if here == null or not here.neighbors.has(dir):
		return false
	return enter_room(here.neighbors[dir], dir)


func enter_room(pos: Vector2i, from_dir: String = "") -> bool:
	if _floor_map == null or not _floor_map.can_enter(pos):
		return false
	var room_data := _floor_map.get_room(pos)
	if _current_room:
		_current_room.queue_free()
		_current_room = null
	var room := BASIC_ROOM_SCENE.instantiate() as Node2D
	add_child(room)
	_current_room = room
	if room.has_method("apply_room"):
		room.apply_room(room_data)
	_floor_map.set_current(pos)
	_place_player(room, from_dir)
	return true


func get_current_room_node() -> Node2D:
	return _current_room


func _place_player(room: Node2D, from_dir: String) -> void:
	if _player == null:
		return
	var spawn_dir := str(OPPOSITE_DIR.get(from_dir, ""))
	if not spawn_dir.is_empty() and room.has_method("get_door_spawn_global"):
		_player.global_position = room.get_door_spawn_global(spawn_dir)
		return
	if room.has_method("get_spawn_global"):
		_player.global_position = room.get_spawn_global()
	else:
		_player.global_position = room.global_position
