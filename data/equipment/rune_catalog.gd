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
	# Unique card_number 1..25 on shelf_rune (5×5).
	_add(_make(
		&"counter_verse", "Rune of Countering", 1,
		[&"weapon", &"melee"], "Counter Stance", "strike", 14, "X",
		[&"counter", &"blood"]
	))
	_add(_make(
		&"flurry_verse", "Rune of Flurry", 2,
		[&"weapon", &"melee"], "Flurry", "combo", 10, "X",
		[&"flurry", &"wind"]
	))
	_add(_make(
		&"pierce_verse", "Rune of Piercing", 3,
		[&"weapon"], "Piercing Strike", "strike", 16, "Y",
		[&"pierce", &"wind"]
	))
	_add(_make(
		&"tide_verse", "Rune of the Tide", 4,
		[&"weapon"], "Tide Crash", "aoe", 20, "Y",
		[&"tide", &"frost"]
	))
	_add(_make(
		&"hymn_verse", "Rune of Hymns", 5,
		[&"weapon", &"staff", &"melee"], "Hymn", "heal", 16, "B",
		[&"hymn", &"ward"]
	))
	_add(_make(
		&"erupt_verse", "Rune of Eruption", 6,
		[&"weapon", &"sword"], "Erupt Slash", "strike", 18, "B",
		[&"erupt", &"fire"]
	))
	_add(_make(
		&"ward_verse", "Rune of Warding", 7,
		[&"weapon"], "Ward Pulse", "ward", 14, "A",
		[&"ward", &"holy"]
	))
	_add(_make(
		&"thorn_verse", "Rune of Thorns", 8,
		[&"weapon", &"melee"], "Thorn Guard", "thorns", 12, "X",
		[&"thorn", &"earth"]
	))
	_add(_make(
		&"surge_verse", "Rune of Surging", 9,
		[&"weapon"], "Damage Surge", "buff", 18, "Y",
		[&"surge", &"blood"]
	))
	_add(_make(
		&"chain_verse", "Rune of Chains", 10,
		[&"weapon", &"staff"], "Arc Bolt", "aoe", 16, "Y",
		[&"chain", &"storm"]
	))
	_add(_make(
		&"plague_verse", "Rune of Plague", 11,
		[&"weapon"], "Plague Sweep", "aoe", 18, "B",
		[&"plague", &"grave"]
	))
	_add(_make(
		&"crush_verse", "Rune of Crushing", 12,
		[&"weapon", &"melee"], "Plague Crush", "strike", 20, "B",
		[&"plague", &"crush"]
	))
	_add(_make(
		&"swirl_verse", "Rune of the Swirl", 13,
		[&"weapon"], "Venom Cloud", "aoe", 15, "A",
		[&"plague", &"wind"]
	))
	_add(_make(
		&"pulse_verse", "Rune of Vitality", 14,
		[&"weapon"], "Vital Pulse", "heal", 12, "A",
		[&"pulse", &"blood"]
	))
	_add(_make(
		&"channel_verse", "Rune of Channeling", 15,
		[&"weapon"], "Blood Channel", "convert", 0, "X",
		[&"channel", &"ash"]
	))
	_add(_make(
		&"smash_verse", "Rune of Smashing", 16,
		[&"weapon", &"melee"], "Balance Smash", "strike", 22, "Y",
		[&"smash", &"earth"]
	))
	_add(_make(
		&"volley_verse", "Rune of Volleys", 17,
		[&"weapon", &"ranged"], "Multi Shot", "aoe", 14, "Y",
		[&"volley", &"wind"]
	))
	_add(_make(
		&"mark_verse", "Rune of the Mark", 18,
		[&"weapon"], "Hunter's Mark", "debuff", 10, "B",
		[&"mark", &"wind"]
	))
	_add(_make(
		&"riposte_verse", "Rune of Riposte", 19,
		[&"weapon", &"melee"], "Perfect Riposte", "counter", 14, "X",
		[&"counter", &"steel"]
	))
	_add(_make(
		&"siphon_verse", "Rune of Siphoning", 20,
		[&"weapon"], "Life Siphon", "strike", 16, "B",
		[&"siphon", &"blood"]
	))
	_add(_make(
		&"shatter_verse", "Rune of Shattering", 21,
		[&"weapon"], "Frost Shatter", "strike", 18, "A",
		[&"shatter", &"frost"]
	))
	_add(_make(
		&"spark_verse", "Rune of Sparks", 22,
		[&"weapon"], "Static Edge", "strike", 14, "A",
		[&"spark", &"storm"]
	))
	_add(_make(
		&"grave_verse", "Rune of the Grave", 23,
		[&"weapon"], "Grave Toll", "aoe", 20, "X",
		[&"grave", &"ash"]
	))
	_add(_make(
		&"sanctum_verse", "Rune of the Sanctum", 24,
		[&"weapon", &"staff"], "Sanctum Seal", "ward", 16, "B",
		[&"sanctum", &"holy"]
	))
	_add(_make(
		&"ash_verse", "Rune of Ash", 25,
		[&"weapon"], "Ash Rain", "aoe", 18, "Y",
		[&"ash", &"fire"]
	))


func _add(rune: RuneData) -> void:
	if rune and not String(rune.rune_id).is_empty():
		_templates[String(rune.rune_id)] = rune


func _make(
	id: StringName,
	name: String,
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
	r.shelf_id = ShelfDefinition.SHELF_RUNE
	r.card_number = card
	r.required_equipment_tags = tags
	r.skill_name = skill
	r.skill_kind = kind
	r.mana_cost = mana
	r.button = button
	r.resonance_tags = reso
	r.icon = RuneData.icon_for_kind(kind)
	return r
