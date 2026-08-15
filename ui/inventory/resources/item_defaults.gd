class_name ItemDefaults
extends RefCounted

const ICON := preload("res://icon.svg")


static func factories() -> Array[Callable]:
	return [
		create_leather_cap,
		create_watcher_circlet,
		create_bone_crown,
		create_traveler_coat,
		create_manor_mail,
		create_warplate,
		create_hide_greaves,
		create_thorn_chausses,
		create_silent_treads,
		create_iron_longsword,
		create_ashwood_staff,
		create_field_pike,
		create_widows_needle,
		create_splinter_buckler,
		create_ash_codex,
		create_grave_lantern,
		create_moss_ring,
		create_bloodseal_ring,
		create_warcloud_band,
		create_sanctum_ring,
		create_ossuary_band,
		create_cinder_loop,
		create_herb_pouch,
		create_grave_spade,
		create_war_compass,
		create_pine_torch,
		create_manor_keys,
		create_survey_line,
	]


static func create_leather_cap() -> ItemData:
	return _armor(
		"leather_cap", "Leather Cap", "Head Armor",
		ItemData.ItemRarity.COMMON, "head", 5, 2.4,
		[&"armor", &"defense"], []
	)


static func create_watcher_circlet() -> ItemData:
	return _armor(
		"watcher_circlet", "Watcher's Circlet", "Head Armor",
		ItemData.ItemRarity.UNCOMMON, "head", 6, 1.8,
		[&"armor", &"condition"],
		[_affix("evasion", 0.06, "+6% Evasion")]
	)


static func create_bone_crown() -> ItemData:
	return _armor(
		"bone_crown", "Bone Crown", "Head Armor",
		ItemData.ItemRarity.RARE, "head", 11, 6.5,
		[&"armor", &"defense", &"grave"],
		[
			_affix("retaliation", 1.5, "+1.5 Retaliation"),
			_affix("magic_hp", 8.0, "+8 Magic HP"),
		]
	)


static func create_traveler_coat() -> ItemData:
	return _armor(
		"traveler_coat", "Traveler's Coat", "Chest Armor",
		ItemData.ItemRarity.COMMON, "chest", 10, 6.0,
		[&"armor", &"defense"], []
	)


static func create_manor_mail() -> ItemData:
	return _armor(
		"manor_mail", "Manor Mail", "Chest Armor",
		ItemData.ItemRarity.UNCOMMON, "chest", 16, 12.5,
		[&"armor", &"blood"],
		[_affix("magic_hp", 10.0, "+10 Magic HP")]
	)


static func create_warplate() -> ItemData:
	return _armor(
		"warplate", "Warplate", "Chest Armor",
		ItemData.ItemRarity.LEGENDARY, "chest", 24, 22.0,
		[&"armor", &"defense", &"heavy"],
		[
			_affix("retaliation", 2.5, "+2.5 Retaliation"),
			_affix("defense", 4.0, "+4 Defense"),
		]
	)


static func create_hide_greaves() -> ItemData:
	return _armor(
		"hide_greaves", "Hide Greaves", "Leg Armor",
		ItemData.ItemRarity.COMMON, "legs", 7, 4.0,
		[&"armor", &"defense"], []
	)


static func create_thorn_chausses() -> ItemData:
	return _armor(
		"thorn_chausses", "Thorn Chausses", "Leg Armor",
		ItemData.ItemRarity.UNCOMMON, "legs", 12, 8.5,
		[&"armor", &"defense"],
		[_affix("retaliation", 1.2, "+1.2 Retaliation")]
	)


static func create_silent_treads() -> ItemData:
	return _armor(
		"silent_treads", "Silent Treads", "Leg Armor",
		ItemData.ItemRarity.RARE, "legs", 8, 3.2,
		[&"armor", &"condition"],
		[
			_affix("evasion", 0.08, "+8% Evasion"),
			_affix("attack_speed", 0.05, "+5% Attack Speed"),
		]
	)


static func create_iron_longsword() -> ItemData:
	return _weapon(
		"iron_longsword", "Iron Longsword", "One Handed Sword",
		ItemData.ItemRarity.COMMON, "main_hand",
		12, 4, "strength", 9.5, 10,
		[&"weapon", &"sword", &"melee"],
		[&"weapon", &"element", &"condition"],
		[]
	)


static func create_ashwood_staff() -> ItemData:
	return _weapon(
		"ashwood_staff", "Ashwood Staff", "Staff",
		ItemData.ItemRarity.COMMON, "main_hand",
		9, 5, "intelligence", 8.0, 10,
		[&"weapon", &"staff", &"magic"],
		[&"weapon", &"element"],
		[]
	)


static func create_field_pike() -> ItemData:
	return _weapon(
		"field_pike", "Field Pike", "Polearm",
		ItemData.ItemRarity.UNCOMMON, "main_hand",
		16, 4, "strength", 18.4, 12,
		[&"weapon", &"polearm", &"melee"],
		[&"weapon", &"element"],
		[_affix("damage_all", 2.0, "+2 Damage to All")],
		true
	)


static func create_widows_needle() -> ItemData:
	return _weapon(
		"widows_needle", "Widow's Needle", "Ritual Dagger",
		ItemData.ItemRarity.RARE, "main_hand",
		11, 7, "faith", 5.1, 12,
		[&"weapon", &"dagger", &"melee"],
		[&"weapon", &"condition"],
		[
			_affix("vampirism", 0.08, "+8% Vampirism"),
			_affix("magic_damage", 3.0, "+3 Magic Damage"),
		]
	)


static func create_splinter_buckler() -> ItemData:
	return _armor(
		"splinter_buckler", "Splintered Buckler", "Shield",
		ItemData.ItemRarity.COMMON, "off_hand", 8, 7.2,
		[&"off_hand", &"defense"], []
	)


static func create_ash_codex() -> ItemData:
	return _weapon(
		"ash_codex", "Ash Codex", "Tome",
		ItemData.ItemRarity.UNCOMMON, "off_hand",
		4, 6, "intelligence", 3.0, 10,
		[],
		[&"off_hand", &"element"],
		[_affix("magic_damage", 4.0, "+4 Magic Damage")]
	)


static func create_grave_lantern() -> ItemData:
	return _weapon(
		"grave_lantern", "Grave Lantern", "Lantern",
		ItemData.ItemRarity.RARE, "off_hand",
		3, 2, "faith", 2.6, 10,
		[],
		[&"off_hand", &"condition"],
		[
			_affix("regen_per_sec", 0.8, "+0.8 Regen/sec"),
			_affix("magic_hp", 6.0, "+6 Magic HP"),
		]
	)


static func create_moss_ring() -> ItemData:
	return _ring(
		"moss_ring", "Moss Ring",
		ItemData.ItemRarity.COMMON, "ring_1",
		[&"ring", &"explore"], []
	)


static func create_bloodseal_ring() -> ItemData:
	return _ring(
		"bloodseal_ring", "Bloodseal Ring",
		ItemData.ItemRarity.UNCOMMON, "ring_1",
		[&"ring", &"blood"],
		[_affix("vampirism", 0.06, "+6% Vampirism")]
	)


static func create_warcloud_band() -> ItemData:
	return _ring(
		"warcloud_band", "Warcloud Band",
		ItemData.ItemRarity.RARE, "ring_1",
		[&"ring", &"condition"],
		[_affix("crit_chance", 0.08, "+8% Critical Chance")]
	)


static func create_sanctum_ring() -> ItemData:
	return _ring(
		"sanctum_ring", "Sanctum Ring",
		ItemData.ItemRarity.UNCOMMON, "ring_2",
		[&"ring", &"ward"],
		[_affix("regen_per_sec", 0.6, "+0.6 Regen/sec")]
	)


static func create_ossuary_band() -> ItemData:
	return _ring(
		"ossuary_band", "Ossuary Band",
		ItemData.ItemRarity.RARE, "ring_2",
		[&"ring", &"grave"],
		[_affix("magic_hp", 12.0, "+12 Magic HP")]
	)


static func create_cinder_loop() -> ItemData:
	return _ring(
		"cinder_loop", "Cinder Loop",
		ItemData.ItemRarity.LEGENDARY, "ring_2",
		[&"ring", &"fire"],
		[
			_affix("magic_damage", 5.0, "+5 Magic Damage"),
		]
	)


static func create_herb_pouch() -> ItemData:
	return _tool(
		"herb_pouch", "Herb Pouch",
		ItemData.ItemRarity.COMMON, "tool_1", 1.2,
		[&"tool", &"explore"]
	)


static func create_grave_spade() -> ItemData:
	return _tool(
		"grave_spade", "Grave Spade",
		ItemData.ItemRarity.UNCOMMON, "tool_1", 4.8,
		[&"tool", &"explore", &"grave"]
	)


static func create_war_compass() -> ItemData:
	return _tool(
		"war_compass", "War Compass",
		ItemData.ItemRarity.RARE, "tool_1", 1.6,
		[&"tool", &"explore"]
	)


static func create_pine_torch() -> ItemData:
	return _tool(
		"pine_torch", "Pine Torch",
		ItemData.ItemRarity.COMMON, "tool_2", 1.5,
		[&"tool", &"explore"]
	)


static func create_manor_keys() -> ItemData:
	return _tool(
		"manor_keys", "Manor Keys",
		ItemData.ItemRarity.UNCOMMON, "tool_2", 0.8,
		[&"tool", &"explore"]
	)


static func create_survey_line() -> ItemData:
	return _tool(
		"survey_line", "Survey Line",
		ItemData.ItemRarity.RARE, "tool_2", 2.0,
		[&"tool", &"explore"]
	)


static func _affix(id: String, value: float, text: String, positive: bool = true) -> Dictionary:
	return {"id": id, "value": value, "positive": positive, "text": text}


static func _to_affixes(raw: Array) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for entry in raw:
		if entry is Dictionary:
			out.append(entry)
	return out


static func _armor(
	id: String,
	display_name: String,
	item_type: String,
	rarity: ItemData.ItemRarity,
	equip_slot: String,
	defense: int,
	weight: float,
	gem_tags: Array[StringName],
	affixes: Array
) -> ItemData:
	var item := ItemData.new()
	item.id = id
	item.display_name = display_name
	item.item_type = item_type
	item.category = ItemData.ItemCategory.ARMOR
	item.rarity = rarity
	item.icon = ICON
	item.tier = 1
	item.defense = defense
	item.weight = weight
	item.equip_slot = equip_slot
	item.compatible_gem_tags = gem_tags
	item.affixes = _to_affixes(affixes)
	item.socket_layout = SocketLayout.for_slot(equip_slot)
	return item


static func _weapon(
	id: String,
	display_name: String,
	item_type: String,
	rarity: ItemData.ItemRarity,
	equip_slot: String,
	attack: int,
	attack_bonus: int,
	scales_with: String,
	weight: float,
	required_value: int,
	rune_tags: Array[StringName],
	gem_tags: Array[StringName],
	affixes: Array,
	two_handed: bool = false
) -> ItemData:
	var item := ItemData.new()
	item.id = id
	item.display_name = display_name
	item.item_type = item_type
	item.category = ItemData.ItemCategory.WEAPON
	item.rarity = rarity
	item.icon = ICON
	item.tier = 1
	item.attack = attack
	item.attack_bonus = attack_bonus
	item.scales_with = scales_with
	item.required_stat = scales_with
	item.required_value = required_value
	item.weight = weight
	item.equip_slot = equip_slot
	item.two_handed = two_handed
	item.compatible_rune_tags = rune_tags
	item.compatible_gem_tags = gem_tags
	item.affixes = _to_affixes(affixes)
	item.socket_layout = SocketLayout.for_slot(equip_slot)
	return item


static func _ring(
	id: String,
	display_name: String,
	rarity: ItemData.ItemRarity,
	equip_slot: String,
	gem_tags: Array[StringName],
	affixes: Array
) -> ItemData:
	var item := ItemData.new()
	item.id = id
	item.display_name = display_name
	item.item_type = "Ring"
	item.category = ItemData.ItemCategory.ARMOR
	item.rarity = rarity
	item.icon = ICON
	item.tier = 1
	item.weight = 0.4
	item.equip_slot = equip_slot
	item.compatible_gem_tags = gem_tags
	item.affixes = _to_affixes(affixes)
	item.socket_layout = SocketLayout.for_slot(equip_slot)
	return item


static func _tool(
	id: String,
	display_name: String,
	rarity: ItemData.ItemRarity,
	equip_slot: String,
	weight: float,
	gem_tags: Array[StringName]
) -> ItemData:
	var item := ItemData.new()
	item.id = id
	item.display_name = display_name
	item.item_type = "Tool"
	item.category = ItemData.ItemCategory.TOOL
	item.rarity = rarity
	item.icon = ICON
	item.tier = 1
	item.weight = weight
	item.equip_slot = equip_slot
	item.compatible_gem_tags = gem_tags
	item.socket_layout = SocketLayout.for_slot(equip_slot)
	return item
