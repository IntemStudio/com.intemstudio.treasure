extends SceneTree

# Run: godot --headless --path . -s res://ui/inventory/resources/verify_item_icons.gd
# Exits 0 on success.


func _initialize() -> void:
	var failed := 0
	failed += _test_sheet_slice()
	failed += _test_catalog_icons()
	failed += _test_skill_kind_icons()
	failed += _test_modifier_icons()
	failed += _test_ui_sheet_icons()
	if failed == 0:
		print("ITEM_ICONS_VERIFY_OK")
		quit(0)
	else:
		push_error("ITEM_ICONS_VERIFY_FAILED: %d" % failed)
		quit(1)


func _test_sheet_slice() -> int:
	if ItemData.ICON_SHEET == null:
		push_error("icon sheet missing")
		return 1
	if ItemData.ICON_SHEET.get_width() != 512 or ItemData.ICON_SHEET.get_height() != 4384:
		push_error("icon sheet size mismatch")
		return 1
	var tex := ItemData.sheet_icon(3, 0)
	if tex.region != Rect2(96, 0, 32, 32):
		push_error("sheet_icon region mismatch")
		return 1
	return 0


func _test_catalog_icons() -> int:
	var catalog := ItemCatalog.new()
	var checks := {
		"iron_longsword": Rect2(96, 3328, 32, 32),
		"health_potion": Rect2(256, 512, 32, 32),
		"dried_fish": Rect2(480, 1088, 32, 32),
		"fishing_rod": Rect2(288, 1792, 32, 32),
	}
	for item_id in checks:
		var item := catalog.get_item(item_id)
		if item == null or not (item.icon is AtlasTexture):
			push_error("catalog icon missing: %s" % item_id)
			return 1
		var atlas := item.icon as AtlasTexture
		if atlas.region != checks[item_id]:
			push_error("catalog icon region mismatch: %s" % item_id)
			return 1
	for item_id in catalog.ids_for_categories([
		ItemData.ItemCategory.WEAPON,
		ItemData.ItemCategory.ARMOR,
		ItemData.ItemCategory.CONSUMABLE,
		ItemData.ItemCategory.MATERIAL,
		ItemData.ItemCategory.TOOL,
	]):
		var item := catalog.get_item(item_id)
		if item == null or item.icon == null:
			push_error("catalog item has no icon: %s" % item_id)
			return 1
	return 0


func _test_skill_kind_icons() -> int:
	var strike := RuneData.icon_for_kind("strike") as AtlasTexture
	if strike == null or strike.region != Rect2(320, 2048, 32, 32):
		push_error("strike skill icon region mismatch")
		return 1
	var heal := RuneData.icon_for_kind("heal") as AtlasTexture
	if heal == null or heal.region != Rect2(256, 512, 32, 32):
		push_error("heal skill icon region mismatch")
		return 1
	return 0


func _test_modifier_icons() -> int:
	var runes := RuneCatalog.new()
	var flurry := runes.get_rune("flurry_verse")
	if flurry == null or flurry.icon == null:
		push_error("rune catalog icon missing")
		return 1
	var gems := GemCatalog.new()
	var frost := gems.get_gem("frostglass")
	if frost == null or frost.icon == null:
		push_error("gem catalog icon missing")
		return 1
	var frost_tex := frost.icon as AtlasTexture
	if frost_tex == null or frost_tex.region != Rect2(0, 320, 32, 32):
		push_error("frostglass icon region mismatch")
		return 1
	for rune_id in runes.all_ids():
		var rune := runes.get_rune(str(rune_id))
		if rune == null or rune.icon == null:
			push_error("rune has no icon: %s" % rune_id)
			return 1
	for gem_id in gems.all_ids():
		var gem := gems.get_gem(str(gem_id))
		if gem == null or gem.icon == null:
			push_error("gem has no icon: %s" % gem_id)
			return 1
	return 0


func _test_ui_sheet_icons() -> int:
	var slots := {
		"head": Rect2(128, 0, 32, 32),
		"chest": Rect2(0, 3840, 32, 32),
		"legs": Rect2(32, 4096, 32, 32),
		"main_hand": Rect2(96, 0, 32, 32),
		"off_hand": Rect2(96, 1280, 32, 32),
		"ring_1": Rect2(384, 4096, 32, 32),
		"tool_1": Rect2(32, 3072, 32, 32),
	}
	for slot_id in slots:
		var tex := ItemDefaults.icon_for_equip_slot(slot_id) as AtlasTexture
		if tex == null or tex.region != slots[slot_id]:
			push_error("equip silhouette region mismatch: %s" % slot_id)
			return 1
	var health := ItemData.sheet_icon(2, 41) as AtlasTexture
	if health == null or health.region != Rect2(64, 1312, 32, 32):
		push_error("health attribute icon region mismatch")
		return 1
	var equipment_tab := ItemData.sheet_icon(3, 0) as AtlasTexture
	if equipment_tab == null or equipment_tab.region != Rect2(96, 0, 32, 32):
		push_error("equipment tab icon region mismatch")
		return 1
	return 0
