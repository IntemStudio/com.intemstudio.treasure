extends SceneTree

# Run: godot --headless --path . -s res://data/equipment/verify_socket_layout.gd
# Exits 0 on success.


func _initialize() -> void:
	var failed := 0
	failed += _test_slot_table()
	failed += _test_trim_overflow()
	failed += _test_rune_kinds()
	failed += _test_two_set_gems()
	failed += _test_socket_row_order()
	failed += _test_equipped_rune_list()
	if failed == 0:
		print("SOCKET_LAYOUT_VERIFY_OK")
		quit(0)
	else:
		push_error("SOCKET_LAYOUT_VERIFY_FAILED: %d" % failed)
		quit(1)


func _expect_layout(slot: String, runes: int, cores: int, aux: int) -> int:
	var layout := SocketLayout.for_slot(slot)
	if layout.rune_slots != runes or layout.core_gem_slots != cores or layout.aux_gem_slots != aux:
		push_error("%s want rune %d core %d aux %d got %d %d %d" % [
			slot, runes, cores, aux, layout.rune_slots, layout.core_gem_slots, layout.aux_gem_slots
		])
		return 1
	return 0


func _test_slot_table() -> int:
	var failed := 0
	failed += _expect_layout("main_hand", 2, 2, 2)
	failed += _expect_layout("off_hand", 1, 1, 1)
	failed += _expect_layout("head", 1, 1, 1)
	failed += _expect_layout("chest", 1, 1, 1)
	failed += _expect_layout("legs", 1, 1, 1)
	failed += _expect_layout("ring_1", 0, 1, 0)
	failed += _expect_layout("tool_1", 0, 1, 0)
	var common := SocketLayout.for_slot("main_hand")
	var legendary_item := ItemData.new()
	legendary_item.equip_slot = "main_hand"
	legendary_item.apply_rarity(ItemData.ItemRarity.LEGENDARY)
	if legendary_item.socket_layout.rune_slots != common.rune_slots:
		push_error("rarity must not change weapon sockets")
		failed += 1
	return failed


func _test_trim_overflow() -> int:
	var item := ItemData.new()
	item.equip_slot = "main_hand"
	item.socket_layout = SocketLayout.for_slot(item.equip_slot)
	item.socketed = [
		{"kind": "rune", "index": 0, "instance_uid": "r0"},
		{"kind": "rune", "index": 1, "instance_uid": "r1"},
		{"kind": "rune", "index": 3, "instance_uid": "r3"},
		{"kind": "core_gem", "index": 0, "instance_uid": "c0"},
		{"kind": "core_gem", "index": 2, "instance_uid": "c2"},
	]
	item.trim_socketed_to_layout()
	if item.socketed.size() != 3:
		push_error("trim want 3 kept got %d" % item.socketed.size())
		return 1
	return 0


func _test_rune_kinds() -> int:
	var catalog := ItemCatalog.new()
	var rune_cat := RuneCatalog.new()
	var service := ResonanceService.new()
	var sword := catalog.get_item("iron_longsword")
	var coat := catalog.get_item("traveler_coat")
	var ring := catalog.get_item("moss_ring")
	var pouch := catalog.get_item("herb_pouch")
	var hymn := rune_cat.get_rune("hymn_verse")
	var counter := rune_cat.get_rune("counter_verse")
	if service.can_socket_rune(sword, hymn):
		push_error("weapon must reject heal rune")
		return 1
	if not service.can_socket_rune(sword, counter):
		push_error("weapon must accept strike rune")
		return 1
	if not service.can_socket_rune(coat, hymn):
		push_error("chest must accept heal rune")
		return 1
	if service.can_socket_rune(coat, counter):
		push_error("chest must reject strike rune")
		return 1
	if service.can_socket_rune(ring, hymn) or service.can_socket_rune(ring, counter):
		push_error("ring must reject runes")
		return 1
	if service.can_socket_rune(pouch, hymn) or service.can_socket_rune(pouch, counter):
		push_error("tool must reject runes")
		return 1
	if ResonanceService.slots_for_rune_kind("strike") != PackedStringArray(["main_hand"]):
		push_error("active rune slots must be main_hand")
		return 1
	if ResonanceService.slots_for_rune_kind("heal") != PackedStringArray([
		"off_hand", "head", "chest", "legs"
	]):
		push_error("passive rune slots must be off_hand and armor")
		return 1
	return 0


func _test_two_set_gems() -> int:
	var catalog := ItemCatalog.new()
	var rune_cat := RuneCatalog.new()
	var gem_cat := GemCatalog.new()
	var inventory := InventoryData.new()
	var sword := catalog.get_item("iron_longsword")
	inventory.equipped["main_hand"] = sword
	var r0 := RuneInstance.create("counter_verse")
	var r1 := RuneInstance.create("pierce_verse")
	var g0 := GemInstance.create("bloodstone")
	var g1 := GemInstance.create("wind_shard")
	if not inventory.try_add_rune(r0) or not inventory.try_add_rune(r1):
		push_error("try_add_rune failed")
		return 1
	if not inventory.try_add_gem(g0) or not inventory.try_add_gem(g1):
		push_error("try_add_gem failed")
		return 1
	if not inventory.socket_rune_on_item(sword, r0.instance_uid, 0):
		push_error("socket rune 0 failed")
		return 1
	if not inventory.socket_rune_on_item(sword, r1.instance_uid, 1):
		push_error("socket rune 1 failed")
		return 1
	if not inventory.socket_gem_on_item(sword, g0.instance_uid, "core_gem", 0):
		push_error("socket core 0 failed")
		return 1
	if not inventory.socket_gem_on_item(sword, g1.instance_uid, "core_gem", 1):
		push_error("socket core 1 failed")
		return 1
	if inventory.find_rune(r0.instance_uid) != null or inventory.find_gem(g0.instance_uid) != null:
		push_error("socketed rune/gem must leave the bag")
		return 1
	if inventory.modifier_count() != 0:
		push_error("bag modifiers want 0 after socket got %d" % inventory.modifier_count())
		return 1
	var rune0_id := ""
	for entry in sword.socketed:
		if str(entry.get("kind", "")) == "rune" and int(entry.get("index", -1)) == 0:
			rune0_id = str(entry.get("rune_id", ""))
	if rune0_id != "counter_verse":
		push_error("socketed rune_id want counter_verse got %s" % rune0_id)
		return 1
	var service := ResonanceService.new()
	service.rebuild_main_hand_skills(inventory, rune_cat, gem_cat)
	if str(sword.skills[0].get("gem_id", "")) != "bloodstone":
		push_error("set 0 gem_id want bloodstone got %s" % sword.skills[0].get("gem_id", ""))
		return 1
	if str(sword.skills[1].get("gem_id", "")) != "wind_shard":
		push_error("set 1 gem_id want wind_shard got %s" % sword.skills[1].get("gem_id", ""))
		return 1
	if sword.skills.size() != 2:
		push_error("weapon skills want 2 got %d" % sword.skills.size())
		return 1
	return 0


func _test_socket_row_order() -> int:
	var catalog := ItemCatalog.new()
	var inventory := InventoryData.new()
	var sword := catalog.get_item("iron_longsword")
	var want := [
		["rune", 0], ["core_gem", 0], ["aux_gem", 0],
		["rune", 1], ["core_gem", 1], ["aux_gem", 1],
	]
	var rows := inventory.list_socket_rows(sword)
	if rows.size() != want.size():
		push_error("weapon socket rows want %d got %d" % [want.size(), rows.size()])
		return 1
	for i in want.size():
		var kind := str(rows[i].get("kind", ""))
		var index := int(rows[i].get("index", -1))
		if kind != want[i][0] or index != want[i][1]:
			push_error("socket row %d want %s %d got %s %d" % [
				i, want[i][0], want[i][1], kind, index
			])
			return 1
	var ring := catalog.get_item("moss_ring")
	var ring_rows := inventory.list_socket_rows(ring)
	if ring_rows.size() != 1 or str(ring_rows[0].get("kind", "")) != "core_gem":
		push_error("ring must list one core gem row")
		return 1
	return 0


func _test_equipped_rune_list() -> int:
	var catalog := ItemCatalog.new()
	var rune_cat := RuneCatalog.new()
	var gem_cat := GemCatalog.new()
	var inventory := InventoryData.new()
	var sword := catalog.get_item("iron_longsword")
	var coat := catalog.get_item("traveler_coat")
	var ring := catalog.get_item("moss_ring")
	inventory.equipped["main_hand"] = sword
	inventory.equipped["chest"] = coat
	inventory.equipped["ring_1"] = ring
	var r0 := RuneInstance.create("counter_verse")
	var r1 := RuneInstance.create("hymn_verse")
	if not inventory.try_add_rune(r0) or not inventory.try_add_rune(r1):
		push_error("try_add_rune failed")
		return 1
	if not inventory.socket_rune_on_item(sword, r0.instance_uid, 0):
		push_error("socket sword rune failed")
		return 1
	if not inventory.socket_rune_on_item(coat, r1.instance_uid, 0):
		push_error("socket coat rune failed")
		return 1
	if inventory.socket_rune_on_item(ring, r1.instance_uid, 0):
		push_error("ring must not accept runes")
		return 1
	var service := ResonanceService.new()
	var listed: Array = service.list_equipped_rune_skills(inventory, rune_cat, gem_cat)
	if listed.size() != 2:
		push_error("equipped rune list want 2 got %d" % listed.size())
		return 1
	if str(listed[0].get("rune_id", "")) != "counter_verse":
		push_error("list[0] want counter_verse got %s" % listed[0].get("rune_id", ""))
		return 1
	if str(listed[1].get("rune_id", "")) != "hymn_verse":
		push_error("list[1] want hymn_verse got %s" % listed[1].get("rune_id", ""))
		return 1
	if not ResonanceService.ACTIVE_KINDS.has(str(listed[0].get("kind", ""))):
		push_error("weapon rune must be active kind")
		return 1
	if ResonanceService.ACTIVE_KINDS.has(str(listed[1].get("kind", ""))):
		push_error("chest hymn must not be active kind")
		return 1
	if inventory.find_rune(r0.instance_uid) != null or inventory.find_rune(r1.instance_uid) != null:
		push_error("equipped runes must not stay in the bag")
		return 1
	if not inventory.unsocket(sword, "rune", 0):
		push_error("unsocket sword rune failed")
		return 1
	if inventory.find_rune(r0.instance_uid) == null:
		push_error("unsocket must return rune to the bag")
		return 1
	return 0
