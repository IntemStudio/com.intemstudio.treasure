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
		var slot_index := inventory.find_empty_slot()
		if slot_index < 0:
			skipped += count - i
			break
		var item_id: String = equipment_pool[rng.randi() % equipment_pool.size()]
		var item := catalog.get_item(item_id)
		if item == null:
			continue
		inventory.slots[slot_index] = item
		granted.append(item)

	return {"granted": granted, "skipped": skipped}


## ctx: seed (int), cell (Vector2i)
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

	var pool := _pool_ids(reward_type, catalog, rune_catalog, gem_catalog)
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
			var slot_index := inventory.find_empty_slot()
			if slot_index < 0:
				return {
					"ok": false,
					"granted_name": item.display_name,
					"skipped": 1,
					"granted": [],
				}
			var copy := item.duplicate(true) as ItemData
			inventory.ensure_grid_size()
			inventory.slots[slot_index] = copy
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
			inventory.runes.append(ri)
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
			inventory.gems.append(gi)
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
	return kind == "weapon" or kind == "armor"


static func _pool_ids(
	reward_type: int,
	catalog: ItemCatalog,
	rune_catalog: RuneCatalog,
	gem_catalog: GemCatalog
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
			var out: Array[String] = []
			if rune_catalog == null:
				return out
			for id in rune_catalog.all_ids():
				out.append(str(id))
			out.sort()
			return out
		RoomData.RewardType.GEM:
			var gout: Array[String] = []
			if gem_catalog == null:
				return gout
			for id in gem_catalog.all_ids():
				gout.append(str(id))
			gout.sort()
			return gout
		_:
			return []


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
