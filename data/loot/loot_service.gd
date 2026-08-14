class_name LootService
extends RefCounted

const TABLE_PATH := "res://data/loot/loot_table.tres"
const OFFER_COUNT := 3

static var _table: LootTable


static func default_table() -> LootTable:
	if _table == null:
		_table = load(TABLE_PATH) as LootTable
	if _table == null:
		_table = LootTable.new()
	return _table


## Legacy auto-grant (unused by EncounterDirector after loot choice).
## ctx: room_type, seed, cell
## returns { granted: Array[ItemData], skipped: int }
static func grant(
	inventory: InventoryData,
	catalog: ItemCatalog,
	table: LootTable,
	ctx: Dictionary
) -> Dictionary:
	var granted: Array[ItemData] = []
	var skipped := 0
	var empty_result := {"granted": granted, "skipped": skipped}
	if inventory == null or catalog == null:
		return empty_result
	var loot_table := table if table else default_table()
	if loot_table == null:
		return empty_result

	var room_type := int(ctx.get("room_type", RoomData.RoomType.NORMAL))
	var seed_value := int(ctx.get("seed", 0))
	var cell: Vector2i = ctx.get("cell", Vector2i.ZERO) as Vector2i

	var rng := RandomNumberGenerator.new()
	rng.seed = hash([seed_value, cell.x, cell.y])

	var span := loot_table.count_range_for(room_type)
	var count_min := mini(span.x, span.y)
	var count_max := maxi(span.x, span.y)
	var count := rng.randi_range(count_min, count_max)
	if count <= 0:
		return empty_result

	var equipment_pool := catalog.ids_for_categories([
		ItemData.ItemCategory.WEAPON,
		ItemData.ItemCategory.ARMOR,
	])

	for i in count:
		var kind := loot_table.pick_kind(rng)
		if kind != LootTable.LootKind.EQUIPMENT:
			continue
		if equipment_pool.is_empty():
			skipped += count - i
			break
		var slot_index := inventory.find_empty_slot(InventoryData.BAG_EQUIPMENT)
		if slot_index < 0:
			skipped += count - i
			break
		var item_id: String = equipment_pool[rng.randi() % equipment_pool.size()]
		var item := catalog.get_item(item_id)
		if item == null:
			continue
		inventory.set_item(InventoryData.BAG_EQUIPMENT, slot_index, item)
		granted.append(item)

	return {"granted": granted, "skipped": skipped}


## ctx: seed (int), cell (Vector2i), card_meta (Dictionary) — rune/gem pool uses open_cards
## returns Array of { kind, id, item?, rune?, gem? }
static func roll_offers(
	reward_type: int,
	catalog: ItemCatalog,
	rune_catalog: RuneCatalog,
	gem_catalog: GemCatalog,
	ctx: Dictionary
) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if reward_type == RoomData.RewardType.NONE:
		return out
	var seed_value := int(ctx.get("seed", 0))
	var cell: Vector2i = ctx.get("cell", Vector2i.ZERO) as Vector2i
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([seed_value, cell.x, cell.y, "offers"])

	var pool := _pool_ids(reward_type, catalog, rune_catalog, gem_catalog, ctx)
	if pool.is_empty():
		return out

	var picked: Array[String] = []
	var attempts := 0
	while picked.size() < OFFER_COUNT and attempts < OFFER_COUNT * 8:
		attempts += 1
		var id: String = pool[rng.randi() % pool.size()]
		if picked.has(id) and pool.size() >= OFFER_COUNT:
			continue
		picked.append(id)

	while picked.size() < OFFER_COUNT:
		picked.append(pool[rng.randi() % pool.size()])

	for id in picked:
		var offer := _make_offer(reward_type, id, catalog, rune_catalog, gem_catalog)
		if not offer.is_empty():
			out.append(offer)
	return out


static func take_offer(inventory: InventoryData, offer: Dictionary) -> Dictionary:
	var empty := {"ok": false, "granted_name": "", "skipped": 0, "granted": []}
	if inventory == null or offer.is_empty():
		return empty
	var kind := str(offer.get("kind", ""))
	match kind:
		"weapon", "armor":
			var item: ItemData = offer.get("item") as ItemData
			if item == null:
				return empty
			var copy := item.duplicate(true) as ItemData
			if inventory.try_place_item(copy) < 0:
				return {
					"ok": false,
					"granted_name": item.display_name,
					"skipped": 1,
					"granted": [],
				}
			return {
				"ok": true,
				"granted_name": copy.display_name,
				"skipped": 0,
				"granted": [copy],
			}
		"rune":
			var rune_id := str(offer.get("id", ""))
			if rune_id.is_empty():
				return empty
			var ri := RuneInstance.create(rune_id)
			if not inventory.try_add_rune(ri):
				return {
					"ok": false,
					"granted_name": rune_id,
					"skipped": 1,
					"granted": [],
				}
			var rname := ""
			var rd: RuneData = offer.get("rune") as RuneData
			if rd:
				rname = rd.display_name
			else:
				rname = rune_id
			return {
				"ok": true,
				"granted_name": rname,
				"skipped": 0,
				"granted": [],
			}
		"gem":
			var gem_id := str(offer.get("id", ""))
			if gem_id.is_empty():
				return empty
			var gi := GemInstance.create(gem_id)
			if not inventory.try_add_gem(gi):
				return {
					"ok": false,
					"granted_name": gem_id,
					"skipped": 1,
					"granted": [],
				}
			var gname := ""
			var gd: GemData = offer.get("gem") as GemData
			if gd:
				gname = gd.display_name
			else:
				gname = gem_id
			return {
				"ok": true,
				"granted_name": gname,
				"skipped": 0,
				"granted": [],
			}
		_:
			return empty


static func offer_needs_inventory_slot(offer: Dictionary) -> bool:
	var kind := str(offer.get("kind", ""))
	return kind == "weapon" or kind == "armor" or kind == "rune" or kind == "gem"


static func offer_inventory_full(inventory: InventoryData, offer: Dictionary) -> bool:
	if inventory == null or offer.is_empty():
		return true
	var kind := str(offer.get("kind", ""))
	match kind:
		"weapon", "armor":
			return inventory.find_empty_slot(InventoryData.BAG_EQUIPMENT) < 0
		"rune", "gem":
			return not inventory.can_add_modifier()
		_:
			return false


static func _pool_ids(
	reward_type: int,
	catalog: ItemCatalog,
	rune_catalog: RuneCatalog,
	gem_catalog: GemCatalog,
	ctx: Dictionary = {}
) -> Array[String]:
	match reward_type:
		RoomData.RewardType.WEAPON:
			if catalog == null:
				return []
			return catalog.ids_for_categories([ItemData.ItemCategory.WEAPON])
		RoomData.RewardType.ARMOR:
			if catalog == null:
				return []
			return catalog.ids_for_categories([ItemData.ItemCategory.ARMOR])
		RoomData.RewardType.RUNE:
			return CardRegistrationService.loot_pool_ids(_card_meta_from_ctx(ctx), "rune", rune_catalog)
		RoomData.RewardType.GEM:
			return CardRegistrationService.loot_pool_ids(_card_meta_from_ctx(ctx), "gem", gem_catalog)
		_:
			return []


static func _card_meta_from_ctx(ctx: Dictionary) -> Dictionary:
	if ctx.has("card_meta") and ctx["card_meta"] is Dictionary:
		return CardRegistrationService.ensure_meta(ctx["card_meta"] as Dictionary)
	if ctx.has("unlocked_shelves"):
		return CardRegistrationService.ensure_meta({"unlocked_shelves": ctx["unlocked_shelves"]})
	return CardRegistrationService.ensure_meta({})


static func _make_offer(
	reward_type: int,
	id: String,
	catalog: ItemCatalog,
	rune_catalog: RuneCatalog,
	gem_catalog: GemCatalog
) -> Dictionary:
	match reward_type:
		RoomData.RewardType.WEAPON:
			var item := catalog.get_item(id) if catalog else null
			if item == null:
				return {}
			return {"kind": "weapon", "id": id, "item": item, "rune": null, "gem": null}
		RoomData.RewardType.ARMOR:
			var armor := catalog.get_item(id) if catalog else null
			if armor == null:
				return {}
			return {"kind": "armor", "id": id, "item": armor, "rune": null, "gem": null}
		RoomData.RewardType.RUNE:
			var rune := rune_catalog.get_rune(id) if rune_catalog else null
			if rune == null:
				return {}
			return {"kind": "rune", "id": id, "item": null, "rune": rune, "gem": null}
		RoomData.RewardType.GEM:
			var gem := gem_catalog.get_gem(id) if gem_catalog else null
			if gem == null:
				return {}
			return {"kind": "gem", "id": id, "item": null, "rune": null, "gem": gem}
		_:
			return {}


static func reward_type_label_key(reward_type: int) -> String:
	match reward_type:
		RoomData.RewardType.WEAPON:
			return "LOOT_TYPE_WEAPON"
		RoomData.RewardType.ARMOR:
			return "LOOT_TYPE_ARMOR"
		RoomData.RewardType.RUNE:
			return "LOOT_TYPE_RUNE"
		RoomData.RewardType.GEM:
			return "LOOT_TYPE_GEM"
		_:
			return "LOOT_TYPE_NONE"
