class_name CombatArena
extends Node

const ACTOR_SCENE := preload("res://world/combat/combatant_actor.tscn")
const FALLBACK_ALLY := Vector2(-160, 40)
const FALLBACK_ENEMY := Vector2(160, 40)
const FALLBACK_ENEMY_STEP := Vector2(0, 72)

var player: Node2D
var _session: CombatSession
var _room: Node2D
var _actors_host: Node2D
var _actors: Dictionary = {}
var _bound: bool = false


func setup(p_player: Node2D) -> void:
	player = p_player


func bind_session(session: CombatSession) -> void:
	if _session and _bound:
		if _session.state_changed.is_connected(_on_state_changed):
			_session.state_changed.disconnect(_on_state_changed)
		if _session.unit_hit.is_connected(_on_unit_hit):
			_session.unit_hit.disconnect(_on_unit_hit)
		_bound = false
	_session = session
	if _session:
		if not _session.state_changed.is_connected(_on_state_changed):
			_session.state_changed.connect(_on_state_changed)
		if not _session.unit_hit.is_connected(_on_unit_hit):
			_session.unit_hit.connect(_on_unit_hit)
		_bound = true


func start(room_node: Node2D, state: Dictionary, _encounter: EncounterDef = null) -> void:
	clear(false)
	_room = room_node
	if player:
		player.visible = false
	if _room == null:
		return
	_actors_host = Node2D.new()
	_actors_host.name = "CombatActors"
	_actors_host.z_index = 5
	_room.add_child(_actors_host)
	_spawn_from_state(state)


func clear(show_player: bool = true) -> void:
	_clear_actors()
	if _actors_host and is_instance_valid(_actors_host):
		_actors_host.queue_free()
	_actors_host = null
	_room = null
	if show_player and player and is_instance_valid(player):
		player.visible = true


func _spawn_from_state(state: Dictionary) -> void:
	if _actors_host == null:
		return
	var units: Array = state.get("units", [])
	var ally_i := 0
	var enemy_i := 0
	for unit in units:
		var side: int = int(unit.get("side", CombatUnitDef.UnitSide.ENEMY))
		var pos: Vector2
		if side == CombatUnitDef.UnitSide.ALLY:
			pos = _slot_global(true, ally_i)
			ally_i += 1
		else:
			pos = _slot_global(false, enemy_i)
			enemy_i += 1
		var actor: CombatantActor = ACTOR_SCENE.instantiate() as CombatantActor
		_actors_host.add_child(actor)
		actor.global_position = pos
		actor.setup(unit)
		_actors[str(unit.get("id", ""))] = actor


func _slot_global(is_ally: bool, index: int) -> Vector2:
	if _room and _room.has_method("get_ally_slot_global") and is_ally:
		return _room.get_ally_slot_global(index)
	if _room and _room.has_method("get_enemy_slot_global") and not is_ally:
		return _room.get_enemy_slot_global(index)
	var origin := FALLBACK_ALLY if is_ally else FALLBACK_ENEMY
	var step := Vector2(0, 64) if is_ally else FALLBACK_ENEMY_STEP
	var local := origin + step * index
	if _room:
		return _room.to_global(local)
	return local


func _on_state_changed() -> void:
	if _session == null or _actors_host == null:
		return
	_apply_state(_session.get_state())


func _on_unit_hit(unit_id: String, amount: int) -> void:
	if amount <= 0 or not _actors.has(unit_id):
		return
	var actor: CombatantActor = _actors[unit_id]
	if is_instance_valid(actor):
		actor.spawn_damage_float(amount)


func _apply_state(state: Dictionary) -> void:
	var units: Array = state.get("units", [])
	var seen: Dictionary = {}
	for unit in units:
		var id := str(unit.get("id", ""))
		seen[id] = true
		if not _actors.has(id):
			_clear_actors()
			_spawn_from_state(state)
			return
		var actor: CombatantActor = _actors[id]
		if is_instance_valid(actor):
			actor.apply_unit(unit)
	for id in _actors.keys():
		if not seen.has(id):
			var actor: CombatantActor = _actors[id]
			if is_instance_valid(actor):
				actor.queue_free()
			_actors.erase(id)


func _clear_actors() -> void:
	for id in _actors.keys():
		var actor: Node = _actors[id]
		if is_instance_valid(actor):
			actor.queue_free()
	_actors.clear()
