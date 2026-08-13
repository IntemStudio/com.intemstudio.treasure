class_name EncounterDirector
extends Node

signal combat_started
signal combat_finished(result: String)

const RULES_PATH := "res://data/combat/combat_rules.tres"
const NORMAL_ENCOUNTER_PATH := "res://data/combat/encounters/normal_slimes.tres"
const BOSS_ENCOUNTER_PATH := "res://data/combat/encounters/boss_brute.tres"

var session: CombatSession
var arena: CombatArena
var hud: CombatHud
var ui_manager: UIManager
var floor_map: FloorMap
var room_host: RoomHost

var _rules: CombatRules
var _normal_encounter: EncounterDef
var _boss_encounter: EncounterDef
var _active_room: RoomData
var _force_encounter: EncounterDef


func setup(
	p_ui_manager: UIManager,
	p_floor_map: FloorMap,
	p_room_host: RoomHost,
	p_session: CombatSession,
	p_arena: CombatArena,
	p_hud: CombatHud
) -> void:
	ui_manager = p_ui_manager
	floor_map = p_floor_map
	room_host = p_room_host
	session = p_session
	arena = p_arena
	hud = p_hud
	_rules = load(RULES_PATH) as CombatRules
	if _rules == null:
		_rules = CombatRules.new()
	_normal_encounter = load(NORMAL_ENCOUNTER_PATH) as EncounterDef
	_boss_encounter = load(BOSS_ENCOUNTER_PATH) as EncounterDef
	if session:
		session.setup(_rules)
		if not session.combat_ended.is_connected(_on_combat_ended):
			session.combat_ended.connect(_on_combat_ended)
		if arena:
			arena.bind_session(session)
		if hud:
			hud.bind_session(session)
			hud.set_retreat_callback(Callable(self, "request_retreat"))


func is_active() -> bool:
	return session != null and session.active


func on_room_entered(room: RoomData) -> void:
	if room == null:
		return
	if is_active():
		return
	if room.room_type == RoomData.RoomType.START or room.cleared:
		return
	start(room)


func start(room: RoomData, override_encounter: EncounterDef = null) -> bool:
	if room == null or session == null or ui_manager == null:
		return false
	if is_active():
		return false
	if room.room_type == RoomData.RoomType.START and override_encounter == null:
		return false

	var enc := override_encounter
	if enc == null:
		enc = _force_encounter
		_force_encounter = null
	if enc == null:
		enc = _pick_encounter(room)
	if enc == null:
		return false

	_active_room = room
	var hero_stats := CombatStatsBuilder.build(ui_manager.character_stats, ui_manager.inventory_data)
	var hero_hp := ui_manager.character_stats.hp if ui_manager.character_stats else hero_stats.max_hp
	var hero_name := ui_manager.character_stats.character_name if ui_manager.character_stats else "Hero"
	session.start(enc, hero_stats, hero_hp, hero_name)
	if ui_manager:
		ui_manager.set_combat_active(true)
	var state := session.get_state()
	var room_node: Node2D = room_host.get_current_room_node() if room_host else null
	if arena:
		arena.start(room_node, state, enc)
	if hud:
		hud.show_combat(state, enc)
	combat_started.emit()
	return true


func _pick_encounter(room: RoomData) -> EncounterDef:
	match room.room_type:
		RoomData.RoomType.BOSS:
			return _boss_encounter
		RoomData.RoomType.NORMAL:
			return _normal_encounter
		_:
			return null


func request_retreat() -> void:
	if session:
		session.request_retreat()


func force_encounter_next(enc: EncounterDef = null) -> void:
	_force_encounter = enc if enc else _normal_encounter


func force_start_current() -> bool:
	if floor_map == null:
		return false
	var room := floor_map.get_room(floor_map.get_current())
	if room == null:
		return false
	return start(room, _normal_encounter)


func force_result(result: String) -> void:
	if session:
		session.force_result(result)


func _on_combat_ended(result: String) -> void:
	var pending_xp := session.pending_xp if session else 0
	var hero_hp := session.get_hero_hp() if session else 0
	var snapshot := session.snapshot_hero_hp if session else 0

	if arena:
		arena.clear(true)
	if hud:
		hud.hide_combat()
	if ui_manager:
		ui_manager.set_combat_active(false)

	match result:
		CombatSession.RESULT_WIN:
			_apply_win(pending_xp, hero_hp)
		CombatSession.RESULT_LOSE:
			_apply_lose()
		CombatSession.RESULT_RETREAT:
			_apply_retreat(snapshot)

	_active_room = null
	combat_finished.emit(result)


func _apply_win(pending_xp: int, hero_hp: int) -> void:
	if _active_room:
		_active_room.cleared = true
	if ui_manager and ui_manager.character_stats:
		ui_manager.character_stats.hp = clampi(
			hero_hp, 1, ui_manager.character_stats.hp_max
		)
		if pending_xp > 0:
			ui_manager.character_stats.add_xp(pending_xp)
		ui_manager.refresh_character_views()


func _apply_lose() -> void:
	if ui_manager:
		ui_manager.return_to_title()


func _apply_retreat(snapshot_hp: int) -> void:
	if ui_manager and ui_manager.character_stats:
		ui_manager.character_stats.hp = clampi(
			snapshot_hp, 1, ui_manager.character_stats.hp_max
		)
		ui_manager.refresh_character_views()
	if room_host:
		room_host.enter_room(Vector2i.ZERO)
