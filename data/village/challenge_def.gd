class_name ChallengeDef
extends RefCounted

## Village challenge board: regions + expedition lengths.

const DUNGEON_ID_DEFAULT := "cemetery"

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

const LENGTHS: Array[Dictionary] = [
	{
		"id": "short",
		"title_key": "CHALLENGE_SHORT",
		"desc_key": "CHALLENGE_DESC_SHORT",
		"room_count": 8,
		"reward_mult": 1.0,
	},
	{
		"id": "normal",
		"title_key": "CHALLENGE_NORMAL",
		"desc_key": "CHALLENGE_DESC_NORMAL",
		"room_count": 12,
		"reward_mult": 1.5,
	},
	{
		"id": "long",
		"title_key": "CHALLENGE_LONG",
		"desc_key": "CHALLENGE_DESC_LONG",
		"room_count": 16,
		"reward_mult": 2.0,
	},
]


static func get_region(index: int) -> Dictionary:
	if REGIONS.is_empty():
		return {}
	var i := clampi(index, 0, REGIONS.size() - 1)
	return REGIONS[i]


static func get_length(index: int) -> Dictionary:
	if LENGTHS.is_empty():
		return {}
	var i := clampi(index, 0, LENGTHS.size() - 1)
	return LENGTHS[i]


static func build_run_params(
	region_index: int,
	length_index: int,
	seed_value: int = -1
) -> Dictionary:
	var region := get_region(region_index)
	var length := get_length(length_index)
	if region.is_empty() or length.is_empty():
		return {}
	var seed_v := seed_value
	if seed_v < 0:
		seed_v = randi()
	return {
		"dungeon_id": str(region.get("id", DUNGEON_ID_DEFAULT)),
		"length_id": str(length.get("id", "normal")),
		"seed": seed_v,
		"room_count": int(length.get("room_count", 12)),
		"reward_mult": float(length.get("reward_mult", 1.0)),
	}
