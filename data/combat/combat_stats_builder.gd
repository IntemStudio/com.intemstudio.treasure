class_name CombatStatsBuilder
extends RefCounted

const WEAPON_RANGE_RATIO := 0.85


static func build(character: CharacterStats, _inventory: InventoryData = null) -> CombatStats:
	var out := CombatStats.new()
	if character == null:
		return out

	character.recalculate_derived()
	out.max_hp = character.hp_max
	out.defense = float(character.defense.get("armor", 0))

	var total := _weapon_total(character)
	if total <= 0:
		out.damage_min = 1
		out.damage_max = 1
	else:
		out.damage_min = maxi(1, int(round(float(total) * WEAPON_RANGE_RATIO)))
		out.damage_max = maxi(out.damage_min, total)

	out.attack_speed = 0.0
	out.magic_hp = 0
	return out


static func _weapon_total(character: CharacterStats) -> int:
	if character.weapons.is_empty():
		return 0
	var first: Variant = character.weapons[0]
	if first is Dictionary:
		return int((first as Dictionary).get("total", 0))
	return 0
