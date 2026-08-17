extends SceneTree

# Run: godot --headless --path . -s res://data/combat/verify_combat_stats_builder.gd
# Exits 0 on success.


func _initialize() -> void:
	var failed := 0
	failed += _test_naked_attrs_do_not_raise_combat()
	failed += _test_circlet_evasion_ignores_dex()
	failed += _test_dex_scales_needle()
	failed += _test_str_int_do_not_scale_needle()
	failed += _test_dex_scales_dex_weapon()
	failed += _test_armor_defense_from_item()
	failed += _test_thorn_retaliation_ignores_str()
	failed += _test_codex_magic_damage_ignores_int()
	failed += _test_bloodseal_vampirism()
	failed += _test_stat_desc_locale_keys()
	if failed == 0:
		print("COMBAT_STATS_BUILDER_VERIFY_OK")
		quit(0)
	else:
		push_error("COMBAT_STATS_BUILDER_VERIFY_FAILED: %d" % failed)
		quit(1)


func _test_naked_attrs_do_not_raise_combat() -> int:
	var character := _character(40, 40, 40)
	var out := CombatStatsBuilder.build(character, null)
	if out.attack_speed != 0.0 or out.evasion != 0.0 or out.crit_chance != 0.0 or out.counter_chance != 0.0:
		push_error("naked attrs must not raise combat rates")
		return 1
	if not is_equal_approx(out.defense, 0.0):
		push_error("naked defense want 0 got %s" % out.defense)
		return 1
	if not is_equal_approx(out.retaliation, 0.0):
		push_error("naked retaliation want 0 got %s" % out.retaliation)
		return 1
	if not is_equal_approx(out.magic_damage, 0.0):
		push_error("naked magic_damage want 0 got %s" % out.magic_damage)
		return 1
	if not is_equal_approx(out.vampirism, 0.0):
		push_error("naked vampirism want 0 got %s" % out.vampirism)
		return 1
	if not is_equal_approx(out.regen_per_sec, 0.0):
		push_error("naked regen want 0 got %s" % out.regen_per_sec)
		return 1
	if out.magic_hp != 0:
		push_error("naked magic_hp want 0 got %d" % out.magic_hp)
		return 1
	return 0


func _test_circlet_evasion_ignores_dex() -> int:
	var catalog := ItemCatalog.new()
	var character := _character(40, 10)
	var inventory := InventoryData.new()
	inventory.equipped["head"] = catalog.get_item("watcher_circlet")
	var out := CombatStatsBuilder.build(character, inventory)
	if not is_equal_approx(out.evasion, 0.06):
		push_error("circlet evasion want 0.06 got %s" % out.evasion)
		return 1
	if out.attack_speed != 0.0 or out.crit_chance != 0.0 or out.counter_chance != 0.0:
		push_error("circlet must not leak other DEX rates")
		return 1
	return 0


func _test_dex_scales_needle() -> int:
	var catalog := ItemCatalog.new()
	var needle := catalog.get_item("widows_needle")
	if needle == null:
		push_error("missing widows_needle")
		return 1
	var low := CombatStatsBuilder.build(_character(10, 10), _equipped("main_hand", needle))
	var high := CombatStatsBuilder.build(_character(40, 10), _equipped("main_hand", needle.duplicate(true)))
	if high.damage_max <= low.damage_max:
		push_error("DEX needle damage must rise (%d vs %d)" % [low.damage_max, high.damage_max])
		return 1
	return 0


func _test_str_int_do_not_scale_needle() -> int:
	var catalog := ItemCatalog.new()
	var needle := catalog.get_item("widows_needle")
	if needle == null:
		push_error("missing widows_needle")
		return 1
	var base := CombatStatsBuilder.build(_character(10, 10, 10), _equipped("main_hand", needle))
	var str_high := CombatStatsBuilder.build(_character(10, 40, 10), _equipped("main_hand", needle.duplicate(true)))
	var int_high := CombatStatsBuilder.build(_character(10, 10, 40), _equipped("main_hand", needle.duplicate(true)))
	if str_high.damage_max != base.damage_max:
		push_error("STR must not change needle damage (%d vs %d)" % [base.damage_max, str_high.damage_max])
		return 1
	if int_high.damage_max != base.damage_max:
		push_error("INT must not change needle damage (%d vs %d)" % [base.damage_max, int_high.damage_max])
		return 1
	return 0


func _test_dex_scales_dex_weapon() -> int:
	var catalog := ItemCatalog.new()
	var sword := catalog.get_item("blood_rusted_sword")
	if sword == null:
		push_error("missing blood_rusted_sword")
		return 1
	var low := CombatStatsBuilder.build(_character(10, 10), _equipped("main_hand", sword))
	var high := CombatStatsBuilder.build(_character(40, 10), _equipped("main_hand", sword.duplicate(true)))
	if high.damage_max <= low.damage_max:
		push_error("DEX weapon damage must rise (%d vs %d)" % [low.damage_max, high.damage_max])
		return 1
	return 0


func _test_armor_defense_from_item() -> int:
	var catalog := ItemCatalog.new()
	var cap := catalog.get_item("leather_cap")
	if cap == null:
		push_error("missing leather_cap")
		return 1
	var low := CombatStatsBuilder.build(_character(10, 10), _equipped("head", cap))
	var high := CombatStatsBuilder.build(_character(10, 40), _equipped("head", cap.duplicate(true)))
	if not is_equal_approx(low.defense, 5.0) or not is_equal_approx(high.defense, 5.0):
		push_error("leather_cap defense want 5 got %s / %s" % [low.defense, high.defense])
		return 1
	return 0


func _test_thorn_retaliation_ignores_str() -> int:
	var catalog := ItemCatalog.new()
	var legs := catalog.get_item("thorn_chausses")
	if legs == null:
		push_error("missing thorn_chausses")
		return 1
	var low := CombatStatsBuilder.build(_character(10, 10), _equipped("legs", legs))
	var high := CombatStatsBuilder.build(_character(10, 40), _equipped("legs", legs.duplicate(true)))
	if not is_equal_approx(low.retaliation, 1.2) or not is_equal_approx(high.retaliation, 1.2):
		push_error("thorn retaliation want 1.2 got %s / %s" % [low.retaliation, high.retaliation])
		return 1
	return 0


func _test_codex_magic_damage_ignores_int() -> int:
	var catalog := ItemCatalog.new()
	var codex := catalog.get_item("ash_codex")
	if codex == null:
		push_error("missing ash_codex")
		return 1
	var low := CombatStatsBuilder.build(_character(10, 10, 10), _equipped("off_hand", codex))
	var high := CombatStatsBuilder.build(_character(10, 10, 40), _equipped("off_hand", codex.duplicate(true)))
	if not is_equal_approx(low.magic_damage, 4.0) or not is_equal_approx(high.magic_damage, 4.0):
		push_error("codex magic_damage want 4 got %s / %s" % [low.magic_damage, high.magic_damage])
		return 1
	return 0


func _test_bloodseal_vampirism() -> int:
	var catalog := ItemCatalog.new()
	var ring := catalog.get_item("bloodseal_ring")
	if ring == null:
		push_error("missing bloodseal_ring")
		return 1
	var out := CombatStatsBuilder.build(_character(10, 10), _equipped("ring_1", ring))
	if not is_equal_approx(out.vampirism, 0.06):
		push_error("bloodseal vampirism want 0.06 got %s" % out.vampirism)
		return 1
	return 0


func _test_stat_desc_locale_keys() -> int:
	var csv_keys := _ui_string_keys()
	if csv_keys.is_empty():
		push_error("ui_strings.csv missing or empty")
		return 1
	var needed := PackedStringArray([
		"health",
		"stamina",
		"stamina_regen",
		"focus",
		"focus_gain",
		"damage",
		"attack_speed",
		"crit_chance",
		"crit_damage",
		"magic_damage",
		"damage_all",
		"vampirism",
		"regen_per_sec",
		"counter_chance",
		"evasion",
		"magic_hp",
		"retaliation",
		"defense",
	])
	var failed := 0
	for stat_key in needed:
		var key := "STAT_DESC_%s" % stat_key
		if not csv_keys.has(key):
			push_error("missing locale key %s" % key)
			failed += 1
	return 1 if failed > 0 else 0


func _ui_string_keys() -> Dictionary:
	var file := FileAccess.open("res://locale/ui_strings.csv", FileAccess.READ)
	if file == null:
		return {}
	var keys := {}
	file.get_csv_line()
	while not file.eof_reached():
		var cols := file.get_csv_line()
		if cols.is_empty() or cols[0].is_empty():
			continue
		keys[cols[0]] = true
	return keys


func _character(dexterity: int, strength: int, intelligence: int = 10) -> CharacterStats:
	var character: CharacterStats = load("res://ui/stats/resources/character_stats.tres").duplicate(true)
	character.attributes["dexterity"] = dexterity
	character.attributes["strength"] = strength
	character.attributes["intelligence"] = intelligence
	character.recalculate_derived()
	return character


func _equipped(slot_id: String, item: ItemData) -> InventoryData:
	var inventory := InventoryData.new()
	inventory.equipped[slot_id] = item
	return inventory
