class_name BasinProgress
extends RefCounted

## Meta gates for name-stones, verses, and the altar below.

const EMPTY_OPEN_MIN := 12
const LAST_VERSE_RUNE_ID := "sanctum_verse"
const ENDING_TAKE := "take"
const ENDING_SEAL := "seal"
const ENDING_EMPTY := "empty"

const META_KEYS: Array[String] = [
	"name_stones",
	"verses_read",
	"ending",
	"altar_emptied",
]


static func seed_meta(meta: Dictionary) -> Dictionary:
	var out := meta.duplicate(true)
	if not out.has("name_stones") or not (out["name_stones"] is Array) or (out["name_stones"] as Array).is_empty():
		out["name_stones"] = ChallengeDef.ENTRANCE_STONES.duplicate()
	if not out.has("verses_read") or not (out["verses_read"] is Array):
		out["verses_read"] = []
	if not out.has("ending"):
		out["ending"] = ""
	if not out.has("altar_emptied"):
		out["altar_emptied"] = false
	return out


static func stone_key(dungeon_id: String, zone_id: String) -> String:
	return ChallengeDef.stone_key(dungeon_id, zone_id)


static func is_stone_open(meta: Dictionary, dungeon_id: String, zone_id: String) -> bool:
	var seeded := seed_meta(meta)
	if dungeon_id == ChallengeDef.DUNGEON_ALTAR:
		return can_open_altar(seeded) and zone_id == altar_zone_id(seeded)
	var stones: Array = seeded.get("name_stones", []) as Array
	return stones.has(stone_key(dungeon_id, zone_id))


static func list_open_stones(meta: Dictionary) -> Array[Dictionary]:
	var seeded := seed_meta(meta)
	var out: Array[Dictionary] = []
	var stones: Array = seeded.get("name_stones", []) as Array
	for dungeon_id in ["cemetery", "grove", "mansion", "battlefield"]:
		for zone in ChallengeDef.list_zones(dungeon_id):
			if not (zone is Dictionary):
				continue
			var zone_id := str(zone.get("id", ""))
			if stones.has(stone_key(dungeon_id, zone_id)):
				out.append({"dungeon_id": dungeon_id, "zone_id": zone_id})
	if can_open_altar(seeded):
		out.append({
			"dungeon_id": ChallengeDef.DUNGEON_ALTAR,
			"zone_id": altar_zone_id(seeded),
		})
	return out


static func list_open_zones_for(meta: Dictionary, dungeon_id: String) -> Array[Dictionary]:
	var seeded := seed_meta(meta)
	var out: Array[Dictionary] = []
	if dungeon_id == ChallengeDef.DUNGEON_ALTAR:
		if can_open_altar(seeded):
			var zid := altar_zone_id(seeded)
			var zone := ChallengeDef.get_zone(dungeon_id, zid)
			if not zone.is_empty():
				out.append(zone)
		return out
	var stones: Array = seeded.get("name_stones", []) as Array
	for zone in ChallengeDef.list_zones(dungeon_id):
		if not (zone is Dictionary):
			continue
		var zone_id := str(zone.get("id", ""))
		if stones.has(stone_key(dungeon_id, zone_id)):
			out.append(zone)
	return out


static func unlock_next(meta: Dictionary, dungeon_id: String, zone_id: String) -> Dictionary:
	var out := seed_meta(meta)
	var next_id := ChallengeDef.next_zone_id(dungeon_id, zone_id)
	if next_id.is_empty():
		return out
	var key := stone_key(dungeon_id, next_id)
	var stones: Array = out.get("name_stones", []) as Array
	if not stones.has(key):
		stones.append(key)
	out["name_stones"] = stones
	return out


static func try_read_verse(meta: Dictionary, dungeon_id: String, zone_id: String) -> bool:
	var seeded := seed_meta(meta)
	if not ChallengeDef.zone_has_verse(dungeon_id, zone_id):
		return false
	var read: Array = seeded.get("verses_read", []) as Array
	if read.has(dungeon_id):
		return false
	read.append(dungeon_id)
	meta["name_stones"] = seeded.get("name_stones", [])
	meta["verses_read"] = read
	meta["ending"] = seeded.get("ending", "")
	meta["altar_emptied"] = seeded.get("altar_emptied", false)
	return true


static func unique_verse_count(meta: Dictionary) -> int:
	var seeded := seed_meta(meta)
	var seen: Dictionary = {}
	for id in seeded.get("verses_read", []) as Array:
		var s := str(id)
		if s.is_empty():
			continue
		seen[s] = true
	return seen.size()


static func can_open_altar(meta: Dictionary) -> bool:
	var seeded := seed_meta(meta)
	if str(seeded.get("ending", "")) == ENDING_SEAL:
		return false
	if bool(seeded.get("altar_emptied", false)):
		return false
	if unique_verse_count(seeded) < 3:
		return false
	return true


static func altar_zone_id(meta: Dictionary) -> String:
	var seeded := seed_meta(meta)
	if str(seeded.get("ending", "")) == ENDING_EMPTY and not bool(seeded.get("altar_emptied", false)):
		return ChallengeDef.ZONE_MOUTH_DEEP
	return ChallengeDef.ZONE_MOUTH


static func apply_ending(meta: Dictionary, ending_id: String) -> Dictionary:
	var out := seed_meta(meta)
	match ending_id:
		ENDING_TAKE:
			out["ending"] = ENDING_TAKE
		ENDING_SEAL:
			out["ending"] = ENDING_SEAL
			out["name_stones"] = ChallengeDef.ENTRANCE_STONES.duplicate()
		ENDING_EMPTY:
			out["ending"] = ENDING_EMPTY
		_:
			pass
	return out


static func mark_altar_deep_cleared(meta: Dictionary) -> Dictionary:
	var out := seed_meta(meta)
	out["altar_emptied"] = true
	return out


static func can_empty(meta: Dictionary, zone_id: String) -> bool:
	var seeded := seed_meta(meta)
	if zone_id != ChallengeDef.ZONE_MOUTH:
		return false
	if bool(seeded.get("altar_emptied", false)):
		return false
	var open: Array = seeded.get("open_cards", []) as Array
	return open.size() >= EMPTY_OPEN_MIN
