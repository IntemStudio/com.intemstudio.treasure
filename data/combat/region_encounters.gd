class_name RegionEncounters
extends RefCounted

## Maps dungeon_id (challenge region) to normal/boss EncounterDef paths.

const DEFAULT_REGION := "cemetery"

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


static func normalize_region(dungeon_id: String) -> String:
	if dungeon_id.is_empty() or not TABLE.has(dungeon_id):
		return DEFAULT_REGION
	return dungeon_id


static func load_pair(dungeon_id: String) -> Dictionary:
	var region := normalize_region(dungeon_id)
	var entry: Dictionary = TABLE[region]
	var normal_path := str(entry.get("normal", ""))
	var boss_path := str(entry.get("boss", ""))
	return {
		"region": region,
		"normal": load(normal_path) as EncounterDef,
		"boss": load(boss_path) as EncounterDef,
	}
