extends SceneTree

# Run: godot --headless --path . -s res://save/verify_save_v1.gd
# Exits 0 on success.


func _initialize() -> void:
	var failed := 0
	failed += _test_roundtrip()
	failed += _test_unknown_item()
	failed += _test_faith_refund()
	failed += _test_slot_io()
	failed += _test_no_run_or_locale_keys()
	failed += _test_socketed_not_in_bag()
	failed += _test_legacy_socketed_migrate()
	if failed == 0:
		print("SAVE_V1_VERIFY_OK")
		quit(0)
	else:
		push_error("SAVE_V1_VERIFY_FAILED: %d" % failed)
		quit(1)


func _test_roundtrip() -> int:
	var catalog := ItemCatalog.new()
	var character: CharacterStats = load("res://ui/stats/resources/character_stats.tres").duplicate(true)
	character.level = 7
	character.xp = 42
	character.attribute_points = 0
	character.attributes["strength"] = 15
	character.recalculate_derived()
	character.mana = mini(character.mana_max - 5, character.mana_max)
	var inventory := ItemBootstrap.create_sample_inventory()
	inventory.equipped["main_hand"] = catalog.get_item("claymore")
	inventory.equipped["main_hand"].durability = 87
	inventory.quick_item = catalog.get_item("health_potion")
	inventory.quick_item.quantity = 7
	inventory.quick_food = catalog.get_item("dried_fish")
	inventory.quick_food.quantity = 2
	var potion := catalog.get_item("health_potion")
	potion.quantity = 5
	inventory.set_item(InventoryData.BAG_CONSUMABLE, 0, potion)

	var meta := {"slot": 0, "level": character.level}
	var data := SaveSerializer.to_dict(character, inventory, meta)
	var save := SaveSerializer.from_dict(data, catalog)
	if save.character.level != 7:
		push_error("level mismatch")
		return 1
	if save.character.xp != 42:
		push_error("xp mismatch")
		return 1
	if int(save.character.attributes["strength"]) != 15:
		push_error("strength mismatch")
		return 1
	if save.character.mana != character.mana or save.character.mana_max != character.mana_max:
		push_error("mana mismatch")
		return 1
	var loaded_main: ItemData = save.inventory.equipped.get("main_hand")
	if loaded_main == null or loaded_main.id != "claymore" or loaded_main.durability != 87:
		push_error("equipped claymore mismatch")
		return 1
	if save.inventory.quick_item == null or save.inventory.quick_item.id != "health_potion" or save.inventory.quick_item.quantity != 7:
		push_error("quick_item mismatch")
		return 1
	if save.inventory.quick_food == null or save.inventory.quick_food.id != "dried_fish" or save.inventory.quick_food.quantity != 2:
		push_error("quick_food mismatch")
		return 1
	var qty_ok := false
	for item in save.inventory.get_bag(InventoryData.BAG_CONSUMABLE):
		if item and item.id == "health_potion" and item.quantity == 5:
			qty_ok = true
	if not qty_ok:
		push_error("potion quantity mismatch")
		return 1
	return 0


func _test_unknown_item() -> int:
	var catalog := ItemCatalog.new()
	var data := {
		"version": 1,
		"meta": {},
		"character": {},
		"inventory": {
			"bags": {
				"consumable": [{"index": 0, "item": {"id": "does_not_exist", "quantity": 1}}],
			},
			"equipped": {},
		},
	}
	var save := SaveSerializer.from_dict(data, catalog)
	if save.inventory.get_item(InventoryData.BAG_CONSUMABLE, 0) != null:
		push_error("unknown item should clear slot")
		return 1
	return 0


func _test_faith_refund() -> int:
	var catalog := ItemCatalog.new()
	var data := {
		"version": 1,
		"meta": {},
		"character": {
			"attribute_points": 0,
			"attributes": {"faith": 18, "strength": 10},
		},
		"inventory": {"bags": {}, "equipped": {}},
	}
	var save := SaveSerializer.from_dict(data, catalog)
	if save.character.attributes.has("faith"):
		push_error("faith must not load")
		return 1
	if save.character.attribute_points != 8:
		push_error("faith refund want 8 got %d" % save.character.attribute_points)
		return 1
	return 0


func _test_slot_io() -> int:
	var sm = get_root().get_node("SaveManager")
	var slot := 0
	sm.delete_slot(slot)
	var sg: SaveGame = sm.new_game(slot)
	if sg == null:
		push_error("new_game failed")
		return 1
	sg.character.level = 9
	sg.character.xp = 11
	var err: Error = sm.save_game(slot, sg.character, sg.inventory)
	if err != OK:
		push_error("save_game failed")
		return 1
	var loaded: SaveGame = sm.load_game(slot)
	if loaded == null or loaded.character.level != 9 or loaded.character.xp != 11:
		push_error("load_game mismatch")
		return 1
	var info: Dictionary = sm.get_slot_info(slot)
	if info.get("status") != "valid":
		push_error("slot info not valid")
		return 1
	sm.delete_slot(slot)
	if sm.has_save(slot):
		push_error("delete_slot failed")
		return 1
	return 0


func _test_no_run_or_locale_keys() -> int:
	var catalog := ItemCatalog.new()
	var character: CharacterStats = load("res://ui/stats/resources/character_stats.tres").duplicate(true)
	var inventory := ItemBootstrap.create_sample_inventory()
	var data := SaveSerializer.to_dict(character, inventory, {"slot": 0})
	if data.has("run") or data.has("locale"):
		push_error("save must not contain run/locale")
		return 1
	if not data.has("version") or not data.has("meta") or not data.has("character") or not data.has("inventory"):
		push_error("missing required keys")
		return 1
	return 0


func _test_socketed_not_in_bag() -> int:
	var catalog := ItemCatalog.new()
	var character: CharacterStats = load("res://ui/stats/resources/character_stats.tres").duplicate(true)
	var inventory := InventoryData.new()
	var sword := catalog.get_item("iron_longsword")
	inventory.equipped["main_hand"] = sword
	var ri := RuneInstance.create("counter_verse")
	if not inventory.try_add_rune(ri):
		push_error("try_add_rune failed")
		return 1
	if not inventory.socket_rune_on_item(sword, ri.instance_uid, 0):
		push_error("socket failed")
		return 1
	var data := SaveSerializer.to_dict(character, inventory, {})
	var saved_runes: Array = (data.get("inventory", {}) as Dictionary).get("runes", [])
	if not saved_runes.is_empty():
		push_error("saved runes[] must omit socketed")
		return 1
	var save := SaveSerializer.from_dict(data, catalog)
	if save.inventory.find_rune(ri.instance_uid) != null:
		push_error("loaded bag still has socketed rune")
		return 1
	var loaded: ItemData = save.inventory.equipped.get("main_hand") as ItemData
	if loaded == null or loaded.socketed.is_empty():
		push_error("loaded sword missing socketed")
		return 1
	if str(loaded.socketed[0].get("rune_id", "")) != "counter_verse":
		push_error("loaded socketed missing rune_id")
		return 1
	if loaded.skills.is_empty():
		push_error("loaded sword skills empty")
		return 1
	return 0


func _test_legacy_socketed_migrate() -> int:
	var catalog := ItemCatalog.new()
	var ri := RuneInstance.create("counter_verse")
	var data := {
		"version": 1,
		"meta": {},
		"character": {},
		"inventory": {
			"bags": {},
			"equipped": {
				"main_hand": {
					"id": "iron_longsword",
					"socketed": [{
						"kind": "rune",
						"index": 0,
						"instance_uid": ri.instance_uid,
					}],
				},
			},
			"runes": [ri.to_dict()],
			"gems": [],
		},
	}
	var save := SaveSerializer.from_dict(data, catalog)
	if save.inventory.find_rune(ri.instance_uid) != null:
		push_error("legacy migrate left rune in bag")
		return 1
	var sword: ItemData = save.inventory.equipped.get("main_hand") as ItemData
	if sword == null or sword.socketed.is_empty():
		push_error("legacy migrate missing socketed")
		return 1
	if str(sword.socketed[0].get("rune_id", "")) != "counter_verse":
		push_error("legacy migrate missing rune_id on item")
		return 1
	return 0
