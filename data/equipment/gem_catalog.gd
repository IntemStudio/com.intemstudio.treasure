class_name GemCatalog
extends RefCounted

var _templates: Dictionary = {}


func _init() -> void:
	_register_defaults()


func has_id(gem_id: String) -> bool:
	return _templates.has(gem_id)


func get_gem(gem_id: String) -> GemData:
	if not _templates.has(gem_id):
		return null
	return (_templates[gem_id] as GemData).duplicate(true)


func all_ids() -> Array:
	return _templates.keys()


func _register_defaults() -> void:
	_add(_make(
		&"bloodstone",
		"Bloodstone",
		ItemData.ItemRarity.COMMON,
		&"shelf_common",
		1,
		&"condition",
		[&"blood", &"counter"],
		{"main_hand": "lifesteal_on_skill"},
		" of Blood"
	))
	_add(_make(
		&"wind_shard",
		"Wind Shard",
		ItemData.ItemRarity.UNCOMMON,
		&"shelf_uncommon",
		2,
		&"element",
		[&"wind", &"pierce"],
		{"main_hand": "pierce_flag", "chest": "evade_reaction"},
		" of Storm"
	))
	_add(_make(
		&"ember_core",
		"Ember Core",
		ItemData.ItemRarity.RARE,
		&"shelf_rare",
		3,
		&"element",
		[&"fire", &"erupt"],
		{"main_hand": "fire_infusion", "tool_1": "volcano_find", "tool_2": "volcano_find"},
		" of Flame"
	))
	_add(_make(
		&"chain_spark",
		"Chain Spark",
		ItemData.ItemRarity.COMMON,
		&"shelf_common",
		4,
		&"mediator",
		[&"chain", &"fire", &"wind"],
		{"main_hand": "chain_hit"},
		" Chained"
	))
	_add(_make(
		&"frostglass",
		"Frostglass",
		ItemData.ItemRarity.COMMON,
		&"shelf_common",
		5,
		&"element",
		[&"frost", &"tide"],
		{"main_hand": "chill_on_skill", "chest": "frost_shell"},
		" of Frost"
	))
	_add(_make(
		&"grave_pearl",
		"Grave Pearl",
		ItemData.ItemRarity.UNCOMMON,
		&"shelf_uncommon",
		3,
		&"condition",
		[&"plague", &"grave"],
		{
			"main_hand": "plague_on_skill",
			"head": "plague_ward",
			"ring_1": "linger_plague",
			"ring_2": "linger_plague",
		},
		" of the Grave"
	))
	_add(_make(
		&"sanctum_tear",
		"Sanctum Tear",
		ItemData.ItemRarity.RARE,
		&"shelf_rare",
		4,
		&"condition",
		[&"holy", &"ward", &"hymn"],
		{
			"main_hand": "ward_on_skill",
			"head": "sanctum_aegis",
			"ring_1": "hymn_hold",
			"ring_2": "hymn_hold",
		},
		" of Sanctum"
	))
	_add(_make(
		&"root_amber",
		"Root Amber",
		ItemData.ItemRarity.COMMON,
		&"shelf_common",
		6,
		&"explore",
		[&"earth", &"thorn"],
		{
			"main_hand": "root_on_skill",
			"legs": "root_on_hit",
			"tool_1": "forest_find",
			"tool_2": "forest_find",
		},
		" Rooted"
	))
	_add(_make(
		&"ash_veil",
		"Ash Veil",
		ItemData.ItemRarity.RARE,
		&"shelf_rare",
		5,
		&"mediator",
		[&"ash", &"blood"],
		{
			"main_hand": "ash_on_skill",
			"chest": "ash_shroud",
			"ring_1": "blood_hold",
			"ring_2": "blood_hold",
			"tool_1": "manor_find",
			"tool_2": "manor_find",
		},
		" of Ash"
	))


func _add(gem: GemData) -> void:
	if gem and not String(gem.gem_id).is_empty():
		_templates[String(gem.gem_id)] = gem


func _make(
	id: StringName,
	name: String,
	rarity: ItemData.ItemRarity,
	shelf: StringName,
	card: int,
	gem_type: StringName,
	reso: Array[StringName],
	slot_effects: Dictionary,
	suffix: String
) -> GemData:
	var g := GemData.new()
	g.gem_id = id
	g.display_name = name
	g.rarity = rarity
	g.shelf_id = shelf
	g.card_number = card
	g.gem_type = gem_type
	g.resonance_tags = reso
	g.slot_effects = slot_effects
	g.skill_name_suffix = suffix
	return g
