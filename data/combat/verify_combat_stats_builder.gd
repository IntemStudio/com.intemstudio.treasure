extends SceneTree

# Run: godot --headless --path . -s res://data/combat/verify_combat_stats_builder.gd
# Exits 0 on success.


func _initialize() -> void:
	var failed := 0
	failed += _test_dex_rates_from_affix_only()
	failed += _test_circlet_evasion_ignores_dex()
	failed += _test_dex_does_not_scale_faith_weapon()
	failed += _test_dex_scales_dex_weapon()
	failed += _test_stat_desc_locale_keys()
	if failed == 0:
		print("COMBAT_STATS_BUILDER_VERIFY_OK")
		quit(0)
	else:
		push_error("COMBAT_STATS_BUILDER_VERIFY_FAILED: %d" % failed)
		quit(1)


func _test_dex_rates_from_affix_only() -> int:
	var character := _character(40, 15)
	var out := CombatStatsBuilder.build(character, null)
	if out.attack_speed != 0.0 or out.evasion != 0.0 or out.crit_chance != 0.0 or out.counter_chance != 0.0:
		push_error("naked DEX 40 must not raise combat rates")
		return 1
	if not is_equal_approx(out.defense, 5.0):
		push_error("STR 15 defense want 5 got %s" % out.defense)
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


func _test_dex_does_not_scale_faith_weapon() -> int:
	var catalog := ItemCatalog.new()
	var needle := catalog.get_item("widows_needle")
	if needle == null:
		push_error("missing widows_needle")
		return 1
	var low := CombatStatsBuilder.build(_character(10, 10), _main_hand(needle))
	var high := CombatStatsBuilder.build(_character(40, 10), _main_hand(needle.duplicate(true)))
	if low.damage_max != high.damage_max:
		push_error("DEX must not change faith weapon damage (%d vs %d)" % [low.damage_max, high.damage_max])
		return 1
	return 0


func _test_dex_scales_dex_weapon() -> int:
	var catalog := ItemCatalog.new()
	var sword := catalog.get_item("blood_rusted_sword")
	if sword == null:
		push_error("missing blood_rusted_sword")
		return 1
	var low := CombatStatsBuilder.build(_character(10, 10), _main_hand(sword))
	var high := CombatStatsBuilder.build(_character(40, 10), _main_hand(sword.duplicate(true)))
	if high.damage_max <= low.damage_max:
		push_error("DEX weapon damage must rise (%d vs %d)" % [low.damage_max, high.damage_max])
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


func _character(dexterity: int, strength: int) -> CharacterStats:
	var character: CharacterStats = load("res://ui/stats/resources/character_stats.tres").duplicate(true)
	character.attributes["dexterity"] = dexterity
	character.attributes["strength"] = strength
	character.recalculate_derived()
	return character


func _main_hand(item: ItemData) -> InventoryData:
	var inventory := InventoryData.new()
	inventory.equipped["main_hand"] = item
	return inventory
