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

## Rune / gem bags (not ItemCategory grid).
var runes: Array = []
var gems: Array = []


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


func is_two_handed_equipped() -> bool:
	var main: ItemData = equipped.get("main_hand") as ItemData
	return main != null and main.is_two_handed()


func can_equip_from_bag(grid_index: int) -> bool:
	ensure_grid_size()
	if grid_index < 0 or grid_index >= slots.size():
		return false
	var item: ItemData = slots[grid_index]
	if item == null:
		return false
	var slot := get_slot_for_equip(item)
	if slot.is_empty():
		return false
	if item.is_two_handed():
		return _two_hand_bag_space_ok(grid_index)
	if slot == "off_hand" and is_two_handed_equipped():
		return _off_hand_replaces_two_hand_ok(grid_index)
	return true


func equip_from_bag(grid_index: int) -> bool:
	if not can_equip_from_bag(grid_index):
		return false
	var item: ItemData = slots[grid_index]
	if item.is_two_handed():
		var returning: Array[ItemData] = []
		var main: ItemData = equipped.get("main_hand") as ItemData
		var off: ItemData = equipped.get("off_hand") as ItemData
		if main:
			returning.append(main)
		if off:
			returning.append(off)
		slots[grid_index] = null
		equipped["main_hand"] = item
		equipped["off_hand"] = null
		for returned in returning:
			var idx := find_empty_slot()
			if idx < 0:
				return false
			slots[idx] = returned
		return true
	var slot := get_slot_for_equip(item)
	if slot == "off_hand" and is_two_handed_equipped():
		return _equip_off_hand_over_two_hand(grid_index, item)
	var previous: ItemData = equipped.get(slot) as ItemData
	equipped[slot] = item
	slots[grid_index] = previous
	return true


func _two_hand_bag_space_ok(grid_index: int) -> bool:
	var returning := 0
	if equipped.get("main_hand") != null:
		returning += 1
	if equipped.get("off_hand") != null:
		returning += 1
	return _bag_empty_count(grid_index) >= returning


func _off_hand_replaces_two_hand_ok(grid_index: int) -> bool:
	if equipped.get("off_hand") == null:
		return true
	return _bag_empty_count(grid_index) >= 2


func _equip_off_hand_over_two_hand(grid_index: int, item: ItemData) -> bool:
	var main: ItemData = equipped.get("main_hand") as ItemData
	var off: ItemData = equipped.get("off_hand") as ItemData
	slots[grid_index] = main
	equipped["main_hand"] = null
	equipped["off_hand"] = item
	if off:
		var idx := find_empty_slot()
		if idx < 0:
			return false
		slots[idx] = off
	return true


func _bag_empty_count(grid_index: int) -> int:
	var empty := 0
	for i in range(slots.size()):
		if slots[i] == null or i == grid_index:
			empty += 1
	return empty


func get_slot_for_equip(item: ItemData) -> String:
	if item == null:
		return ""
	var preferred := item.equip_slot
	if preferred != "":
		return _pair_slot_fallback(preferred)
	match item.category:
		ItemData.ItemCategory.WEAPON:
			return "main_hand"
		ItemData.ItemCategory.ARMOR:
			return "chest"
		ItemData.ItemCategory.TOOL:
			return _pair_slot_fallback("tool_1")
		_:
			return ""


func _pair_slot_fallback(preferred: String) -> String:
	var pair := ""
	match preferred:
		"ring_1":
			pair = "ring_2"
		"ring_2":
			pair = "ring_1"
		"tool_1":
			pair = "tool_2"
		"tool_2":
			pair = "tool_1"
		_:
			return preferred
	if equipped.get(preferred) == null:
		return preferred
	if equipped.get(pair) == null:
		return pair
	return preferred


func find_rune(uid: String) -> RuneInstance:
	for ri in runes:
		if ri is RuneInstance and (ri as RuneInstance).instance_uid == uid:
			return ri as RuneInstance
	return null


func find_gem(uid: String) -> GemInstance:
	for gi in gems:
		if gi is GemInstance and (gi as GemInstance).instance_uid == uid:
			return gi as GemInstance
	return null


func remove_rune_uid(uid: String) -> RuneInstance:
	for i in range(runes.size()):
		var ri: RuneInstance = runes[i] as RuneInstance
		if ri and ri.instance_uid == uid:
			runes.remove_at(i)
			_clear_socket_refs(uid)
			return ri
	return null


func remove_gem_uid(uid: String) -> GemInstance:
	for i in range(gems.size()):
		var gi: GemInstance = gems[i] as GemInstance
		if gi and gi.instance_uid == uid:
			gems.remove_at(i)
			_clear_socket_refs(uid)
			return gi
	return null


func _clear_socket_refs(uid: String) -> void:
	for slot_id in EQUIP_SLOTS:
		var item: ItemData = equipped.get(slot_id) as ItemData
		if item == null:
			continue
		var kept: Array[Dictionary] = []
		for entry in item.socketed:
			if entry is Dictionary and str(entry.get("instance_uid", "")) != uid:
				kept.append(entry)
		item.socketed = kept
	for item in slots:
		if item == null:
			continue
		var kept2: Array[Dictionary] = []
		for entry in item.socketed:
			if entry is Dictionary and str(entry.get("instance_uid", "")) != uid:
				kept2.append(entry)
		item.socketed = kept2


func socket_rune(equip_slot: String, rune_uid: String, index: int = 0) -> bool:
	if equip_slot != "main_hand":
		return false
	var item: ItemData = equipped.get(equip_slot) as ItemData
	var ri := find_rune(rune_uid)
	if item == null or ri == null or ri.registered:
		return false
	item.ensure_socket_layout()
	if item.socket_layout == null or index < 0 or index >= item.socket_layout.rune_slots:
		return false
	_set_socket(item, "rune", index, rune_uid)
	return true


func socket_gem(equip_slot: String, gem_uid: String, kind: String, index: int = 0) -> bool:
	var item: ItemData = equipped.get(equip_slot) as ItemData
	var gi := find_gem(gem_uid)
	if item == null or gi == null or gi.registered:
		return false
	item.ensure_socket_layout()
	if item.socket_layout == null:
		return false
	if kind == "core_gem":
		if index < 0 or index >= item.socket_layout.core_gem_slots:
			return false
	elif kind == "aux_gem":
		if index < 0 or index >= item.socket_layout.aux_gem_slots:
			return false
	else:
		return false
	_set_socket(item, kind, index, gem_uid)
	return true


func _set_socket(item: ItemData, kind: String, index: int, uid: String) -> void:
	var next: Array[Dictionary] = []
	for entry in item.socketed:
		if not entry is Dictionary:
			continue
		var d: Dictionary = entry
		if str(d.get("kind", "")) == kind and int(d.get("index", -1)) == index:
			continue
		if str(d.get("instance_uid", "")) == uid:
			continue
		next.append(d)
	next.append({"kind": kind, "index": index, "instance_uid": uid})
	item.socketed = next


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
