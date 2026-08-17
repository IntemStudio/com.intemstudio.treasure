extends SceneTree

# Run: godot --headless --path . -s res://data/village/verify_basin_progress.gd

const Basin := preload("res://data/village/basin_progress.gd")
const Zones := preload("res://data/village/challenge_def.gd")


func _initialize() -> void:
	var failed := 0
	failed += _test_seed_four_entrances()
	failed += _test_unlock_entrance_to_mid()
	failed += _test_verse_once()
	failed += _test_three_verses_open_altar()
	failed += _test_seal_closes_altar()
	failed += _test_empty_condition()
	if failed == 0:
		print("BASIN_VERIFY_OK")
		quit(0)
	else:
		push_error("BASIN_VERIFY_FAILED: %d" % failed)
		quit(1)


func _test_seed_four_entrances() -> int:
	var meta := Basin.seed_meta({})
	var stones: Array = meta.get("name_stones", []) as Array
	if stones.size() != 4:
		push_error("seed want 4 stones got %d" % stones.size())
		return 1
	for key in Zones.ENTRANCE_STONES:
		if not stones.has(key):
			push_error("missing entrance %s" % key)
			return 1
	if Basin.can_open_altar(meta):
		push_error("fresh meta should not open altar")
		return 1
	return 0


func _test_unlock_entrance_to_mid() -> int:
	var meta := Basin.seed_meta({})
	meta = Basin.unlock_next(meta, "cemetery", "graves")
	if not Basin.is_stone_open(meta, "cemetery", "ossuary"):
		push_error("graves clear should open ossuary")
		return 1
	meta = Basin.unlock_next(meta, "cemetery", "graves")
	var stones: Array = meta.get("name_stones", []) as Array
	var count := 0
	for key in stones:
		if str(key) == "cemetery:ossuary":
			count += 1
	if count != 1:
		push_error("unlock_next should be idempotent, got %d" % count)
		return 1
	meta = Basin.unlock_next(meta, "cemetery", "bone_altar")
	if Basin.is_stone_open(meta, "cemetery", "bone_altar") == false:
		pass
	var after_guardian: Array = meta.get("name_stones", []) as Array
	if after_guardian.has("cemetery:"):
		push_error("guardian should not append empty next")
		return 1
	return 0


func _test_verse_once() -> int:
	var meta := Basin.seed_meta({})
	if Basin.try_read_verse(meta, "cemetery", "graves"):
		push_error("entrance should not read verse")
		return 1
	if not Basin.try_read_verse(meta, "cemetery", "ossuary"):
		push_error("ossuary should read verse")
		return 1
	if Basin.try_read_verse(meta, "cemetery", "ossuary"):
		push_error("verse should not duplicate")
		return 1
	var read: Array = meta.get("verses_read", []) as Array
	if read.size() != 1 or str(read[0]) != "cemetery":
		push_error("verses_read want [cemetery] got %s" % str(read))
		return 1
	return 0


func _test_three_verses_open_altar() -> int:
	var meta := Basin.seed_meta({})
	Basin.try_read_verse(meta, "cemetery", "ossuary")
	Basin.try_read_verse(meta, "grove", "thicket")
	if Basin.can_open_altar(meta):
		push_error("two verses should not open altar")
		return 1
	Basin.try_read_verse(meta, "mansion", "servants")
	if not Basin.can_open_altar(meta):
		push_error("three verses should open altar")
		return 1
	if Basin.altar_zone_id(meta) != Zones.ZONE_MOUTH:
		push_error("default altar zone want mouth")
		return 1
	return 0


func _test_seal_closes_altar() -> int:
	var meta := Basin.seed_meta({})
	Basin.try_read_verse(meta, "cemetery", "ossuary")
	Basin.try_read_verse(meta, "grove", "thicket")
	Basin.try_read_verse(meta, "mansion", "servants")
	meta = Basin.unlock_next(meta, "cemetery", "graves")
	meta = Basin.apply_ending(meta, Basin.ENDING_SEAL)
	if Basin.can_open_altar(meta):
		push_error("seal should close altar even with 3 verses")
		return 1
	if Basin.is_stone_open(meta, "cemetery", "ossuary"):
		push_error("seal should reset stones to entrances")
		return 1
	if not Basin.is_stone_open(meta, "cemetery", "graves"):
		push_error("seal should keep entrance stones")
		return 1
	return 0


func _test_empty_condition() -> int:
	var meta := Basin.seed_meta({})
	Basin.try_read_verse(meta, "cemetery", "ossuary")
	Basin.try_read_verse(meta, "grove", "thicket")
	Basin.try_read_verse(meta, "mansion", "servants")
	if Basin.can_empty(meta, Zones.ZONE_MOUTH):
		push_error("empty needs open_cards >= 12")
		return 1
	var open: Array = []
	for i in range(Basin.EMPTY_OPEN_MIN):
		open.append("shelf_rune:%d" % (i + 1))
	meta["open_cards"] = open
	if not Basin.can_empty(meta, Zones.ZONE_MOUTH):
		push_error("empty should pass with 12 open_cards on mouth")
		return 1
	if Basin.can_empty(meta, Zones.ZONE_MOUTH_DEEP):
		push_error("empty forbidden on mouth_deep")
		return 1
	meta = Basin.apply_ending(meta, Basin.ENDING_EMPTY)
	if Basin.altar_zone_id(meta) != Zones.ZONE_MOUTH_DEEP:
		push_error("empty ending should point at mouth_deep")
		return 1
	meta = Basin.apply_ending(meta, Basin.ENDING_TAKE)
	meta = Basin.mark_altar_deep_cleared(meta)
	if Basin.can_open_altar(meta):
		push_error("emptied altar should close the pin")
		return 1
	return 0
