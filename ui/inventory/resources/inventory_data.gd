class_name InventoryData
extends Resource

const GRID_SIZE := 25

const BAG_EQUIPMENT := "equipment"
const BAG_CONSUMABLE := "consumable"
const BAG_MATERIAL := "material"
const BAG_TOOL := "tool"
const BAG_KEYS: Array[String] = [
	BAG_EQUIPMENT,
	BAG_CONSUMABLE,
	BAG_MATERIAL,
	BAG_TOOL,
]

const EQUIP_SLOTS: Array[String] = [
	"head", "chest", "legs", "main_hand", "off_hand",
	"ring_1", "ring_2", "tool_1", "tool_2",
]

## Per-tab item bags (each GRID_SIZE). Loose runes[]/gems[] capped at GRID_SIZE. Socketed instances live on ItemData.socketed.
@export var bags: Dictionary = {}
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
var _socket_normalize: bool = false
@export var current_category: ItemData.ItemCategory = ItemData.ItemCategory.WEAPON
@export var sort_mode: String = "time"

## Rune / gem bags (not ItemCategory grids). Combined capacity = GRID_SIZE.
var runes: Array = []
var gems: Array = []


static func bag_key_for_category(category: ItemData.ItemCategory) -> String:
	match category:
		ItemData.ItemCategory.WEAPON, ItemData.ItemCategory.ARMOR:
			return BAG_EQUIPMENT
		ItemData.ItemCategory.CONSUMABLE:
			return BAG_CONSUMABLE
		ItemData.ItemCategory.MATERIAL:
			return BAG_MATERIAL
		ItemData.ItemCategory.TOOL:
			return BAG_TOOL
		_:
			return BAG_EQUIPMENT


func ensure_grid_size() -> void:
	for key in BAG_KEYS:
		if not bags.has(key) or not bags[key] is Array:
			bags[key] = []
		var bag: Array = bags[key]
		while bag.size() < GRID_SIZE:
			bag.append(null)
		if bag.size() > GRID_SIZE:
			while bag.size() > GRID_SIZE and bag[bag.size() - 1] == null:
				bag.pop_back()
			if bag.size() > GRID_SIZE:
				bag.resize(GRID_SIZE)
		bags[key] = bag
	if not _socket_normalize:
		ensure_socketed_on_items()


func get_bag(bag_key: String) -> Array:
	ensure_grid_size()
	if not BAG_KEYS.has(bag_key):
		return []
	return bags[bag_key] as Array


func bag_used_count(bag_key: String) -> int:
	var used := 0
	for item in get_bag(bag_key):
		if item:
			used += 1
	return used


func modifier_count() -> int:
	return runes.size() + gems.size()


func can_add_modifier() -> bool:
	return modifier_count() < GRID_SIZE


func find_empty_slot(bag_key: String) -> int:
	var bag := get_bag(bag_key)
	for i in range(bag.size()):
		if bag[i] == null:
			return i
	return -1


func find_empty_slot_for_category(category: ItemData.ItemCategory) -> int:
	return find_empty_slot(bag_key_for_category(category))


func find_empty_slot_for_item(item: ItemData) -> int:
	if item == null:
		return -1
	return find_empty_slot_for_category(item.category)


func try_place_item(item: ItemData) -> int:
	if item == null:
		return -1
	var key := bag_key_for_category(item.category)
	var idx := find_empty_slot(key)
	if idx < 0:
		return -1
	get_bag(key)[idx] = item
	return idx


func get_item(bag_key: String, index: int) -> ItemData:
	var bag := get_bag(bag_key)
	if index < 0 or index >= bag.size():
		return null
	return bag[index] as ItemData


func set_item(bag_key: String, index: int, item: ItemData) -> void:
	var bag := get_bag(bag_key)
	if index < 0 or index >= bag.size():
		return
	bag[index] = item


func is_two_handed_equipped() -> bool:
	var main: ItemData = equipped.get("main_hand") as ItemData
	return main != null and main.is_two_handed()


func can_equip_from_bag(bag_key: String, grid_index: int) -> bool:
	var item := get_item(bag_key, grid_index)
	if item == null:
		return false
	var slot := get_slot_for_equip(item)
	if slot.is_empty():
		return false
	if item.is_two_handed():
		return _two_hand_bag_space_ok(bag_key, grid_index)
	if slot == "off_hand" and is_two_handed_equipped():
		return _off_hand_replaces_two_hand_ok(bag_key, grid_index)
	return true


func equip_from_bag(bag_key: String, grid_index: int) -> bool:
	if not can_equip_from_bag(bag_key, grid_index):
		return false
	var bag := get_bag(bag_key)
	var item: ItemData = bag[grid_index] as ItemData
	if item.is_two_handed():
		var returning: Array[ItemData] = []
		var main: ItemData = equipped.get("main_hand") as ItemData
		var off: ItemData = equipped.get("off_hand") as ItemData
		if main:
			returning.append(main)
		if off:
			returning.append(off)
		bag[grid_index] = null
		equipped["main_hand"] = item
		equipped["off_hand"] = null
		for returned in returning:
			if try_place_item(returned) < 0:
				return false
		return true
	var slot := get_slot_for_equip(item)
	if slot == "off_hand" and is_two_handed_equipped():
		return _equip_off_hand_over_two_hand(bag_key, grid_index, item)
	var previous: ItemData = equipped.get(slot) as ItemData
	equipped[slot] = item
	bag[grid_index] = null
	if previous != null:
		if bag_key_for_category(previous.category) == bag_key:
			bag[grid_index] = previous
		elif try_place_item(previous) < 0:
			equipped[slot] = previous
			bag[grid_index] = item
			return false
	return true


func _two_hand_bag_space_ok(bag_key: String, grid_index: int) -> bool:
	var returning: Array[ItemData] = []
	var main: ItemData = equipped.get("main_hand") as ItemData
	var off: ItemData = equipped.get("off_hand") as ItemData
	if main:
		returning.append(main)
	if off:
		returning.append(off)
	return _can_return_items(returning, bag_key, grid_index)


func _off_hand_replaces_two_hand_ok(bag_key: String, grid_index: int) -> bool:
	var returning: Array[ItemData] = []
	var main: ItemData = equipped.get("main_hand") as ItemData
	var off: ItemData = equipped.get("off_hand") as ItemData
	if main:
		returning.append(main)
	if off:
		returning.append(off)
	return _can_return_items(returning, bag_key, grid_index)


func _equip_off_hand_over_two_hand(bag_key: String, grid_index: int, item: ItemData) -> bool:
	var bag := get_bag(bag_key)
	var main: ItemData = equipped.get("main_hand") as ItemData
	var off: ItemData = equipped.get("off_hand") as ItemData
	bag[grid_index] = null
	equipped["main_hand"] = null
	equipped["off_hand"] = item
	if main and try_place_item(main) < 0:
		return false
	if off and try_place_item(off) < 0:
		return false
	return true


func _can_return_items(items: Array[ItemData], free_bag: String, free_index: int) -> bool:
	var need: Dictionary = {}
	for item in items:
		if item == null:
			continue
		var key := bag_key_for_category(item.category)
		need[key] = int(need.get(key, 0)) + 1
	for key in need.keys():
		var empty := 0
		var bag := get_bag(str(key))
		for i in range(bag.size()):
			if bag[i] == null or (str(key) == free_bag and i == free_index):
				empty += 1
		if empty < int(need[key]):
			return false
	return true


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


func equipped_in_same_slot(item: ItemData) -> ItemData:
	var slot := get_slot_for_equip(item)
	if slot.is_empty():
		return null
	var current: ItemData = equipped.get(slot) as ItemData
	if current == null or current == item:
		return null
	return current


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


func try_add_rune(ri: RuneInstance) -> bool:
	if ri == null or not can_add_modifier():
		return false
	runes.append(ri)
	return true


func try_add_gem(gi: GemInstance) -> bool:
	if gi == null or not can_add_modifier():
		return false
	gems.append(gi)
	return true


func remove_rune_uid(uid: String) -> RuneInstance:
	var ri := _take_rune_from_bag(uid)
	if ri:
		_clear_socket_refs(uid)
	return ri


func remove_gem_uid(uid: String) -> GemInstance:
	var gi := _take_gem_from_bag(uid)
	if gi:
		_clear_socket_refs(uid)
	return gi


func _take_rune_from_bag(uid: String) -> RuneInstance:
	if uid.is_empty():
		return null
	for i in range(runes.size()):
		var ri: RuneInstance = runes[i] as RuneInstance
		if ri and ri.instance_uid == uid:
			runes.remove_at(i)
			return ri
	return null


func _take_gem_from_bag(uid: String) -> GemInstance:
	if uid.is_empty():
		return null
	for i in range(gems.size()):
		var gi: GemInstance = gems[i] as GemInstance
		if gi and gi.instance_uid == uid:
			gems.remove_at(i)
			return gi
	return null


func _iter_bag_items() -> Array[ItemData]:
	var out: Array[ItemData] = []
	ensure_grid_size()
	for key in BAG_KEYS:
		for item in bags[key]:
			if item is ItemData:
				out.append(item as ItemData)
	return out


func _gear_items() -> Array[ItemData]:
	var out: Array[ItemData] = []
	for slot_id in EQUIP_SLOTS:
		var item: ItemData = equipped.get(slot_id) as ItemData
		if item:
			out.append(item)
	for key in BAG_KEYS:
		if not bags.has(key) or not bags[key] is Array:
			continue
		for item in bags[key]:
			if item is ItemData:
				out.append(item as ItemData)
	return out


## Move socketed instances out of runes[]/gems[] onto ItemData.socketed. Old saves keep uid-only rows until this runs.
func ensure_socketed_on_items() -> void:
	if _socket_normalize:
		return
	_socket_normalize = true
	for item in _gear_items():
		if item == null:
			continue
		for entry in item.socketed:
			if not entry is Dictionary:
				continue
			var d: Dictionary = entry
			var uid := str(d.get("instance_uid", ""))
			if uid.is_empty():
				continue
			if str(d.get("rune_id", "")).is_empty():
				var ri := find_rune(uid)
				if ri:
					d["rune_id"] = ri.rune_id
					d["registered"] = ri.registered
			if str(d.get("gem_id", "")).is_empty():
				var gi := find_gem(uid)
				if gi:
					d["gem_id"] = gi.gem_id
					d["registered"] = gi.registered
			_take_rune_from_bag(uid)
			_take_gem_from_bag(uid)
	_socket_normalize = false


func _clear_socket_refs(uid: String) -> void:
	for item in _gear_items():
		var kept: Array[Dictionary] = []
		for entry in item.socketed:
			if entry is Dictionary and str(entry.get("instance_uid", "")) != uid:
				kept.append(entry)
		item.socketed = kept


func socket_rune(equip_slot: String, rune_uid: String, index: int = 0) -> bool:
	return socket_rune_on_item(equipped.get(equip_slot) as ItemData, rune_uid, index)


func socket_gem(equip_slot: String, gem_uid: String, kind: String, index: int = 0) -> bool:
	return socket_gem_on_item(equipped.get(equip_slot) as ItemData, gem_uid, kind, index)


func socket_rune_on_item(item: ItemData, rune_uid: String, index: int = 0) -> bool:
	if item == null:
		return false
	var ri := find_rune(rune_uid)
	if ri == null or ri.registered:
		return false
	item.ensure_socket_layout()
	if item.socket_layout == null or item.socket_layout.rune_slots <= 0:
		return false
	if index < 0 or index >= item.socket_layout.rune_slots:
		return false
	if not _socket_uid_on_item(item, "rune", index).is_empty():
		return false
	_set_socket(item, "rune", index, rune_uid, ri.rune_id, "", ri.registered)
	_take_rune_from_bag(rune_uid)
	return true


func socket_gem_on_item(item: ItemData, gem_uid: String, kind: String, index: int = 0) -> bool:
	if item == null:
		return false
	var gi := find_gem(gem_uid)
	if gi == null or gi.registered:
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
	if not _socket_uid_on_item(item, kind, index).is_empty():
		return false
	_set_socket(item, kind, index, gem_uid, "", gi.gem_id, gi.registered)
	_take_gem_from_bag(gem_uid)
	return true


func unsocket(item: ItemData, kind: String, index: int) -> bool:
	if item == null:
		return false
	var next: Array[Dictionary] = []
	var pulled: Dictionary = {}
	for entry in item.socketed:
		if not entry is Dictionary:
			continue
		var d: Dictionary = entry
		if str(d.get("kind", "")) == kind and int(d.get("index", -1)) == index:
			pulled = d
			continue
		next.append(d)
	if pulled.is_empty():
		return false
	if not _return_socket_entry_to_bag(pulled):
		return false
	item.socketed = next
	return true


func _return_socket_entry_to_bag(entry: Dictionary) -> bool:
	var uid := str(entry.get("instance_uid", ""))
	var rune_id := str(entry.get("rune_id", ""))
	if not rune_id.is_empty():
		if find_rune(uid):
			return true
		var ri := RuneInstance.from_dict({
			"instance_uid": uid,
			"rune_id": rune_id,
			"registered": bool(entry.get("registered", false)),
		})
		return try_add_rune(ri)
	var gem_id := str(entry.get("gem_id", ""))
	if not gem_id.is_empty():
		if find_gem(uid):
			return true
		var gi := GemInstance.from_dict({
			"instance_uid": uid,
			"gem_id": gem_id,
			"registered": bool(entry.get("registered", false)),
		})
		return try_add_gem(gi)
	return true


func find_socket(uid: String) -> Dictionary:
	if uid.is_empty():
		return {}
	for slot_id in EQUIP_SLOTS:
		var item: ItemData = equipped.get(slot_id) as ItemData
		var found := _find_socket_on_item(item, uid)
		if not found.is_empty():
			found["equip_slot"] = slot_id
			found["item"] = item
			return found
	for item in _iter_bag_items():
		var found2 := _find_socket_on_item(item, uid)
		if not found2.is_empty():
			found2["equip_slot"] = ""
			found2["item"] = item
			return found2
	return {}


func is_uid_socketed(uid: String) -> bool:
	return not find_socket(uid).is_empty()


func list_socket_rows(item: ItemData) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if item == null:
		return out
	item.ensure_socket_layout()
	if item.socket_layout == null:
		return out
	var layout: SocketLayout = item.socket_layout
	var n := maxi(layout.rune_slots, maxi(layout.core_gem_slots, layout.aux_gem_slots))
	for i in range(n):
		if i < layout.rune_slots:
			out.append(_socket_row_dict(item, "rune", i))
		if i < layout.core_gem_slots:
			out.append(_socket_row_dict(item, "core_gem", i))
		if i < layout.aux_gem_slots:
			out.append(_socket_row_dict(item, "aux_gem", i))
	return out


func empty_socket_rows(item: ItemData, kind_filter: String = "") -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for row in list_socket_rows(item):
		if not str(row.get("instance_uid", "")).is_empty():
			continue
		if not kind_filter.is_empty() and str(row.get("kind", "")) != kind_filter:
			continue
		out.append(row)
	return out


func _socket_row_dict(item: ItemData, kind: String, index: int) -> Dictionary:
	var uid := ""
	var rune_id := ""
	var gem_id := ""
	for entry in item.socketed:
		if not entry is Dictionary:
			continue
		var d: Dictionary = entry
		if str(d.get("kind", "")) == kind and int(d.get("index", -1)) == index:
			uid = str(d.get("instance_uid", ""))
			rune_id = str(d.get("rune_id", ""))
			gem_id = str(d.get("gem_id", ""))
			break
	return {
		"kind": kind,
		"index": index,
		"instance_uid": uid,
		"rune_id": rune_id,
		"gem_id": gem_id,
	}


func _socket_uid_on_item(item: ItemData, kind: String, index: int) -> String:
	if item == null:
		return ""
	for entry in item.socketed:
		if not entry is Dictionary:
			continue
		var d: Dictionary = entry
		if str(d.get("kind", "")) == kind and int(d.get("index", -1)) == index:
			return str(d.get("instance_uid", ""))
	return ""


func _find_socket_on_item(item: ItemData, uid: String) -> Dictionary:
	if item == null:
		return {}
	for entry in item.socketed:
		if not entry is Dictionary:
			continue
		var d: Dictionary = entry
		if str(d.get("instance_uid", "")) == uid:
			return {
				"kind": str(d.get("kind", "")),
				"index": int(d.get("index", -1)),
			}
	return {}


func _set_socket(
	item: ItemData,
	kind: String,
	index: int,
	uid: String,
	rune_id: String,
	gem_id: String,
	registered: bool
) -> void:
	_clear_socket_refs(uid)
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
	var payload := {
		"kind": kind,
		"index": index,
		"instance_uid": uid,
		"registered": registered,
	}
	if not rune_id.is_empty():
		payload["rune_id"] = rune_id
	if not gem_id.is_empty():
		payload["gem_id"] = gem_id
	next.append(payload)
	item.socketed = next


func sort_bag(bag_key: String) -> void:
	if not BAG_KEYS.has(bag_key):
		return
	var bag := get_bag(bag_key)
	var filtered: Array[ItemData] = []
	for item in bag:
		if item:
			filtered.append(item as ItemData)
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
	var next: Array = []
	for item in filtered:
		next.append(item)
	while next.size() < GRID_SIZE:
		next.append(null)
	bags[bag_key] = next
