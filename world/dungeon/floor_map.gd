class_name FloorMap
extends Node

signal room_changed(pos: Vector2i)

const DEFAULT_ROOM_COUNT := 12

var seed_value: int = 0
var rooms: Dictionary = {}
var current: Vector2i = Vector2i.ZERO


func generate(p_seed: int, room_count: int = DEFAULT_ROOM_COUNT) -> void:
	seed_value = p_seed
	rooms = FloorGenerator.generate(p_seed, room_count)
	current = Vector2i.ZERO
	if rooms.has(current):
		(rooms[current] as RoomData).visited = true


func has_room(pos: Vector2i) -> bool:
	return rooms.has(pos)


func get_room(pos: Vector2i) -> RoomData:
	return rooms.get(pos) as RoomData


func get_rooms() -> Dictionary:
	return rooms


func get_current() -> Vector2i:
	return current


func set_current(pos: Vector2i) -> void:
	if not rooms.has(pos):
		return
	current = pos
	var room: RoomData = rooms[pos]
	room.visited = true
	room_changed.emit(pos)


## Visited rooms are always reachable. Unvisited rooms only if adjacent to current.
func can_enter(pos: Vector2i) -> bool:
	if not rooms.has(pos):
		return false
	var room: RoomData = rooms[pos]
	if room.visited or pos == current:
		return true
	var here: RoomData = rooms.get(current) as RoomData
	if here == null:
		return false
	for neighbor in here.neighbors.values():
		if neighbor == pos:
			return true
	return false
