class_name CombatSession
extends Node

signal combat_ended(result: String)
signal state_changed
signal unit_hit(unit_id: String, amount: int)

const RESULT_WIN := "win"
const RESULT_LOSE := "lose"
const RESULT_RETREAT := "retreat"

var rules: CombatRules
var encounter: EncounterDef
var combatants: Array[Dictionary] = []
var active: bool = false
var can_retreat: bool = true
var snapshot_hero_hp: int = 0
var pending_xp: int = 0
var speed_index: int = 0
var _ended: bool = false
var _counter_depth: int = 0


func setup(p_rules: CombatRules) -> void:
	rules = p_rules if p_rules else CombatRules.new()
	speed_index = rules.default_speed_index


func start(
	p_encounter: EncounterDef,
	hero_stats: CombatStats,
	hero_hp: int,
	hero_name: String = "Hero"
) -> void:
	encounter = p_encounter
	combatants.clear()
	pending_xp = 0
	_ended = false
	active = true
	_counter_depth = 0
	can_retreat = encounter.can_retreat if encounter else true
	snapshot_hero_hp = hero_hp

	var hero := _make_combatant(
		"hero",
		hero_name,
		CombatUnitDef.UnitSide.ALLY,
		hero_stats.duplicate_stats() if hero_stats else CombatStats.new(),
		hero_hp,
		0,
		Color(0.85, 0.75, 0.35, 1),
		false
	)
	hero["is_hero"] = true
	combatants.append(hero)

	if encounter:
		var idx := 0
		for def in encounter.enemies:
			if def == null:
				continue
			var scaled := def.scaled_stats(encounter.enemy_level)
			var unit := _make_combatant(
				"%s_%d" % [def.id, idx],
				def.display_name if not def.display_name.is_empty() else def.id,
				CombatUnitDef.UnitSide.ENEMY,
				scaled,
				scaled.max_hp,
				def.xp_reward,
				def.body_color,
				def.face_left
			)
			unit["target_priority"] = def.target_priority
			combatants.append(unit)
			idx += 1

	state_changed.emit()


func _make_combatant(
	id: String,
	display_name: String,
	side: CombatUnitDef.UnitSide,
	stats: CombatStats,
	hp: int,
	xp_reward: int,
	body_color: Color,
	face_left: bool
) -> Dictionary:
	var max_hp := stats.max_hp if stats else 1
	var stamina_max := stats.stamina_max if stats else rules.stamina_max
	var magic_hp := 0
	if stats and rules and rules.magic_hp_refills_each_fight:
		magic_hp = maxi(0, stats.magic_hp)
	elif stats:
		magic_hp = maxi(0, stats.magic_hp)
	return {
		"id": id,
		"display_name": display_name,
		"side": side,
		"stats": stats,
		"hp": clampi(hp, 0, max_hp),
		"max_hp": max_hp,
		"magic_hp": magic_hp,
		"atb": 0.0,
		"alive": hp > 0,
		"xp_reward": xp_reward,
		"body_color": body_color,
		"face_left": face_left,
		"is_hero": false,
		"target_priority": 0,
		"stamina": stamina_max,
		"stamina_max": stamina_max,
		"tired_t": 0.0,
		"regen_accum": 0.0,
	}


func _process(delta: float) -> void:
	if not active or _ended:
		return
	tick(delta)


func tick(dt: float) -> void:
	if not active or _ended or rules == null:
		return
	dt *= get_speed_mult()
	for unit in combatants:
		if not unit["alive"]:
			continue
		_tick_resources(unit, dt)
		var stats: CombatStats = unit["stats"]
		var ias := 0.0
		if stats and float(unit.get("tired_t", 0.0)) <= 0.0:
			ias = stats.attack_speed
		var aps := rules.attacks_per_sec(ias)
		unit["atb"] = float(unit["atb"]) + aps * dt
		while float(unit["atb"]) >= rules.atb_full and unit["alive"] and not _ended:
			unit["atb"] = float(unit["atb"]) - rules.atb_full
			_try_attack(unit)
	state_changed.emit()
	_check_end()


func _tick_resources(unit: Dictionary, dt: float) -> void:
	var stats: CombatStats = unit["stats"]
	if stats == null:
		return
	var tired_t := float(unit.get("tired_t", 0.0))
	if tired_t > 0.0:
		unit["tired_t"] = maxf(0.0, tired_t - dt)

	var stam_max := float(unit.get("stamina_max", rules.stamina_max))
	var regen := stats.stamina_regen if stats.stamina_regen > 0.0 else rules.stamina_regen_per_sec
	unit["stamina"] = minf(stam_max, float(unit.get("stamina", stam_max)) + regen * dt)

	if stats.regen_per_sec > 0.0 and int(unit["hp"]) < int(unit["max_hp"]):
		unit["regen_accum"] = float(unit.get("regen_accum", 0.0)) + stats.regen_per_sec * dt
		var heal := int(floor(float(unit["regen_accum"])))
		if heal > 0:
			unit["regen_accum"] = float(unit["regen_accum"]) - float(heal)
			unit["hp"] = mini(int(unit["max_hp"]), int(unit["hp"]) + heal)


func get_speed_mult() -> float:
	if rules == null or rules.speed_steps.is_empty():
		return 1.0
	var idx := clampi(speed_index, 0, rules.speed_steps.size() - 1)
	return float(rules.speed_steps[idx])


func cycle_speed() -> float:
	if rules == null or rules.speed_steps.is_empty():
		speed_index = 0
		return 1.0
	speed_index = (speed_index + 1) % rules.speed_steps.size()
	state_changed.emit()
	return get_speed_mult()


func _try_attack(attacker: Dictionary) -> void:
	var target := _pick_target(attacker)
	if target.is_empty():
		return
	_spend_stamina(attacker, rules.stamina_cost_attack)
	_resolve_hit(attacker, target, false)


func _pick_target(attacker: Dictionary) -> Dictionary:
	var enemy_side: CombatUnitDef.UnitSide = (
		CombatUnitDef.UnitSide.ENEMY
		if attacker["side"] == CombatUnitDef.UnitSide.ALLY
		else CombatUnitDef.UnitSide.ALLY
	)
	var candidates: Array[Dictionary] = []
	var best_priority := 999999
	for unit in combatants:
		if not unit["alive"] or unit["side"] != enemy_side:
			continue
		var prio := int(unit.get("target_priority", 0))
		if prio < best_priority:
			best_priority = prio
			candidates.clear()
			candidates.append(unit)
		elif prio == best_priority:
			candidates.append(unit)
	if candidates.is_empty():
		return {}
	return candidates[randi() % candidates.size()]


func _resolve_hit(attacker: Dictionary, defender: Dictionary, is_counter: bool) -> void:
	var atk_stats: CombatStats = attacker["stats"]
	var def_stats: CombatStats = defender["stats"]
	if atk_stats == null or not defender["alive"] or _ended:
		return

	var evaded := _roll_evasion(defender)
	if evaded:
		_spend_stamina(defender, rules.stamina_cost_evade)
		# amount 0 = miss (arena may skip float)
		unit_hit.emit(str(defender["id"]), 0)
		if not is_counter and rules.counter_can_trigger_on_evade:
			_try_counter(defender, attacker)
		return

	var raw := float(randi_range(atk_stats.damage_min, maxi(atk_stats.damage_min, atk_stats.damage_max)))
	var defense := def_stats.defense if def_stats else 0.0
	var after_def := rules.apply_defense(raw, defense, false)
	if randf() < atk_stats.crit_chance:
		after_def *= atk_stats.crit_damage
	if atk_stats.magic_damage > 0.0:
		after_def += rules.apply_defense(atk_stats.magic_damage, defense, true)
	var dmg := rules.finalize_damage(after_def)
	var dealt := _apply_damage(defender, dmg)
	if dealt > 0:
		_on_landed_hit(attacker, defender, dealt)

	if not is_counter and atk_stats.damage_all > 0.0:
		_apply_damage_all(attacker, defender, atk_stats.damage_all)

	if not is_counter:
		_try_counter(defender, attacker)
	elif rules.counter_can_be_countered:
		_try_counter(defender, attacker)


func _apply_damage_all(attacker: Dictionary, primary: Dictionary, amount: float) -> void:
	var atk_stats: CombatStats = attacker["stats"]
	if atk_stats == null:
		return
	for unit in combatants:
		if not unit["alive"] or unit == primary:
			continue
		if unit["side"] == attacker["side"]:
			continue
		if _roll_evasion(unit):
			continue
		var def_stats: CombatStats = unit["stats"]
		var defense := def_stats.defense if def_stats else 0.0
		var after := rules.apply_defense(amount, defense, false)
		var dmg := rules.finalize_damage(after)
		var dealt := _apply_damage(unit, dmg)
		if dealt > 0 and atk_stats.vampirism > 0.0:
			_heal(attacker, int(floor(float(dealt) * atk_stats.vampirism)))


func _roll_evasion(defender: Dictionary) -> bool:
	var stats: CombatStats = defender["stats"]
	if stats == null:
		return false
	var chance := stats.evasion
	if float(defender.get("tired_t", 0.0)) > 0.0:
		chance *= rules.tired_evasion_mult
	return randf() < chance


func _on_landed_hit(attacker: Dictionary, defender: Dictionary, dealt: int) -> void:
	var atk_stats: CombatStats = attacker["stats"]
	var def_stats: CombatStats = defender["stats"]
	if atk_stats and atk_stats.vampirism > 0.0 and dealt > 0:
		_heal(attacker, int(floor(float(dealt) * atk_stats.vampirism)))
	if def_stats and def_stats.retaliation > 0.0 and attacker["alive"]:
		var after := rules.apply_defense(def_stats.retaliation, atk_stats.defense if atk_stats else 0.0, false)
		_apply_damage(attacker, rules.finalize_damage(after))
	_gain_stamina_on_hit(defender)


func _try_counter(defender: Dictionary, attacker: Dictionary) -> void:
	if _ended:
		return
	if not defender["alive"] or not attacker["alive"]:
		return
	if _counter_depth > 0 and not rules.counter_can_be_countered:
		return
	if _counter_depth >= 2:
		return
	var def_stats: CombatStats = defender["stats"]
	if def_stats == null or def_stats.counter_chance <= 0.0:
		return
	if randf() >= def_stats.counter_chance:
		return
	_spend_stamina(defender, rules.stamina_cost_counter)
	if rules.counter_resets_atb:
		defender["atb"] = 0.0
	_counter_depth += 1
	_resolve_hit(defender, attacker, true)
	_counter_depth -= 1


func _apply_damage(unit: Dictionary, amount: int) -> int:
	if not unit["alive"] or amount <= 0:
		return 0
	var remaining := amount
	var absorbed := 0
	if rules and rules.magic_hp_before_hp:
		var shield := int(unit.get("magic_hp", 0))
		if shield > 0:
			absorbed = mini(shield, remaining)
			unit["magic_hp"] = shield - absorbed
			remaining -= absorbed
	if remaining > 0:
		unit["hp"] = maxi(0, int(unit["hp"]) - remaining)
	unit_hit.emit(str(unit["id"]), amount)
	if int(unit["hp"]) <= 0:
		unit["alive"] = false
		unit["atb"] = 0.0
		unit["hp"] = 0
		if unit["side"] == CombatUnitDef.UnitSide.ENEMY:
			pending_xp += int(unit.get("xp_reward", 0))
	return amount


func _heal(unit: Dictionary, amount: int) -> void:
	if not unit["alive"] or amount <= 0:
		return
	unit["hp"] = mini(int(unit["max_hp"]), int(unit["hp"]) + amount)


func _spend_stamina(unit: Dictionary, cost: float) -> bool:
	var stam := float(unit.get("stamina", 0.0))
	# Always attempt the action; depleting stamina applies Tired.
	unit["stamina"] = maxf(0.0, stam - cost)
	if float(unit["stamina"]) <= 0.0:
		unit["tired_t"] = rules.tired_duration_sec
	return true


func _gain_stamina_on_hit(unit: Dictionary) -> void:
	var stam_max := float(unit.get("stamina_max", rules.stamina_max))
	unit["stamina"] = minf(stam_max, float(unit.get("stamina", 0.0)) + rules.stamina_gain_on_hit)


func _check_end() -> void:
	if _ended:
		return
	var hero_alive := false
	var enemy_alive := false
	for unit in combatants:
		if not unit["alive"]:
			continue
		if unit["side"] == CombatUnitDef.UnitSide.ALLY:
			hero_alive = true
		else:
			enemy_alive = true
	if not hero_alive:
		_finish(RESULT_LOSE)
	elif not enemy_alive:
		_finish(RESULT_WIN)


func request_retreat() -> bool:
	if not active or _ended or not can_retreat:
		return false
	_finish(RESULT_RETREAT)
	return true


func force_result(result: String) -> void:
	if not active or _ended:
		return
	if result == RESULT_WIN or result == RESULT_LOSE or result == RESULT_RETREAT:
		_finish(result)


func _finish(result: String) -> void:
	if _ended:
		return
	_ended = true
	active = false
	state_changed.emit()
	combat_ended.emit(result)


func get_hero() -> Dictionary:
	for unit in combatants:
		if unit.get("is_hero", false):
			return unit
	return {}


func get_hero_hp() -> int:
	var hero := get_hero()
	if hero.is_empty():
		return 0
	return int(hero["hp"])


func get_state() -> Dictionary:
	var units: Array = []
	for unit in combatants:
		units.append({
			"id": unit["id"],
			"display_name": unit["display_name"],
			"side": unit["side"],
			"hp": unit["hp"],
			"max_hp": unit["max_hp"],
			"magic_hp": unit.get("magic_hp", 0),
			"atb": unit["atb"],
			"alive": unit["alive"],
			"body_color": unit["body_color"],
			"face_left": unit["face_left"],
			"is_hero": unit.get("is_hero", false),
			"stamina": unit.get("stamina", 0.0),
			"tired": float(unit.get("tired_t", 0.0)) > 0.0,
		})
	return {
		"active": active,
		"can_retreat": can_retreat,
		"pending_xp": pending_xp,
		"units": units,
		"enemy_level": encounter.enemy_level if encounter else 1,
		"round_index": encounter.round_index if encounter else 1,
		"speed_mult": get_speed_mult(),
		"speed_index": speed_index,
	}
