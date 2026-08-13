class_name CombatStatsBuilder
extends RefCounted

const WEAPON_RANGE_RATIO := 0.85
const ATTR_BASE := 10
const SCALE_PER_OVER := 1.0

const OVER_IAS := 0.01
const OVER_EVASION := 0.005
const OVER_CRIT_CHANCE := 0.005
const OVER_COUNTER := 0.005
const OVER_VAMPIRISM := 0.005
const OVER_REGEN := 0.1
const OVER_MAGIC_HP := 1.0
const OVER_MAGIC_DAMAGE := 0.5
const OVER_RETALIATION := 0.3
const OVER_DEFENSE := 1.0
const BASE_CRIT_DAMAGE := 1.4

const AFFIX_FIELDS: Array[String] = [
	"attack_speed",
	"evasion",
	"crit_chance",
	"crit_damage",
	"counter_chance",
	"vampirism",
	"regen_per_sec",
	"magic_hp",
	"magic_damage",
	"damage_all",
	"retaliation",
	"defense",
]


static func build(character: CharacterStats, inventory: InventoryData = null) -> CombatStats:
	var out := CombatStats.new()
	if character == null:
		return out

	character.recalculate_derived()

	var over_str := _over(character, "strength")
	var over_dex := _over(character, "dexterity")
	var over_int := _over(character, "intelligence")
	var over_faith := _over(character, "faith")

	out.max_hp = character.hp_max
	out.stamina_max = float(character.general.get("stamina", 100))
	out.stamina_regen = float(character.general.get("stamina_regen", 15.0))
	out.crit_damage = BASE_CRIT_DAMAGE

	out.attack_speed = over_dex * OVER_IAS
	out.evasion = over_dex * OVER_EVASION
	out.crit_chance = over_dex * OVER_CRIT_CHANCE
	out.counter_chance = over_dex * OVER_COUNTER
	out.vampirism = over_faith * OVER_VAMPIRISM
	out.regen_per_sec = over_faith * OVER_REGEN
	out.magic_hp = int(round(over_faith * OVER_MAGIC_HP))
	out.magic_damage = over_int * OVER_MAGIC_DAMAGE
	out.damage_all = 0.0
	out.retaliation = over_str * OVER_RETALIATION
	out.defense = over_str * OVER_DEFENSE

	var damage_total := 1
	if inventory != null:
		_apply_equipped(out, inventory)
		damage_total = _weapon_damage_from_inventory(character, inventory)
		_sync_character_from_inventory(character, inventory, out)
	else:
		damage_total = _weapon_total_fallback(character)
		character.defense["defense"] = out.defense

	if damage_total <= 0:
		out.damage_min = 1
		out.damage_max = 1
	else:
		out.damage_min = maxi(1, int(round(float(damage_total) * WEAPON_RANGE_RATIO)))
		out.damage_max = maxi(out.damage_min, damage_total)

	_clamp_rates(out)
	return out


static func _over(character: CharacterStats, attr_id: String) -> float:
	return maxf(0.0, float(character.attributes.get(attr_id, ATTR_BASE)) - float(ATTR_BASE))


static func _apply_equipped(out: CombatStats, inventory: InventoryData) -> void:
	for slot_id in InventoryData.EQUIP_SLOTS:
		var item: ItemData = inventory.equipped.get(slot_id) as ItemData
		if item == null:
			continue
		if item.category == ItemData.ItemCategory.ARMOR or item.equip_slot in ["head", "chest", "legs"]:
			out.defense += float(item.defense) + float(item.defense_bonus)
		_apply_affixes(out, item.affixes)


static func _apply_affixes(out: CombatStats, affixes: Array) -> void:
	for entry in affixes:
		if not entry is Dictionary:
			continue
		var d: Dictionary = entry
		var id := str(d.get("id", ""))
		if id.is_empty() or not AFFIX_FIELDS.has(id):
			continue
		var value := float(d.get("value", 0.0))
		match id:
			"magic_hp":
				out.magic_hp += int(round(value))
			"crit_damage":
				out.crit_damage += value
			"defense":
				out.defense += value
			"attack_speed":
				out.attack_speed += value
			"evasion":
				out.evasion += value
			"crit_chance":
				out.crit_chance += value
			"counter_chance":
				out.counter_chance += value
			"vampirism":
				out.vampirism += value
			"regen_per_sec":
				out.regen_per_sec += value
			"magic_damage":
				out.magic_damage += value
			"damage_all":
				out.damage_all += value
			"retaliation":
				out.retaliation += value


static func _weapon_damage_from_inventory(character: CharacterStats, inventory: InventoryData) -> int:
	var main: ItemData = inventory.equipped.get("main_hand") as ItemData
	if main == null:
		return 1
	var base := main.attack + main.attack_bonus
	var scale_attr := main.scales_with
	if scale_attr.is_empty():
		scale_attr = main.required_stat
	var over := _over(character, scale_attr) if not scale_attr.is_empty() else 0.0
	return maxi(1, base + int(round(over * SCALE_PER_OVER)))


static func _weapon_total_fallback(character: CharacterStats) -> int:
	if character.weapons.is_empty():
		return 1
	var first: Variant = character.weapons[0]
	if first is Dictionary:
		return maxi(1, int((first as Dictionary).get("total", 1)))
	return 1


static func _sync_character_from_inventory(
	character: CharacterStats,
	inventory: InventoryData,
	combat: CombatStats
) -> void:
	var weight := 0.0
	var weapon_rows: Array[Dictionary] = []
	for slot_id in InventoryData.EQUIP_SLOTS:
		var item: ItemData = inventory.equipped.get(slot_id) as ItemData
		if item == null:
			continue
		weight += item.weight
		if slot_id == "main_hand" or (slot_id == "off_hand" and item.category == ItemData.ItemCategory.WEAPON):
			weapon_rows.append(_weapon_row(character, item))
	character.weight_current = weight
	character.defense["defense"] = combat.defense
	if not weapon_rows.is_empty():
		character.weapons = weapon_rows


static func _weapon_row(character: CharacterStats, item: ItemData) -> Dictionary:
	var scale_attr := item.scales_with
	if scale_attr.is_empty():
		scale_attr = item.required_stat
	var over := _over(character, scale_attr) if not scale_attr.is_empty() else 0.0
	var attr_bonus := int(round(over * SCALE_PER_OVER))
	var base := item.attack
	var other := item.attack_bonus
	return {
		"name": item.display_name,
		"base": base,
		"attr_bonus": attr_bonus,
		"attr_icon": scale_attr,
		"other": other,
		"total": maxi(1, base + attr_bonus + other),
	}


static func _clamp_rates(out: CombatStats) -> void:
	out.evasion = clampf(out.evasion, 0.0, 0.95)
	out.crit_chance = clampf(out.crit_chance, 0.0, 1.0)
	out.counter_chance = clampf(out.counter_chance, 0.0, 1.0)
	out.vampirism = clampf(out.vampirism, 0.0, 1.0)
	out.attack_speed = maxf(0.0, out.attack_speed)
	out.crit_damage = maxf(1.0, out.crit_damage)
	out.defense = maxf(0.0, out.defense)
	out.magic_hp = maxi(0, out.magic_hp)
	out.stamina_max = maxf(1.0, out.stamina_max)
	out.stamina_regen = maxf(0.0, out.stamina_regen)
