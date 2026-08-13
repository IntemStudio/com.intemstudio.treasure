class_name RuneCatalog
extends RefCounted

var _templates: Dictionary = {}


func _init() -> void:
	_register_defaults()


func has_id(rune_id: String) -> bool:
	return _templates.has(rune_id)


func get_rune(rune_id: String) -> RuneData:
	if not _templates.has(rune_id):
		return null
	return (_templates[rune_id] as RuneData).duplicate(true)


func all_ids() -> Array:
	return _templates.keys()


func _register_defaults() -> void:
	_add(_make(
		&"counter_verse",
		"Counter Verse",
		ItemData.ItemRarity.COMMON,
		&"shelf_common",
		1,
		[&"weapon", &"melee"],
		"Counter Stance",
		"strike",
		14,
		"X",
		[&"counter", &"blood"]
	))
	_add(_make(
		&"pierce_verse",
		"Pierce Verse",
		ItemData.ItemRarity.UNCOMMON,
		&"shelf_uncommon",
		2,
		[&"weapon"],
		"Piercing Strike",
		"strike",
		16,
		"Y",
		[&"pierce", &"wind"]
	))
	_add(_make(
		&"erupt_verse",
		"Erupt Verse",
		ItemData.ItemRarity.RARE,
		&"shelf_rare",
		3,
		[&"weapon", &"sword"],
		"Erupt Slash",
		"strike",
		18,
		"B",
		[&"erupt", &"fire"]
	))
	_add(_make(
		&"flurry_verse",
		"Flurry Verse",
		ItemData.ItemRarity.COMMON,
		&"shelf_common",
		4,
		[&"weapon", &"melee"],
		"Flurry",
		"combo",
		10,
		"X",
		[&"flurry", &"wind"]
	))
	_add(_make(
		&"tide_verse",
		"Tide Verse",
		ItemData.ItemRarity.UNCOMMON,
		&"shelf_uncommon",
		3,
		[&"weapon"],
		"Tide Crash",
		"aoe",
		20,
		"Y",
		[&"tide", &"frost"]
	))
	_add(_make(
		&"hymn_verse",
		"Hymn Verse",
		ItemData.ItemRarity.UNCOMMON,
		&"shelf_uncommon",
		4,
		[&"weapon", &"staff", &"melee"],
		"Hymn",
		"heal",
		16,
		"B",
		[&"hymn", &"ward"]
	))
	_add(_make(
		&"ward_verse",
		"Ward Verse",
		ItemData.ItemRarity.RARE,
		&"shelf_rare",
		4,
		[&"weapon"],
		"Ward Pulse",
		"ward",
		14,
		"A",
		[&"ward", &"holy"]
	))
	_add(_make(
		&"thorn_verse",
		"Thorn Verse",
		ItemData.ItemRarity.RARE,
		&"shelf_rare",
		5,
		[&"weapon", &"melee"],
		"Thorn Guard",
		"thorns",
		12,
		"X",
		[&"thorn", &"earth"]
	))


func _add(rune: RuneData) -> void:
	if rune and not String(rune.rune_id).is_empty():
		_templates[String(rune.rune_id)] = rune


func _make(
	id: StringName,
	name: String,
	rarity: ItemData.ItemRarity,
	shelf: StringName,
	card: int,
	tags: Array[StringName],
	skill: String,
	kind: String,
	mana: int,
	button: String,
	reso: Array[StringName]
) -> RuneData:
	var r := RuneData.new()
	r.rune_id = id
	r.display_name = name
	r.rarity = rarity
	r.shelf_id = shelf
	r.card_number = card
	r.required_equipment_tags = tags
	r.skill_name = skill
	r.skill_kind = kind
	r.mana_cost = mana
	r.button = button
	r.resonance_tags = reso
	return r
