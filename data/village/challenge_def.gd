class_name ChallengeDef
extends RefCounted

## Village rumor board: wounds + name-stone zones.

const DUNGEON_ID_DEFAULT := "cemetery"
const ZONE_ID_DEFAULT := "graves"
const DUNGEON_ALTAR := "altar_below"
const ZONE_MOUTH := "mouth"
const ZONE_MOUTH_DEEP := "mouth_deep"

const REGIONS: Array[Dictionary] = [
	{
		"id": "cemetery",
		"title_key": "REGION_CEMETERY",
		"desc_key": "REGION_DESC_CEMETERY",
	},
	{
		"id": "grove",
		"title_key": "REGION_GROVE",
		"desc_key": "REGION_DESC_GROVE",
	},
	{
		"id": "mansion",
		"title_key": "REGION_MANSION",
		"desc_key": "REGION_DESC_MANSION",
	},
	{
		"id": "battlefield",
		"title_key": "REGION_BATTLEFIELD",
		"desc_key": "REGION_DESC_BATTLEFIELD",
	},
]

const ZONES: Dictionary = {
	"cemetery": [
		{
			"id": "graves",
			"next": "ossuary",
			"room_count": 8,
			"has_verse": false,
			"guardian": false,
			"title_key": "ZONE_TITLE_CEMETERY_GRAVES",
			"desc_key": "ZONE_DESC_CEMETERY_GRAVES",
		},
		{
			"id": "ossuary",
			"next": "crypt",
			"room_count": 8,
			"has_verse": true,
			"guardian": false,
			"title_key": "ZONE_TITLE_CEMETERY_OSSUARY",
			"desc_key": "ZONE_DESC_CEMETERY_OSSUARY",
		},
		{
			"id": "crypt",
			"next": "bone_altar",
			"room_count": 8,
			"has_verse": false,
			"guardian": false,
			"title_key": "ZONE_TITLE_CEMETERY_CRYPT",
			"desc_key": "ZONE_DESC_CEMETERY_CRYPT",
		},
		{
			"id": "bone_altar",
			"next": "",
			"room_count": 6,
			"has_verse": false,
			"guardian": true,
			"title_key": "ZONE_TITLE_CEMETERY_BONE_ALTAR",
			"desc_key": "ZONE_DESC_CEMETERY_BONE_ALTAR",
		},
	],
	"grove": [
		{
			"id": "path",
			"next": "thicket",
			"room_count": 8,
			"has_verse": false,
			"guardian": false,
			"title_key": "ZONE_TITLE_GROVE_PATH",
			"desc_key": "ZONE_DESC_GROVE_PATH",
		},
		{
			"id": "thicket",
			"next": "roots",
			"room_count": 8,
			"has_verse": true,
			"guardian": false,
			"title_key": "ZONE_TITLE_GROVE_THICKET",
			"desc_key": "ZONE_DESC_GROVE_THICKET",
		},
		{
			"id": "roots",
			"next": "mother_tree",
			"room_count": 8,
			"has_verse": false,
			"guardian": false,
			"title_key": "ZONE_TITLE_GROVE_ROOTS",
			"desc_key": "ZONE_DESC_GROVE_ROOTS",
		},
		{
			"id": "mother_tree",
			"next": "",
			"room_count": 6,
			"has_verse": false,
			"guardian": true,
			"title_key": "ZONE_TITLE_GROVE_MOTHER_TREE",
			"desc_key": "ZONE_DESC_GROVE_MOTHER_TREE",
		},
	],
	"mansion": [
		{
			"id": "garden",
			"next": "servants",
			"room_count": 8,
			"has_verse": false,
			"guardian": false,
			"title_key": "ZONE_TITLE_MANSION_GARDEN",
			"desc_key": "ZONE_DESC_MANSION_GARDEN",
		},
		{
			"id": "servants",
			"next": "hall",
			"room_count": 8,
			"has_verse": true,
			"guardian": false,
			"title_key": "ZONE_TITLE_MANSION_SERVANTS",
			"desc_key": "ZONE_DESC_MANSION_SERVANTS",
		},
		{
			"id": "hall",
			"next": "lord_chamber",
			"room_count": 8,
			"has_verse": false,
			"guardian": false,
			"title_key": "ZONE_TITLE_MANSION_HALL",
			"desc_key": "ZONE_DESC_MANSION_HALL",
		},
		{
			"id": "lord_chamber",
			"next": "",
			"room_count": 6,
			"has_verse": false,
			"guardian": true,
			"title_key": "ZONE_TITLE_MANSION_LORD_CHAMBER",
			"desc_key": "ZONE_DESC_MANSION_LORD_CHAMBER",
		},
	],
	"battlefield": [
		{
			"id": "field",
			"next": "camp",
			"room_count": 8,
			"has_verse": false,
			"guardian": false,
			"title_key": "ZONE_TITLE_BATTLEFIELD_FIELD",
			"desc_key": "ZONE_DESC_BATTLEFIELD_FIELD",
		},
		{
			"id": "camp",
			"next": "trench",
			"room_count": 8,
			"has_verse": true,
			"guardian": false,
			"title_key": "ZONE_TITLE_BATTLEFIELD_CAMP",
			"desc_key": "ZONE_DESC_BATTLEFIELD_CAMP",
		},
		{
			"id": "trench",
			"next": "war_altar",
			"room_count": 8,
			"has_verse": false,
			"guardian": false,
			"title_key": "ZONE_TITLE_BATTLEFIELD_TRENCH",
			"desc_key": "ZONE_DESC_BATTLEFIELD_TRENCH",
		},
		{
			"id": "war_altar",
			"next": "",
			"room_count": 6,
			"has_verse": false,
			"guardian": true,
			"title_key": "ZONE_TITLE_BATTLEFIELD_WAR_ALTAR",
			"desc_key": "ZONE_DESC_BATTLEFIELD_WAR_ALTAR",
		},
	],
	"altar_below": [
		{
			"id": "mouth",
			"next": "",
			"room_count": 8,
			"has_verse": false,
			"guardian": true,
			"title_key": "ZONE_TITLE_ALTAR_MOUTH",
			"desc_key": "ZONE_DESC_ALTAR_MOUTH",
		},
		{
			"id": "mouth_deep",
			"next": "",
			"room_count": 12,
			"has_verse": false,
			"guardian": true,
			"title_key": "ZONE_TITLE_ALTAR_MOUTH_DEEP",
			"desc_key": "ZONE_DESC_ALTAR_MOUTH_DEEP",
		},
	],
}

const VERSE_KEYS := {
	"cemetery": "VERSE_LINE_CEMETERY",
	"grove": "VERSE_LINE_GROVE",
	"mansion": "VERSE_LINE_MANSION",
	"battlefield": "VERSE_LINE_BATTLEFIELD",
}

const ENTRANCE_STONES: Array[String] = [
	"cemetery:graves",
	"grove:path",
	"mansion:garden",
	"battlefield:field",
]


static func get_region(index: int) -> Dictionary:
	if REGIONS.is_empty():
		return {}
	var i := clampi(index, 0, REGIONS.size() - 1)
	return REGIONS[i]


static func region_index_of(dungeon_id: String) -> int:
	for i in range(REGIONS.size()):
		if str(REGIONS[i].get("id", "")) == dungeon_id:
			return i
	return -1


static func list_zones(dungeon_id: String) -> Array:
	var raw: Variant = ZONES.get(dungeon_id, [])
	if raw is Array:
		return raw as Array
	return []


static func get_zone(dungeon_id: String, zone_id: String) -> Dictionary:
	for zone in list_zones(dungeon_id):
		if zone is Dictionary and str(zone.get("id", "")) == zone_id:
			return zone
	return {}


static func has_zone(dungeon_id: String, zone_id: String) -> bool:
	return not get_zone(dungeon_id, zone_id).is_empty()


static func zone_has_verse(dungeon_id: String, zone_id: String) -> bool:
	return bool(get_zone(dungeon_id, zone_id).get("has_verse", false))


static func next_zone_id(dungeon_id: String, zone_id: String) -> String:
	return str(get_zone(dungeon_id, zone_id).get("next", ""))


static func room_count_for(dungeon_id: String, zone_id: String) -> int:
	return int(get_zone(dungeon_id, zone_id).get("room_count", 8))


static func location_key(dungeon_id: String, zone_id: String) -> String:
	if dungeon_id == DUNGEON_ALTAR:
		return "LOCATION_ALTAR_BELOW"
	var zone := get_zone(dungeon_id, zone_id)
	return str(zone.get("title_key", "LOCATION_DUNGEON"))


static func verse_line_key(dungeon_id: String) -> String:
	return str(VERSE_KEYS.get(dungeon_id, ""))


static func desc_key_for(dungeon_id: String, zone_id: String, verses_read: Array) -> String:
	if dungeon_id == "mansion" and zone_id == "garden" and verses_read.has("cemetery"):
		return "ZONE_DESC_MANSION_GARDEN_X_CEMETERY"
	if dungeon_id == "grove" and zone_id == "path" and verses_read.has("battlefield"):
		return "ZONE_DESC_GROVE_PATH_X_BATTLEFIELD"
	if dungeon_id == "cemetery" and zone_id == "graves" and verses_read.has("mansion"):
		return "ZONE_DESC_CEMETERY_GRAVES_X_MANSION"
	if dungeon_id == "battlefield" and zone_id == "field" and verses_read.has("grove"):
		return "ZONE_DESC_BATTLEFIELD_FIELD_X_GROVE"
	var zone := get_zone(dungeon_id, zone_id)
	if zone.is_empty():
		return ""
	return str(zone.get("desc_key", ""))


static func stone_key(dungeon_id: String, zone_id: String) -> String:
	return "%s:%s" % [dungeon_id, zone_id]


static func parse_stone_key(key: String) -> Dictionary:
	var parts := key.split(":", false, 1)
	if parts.size() != 2:
		return {}
	return {"dungeon_id": parts[0], "zone_id": parts[1]}


static func build_run_params(
	dungeon_id: String,
	zone_id: String,
	seed_value: int = -1
) -> Dictionary:
	var zone := get_zone(dungeon_id, zone_id)
	if zone.is_empty():
		return {}
	var seed_v := seed_value
	if seed_v < 0:
		seed_v = randi()
	return {
		"dungeon_id": dungeon_id,
		"zone_id": zone_id,
		"seed": seed_v,
		"room_count": int(zone.get("room_count", 8)),
	}
