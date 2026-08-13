class_name LootService
extends RefCounted

const TABLE_PATH := "res://data/loot/loot_table.tres"

static var _table: LootTable


static func default_table() -> LootTable:
	if _table == null:
		_table = load(TABLE_PATH) as LootTable
	if _table == null:
		_table = LootTable.new()
	return _table


## ctx: room_type (RoomData.RoomType), seed (int), cell (Vector2i)
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
			# v1: rune/gem/consumable weights are 0; skip if somehow selected.
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
