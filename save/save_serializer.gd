class_name SaveSerializer
extends RefCounted

const CHARACTER_TEMPLATE_PATH := "res://ui/stats/resources/character_stats.tres"
const SAVE_VERSION := 1


static func to_dict(
	character: CharacterStats,
	inventory: InventoryData,
	meta: Dictionary,
	version: int = SAVE_VERSION
) -> Dictionary:
	return {
		"version": version,
		"meta": meta.duplicate(true),
		"character": _character_to_dict(character),
		"inventory": _inventory_to_dict(inventory),
	}


static func from_dict(data: Dictionary, catalog: ItemCatalog) -> SaveGame:
	var save := SaveGame.new()
	save.version = int(data.get("version", SAVE_VERSION))
	save.meta = (data.get("meta", {}) as Dictionary).duplicate(true)
	save.character = _character_from_dict(data.get("character", {}) as Dictionary)
	save.inventory = _inventory_from_dict(data.get("inventory", {}) as Dictionary, catalog)
	return save


static func item_to_dict(item: ItemData) -> Dictionary:
	if item == null:
		return {}
	var d := {
		"id": item.id,
		"quantity": item.quantity,
	}
	if item.durability != item.durability_max:
		d["durability"] = item.durability
	if item.durability_max != 100:
		d["durability_max"] = item.durability_max
	if not item.affixes.is_empty():
		d["affixes"] = item.affixes.duplicate(true)
	if item.attack_bonus != 0:
		d["attack_bonus"] = item.attack_bonus
	if item.defense_bonus != 0:
		d["defense_bonus"] = item.defense_bonus
	if not item.socketed.is_empty():
		d["socketed"] = item.socketed.duplicate(true)
	if not item.skills.is_empty():
		d["skills"] = item.skills.duplicate(true)
	return d


static func item_from_dict(d: Dictionary, catalog: ItemCatalog) -> ItemData:
	if d.is_empty():
		return null
	var item_id := str(d.get("id", ""))
	if item_id.is_empty() or catalog == null or not catalog.has_id(item_id):
		if not item_id.is_empty():
			push_warning("SaveSerializer: unknown item id '%s', slot cleared" % item_id)
		return null
	var item := catalog.get_item(item_id)
	item.quantity = int(d.get("quantity", 1))
	if d.has("durability_max"):
		item.durability_max = int(d["durability_max"])
	if d.has("durability"):
		item.durability = int(d["durability"])
	else:
		item.durability = item.durability_max
	if d.has("affixes"):
		var affixes: Array[Dictionary] = []
		for entry in d["affixes"]:
			if entry is Dictionary:
				affixes.append((entry as Dictionary).duplicate(true))
		item.affixes = affixes
	if d.has("attack_bonus"):
		item.attack_bonus = int(d["attack_bonus"])
	if d.has("defense_bonus"):
		item.defense_bonus = int(d["defense_bonus"])
	if d.has("socketed"):
		var socketed: Array[Dictionary] = []
		for entry in d["socketed"]:
			if entry is Dictionary:
				socketed.append((entry as Dictionary).duplicate(true))
		item.socketed = socketed
	if d.has("skills"):
		var skills: Array[Dictionary] = []
		for entry in d["skills"]:
			if entry is Dictionary:
				skills.append((entry as Dictionary).duplicate(true))
		item.skills = skills
	item.ensure_socket_layout()
	return item


static func _character_to_dict(character: CharacterStats) -> Dictionary:
	if character == null:
		return {}
	return {
		"character_name": character.character_name,
		"level": character.level,
		"xp": character.xp,
		"xp_to_next": character.xp_to_next,
		"hp": character.hp,
		"mana": character.mana,
		"attribute_points": character.attribute_points,
		"attributes": character.attributes.duplicate(true),
		"weight_current": character.weight_current,
		"weapons": character.weapons.duplicate(true),
	}


static func _character_from_dict(d: Dictionary) -> CharacterStats:
	var character: CharacterStats = load(CHARACTER_TEMPLATE_PATH).duplicate(true)
	if d.is_empty():
		character.recalculate_derived()
		return character

	character.character_name = str(d.get("character_name", character.character_name))
	character.level = int(d.get("level", character.level))
	character.xp = int(d.get("xp", character.xp))
	# xp_to_next is derived from LevelProgression CSV (not trusted from save).
	character.hp = int(d.get("hp", character.hp))
	var has_mana := d.has("mana")
	if has_mana:
		character.mana = int(d["mana"])
	character.attribute_points = int(d.get("attribute_points", character.attribute_points))
	character.weight_current = float(d.get("weight_current", character.weight_current))

	var attrs: Dictionary = character.attributes.duplicate(true)
	var loaded_attrs: Dictionary = d.get("attributes", {}) as Dictionary
	for key in CharacterStats.ATTRIBUTE_IDS:
		if loaded_attrs.has(key):
			attrs[key] = int(loaded_attrs[key])
	character.attributes = attrs

	if d.has("weapons"):
		var weapons: Array[Dictionary] = []
		for entry in d["weapons"]:
			if entry is Dictionary:
				weapons.append((entry as Dictionary).duplicate(true))
		character.weapons = weapons

	character.recalculate_derived()
	character.hp = clampi(character.hp, 0, character.hp_max)
	if has_mana:
		character.mana = clampi(character.mana, 0, character.mana_max)
	else:
		character.mana = character.mana_max
	return character


static func _inventory_to_dict(inventory: InventoryData) -> Dictionary:
	if inventory == null:
		return {}
	inventory.ensure_grid_size()
	var slots: Array = []
	for i in range(inventory.slots.size()):
		var item: ItemData = inventory.slots[i]
		if item:
			slots.append({"index": i, "item": item_to_dict(item)})

	var equipped := {}
	for slot_name in InventoryData.EQUIP_SLOTS:
		var equipped_item: ItemData = inventory.equipped.get(slot_name)
		if equipped_item:
			equipped[slot_name] = item_to_dict(equipped_item)
		else:
			equipped[slot_name] = null

	var quick_item: ItemData = inventory.quick_item
	var quick_food: ItemData = inventory.quick_food
	var runes: Array = []
	for ri in inventory.runes:
		if ri is RuneInstance:
			runes.append((ri as RuneInstance).to_dict())
	var gems: Array = []
	for gi in inventory.gems:
		if gi is GemInstance:
			gems.append((gi as GemInstance).to_dict())
	return {
		"currencies": inventory.currencies.duplicate(true),
		"current_category": int(inventory.current_category),
		"sort_mode": inventory.sort_mode,
		"slots": slots,
		"equipped": equipped,
		"quick_item": item_to_dict(quick_item) if quick_item else null,
		"quick_food": item_to_dict(quick_food) if quick_food else null,
		"runes": runes,
		"gems": gems,
	}


static func _inventory_from_dict(d: Dictionary, catalog: ItemCatalog) -> InventoryData:
	var inventory := InventoryData.new()
	inventory.ensure_grid_size()

	if d.has("currencies"):
		inventory.currencies = (d["currencies"] as Dictionary).duplicate(true)
	inventory.current_category = int(d.get("current_category", ItemData.ItemCategory.WEAPON)) as ItemData.ItemCategory
	inventory.sort_mode = str(d.get("sort_mode", "time"))

	for entry in d.get("slots", []):
		if not entry is Dictionary:
			continue
		var slot_entry := entry as Dictionary
		var index := int(slot_entry.get("index", -1))
		if index < 0 or index >= InventoryData.GRID_SIZE:
			continue
		var item_data: Dictionary = slot_entry.get("item", {}) as Dictionary
		inventory.slots[index] = item_from_dict(item_data, catalog)

	var equipped := {}
	for slot_name in InventoryData.EQUIP_SLOTS:
		equipped[slot_name] = null
	var loaded_equipped: Dictionary = d.get("equipped", {}) as Dictionary
	for slot_name in InventoryData.EQUIP_SLOTS:
		if not loaded_equipped.has(slot_name):
			continue
		var raw = loaded_equipped[slot_name]
		if raw == null or not raw is Dictionary:
			equipped[slot_name] = null
		else:
			equipped[slot_name] = item_from_dict(raw as Dictionary, catalog)
	inventory.equipped = equipped

	var quick_item_raw = d.get("quick_item", null)
	if quick_item_raw is Dictionary:
		inventory.quick_item = item_from_dict(quick_item_raw as Dictionary, catalog)
	else:
		inventory.quick_item = null

	var quick_food_raw = d.get("quick_food", null)
	if quick_food_raw is Dictionary:
		inventory.quick_food = item_from_dict(quick_food_raw as Dictionary, catalog)
	else:
		inventory.quick_food = null

	inventory.runes.clear()
	for entry in d.get("runes", []):
		if entry is Dictionary:
			var ri := RuneInstance.from_dict(entry as Dictionary)
			if ri:
				inventory.runes.append(ri)
	inventory.gems.clear()
	for entry in d.get("gems", []):
		if entry is Dictionary:
			var gi := GemInstance.from_dict(entry as Dictionary)
			if gi:
				inventory.gems.append(gi)

	var service := ResonanceService.new()
	service.rebuild_main_hand_skills(inventory, RuneCatalog.new(), GemCatalog.new())
	return inventory


static func run_to_dict(run: Dictionary) -> Dictionary:
	return run.duplicate(true)


static func run_equipment_snapshot(inventory: InventoryData) -> Dictionary:
	if inventory == null:
		return {}
	var runes: Array = []
	for ri in inventory.runes:
		if ri is RuneInstance:
			runes.append((ri as RuneInstance).to_dict())
	var gems: Array = []
	for gi in inventory.gems:
		if gi is GemInstance:
			gems.append((gi as GemInstance).to_dict())
	var socketed := {}
	for slot_name in InventoryData.EQUIP_SLOTS:
		var item: ItemData = inventory.equipped.get(slot_name) as ItemData
		if item and not item.socketed.is_empty():
			socketed[slot_name] = item.socketed.duplicate(true)
	return {
		"runes": runes,
		"gems": gems,
		"socketed": socketed,
	}
