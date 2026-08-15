extends SceneTree

# Run: godot --headless --path . -s res://ui/shared/verify_ui_colors.gd
# Exits 0 on success.


func _initialize() -> void:
	var failed := 0
	failed += _test_token_hex()
	failed += _test_rarity()
	failed += _test_ui_theme()
	failed += _test_game_log_colors()
	if failed == 0:
		print("UI_COLORS_VERIFY_OK")
		quit(0)
	else:
		push_error("UI_COLORS_VERIFY_FAILED: %d" % failed)
		quit(1)


func _test_token_hex() -> int:
	var checks := {
		"GOLD": ["#d79921", UIColors.GOLD],
		"TEXT_MAIN": ["#ebdbb2", UIColors.TEXT_MAIN],
		"TEXT_MUTED": ["#928374", UIColors.TEXT_MUTED],
		"SELECT_BORDER": ["#fabd2f", UIColors.SELECT_BORDER],
		"HP_FILL": ["#cc241d", UIColors.HP_FILL],
		"RARITY_RARE": ["#83a598", UIColors.RARITY_RARE],
		"RARITY_LEGENDARY": ["#fabd2f", UIColors.RARITY_LEGENDARY],
		"POSITIVE": ["#b8bb26", UIColors.POSITIVE],
		"NEGATIVE": ["#fb4934", UIColors.NEGATIVE],
	}
	var failed := 0
	if UIColors.PALETTE_ID != "gruvbox_dark":
		push_error("PALETTE_ID mismatch")
		failed += 1
	if UIColors.RARE_GLOW != UIColors.RARITY_RARE:
		push_error("RARE_GLOW alias mismatch")
		failed += 1
	for name in checks.keys():
		var expected: String = checks[name][0]
		var color: Color = checks[name][1]
		var got := UIColors.html(color)
		if got != expected:
			push_error("%s hex %s != %s" % [name, got, expected])
			failed += 1
	return failed


func _test_rarity() -> int:
	var pairs := [
		[ItemData.ItemRarity.COMMON, UIColors.RARITY_COMMON],
		[ItemData.ItemRarity.UNCOMMON, UIColors.RARITY_UNCOMMON],
		[ItemData.ItemRarity.RARE, UIColors.RARITY_RARE],
		[ItemData.ItemRarity.LEGENDARY, UIColors.RARITY_LEGENDARY],
	]
	var failed := 0
	for pair in pairs:
		var got := ItemData.color_for_rarity(pair[0])
		if got != pair[1]:
			push_error("rarity color mismatch %s" % pair[0])
			failed += 1
	return failed


func _test_ui_theme() -> int:
	var theme: Theme = load("res://ui/shared/themes/ui_theme.tres")
	if theme == null:
		push_error("ui_theme.tres missing")
		return 1
	var failed := 0
	var label_color: Color = theme.get_color("font_color", "Label")
	if not _approx(label_color, UIColors.TEXT_MAIN):
		push_error("theme Label font_color != TEXT_MAIN")
		failed += 1
	var selected: StyleBox = theme.get_stylebox("panel", "InventorySlotSelected")
	if selected is StyleBoxFlat:
		var flat := selected as StyleBoxFlat
		if not _approx(flat.border_color, UIColors.SELECT_BORDER):
			push_error("theme selected border != SELECT_BORDER")
			failed += 1
	else:
		push_error("InventorySlotSelected missing StyleBoxFlat")
		failed += 1
	for type_name in [
		"InventorySlot",
		"InventorySlotHover",
		"InventorySlotSelected",
		"EquipmentSlot",
		"EquipmentSlotHover",
	]:
		var box: StyleBox = theme.get_stylebox("panel", type_name)
		if not (box is StyleBoxFlat):
			push_error("%s missing StyleBoxFlat" % type_name)
			failed += 1
			continue
		var flat := box as StyleBoxFlat
		if flat.anti_aliasing:
			push_error("%s slot StyleBox anti_aliasing must be off" % type_name)
			failed += 1
		if (
			flat.border_width_left != 2
			or flat.border_width_top != 2
			or flat.border_width_right != 2
			or flat.border_width_bottom != 2
		):
			push_error("%s slot StyleBox border must be 2px" % type_name)
			failed += 1
	return failed


func _test_game_log_colors() -> int:
	var failed := 0
	if GameLogFormatter._color_hit() != UIColors.html(UIColors.NEGATIVE):
		push_error("log hit color != NEGATIVE")
		failed += 1
	if GameLogFormatter._color_crit() != UIColors.html(UIColors.GOLD):
		push_error("log crit color != GOLD")
		failed += 1
	if GameLogFormatter._color_heal() != UIColors.html(UIColors.POSITIVE):
		push_error("log heal color != POSITIVE")
		failed += 1
	if GameLogFormatter._color_system() != UIColors.html(UIColors.TEXT_MUTED):
		push_error("log system color != TEXT_MUTED")
		failed += 1
	return failed


func _approx(a: Color, b: Color, eps: float = 0.01) -> bool:
	return (
		absf(a.r - b.r) <= eps
		and absf(a.g - b.g) <= eps
		and absf(a.b - b.b) <= eps
		and absf(a.a - b.a) <= eps
	)
