extends SceneTree

# Run: godot --headless --path . -s res://data/equipment/verify_bookshelf.gd


func _initialize() -> void:
	var failed := 0
	failed += _test_grid_neighbors()
	failed += _test_unique_cells()
	failed += _test_new_meta_seed_one()
	failed += _test_seal_opens_neighbors()
	failed += _test_no_cross_board()
	failed += _test_reseal_rejected()
	failed += _test_legacy_resets()
	failed += _test_open_all_on_shelf()
	if failed == 0:
		print("BOOKSHELF_VERIFY_OK")
		quit(0)
	else:
		push_error("BOOKSHELF_VERIFY_FAILED: %d" % failed)
		quit(1)


func _test_grid_neighbors() -> int:
	if ShelfDefinition.WIDTH != 5 or ShelfDefinition.CELL_COUNT != 25:
		push_error("expected 5x5 shelf")
		return 1
	var n1 := ShelfDefinition.neighbor_card_numbers(1)
	if n1 != [2, 6]:
		push_error("card 1 neighbors want [2,6] got %s" % str(n1))
		return 1
	var n5 := ShelfDefinition.neighbor_card_numbers(5)
	if n5.has(6) or not n5.has(4) or not n5.has(10):
		push_error("card 5 neighbors want 4+10, no wrap; got %s" % str(n5))
		return 1
	return 0


func _test_unique_cells() -> int:
	var seen: Dictionary = {}
	var rune_cat := RuneCatalog.new()
	var gem_cat := GemCatalog.new()
	var rune_cards: Dictionary = {}
	var gem_cards: Dictionary = {}
	if rune_cat.all_ids().size() != ShelfDefinition.CELL_COUNT:
		push_error("rune catalog want %d got %d" % [ShelfDefinition.CELL_COUNT, rune_cat.all_ids().size()])
		return 1
	if gem_cat.all_ids().size() != ShelfDefinition.CELL_COUNT:
		push_error("gem catalog want %d got %d" % [ShelfDefinition.CELL_COUNT, gem_cat.all_ids().size()])
		return 1
	for id in rune_cat.all_ids():
		var def: RuneData = rune_cat.get_rune(str(id))
		if def == null:
			continue
		if def.card_number < 1 or def.card_number > ShelfDefinition.CELL_COUNT:
			push_error("rune %s card_number out of range: %d" % [id, def.card_number])
			return 1
		if rune_cards.has(def.card_number):
			push_error("duplicate rune card_number %d" % def.card_number)
			return 1
		rune_cards[def.card_number] = true
		var key := ShelfDefinition.discovery_key(String(def.shelf_id), def.card_number)
		if seen.has(key):
			push_error("duplicate cell %s" % key)
			return 1
		seen[key] = true
		if String(def.shelf_id) != String(ShelfDefinition.SHELF_RUNE):
			push_error("rune not on shelf_rune: %s" % id)
			return 1
	for id in gem_cat.all_ids():
		var gdef: GemData = gem_cat.get_gem(str(id))
		if gdef == null:
			continue
		if gdef.card_number < 1 or gdef.card_number > ShelfDefinition.CELL_COUNT:
			push_error("gem %s card_number out of range: %d" % [id, gdef.card_number])
			return 1
		if gem_cards.has(gdef.card_number):
			push_error("duplicate gem card_number %d" % gdef.card_number)
			return 1
		gem_cards[gdef.card_number] = true
		var gkey := ShelfDefinition.discovery_key(String(gdef.shelf_id), gdef.card_number)
		if seen.has(gkey):
			push_error("duplicate cell %s" % gkey)
			return 1
		seen[gkey] = true
		if String(gdef.shelf_id) != String(ShelfDefinition.SHELF_GEM):
			push_error("gem not on shelf_gem: %s" % id)
			return 1
	for n in range(1, ShelfDefinition.CELL_COUNT + 1):
		if not rune_cards.has(n):
			push_error("missing rune card_number %d" % n)
			return 1
		if not gem_cards.has(n):
			push_error("missing gem card_number %d" % n)
			return 1
	return 0


func _test_new_meta_seed_one() -> int:
	var rune_cat := RuneCatalog.new()
	var gem_cat := GemCatalog.new()
	var meta := CardRegistrationService.ensure_meta_seeded({}, rune_cat, gem_cat)
	var open: Array = meta["open_cards"] as Array
	if open.size() != 2:
		push_error("seed should open exactly 2 keys, got %s" % str(open))
		return 1
	if not open.has("shelf_rune:1") or not open.has("shelf_gem:1"):
		push_error("seed keys wrong: %s" % str(open))
		return 1
	var rpool := CardRegistrationService.loot_pool_ids(meta, "rune", rune_cat)
	var gpool := CardRegistrationService.loot_pool_ids(meta, "gem", gem_cat)
	if rpool.size() != 1 or gpool.size() != 1:
		push_error("seed pools want size 1 each; rune=%s gem=%s" % [str(rpool), str(gpool)])
		return 1
	return 0


func _test_seal_opens_neighbors() -> int:
	var rune_cat := RuneCatalog.new()
	var gem_cat := GemCatalog.new()
	var inventory := InventoryData.new()
	inventory.ensure_grid_size()
	var ri := RuneInstance.create("counter_verse")
	inventory.runes.append(ri)
	var meta := CardRegistrationService.ensure_meta_seeded({}, rune_cat, gem_cat)
	var before := CardRegistrationService.loot_pool_ids(meta, "rune", rune_cat)
	var result := CardRegistrationService.register(
		inventory, meta, "rune", ri.instance_uid, rune_cat, gem_cat
	)
	if not bool(result.get("ok", false)):
		push_error("seal failed")
		return 1
	meta = result["meta"] as Dictionary
	# card 1 neighbors: 2 and 6
	if not CardRegistrationService.is_open(meta, "shelf_rune", 2):
		push_error("neighbor 2 not open")
		return 1
	if not CardRegistrationService.is_open(meta, "shelf_rune", 6):
		push_error("neighbor 6 not open")
		return 1
	var after := CardRegistrationService.loot_pool_ids(meta, "rune", rune_cat)
	if after.size() <= before.size():
		push_error("pool did not grow after seal")
		return 1
	return 0


func _test_no_cross_board() -> int:
	var rune_cat := RuneCatalog.new()
	var gem_cat := GemCatalog.new()
	var inventory := InventoryData.new()
	inventory.ensure_grid_size()
	var ri := RuneInstance.create("counter_verse")
	inventory.runes.append(ri)
	var meta := CardRegistrationService.ensure_meta_seeded({}, rune_cat, gem_cat)
	var result := CardRegistrationService.register(
		inventory, meta, "rune", ri.instance_uid, rune_cat, gem_cat
	)
	meta = result["meta"] as Dictionary
	if CardRegistrationService.is_open(meta, "shelf_gem", 2):
		push_error("rune seal opened gem board")
		return 1
	return 0


func _test_reseal_rejected() -> int:
	var rune_cat := RuneCatalog.new()
	var gem_cat := GemCatalog.new()
	var inventory := InventoryData.new()
	inventory.ensure_grid_size()
	var meta := CardRegistrationService.ensure_meta_seeded({}, rune_cat, gem_cat)
	var ri := RuneInstance.create("counter_verse")
	inventory.runes.append(ri)
	var r1 := CardRegistrationService.register(
		inventory, meta, "rune", ri.instance_uid, rune_cat, gem_cat
	)
	meta = r1["meta"] as Dictionary
	var ri2 := RuneInstance.create("counter_verse")
	inventory.runes.append(ri2)
	var r2 := CardRegistrationService.register(
		inventory, meta, "rune", ri2.instance_uid, rune_cat, gem_cat
	)
	if bool(r2.get("ok", false)):
		push_error("reseal should fail")
		return 1
	return 0


func _test_legacy_resets() -> int:
	var rune_cat := RuneCatalog.new()
	var gem_cat := GemCatalog.new()
	var legacy := {
		"discovered_cards": ["shelf_common:2"],
		"unlocked_shelves": ["shelf_common"],
		"open_cards": ["shelf_common:4"],
		"registered_cards": [
			{"kind": "rune", "id": "counter_verse", "shelf_id": "shelf_common", "card_number": 1, "rarity": 0},
		],
	}
	var meta := CardRegistrationService.ensure_meta_seeded(legacy, rune_cat, gem_cat)
	if meta.has("discovered_cards"):
		push_error("discovered_cards should be erased")
		return 1
	var open: Array = meta["open_cards"] as Array
	if open.has("shelf_common:2") or open.has("shelf_common:4"):
		push_error("legacy open keys should be cleared")
		return 1
	if not open.has("shelf_rune:1") or not open.has("shelf_gem:1"):
		push_error("legacy should reseed #1: %s" % str(open))
		return 1
	var cards: Array = meta["registered_cards"] as Array
	if cards.is_empty():
		push_error("registered should survive")
		return 1
	var card: Dictionary = cards[0]
	if str(card.get("shelf_id", "")) != "shelf_rune" or int(card.get("card_number", 0)) != 1:
		push_error("registered rewrite failed: %s" % str(card))
		return 1
	if card.has("rarity"):
		push_error("rarity key should be stripped")
		return 1
	return 0


func _test_open_all_on_shelf() -> int:
	var rune_cat := RuneCatalog.new()
	var gem_cat := GemCatalog.new()
	var meta := CardRegistrationService.ensure_meta_seeded({}, rune_cat, gem_cat)
	meta = CardRegistrationService.open_all_on_shelf(meta, String(ShelfDefinition.SHELF_RUNE))
	for n in range(1, ShelfDefinition.CELL_COUNT + 1):
		if not CardRegistrationService.is_open(meta, "shelf_rune", n):
			push_error("rune cell %d not open" % n)
			return 1
	if CardRegistrationService.is_open(meta, "shelf_gem", 2):
		push_error("open_all rune should not open gem board")
		return 1
	meta = CardRegistrationService.open_all_on_shelf(meta, String(ShelfDefinition.SHELF_GEM))
	var rpool := CardRegistrationService.loot_pool_ids(meta, "rune", rune_cat)
	var gpool := CardRegistrationService.loot_pool_ids(meta, "gem", gem_cat)
	if rpool.size() != rune_cat.all_ids().size():
		push_error("rune pool incomplete after open_all")
		return 1
	if gpool.size() != gem_cat.all_ids().size():
		push_error("gem pool incomplete after open_all")
		return 1
	return 0
