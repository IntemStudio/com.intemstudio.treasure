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
	# Unique card_number 1..25 on shelf_gem (5×5).
	_add(_make(
		&"bloodstone", "Bloodstone", 1, &"condition",
		[&"blood", &"counter"],
		{"main_hand": "lifesteal_on_skill"},
		" of Blood"
	))
	_add(_make(
		&"chain_spark", "Chain Spark", 2, &"mediator",
		[&"chain", &"storm", &"wind"],
		{"main_hand": "chain_hit"},
		" Chained"
	))
	_add(_make(
		&"frostglass", "Frostglass", 3, &"element",
		[&"frost", &"tide"],
		{"main_hand": "chill_on_skill", "chest": "frost_shell"},
		" of Frost"
	))
	_add(_make(
		&"root_amber", "Root Amber", 4, &"explore",
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
		&"wind_shard", "Wind Shard", 5, &"element",
		[&"wind", &"pierce"],
		{"main_hand": "pierce_flag", "chest": "on_evade_thorn"},
		" of Storm"
	))
	_add(_make(
		&"grave_pearl", "Grave Pearl", 6, &"condition",
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
		&"ember_core", "Ember Core", 7, &"element",
		[&"fire", &"erupt"],
		{"main_hand": "fire_infusion", "tool_1": "volcano_find", "tool_2": "volcano_find"},
		" of Flame"
	))
	_add(_make(
		&"sanctum_tear", "Sanctum Tear", 8, &"condition",
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
		&"ash_veil", "Ash Veil", 9, &"mediator",
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
	_add(_make(
		&"quartz_needle", "Quartz Needle", 10, &"element",
		[&"storm", &"spark"],
		{
			"main_hand": "electric_on_skill",
			"head": "mana_on_hit_taken",
			"chest": "skill_gauge_nudge",
		},
		" of Spark"
	))
	_add(_make(
		&"ruby_heart", "Ruby Heart", 11, &"element",
		[&"fire", &"pulse"],
		{
			"main_hand": "heat_on_skill",
			"head": "heal_amp_on_skill",
			"off_hand": "retaliation_heat",
		},
		" of Heat"
	))
	_add(_make(
		&"sapphire_vein", "Sapphire Vein", 12, &"element",
		[&"frost", &"shatter"],
		{
			"main_hand": "cold_on_skill",
			"head": "shatter_window",
			"legs": "cold_shell",
		},
		" of Ice"
	))
	_add(_make(
		&"amethyst_blight", "Amethyst Blight", 13, &"element",
		[&"plague", &"crush"],
		{
			"main_hand": "plague_on_skill",
			"chest": "plague_on_hit_taken",
			"head": "finisher_plague",
		},
		" of Blight"
	))
	_add(_make(
		&"iron_thorn", "Iron Thorn", 14, &"condition",
		[&"thorn", &"counter"],
		{
			"main_hand": "retaliation_on_skill",
			"chest": "thorns_aura",
			"off_hand": "reflect_flag",
		},
		" of Thorns"
	))
	_add(_make(
		&"echo_prism", "Echo Prism", 15, &"mediator",
		[&"chain", &"pierce"],
		{
			"main_hand": "damage_all_on_skill",
			"ring_1": "echo_hold",
			"ring_2": "echo_hold",
		},
		" Echoing"
	))
	_add(_make(
		&"dawnflake", "Dawnflake", 16, &"condition",
		[&"surge", &"holy"],
		{
			"main_hand": "opening_strike",
			"ring_1": "dawn_hold",
			"ring_2": "dawn_hold",
		},
		" of Dawn"
	))
	_add(_make(
		&"buckler_seed", "Buckler Seed", 17, &"condition",
		[&"counter", &"ward"],
		{
			"main_hand": "heal_on_counter",
			"off_hand": "counter_ward",
		},
		" Guarded"
	))
	_add(_make(
		&"mire_opal", "Mire Opal", 18, &"explore",
		[&"plague", &"earth"],
		{
			"main_hand": "slow_on_skill",
			"legs": "mire_stance",
			"tool_1": "swamp_find",
			"tool_2": "swamp_find",
		},
		" of Mire"
	))
	_add(_make(
		&"cinder_eye", "Cinder Eye", 19, &"mediator",
		[&"fire", &"mark"],
		{
			"main_hand": "mark_on_skill",
			"head": "marked_crit_flag",
		},
		" Marked"
	))
	_add(_make(
		&"phantom_glass", "Phantom Glass", 20, &"condition",
		[&"ward", &"ash"],
		{
			"main_hand": "ghost_hp_on_skill",
			"chest": "phantom_shell",
		},
		" Phantom"
	))
	_add(_make(
		&"stillwater", "Stillwater", 21, &"element",
		[&"frost", &"tide"],
		{
			"main_hand": "mana_on_kill",
			"ring_1": "still_hold",
			"ring_2": "still_hold",
		},
		" Still"
	))
	_add(_make(
		&"widows_tear", "Widow's Tear", 22, &"condition",
		[&"blood", &"grave"],
		{
			"main_hand": "execute_below",
			"ring_1": "widow_hold",
			"ring_2": "widow_hold",
		},
		" of the Widow"
	))
	_add(_make(
		&"lodestone", "Lodestone", 23, &"mediator",
		[&"earth", &"smash"],
		{
			"main_hand": "stun_on_skill",
			"legs": "rooted_stance",
		},
		" Anchored"
	))
	_add(_make(
		&"gilded_fang", "Gilded Fang", 24, &"condition",
		[&"flurry", &"wind"],
		{
			"main_hand": "extra_hit_on_skill",
			"ring_1": "fang_hold",
			"ring_2": "fang_hold",
		},
		" Fanged"
	))
	_add(_make(
		&"nameglass", "Nameglass", 25, &"explore",
		[&"holy", &"ash"],
		{
			"tool_1": "name_find",
			"tool_2": "name_find",
			"ring_1": "seal_echo",
			"ring_2": "seal_echo",
		},
		""
	))


func _add(gem: GemData) -> void:
	if gem and not String(gem.gem_id).is_empty():
		_templates[String(gem.gem_id)] = gem


func _make(
	id: StringName,
	name: String,
	card: int,
	gem_type: StringName,
	reso: Array[StringName],
	slot_effects: Dictionary,
	suffix: String
) -> GemData:
	var g := GemData.new()
	g.gem_id = id
	g.display_name = name
	g.shelf_id = ShelfDefinition.SHELF_GEM
	g.card_number = card
	g.gem_type = gem_type
	g.resonance_tags = reso
	g.slot_effects = slot_effects
	g.skill_name_suffix = suffix
	return g
