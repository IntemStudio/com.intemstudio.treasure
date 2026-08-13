class_name CombatUnitDef
extends Resource

enum UnitSide { ALLY, ENEMY }
enum UnitArchetype { HERO, SUMMON, NORMAL, SWARM, BOSS, OBJECT }

@export var id: String = ""
@export var display_name: String = ""
@export var side: UnitSide = UnitSide.ENEMY
@export var archetype: UnitArchetype = UnitArchetype.NORMAL
@export var sprite: Texture2D
@export var body_color: Color = Color(0.75, 0.35, 0.35, 1)
@export var face_left: bool = false
@export var stats: CombatStats
@export var level: int = 1
@export var xp_reward: int = 0
@export var target_priority: int = 0
@export var bony: float = 0.0
@export var swarm: bool = false


func scaled_stats(enemy_level: int) -> CombatStats:
	var base := stats.duplicate_stats() if stats else CombatStats.new()
	var L := maxi(1, enemy_level)
	var mult := float(L) * (1.0 + 0.01 * float(L - 1))
	base.max_hp = maxi(1, int(round(float(base.max_hp) * mult)))
	base.damage_min = maxi(1, int(round(float(base.damage_min) * mult)))
	base.damage_max = maxi(base.damage_min, int(round(float(base.damage_max) * mult)))
	base.defense = base.defense * mult
	return base
