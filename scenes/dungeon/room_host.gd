class_name RoomHost
extends Node2D

const BASIC_ROOM_SCENE := preload("res://scenes/dungeon/rooms/basic_room.tscn")

var _floor_map: FloorMap
var _player: Node2D
var _current_room: Node2D


func setup(floor_map: FloorMap, player: Node2D) -> void:
	_floor_map = floor_map
	_player = player


func enter_room(pos: Vector2i) -> bool:
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
	if _player and room.has_method("get_spawn_global"):
		_player.global_position = room.get_spawn_global()
	elif _player:
		_player.global_position = room.global_position
	return true
