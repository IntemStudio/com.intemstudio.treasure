extends SceneTree

# Run: godot --headless --path . -s res://data/economy/verify_shop_pricing.gd
# Exits 0 on success.


func _initialize() -> void:
	var failed := 0
	failed += _test_catalog_buy_positive()
	failed += _test_same_template()
	failed += _test_known_prices()
	failed += _test_consumable_stack()
	failed += _test_rarity_raises_buy()
	failed += _test_durability_sell_only()
	failed += _test_save_roundtrip()
	failed += _test_can_sell()
	failed += _test_shop_buy_mult()
	if failed == 0:
		print("SHOP_PRICING_VERIFY_OK")
		quit(0)
	else:
		push_error("SHOP_PRICING_VERIFY_FAILED: %d" % failed)
		quit(1)


func _test_catalog_buy_positive() -> int:
	var catalog := ItemCatalog.new()
	var ids := catalog.ids_for_categories([
		ItemData.ItemCategory.WEAPON,
		ItemData.ItemCategory.ARMOR,
		ItemData.ItemCategory.CONSUMABLE,
		ItemData.ItemCategory.MATERIAL,
		ItemData.ItemCategory.TOOL,
	])
	if ids.is_empty():
		push_error("catalog empty")
		return 1
	for item_id in ids:
		var item := catalog.get_item(item_id)
		if ShopPricing.buy_price(item) <= 0:
			push_error("buy_price 0 for %s" % item_id)
			return 1
	return 0


func _test_same_template() -> int:
	var catalog := ItemCatalog.new()
	var a := catalog.get_item("iron_longsword")
	var b := catalog.get_item("iron_longsword")
	if ShopPricing.buy_price(a) != ShopPricing.buy_price(b):
		push_error("same template buy mismatch")
		return 1
	if ShopPricing.sell_price(a) != ShopPricing.sell_price(b):
		push_error("same template sell mismatch")
		return 1
	return 0


func _test_known_prices() -> int:
	var catalog := ItemCatalog.new()
	var sword := catalog.get_item("iron_longsword")
	if ShopPricing.buy_price(sword) != 96 or ShopPricing.sell_price(sword) != 38:
		push_error("iron_longsword want 96/38 got %d/%d" % [
			ShopPricing.buy_price(sword), ShopPricing.sell_price(sword)
		])
		return 1
	var plate := catalog.get_item("warplate")
	if ShopPricing.buy_price(plate) != 594 or ShopPricing.sell_price(plate) != 237:
		push_error("warplate want 594/237 got %d/%d" % [
			ShopPricing.buy_price(plate), ShopPricing.sell_price(plate)
		])
		return 1
	var potion := catalog.get_item("health_potion")
	if ShopPricing.buy_price(potion) != 15 or ShopPricing.sell_price(potion) != 3:
		push_error("health_potion want 15/3 got %d/%d" % [
			ShopPricing.buy_price(potion), ShopPricing.sell_price(potion)
		])
		return 1
	return 0


func _test_consumable_stack() -> int:
	var catalog := ItemCatalog.new()
	var potion := catalog.get_item("health_potion")
	potion.quantity = 3
	if ShopPricing.sell_price(potion) != 3:
		push_error("potion sell is per-unit")
		return 1
	if ShopPricing.sell_price(potion) * potion.quantity != 9:
		push_error("potion stack 3 total want 9")
		return 1
	return 0


func _test_rarity_raises_buy() -> int:
	var catalog := ItemCatalog.new()
	var item := catalog.get_item("iron_longsword")
	var common_buy := ShopPricing.buy_price(item)
	item.apply_rarity(ItemData.ItemRarity.RARE)
	if ShopPricing.buy_price(item) <= common_buy:
		push_error("rarity should raise buy")
		return 1
	return 0


func _test_durability_sell_only() -> int:
	var catalog := ItemCatalog.new()
	var item := catalog.get_item("iron_longsword")
	var buy := ShopPricing.buy_price(item)
	var sell := ShopPricing.sell_price(item)
	item.durability = item.durability_max / 2
	if ShopPricing.buy_price(item) != buy:
		push_error("durability must not change buy")
		return 1
	if ShopPricing.sell_price(item) != sell / 2:
		push_error("50%% durability sell want %d got %d" % [sell / 2, ShopPricing.sell_price(item)])
		return 1
	return 0


func _test_save_roundtrip() -> int:
	var catalog := ItemCatalog.new()
	var item := catalog.get_item("iron_longsword")
	item.durability = 50
	var buy := ShopPricing.buy_price(item)
	var sell := ShopPricing.sell_price(item)
	var d := SaveSerializer.item_to_dict(item)
	if d.has("cost") or d.has("gain"):
		push_error("item JSON must not contain cost/gain")
		return 1
	var loaded := SaveSerializer.item_from_dict(d, catalog)
	if ShopPricing.buy_price(loaded) != buy or ShopPricing.sell_price(loaded) != sell:
		push_error("save roundtrip price mismatch")
		return 1
	return 0


func _test_can_sell() -> int:
	var catalog := ItemCatalog.new()
	var inventory := InventoryData.new()
	inventory.ensure_grid_size()
	var equipped := catalog.get_item("iron_longsword")
	inventory.equipped["main_hand"] = equipped
	if ShopPricing.can_sell(equipped, inventory):
		push_error("equipped must not sell")
		return 1
	var bag := catalog.get_item("iron_longsword")
	if not ShopPricing.can_sell(bag, inventory):
		push_error("bag copy should sell")
		return 1
	bag.socketed = [{"kind": "rune", "index": 0, "instance_uid": "uid"}]
	if ShopPricing.can_sell(bag, inventory):
		push_error("socketed must not sell")
		return 1
	return 0


func _test_shop_buy_mult() -> int:
	var catalog := ItemCatalog.new()
	var item := catalog.get_item("iron_longsword")
	if ShopPricing.shop_buy_price(item) != ShopPricing.buy_price(item):
		push_error("shop_buy_mult 1.0 should match buy")
		return 1
	return 0
