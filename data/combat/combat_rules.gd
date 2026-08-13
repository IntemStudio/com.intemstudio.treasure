class_name CombatRules
extends Resource

@export var tick_hz: float = 60.0
@export var speed_steps: Array[float] = [1.0, 2.0, 3.0]
@export var default_speed_index: int = 0

## Fighter base: 90 frames at 60 Hz = 1.5s between attacks.
@export var base_attack_interval_sec: float = 1.5
@export var atb_full: float = 1.0

## Separate skill gauge (hero only). Full ~ every skill_interval_sec at 1.0 fill rate.
@export var skill_interval_sec: float = 4.0
@export var skill_atb_full: float = 1.0
@export var strike_damage_mult: float = 1.6

@export var stamina_max: float = 100.0
@export var stamina_regen_per_sec: float = 15.0
@export var stamina_cost_attack: float = 25.0
@export var stamina_cost_counter: float = 25.0
@export var stamina_cost_evade: float = 10.0
@export var stamina_gain_on_hit: float = 10.0
@export var tired_duration_sec: float = 6.0
@export var tired_evasion_mult: float = 0.5

@export var min_damage: int = 1
@export var damage_round: bool = true
@export var def_flat_breakpoint_offset: float = 0.5
@export var def_curve_a: float = 20.3125
@export var def_curve_b: float = 18.75
@export var def_curve_c: float = 1.0 / 12.0

@export var magic_hp_refills_each_fight: bool = true
@export var magic_hp_before_hp: bool = true

## sticky: keep current living focus until it dies. random_living: re-roll every attack.
@export var target_mode: String = "sticky"
@export var counter_resets_atb: bool = true
@export var counter_can_trigger_on_evade: bool = true
@export var counter_can_be_countered: bool = true

@export var retreat_allowed: bool = true


func attacks_per_sec(ias: float) -> float:
	if base_attack_interval_sec <= 0.0:
		return 0.0
	return (1.0 / base_attack_interval_sec) * (1.0 + ias)


func apply_defense(atk: float, defense: float, ignore_defense: bool = false) -> float:
	if ignore_defense:
		return atk
	if defense < 0.5 * atk - def_flat_breakpoint_offset:
		return atk - defense
	var half := atk * 0.5
	var denom := def_curve_b + defense - half
	if denom <= 0.0:
		return float(min_damage)
	return half * (def_curve_a / denom - def_curve_c)


func finalize_damage(raw: float) -> int:
	var value := roundf(raw) if damage_round else raw
	return maxi(min_damage, int(value))
