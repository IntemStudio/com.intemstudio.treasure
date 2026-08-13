class_name LootTable
extends Resource

enum LootKind { EQUIPMENT, RUNE, GEM, CONSUMABLE }

@export var weight_equipment: float = 1.0
@export var weight_rune: float = 0.0
@export var weight_gem: float = 0.0
@export var weight_consumable: float = 0.0

@export var normal_min: int = 1
@export var normal_max: int = 2
@export var boss_min: int = 2
@export var boss_max: int = 3


func pick_kind(rng: RandomNumberGenerator) -> LootKind:
	var weights: Array[float] = [
		weight_equipment,
		weight_rune,
		weight_gem,
		weight_consumable,
	]
	var total := 0.0
	for w in weights:
		total += maxf(0.0, w)
	if total <= 0.0:
		return LootKind.EQUIPMENT
	var roll := rng.randf() * total
	var acc := 0.0
	for i in weights.size():
		acc += maxf(0.0, weights[i])
		if roll <= acc:
			return i as LootKind
	return LootKind.EQUIPMENT


func count_range_for(room_type: int) -> Vector2i:
	if room_type == RoomData.RoomType.BOSS:
		return Vector2i(boss_min, boss_max)
	return Vector2i(normal_min, normal_max)
