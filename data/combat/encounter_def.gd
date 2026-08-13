class_name EncounterDef
extends Resource

@export var id: String = ""
@export var enemy_level: int = 1
@export var round_index: int = 1
@export var enemies: Array[CombatUnitDef] = []
@export var can_retreat: bool = true
@export var ally_origin: Vector2 = Vector2(280, 420)
@export var ally_spacing: Vector2 = Vector2(56, 0)
@export var enemy_origin: Vector2 = Vector2(1100, 420)
@export var enemy_spacing: Vector2 = Vector2(-56, 0)
