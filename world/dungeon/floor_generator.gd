class_name FloorGenerator
extends RefCounted

const DIR_OFFSETS: Array[Vector2i] = [
	Vector2i(0, -1),
	Vector2i(1, 0),
	Vector2i(0, 1),
	Vector2i(-1, 0),
]
const DIR_KEYS: Array[String] = ["N", "E", "S", "W"]


static func generate(seed_value: int, room_count: int) -> Dictionary:
	var count := maxi(room_count, 1)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value as int

	var rooms: Dictionary = {}
	var start := RoomData.new()
	start.grid_pos = Vector2i.ZERO
	start.room_type = RoomData.RoomType.START
	rooms[start.grid_pos] = start

	var frontier: Array[Vector2i] = [start.grid_pos]
	while rooms.size() < count and not frontier.is_empty():
		var idx := rng.randi_range(0, frontier.size() - 1)
		var from: Vector2i = frontier[idx]
		var candidates: Array[Vector2i] = []
		for offset in DIR_OFFSETS:
			var next: Vector2i = from + offset
			if not rooms.has(next):
				candidates.append(next)
		if candidates.is_empty():
			frontier.remove_at(idx)
			continue
		var chosen: Vector2i = candidates[rng.randi_range(0, candidates.size() - 1)]
		var room := RoomData.new()
		room.grid_pos = chosen
		room.room_type = RoomData.RoomType.NORMAL
		rooms[chosen] = room
		frontier.append(chosen)

	_link_neighbors(rooms)
	_assign_boss(rooms)
	_assign_reward_types(rooms, seed_value)
	return rooms


static func _link_neighbors(rooms: Dictionary) -> void:
	for pos in rooms.keys():
		var room: RoomData = rooms[pos]
		for i in range(DIR_OFFSETS.size()):
			var neighbor_pos: Vector2i = pos + DIR_OFFSETS[i]
			if not rooms.has(neighbor_pos):
				continue
			var key: String = DIR_KEYS[i]
			room.neighbors[key] = neighbor_pos


static func _assign_boss(rooms: Dictionary) -> void:
	if rooms.size() <= 1:
		return
	var start_pos := Vector2i.ZERO
	var best_pos := start_pos
	var best_dist := -1
	var queue: Array[Vector2i] = [start_pos]
	var dist: Dictionary = {start_pos: 0}
	while not queue.is_empty():
		var cur: Vector2i = queue.pop_front()
		var room: RoomData = rooms[cur]
		for neighbor_pos in room.neighbors.values():
			if dist.has(neighbor_pos):
				continue
			var d: int = int(dist[cur]) + 1
			dist[neighbor_pos] = d
			queue.append(neighbor_pos)
			if d > best_dist:
				best_dist = d
				best_pos = neighbor_pos
	if best_pos != start_pos and rooms.has(best_pos):
		(rooms[best_pos] as RoomData).room_type = RoomData.RoomType.BOSS


static func _assign_reward_types(rooms: Dictionary, seed_value: int) -> void:
	var types: Array[int] = [
		RoomData.RewardType.WEAPON,
		RoomData.RewardType.ARMOR,
		RoomData.RewardType.RUNE,
		RoomData.RewardType.GEM,
	]
	for pos in rooms.keys():
		var room: RoomData = rooms[pos]
		if room.room_type == RoomData.RoomType.START:
			room.reward_type = RoomData.RewardType.NONE
			continue
		var h: int = hash([seed_value, pos.x, pos.y, "reward"])
		room.reward_type = types[posmod(h, types.size())] as RoomData.RewardType
