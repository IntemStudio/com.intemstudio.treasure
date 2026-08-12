class_name InventoryData
extends Resource

const GRID_SIZE := 30

const EQUIP_SLOTS: Array[String] = [
	"head", "chest", "legs", "main_hand", "off_hand",
	"ring_1", "ring_2", "tool_1", "tool_2",
]

@export var slots: Array[ItemData] = []
@export var equipped: Dictionary = {
	"head": null,
	"chest": null,
	"legs": null,
	"main_hand": null,
	"off_hand": null,
	"ring_1": null,
	"ring_2": null,
	"tool_1": null,
	"tool_2": null,
}
@export var currencies: Dictionary = {
	"gold": 1250,
	"silver": 340,
}
@export var quick_item: ItemData
@export var quick_food: ItemData
@export var current_category: ItemData.ItemCategory = ItemData.ItemCategory.WEAPON
@export var sort_mode: String = "time"


func ensure_grid_size() -> void:
	while slots.size() < GRID_SIZE:
		slots.append(null)


func get_items_for_category(category: ItemData.ItemCategory) -> Array:
	var result: Array = []
	ensure_grid_size()
	for i in range(slots.size()):
		var item: ItemData = slots[i]
		if item and item.category == category:
			result.append({"index": i, "item": item})
	return result


func find_empty_slot() -> int:
	ensure_grid_size()
	for i in range(slots.size()):
		if slots[i] == null:
			return i
	return -1


func get_slot_for_equip(item: ItemData) -> String:
	if item.equip_slot != "":
		return item.equip_slot
	match item.category:
		ItemData.ItemCategory.WEAPON:
			return "main_hand"
		ItemData.ItemCategory.ARMOR:
			return "chest"
		ItemData.ItemCategory.TOOL:
			return "tool_1" if equipped.get("tool_1") == null else "tool_2"
		_:
			return ""


func sort_slots() -> void:
	ensure_grid_size()
	var filtered: Array[ItemData] = []
	for item in slots:
		if item:
			filtered.append(item)
	match sort_mode:
		"name":
			filtered.sort_custom(func(a: ItemData, b: ItemData) -> bool:
				return a.display_name < b.display_name)
		"weight":
			filtered.sort_custom(func(a: ItemData, b: ItemData) -> bool:
				return a.weight < b.weight)
		"rarity":
			filtered.sort_custom(func(a: ItemData, b: ItemData) -> bool:
				return a.rarity > b.rarity)
	slots.clear()
	for item in filtered:
		slots.append(item)
	while slots.size() < GRID_SIZE:
		slots.append(null)
