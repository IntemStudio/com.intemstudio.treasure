class_name ItemBootstrap
extends RefCounted

const ICON := preload("res://icon.svg")


static func create_claymore() -> ItemData:
	var item := ItemData.new()
	item.id = "claymore"
	item.display_name = "Claymore"
	item.item_type = "Two Handed Great Sword"
	item.category = ItemData.ItemCategory.WEAPON
	item.rarity = ItemData.ItemRarity.COMMON
	item.icon = ICON
	item.tier = 1
	item.attack = 13
	item.attack_bonus = 8
	item.defense = 20
	item.defense_bonus = 10
	item.scales_with = "strength"
	item.cost = 23
	item.gain = 9
	item.skills = [
		{"button": "X", "name": "Juggle Strike", "kind": "strike", "mana_cost": 12},
		{"button": "Y", "name": ""},
		{"button": "B", "name": ""},
		{"button": "A", "name": ""},
	]
	item.affixes = [
		{"id": "vampirism", "value": 0.05, "positive": true, "text": "+5% Vampirism"},
		{"id": "attack_speed", "value": 0.08, "positive": true, "text": "+8% Attack Speed"},
	]
	item.flavor_text = "A heavy blade forged for warriors who favor raw power."
	item.required_stat = "strength"
	item.required_value = 10
	item.durability = 100
	item.durability_max = 100
	item.weight = 29.6
	item.equip_slot = "main_hand"
	item.compatible_rune_tags = [&"weapon", &"sword", &"melee"]
	item.compatible_gem_tags = [&"weapon", &"element", &"condition"]
	item.socket_layout = SocketLayout.for_rarity(item.equip_slot, item.rarity)
	return item


static func create_blood_rusted_sword() -> ItemData:
	var item := ItemData.new()
	item.id = "blood_rusted_sword"
	item.display_name = "Blood-Rusted Sword"
	item.item_type = "One Handed Sword"
	item.category = ItemData.ItemCategory.WEAPON
	item.rarity = ItemData.ItemRarity.UNCOMMON
	item.icon = ICON
	item.attack = 18
	item.attack_bonus = 4
	item.scales_with = "dexterity"
	item.weight = 12.5
	item.equip_slot = "main_hand"
	item.compatible_rune_tags = [&"weapon", &"sword", &"melee"]
	item.compatible_gem_tags = [&"weapon", &"element"]
	item.socket_layout = SocketLayout.for_rarity(item.equip_slot, item.rarity)
	return item


static func create_iron_helm() -> ItemData:
	var item := ItemData.new()
	item.id = "iron_helm"
	item.display_name = "Iron Helm"
	item.item_type = "Head Armor"
	item.category = ItemData.ItemCategory.ARMOR
	item.rarity = ItemData.ItemRarity.COMMON
	item.icon = ICON
	item.defense = 8
	item.weight = 5.2
	item.equip_slot = "head"
	item.compatible_gem_tags = [&"armor", &"defense"]
	item.socket_layout = SocketLayout.for_rarity(item.equip_slot, item.rarity)
	return item


static func create_chain_chest() -> ItemData:
	var item := ItemData.new()
	item.id = "chain_chest"
	item.display_name = "Chain Chest"
	item.item_type = "Chest Armor"
	item.category = ItemData.ItemCategory.ARMOR
	item.rarity = ItemData.ItemRarity.UNCOMMON
	item.icon = ICON
	item.defense = 14
	item.weight = 11.0
	item.equip_slot = "chest"
	item.compatible_gem_tags = [&"armor", &"defense"]
	item.socket_layout = SocketLayout.for_rarity(item.equip_slot, item.rarity)
	return item


static func create_health_potion() -> ItemData:
	var item := ItemData.new()
	item.id = "health_potion"
	item.display_name = "Health Potion"
	item.item_type = "Consumable"
	item.category = ItemData.ItemCategory.CONSUMABLE
	item.rarity = ItemData.ItemRarity.COMMON
	item.icon = ICON
	item.stackable = true
	item.max_stack = 99
	item.quantity = 5
	item.weight = 0.5
	return item


static func create_dried_fish() -> ItemData:
	var item := ItemData.new()
	item.id = "dried_fish"
	item.display_name = "Dried Fish"
	item.item_type = "Food"
	item.category = ItemData.ItemCategory.CONSUMABLE
	item.rarity = ItemData.ItemRarity.COMMON
	item.icon = ICON
	item.stackable = true
	item.max_stack = 99
	item.quantity = 3
	item.weight = 0.3
	return item


static func create_iron_ore() -> ItemData:
	var item := ItemData.new()
	item.id = "iron_ore"
	item.display_name = "Iron Ore"
	item.item_type = "Material"
	item.category = ItemData.ItemCategory.MATERIAL
	item.rarity = ItemData.ItemRarity.COMMON
	item.icon = ICON
	item.stackable = true
	item.quantity = 12
	item.weight = 1.0
	return item


static func create_fishing_rod() -> ItemData:
	var item := ItemData.new()
	item.id = "fishing_rod"
	item.display_name = "Fishing Rod"
	item.item_type = "Tool"
	item.category = ItemData.ItemCategory.TOOL
	item.rarity = ItemData.ItemRarity.COMMON
	item.icon = ICON
	item.weight = 3.5
	item.equip_slot = "tool_1"
	item.compatible_gem_tags = [&"tool", &"explore"]
	item.socket_layout = SocketLayout.for_rarity(item.equip_slot, item.rarity)
	return item


static func create_rare_dagger() -> ItemData:
	var item := ItemData.new()
	item.id = "night_dagger"
	item.display_name = "Night Dagger"
	item.item_type = "Dagger"
	item.category = ItemData.ItemCategory.WEAPON
	item.rarity = ItemData.ItemRarity.RARE
	item.icon = ICON
	item.attack = 9
	item.attack_bonus = 6
	item.scales_with = "dexterity"
	item.affixes = [
		{"id": "crit_chance", "value": 0.10, "positive": true, "text": "+10% Critical Chance"},
	]
	item.weight = 4.2
	item.equip_slot = "off_hand"
	item.compatible_gem_tags = [&"weapon", &"off_hand", &"element"]
	item.socket_layout = SocketLayout.for_rarity(item.equip_slot, item.rarity)
	return item


static func create_sample_inventory() -> InventoryData:
	var inventory := InventoryData.new()
	inventory.ensure_grid_size()
	var sword := ItemDefaults.create_iron_longsword()
	var shield := ItemDefaults.create_splinter_buckler()
	inventory.equipped["main_hand"] = sword
	inventory.equipped["off_hand"] = shield
	return inventory
