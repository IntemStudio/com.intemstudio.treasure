class_name RegionEncounters
extends RefCounted

## Maps dungeon_id + zone_id to normal/boss EncounterDef paths.

const DEFAULT_REGION := "cemetery"
const DEFAULT_ZONE := "graves"
const DUNGEON_ALTAR := "altar_below"

const TABLE: Dictionary = {
	"cemetery": {
		"normal": "res://data/combat/encounters/cemetery/normal.tres",
		"boss": "res://data/combat/encounters/cemetery/boss.tres",
	},
	"grove": {
		"normal": "res://data/combat/encounters/grove/normal.tres",
		"boss": "res://data/combat/encounters/grove/boss.tres",
	},
	"mansion": {
		"normal": "res://data/combat/encounters/mansion/normal.tres",
		"boss": "res://data/combat/encounters/mansion/boss.tres",
	},
	"battlefield": {
		"normal": "res://data/combat/encounters/battlefield/normal.tres",
		"boss": "res://data/combat/encounters/battlefield/boss.tres",
	},
}

const ALTAR_NORMAL := "res://data/combat/encounters/altar_below/normal.tres"
const ALTAR_BOSS := "res://data/combat/encounters/altar_below/boss.tres"
const ALTAR_BOSS_DEEP := "res://data/combat/encounters/altar_below/boss_deep.tres"

const DEEP_ZONES: Array[String] = ["crypt", "roots", "hall", "trench"]


static func normalize_region(dungeon_id: String) -> String:
	if dungeon_id == DUNGEON_ALTAR:
		return DUNGEON_ALTAR
	if dungeon_id.is_empty() or not TABLE.has(dungeon_id):
		return DEFAULT_REGION
	return dungeon_id


static func normalize_zone(dungeon_id: String, zone_id: String) -> String:
	var region := normalize_region(dungeon_id)
	if ChallengeDef.has_zone(region, zone_id):
		return zone_id
	if region == DUNGEON_ALTAR:
		return ChallengeDef.ZONE_MOUTH
	return DEFAULT_ZONE


static func load_pair(dungeon_id: String, zone_id: String = "") -> Dictionary:
	var region := normalize_region(dungeon_id)
	var zone := normalize_zone(region, zone_id)
	if region == DUNGEON_ALTAR:
		var altar_normal := load(ALTAR_NORMAL) as EncounterDef
		var altar_boss_path := ALTAR_BOSS_DEEP if zone == ChallengeDef.ZONE_MOUTH_DEEP else ALTAR_BOSS
		return {
			"region": region,
			"zone": zone,
			"normal": altar_normal,
			"boss": load(altar_boss_path) as EncounterDef,
		}
	var entry: Dictionary = TABLE[region]
	var normal := load(str(entry.get("normal", ""))) as EncounterDef
	var named_boss := load(str(entry.get("boss", ""))) as EncounterDef
	var zone_def := ChallengeDef.get_zone(region, zone)
	var boss: EncounterDef = named_boss
	if not bool(zone_def.get("guardian", false)):
		boss = normal
		if DEEP_ZONES.has(zone) and normal != null:
			boss = normal.duplicate(true) as EncounterDef
			if boss:
				boss.enemy_level = maxi(normal.enemy_level + 1, 2)
	return {
		"region": region,
		"zone": zone,
		"normal": normal,
		"boss": boss,
	}
