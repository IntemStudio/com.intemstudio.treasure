class_name CombatStats
extends Resource

@export var damage_min: int = 8
@export var damage_max: int = 12
@export var max_hp: int = 64
@export var magic_hp: int = 0
@export var defense: float = 0.0
@export var vampirism: float = 0.0
@export var attack_speed: float = 0.0
@export var evasion: float = 0.0
@export var crit_chance: float = 0.0
@export var crit_damage: float = 1.4
@export var counter_chance: float = 0.0
@export var regen_per_sec: float = 0.0
@export var retaliation: float = 0.0
@export var magic_damage: float = 0.0
@export var damage_all: float = 0.0


func duplicate_stats() -> CombatStats:
	return duplicate(true) as CombatStats
