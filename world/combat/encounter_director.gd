class_name EncounterDirector
extends Node

signal combat_started
signal combat_finished(result: String)

const RULES_PATH := "res://data/combat/combat_rules.tres"
const FALLBACK_NORMAL_PATH := "res://data/combat/encounters/normal_slimes.tres"
const FALLBACK_BOSS_PATH := "res://data/combat/encounters/boss_brute.tres"
const RegionEncountersScript := preload("res://data/combat/region_encounters.gd")

var session: CombatSession
var arena: CombatArena
var hud: CombatHud
var ui_manager: UIManager
var floor_map: FloorMap
var room_host: RoomHost
var dungeon_id: String = "cemetery"
var zone_id: String = "graves"

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
	p_hud: CombatHud,
	p_dungeon_id: String = "",
	p_zone_id: String = ""
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
	set_run(p_dungeon_id, p_zone_id)
	if session:
		session.setup(_rules)
		if not session.combat_ended.is_connected(_on_combat_ended):
			session.combat_ended.connect(_on_combat_ended)
		if arena:
			arena.bind_session(session)
		if hud:
			hud.bind_session(session)
			hud.set_retreat_callback(Callable(self, "request_retreat"))


func set_run(p_dungeon_id: String, p_zone_id: String = "") -> void:
	dungeon_id = RegionEncountersScript.normalize_region(p_dungeon_id)
	zone_id = RegionEncountersScript.normalize_zone(dungeon_id, p_zone_id)
	var pair: Dictionary = RegionEncountersScript.load_pair(dungeon_id, zone_id)
	_normal_encounter = pair.get("normal") as EncounterDef
	_boss_encounter = pair.get("boss") as EncounterDef
	if _normal_encounter == null:
		_normal_encounter = load(FALLBACK_NORMAL_PATH) as EncounterDef
	if _boss_encounter == null:
		_boss_encounter = load(FALLBACK_BOSS_PATH) as EncounterDef


func set_dungeon_id(p_dungeon_id: String) -> void:
	set_run(p_dungeon_id, zone_id)


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
	var hero_name := tr("Hero")
	var hero_mana := ui_manager.character_stats.mana if ui_manager.character_stats else 0
	var hero_mana_max := ui_manager.character_stats.mana_max if ui_manager.character_stats else 0
	var hero_skills: Array = _collect_hero_skills()
	session.start(enc, hero_stats, hero_hp, hero_name, hero_skills, hero_mana, hero_mana_max)
	if ui_manager:
		ui_manager.set_combat_active(true)
		if ui_manager.has_method("bind_skill_gauge"):
			ui_manager.bind_skill_gauge(session)
	var state := session.get_state()
	var room_node: Node2D = room_host.get_current_room_node() if room_host else null
	if arena:
		arena.start(room_node, state, enc)
	if hud:
		hud.show_combat(state, enc)
	combat_started.emit()
	return true


func _collect_hero_skills() -> Array:
	if ui_manager == null or ui_manager.inventory_data == null:
		return []
	var service := ResonanceService.new()
	return service.list_equipped_rune_skills(
		ui_manager.inventory_data,
		RuneCatalog.new(),
		GemCatalog.new()
	)


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
	var hero_mana := session.get_hero_mana() if session else 0
	var snapshot := session.snapshot_hero_hp if session else 0
	var snapshot_mana := session.snapshot_hero_mana if session else 0

	if arena:
		arena.clear(true)
	if hud:
		hud.hide_combat()
	if ui_manager:
		ui_manager.set_combat_active(false)
		if ui_manager.has_method("unbind_skill_gauge"):
			ui_manager.unbind_skill_gauge()

	match result:
		CombatSession.RESULT_WIN:
			_apply_win(pending_xp, hero_hp, hero_mana)
		CombatSession.RESULT_LOSE:
			_apply_lose()
		CombatSession.RESULT_RETREAT:
			_apply_retreat(snapshot, snapshot_mana)

	_active_room = null
	combat_finished.emit(result)


func _apply_win(pending_xp: int, hero_hp: int, hero_mana: int) -> void:
	var room := _active_room
	var was_boss := room != null and room.room_type == RoomData.RoomType.BOSS
	if room:
		room.cleared = true
	if ui_manager and ui_manager.character_stats:
		ui_manager.character_stats.hp = clampi(
			hero_hp, 1, ui_manager.character_stats.hp_max
		)
		ui_manager.character_stats.mana = clampi(
			hero_mana, 0, ui_manager.character_stats.mana_max
		)
		if pending_xp > 0:
			ui_manager.character_stats.add_xp(pending_xp)
	if ui_manager:
		ui_manager.refresh_character_views()
	_begin_loot_choice(room, was_boss)


func _begin_loot_choice(room: RoomData, was_boss: bool) -> void:
	if was_boss and dungeon_id == ChallengeDef.DUNGEON_ALTAR:
		_begin_altar_ending()
		return
	if ui_manager == null or ui_manager.inventory_data == null or room == null:
		if was_boss and ui_manager:
			_finish_zone_boss()
		return
	if room.reward_type == RoomData.RewardType.NONE:
		if was_boss:
			_finish_zone_boss()
		return
	var seed_value := 0
	if floor_map:
		seed_value = floor_map.seed_value
	var catalog := ItemCatalog.new()
	var rune_catalog := RuneCatalog.new()
	var gem_catalog := GemCatalog.new()
	var offers: Array[Dictionary] = LootService.roll_offers(
		room.reward_type,
		catalog,
		rune_catalog,
		gem_catalog,
		{
			"seed": seed_value,
			"cell": room.grid_pos,
			"card_meta": SaveManager.get_card_meta(),
		}
	)
	if offers.is_empty():
		if was_boss:
			_finish_zone_boss()
		return
	ui_manager.show_loot_choice(
		offers,
		room.reward_type,
		func(offer: Dictionary) -> void:
			_finish_loot_choice(offer, was_boss)
	)


func _finish_loot_choice(offer: Dictionary, was_boss: bool) -> void:
	if ui_manager == null:
		return
	if offer.is_empty():
		if was_boss:
			_finish_zone_boss()
		return
	var result: Dictionary = LootService.take_offer(ui_manager.inventory_data, offer)
	if bool(result.get("ok", false)):
		_push_loot_choice_log(result)
		if ui_manager.has_method("show_loot_toast"):
			ui_manager.show_loot_toast({
				"granted": result.get("granted", []),
				"skipped": 0,
				"granted_name": str(result.get("granted_name", "")),
			})
	elif int(result.get("skipped", 0)) > 0:
		_push_loot_log({"granted": [], "skipped": 1})
		if ui_manager.has_method("show_loot_toast"):
			ui_manager.show_loot_toast({"granted": [], "skipped": 1})
	ui_manager.refresh_character_views()
	if was_boss:
		_finish_zone_boss()


func _finish_zone_boss() -> void:
	if ui_manager == null:
		return
	var meta := SaveManager.get_card_meta()
	meta = BasinProgress.unlock_next(meta, dungeon_id, zone_id)
	SaveManager.set_card_meta(meta)
	ui_manager.return_to_village()


func _begin_altar_ending() -> void:
	if ui_manager == null or ui_manager.inventory_data == null:
		if ui_manager:
			ui_manager.return_to_village()
		return
	var offer := LootService.rune_offer(BasinProgress.LAST_VERSE_RUNE_ID)
	var result: Dictionary = LootService.take_offer(ui_manager.inventory_data, offer)
	if not bool(result.get("ok", false)):
		_push_loot_log({"granted": [], "skipped": 1})
		ui_manager.return_to_village()
		return
	_push_loot_choice_log(result)
	ui_manager.refresh_character_views()
	var meta := SaveManager.get_card_meta()
	var allow_seal := not CardRegistrationService.is_id_registered(
		meta, "rune", BasinProgress.LAST_VERSE_RUNE_ID
	)
	var allow_empty := BasinProgress.can_empty(meta, zone_id)
	ui_manager.show_ending_choice(
		allow_seal,
		allow_empty,
		func(ending_id: String) -> void:
			_apply_altar_ending(ending_id)
	)


func _apply_altar_ending(ending_id: String) -> void:
	if ui_manager == null:
		return
	var meta := SaveManager.get_card_meta()
	if ending_id == BasinProgress.ENDING_SEAL:
		var uid := CardRegistrationService.first_owned_uid(
			ui_manager.inventory_data, "rune", BasinProgress.LAST_VERSE_RUNE_ID
		)
		var sealed: Dictionary = CardRegistrationService.register(
			ui_manager.inventory_data, meta, "rune", uid
		)
		if bool(sealed.get("ok", false)):
			meta = sealed.get("meta", meta) as Dictionary
		else:
			ending_id = BasinProgress.ENDING_TAKE
	meta = BasinProgress.apply_ending(meta, ending_id)
	if zone_id == ChallengeDef.ZONE_MOUTH_DEEP:
		meta = BasinProgress.mark_altar_deep_cleared(meta)
	SaveManager.set_card_meta(meta)
	var kind := "ending.take"
	match ending_id:
		BasinProgress.ENDING_SEAL:
			kind = "ending.seal"
		BasinProgress.ENDING_EMPTY:
			kind = "ending.empty"
		_:
			kind = "ending.take"
	ui_manager.push_log({"category": "story", "kind": kind})
	ui_manager.refresh_character_views()
	ui_manager.return_to_village()


func _push_loot_choice_log(result: Dictionary) -> void:
	if ui_manager == null:
		return
	var name := str(result.get("granted_name", "")).strip_edges()
	var granted: Array = result.get("granted", []) as Array
	if name.is_empty() and not granted.is_empty():
		var first = granted[0]
		if first is ItemData:
			name = (first as ItemData).display_name
	if name.is_empty():
		return
	ui_manager.push_log({
		"category": "loot",
		"kind": "loot.grant",
		"actor_name": name,
	})


func _grant_loot() -> void:
	# Kept for compatibility; win path uses loot choice overlay.
	pass


func _push_loot_log(result: Dictionary) -> void:
	if ui_manager == null:
		return
	var granted: Array = result.get("granted", [])
	if not granted.is_empty():
		var names: PackedStringArray = PackedStringArray()
		for item in granted:
			if item is ItemData:
				var data := item as ItemData
				var n := data.display_name if not data.display_name.is_empty() else data.id
				names.append(n)
		ui_manager.push_log({
			"category": "loot",
			"kind": "loot.grant",
			"actor_name": ", ".join(names),
		})
	var skipped := int(result.get("skipped", 0))
	if skipped > 0:
		ui_manager.push_log({
			"category": "loot",
			"kind": "loot.skip",
			"amount": skipped,
		})


func _apply_lose() -> void:
	if ui_manager:
		ui_manager.return_to_village()


func _apply_retreat(snapshot_hp: int, snapshot_mana: int) -> void:
	if ui_manager and ui_manager.character_stats:
		ui_manager.character_stats.hp = clampi(
			snapshot_hp, 1, ui_manager.character_stats.hp_max
		)
		ui_manager.character_stats.mana = clampi(
			snapshot_mana, 0, ui_manager.character_stats.mana_max
		)
		ui_manager.refresh_character_views()
	if room_host:
		room_host.enter_room(Vector2i.ZERO)
