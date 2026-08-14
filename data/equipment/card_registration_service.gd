class_name CardRegistrationService
extends RefCounted

## Meta progression for registered rune/gem cards (village bookshelf).

enum CellState {
	SHELF_LOCKED,
	FOG,
	OPEN,
	REGISTERED,
	EMPTY,
}


static func ensure_meta(meta: Dictionary) -> Dictionary:
	var out := meta.duplicate(true)
	if not out.has("registered_cards"):
		out["registered_cards"] = []
	if not out.has("unlocked_shelves"):
		out["unlocked_shelves"] = _default_shelves()
	if not out.has("open_cards"):
		out["open_cards"] = []
	if not out.has("card_pity"):
		out["card_pity"] = {}
	# Migrate legacy discovered_cards into open_cards (pre-v3).
	if out.has("discovered_cards"):
		var open: Array = out["open_cards"] as Array
		for key in out["discovered_cards"] as Array:
			var s := str(key)
			if not s.is_empty() and not open.has(s):
				open.append(s)
		out["open_cards"] = open
		out.erase("discovered_cards")
	if _needs_legacy_shelf_reset(out):
		out["unlocked_shelves"] = _default_shelves()
		out["open_cards"] = []
		out["_needs_seed"] = true
	else:
		_ensure_shelf_listed(out, String(ShelfDefinition.SHELF_RUNE))
		_ensure_shelf_listed(out, String(ShelfDefinition.SHELF_GEM))
	return out


static func _default_shelves() -> Array:
	return [String(ShelfDefinition.SHELF_RUNE), String(ShelfDefinition.SHELF_GEM)]


static func _needs_legacy_shelf_reset(meta: Dictionary) -> bool:
	for s in meta.get("unlocked_shelves", []):
		if ShelfDefinition.is_legacy_shelf_id(str(s)):
			return true
	for key in meta.get("open_cards", []):
		var shelf := str(key).get_slice(":", 0)
		if ShelfDefinition.is_legacy_shelf_id(shelf):
			return true
	return false


## Seeds card #1 on each board. Call after ensure_meta when catalogs available.
static func seed_open(
	meta: Dictionary,
	rune_catalog: RuneCatalog = null,
	gem_catalog: GemCatalog = null
) -> Dictionary:
	meta = ensure_meta(meta)
	var rune_cat := rune_catalog if rune_catalog else RuneCatalog.new()
	var gem_cat := gem_catalog if gem_catalog else GemCatalog.new()
	if bool(meta.get("_needs_seed", false)) or (meta["open_cards"] as Array).is_empty():
		meta["open_cards"] = []
		_mark_open(meta, String(ShelfDefinition.SHELF_RUNE), 1)
		_mark_open(meta, String(ShelfDefinition.SHELF_GEM), 1)
		meta.erase("_needs_seed")
	_rewrite_registered_from_catalog(meta, rune_cat, gem_cat)
	_ensure_shelf_listed(meta, String(ShelfDefinition.SHELF_RUNE))
	_ensure_shelf_listed(meta, String(ShelfDefinition.SHELF_GEM))
	return meta


static func ensure_meta_seeded(
	meta: Dictionary,
	rune_catalog: RuneCatalog = null,
	gem_catalog: GemCatalog = null
) -> Dictionary:
	return seed_open(ensure_meta(meta), rune_catalog, gem_catalog)


## Legacy alias.
static func seed_common_open(
	meta: Dictionary,
	rune_catalog: RuneCatalog = null,
	gem_catalog: GemCatalog = null
) -> Dictionary:
	return seed_open(meta, rune_catalog, gem_catalog)


static func _rewrite_registered_from_catalog(
	meta: Dictionary,
	rune_cat: RuneCatalog,
	gem_cat: GemCatalog
) -> void:
	var cards: Array = meta.get("registered_cards", []) as Array
	var out: Array = []
	for card in cards:
		var kind := str(card.get("kind", ""))
		var id := str(card.get("id", ""))
		var entry: Dictionary = (card as Dictionary).duplicate(true)
		entry.erase("rarity")
		if kind == "rune":
			var def: RuneData = rune_cat.get_rune(id)
			if def:
				entry["shelf_id"] = String(def.shelf_id)
				entry["card_number"] = def.card_number
		elif kind == "gem":
			var gdef: GemData = gem_cat.get_gem(id)
			if gdef:
				entry["shelf_id"] = String(gdef.shelf_id)
				entry["card_number"] = gdef.card_number
		out.append(entry)
	meta["registered_cards"] = out


static func is_shelf_unlocked(meta: Dictionary, shelf_id: String) -> bool:
	meta = ensure_meta(meta)
	return (meta["unlocked_shelves"] as Array).has(shelf_id)


static func is_open(meta: Dictionary, shelf_id: String, card_number: int) -> bool:
	meta = ensure_meta(meta)
	var key := ShelfDefinition.discovery_key(shelf_id, card_number)
	return (meta["open_cards"] as Array).has(key)


static func is_discovered(meta: Dictionary, shelf_id: String, card_number: int) -> bool:
	return is_open(meta, shelf_id, card_number)


static func is_id_registered(meta: Dictionary, kind: String, id: String) -> bool:
	for card in meta.get("registered_cards", []):
		if str(card.get("kind", "")) == kind and str(card.get("id", "")) == id:
			return true
	return false


static func cell_state(
	meta: Dictionary,
	shelf_id: String,
	card_number: int,
	kind: String = "",
	id: String = ""
) -> CellState:
	meta = ensure_meta(meta)
	if not is_shelf_unlocked(meta, shelf_id):
		return CellState.SHELF_LOCKED
	if card_number <= 0:
		return CellState.EMPTY
	if not kind.is_empty() and not id.is_empty() and is_id_registered(meta, kind, id):
		return CellState.REGISTERED
	for card in meta.get("registered_cards", []):
		if str(card.get("shelf_id", "")) == shelf_id and int(card.get("card_number", 0)) == card_number:
			return CellState.REGISTERED
	if is_open(meta, shelf_id, card_number):
		return CellState.OPEN
	return CellState.FOG


static func loot_pool_ids(meta: Dictionary, kind: String, catalog: Variant) -> Array[String]:
	meta = ensure_meta(meta)
	var open: Array = meta["open_cards"] as Array
	var out: Array[String] = []
	if catalog == null:
		return out
	if kind == "rune":
		var rune_cat := catalog as RuneCatalog
		if rune_cat == null:
			return out
		for id in rune_cat.all_ids():
			var def: RuneData = rune_cat.get_rune(str(id))
			if def == null:
				continue
			var key := ShelfDefinition.discovery_key(String(def.shelf_id), def.card_number)
			if open.has(key):
				out.append(str(id))
	elif kind == "gem":
		var gem_cat := catalog as GemCatalog
		if gem_cat == null:
			return out
		for id in gem_cat.all_ids():
			var gdef: GemData = gem_cat.get_gem(str(id))
			if gdef == null:
				continue
			var gkey := ShelfDefinition.discovery_key(String(gdef.shelf_id), gdef.card_number)
			if open.has(gkey):
				out.append(str(id))
	out.sort()
	return out


static func first_owned_uid(inventory: InventoryData, kind: String, id: String) -> String:
	if inventory == null or id.is_empty():
		return ""
	if kind == "rune":
		for ri in inventory.runes:
			if ri is RuneInstance and String((ri as RuneInstance).rune_id) == id:
				var uid := (ri as RuneInstance).instance_uid
				if not inventory.is_uid_socketed(uid):
					return uid
	elif kind == "gem":
		for gi in inventory.gems:
			if gi is GemInstance and String((gi as GemInstance).gem_id) == id:
				var guid := (gi as GemInstance).instance_uid
				if not inventory.is_uid_socketed(guid):
					return guid
	return ""


static func register(
	inventory: InventoryData,
	meta: Dictionary,
	kind: String,
	uid: String,
	rune_catalog: RuneCatalog = null,
	gem_catalog: GemCatalog = null
) -> Dictionary:
	var rune_cat := rune_catalog if rune_catalog else RuneCatalog.new()
	var gem_cat := gem_catalog if gem_catalog else GemCatalog.new()
	meta = ensure_meta_seeded(meta, rune_cat, gem_cat)
	if inventory == null or uid.is_empty():
		return {"ok": false, "meta": meta, "message": "Invalid."}

	var card := {}
	if kind == "rune":
		var ri := inventory.find_rune(uid)
		if ri == null or ri.registered:
			return {"ok": false, "meta": meta, "message": "Rune not found."}
		if is_id_registered(meta, "rune", ri.rune_id):
			return {"ok": false, "meta": meta, "message": "Already sealed."}
		if inventory.is_uid_socketed(uid):
			return {"ok": false, "meta": meta, "message": "Unequip first."}
		var def: RuneData = rune_cat.get_rune(ri.rune_id)
		card = {
			"kind": "rune",
			"id": ri.rune_id,
			"instance_uid": uid,
			"shelf_id": String(def.shelf_id) if def else String(ShelfDefinition.SHELF_RUNE),
			"card_number": def.card_number if def else 0,
		}
		ri.registered = true
		inventory.remove_rune_uid(uid)
	elif kind == "gem":
		var gi := inventory.find_gem(uid)
		if gi == null or gi.registered:
			return {"ok": false, "meta": meta, "message": "Gem not found."}
		if is_id_registered(meta, "gem", gi.gem_id):
			return {"ok": false, "meta": meta, "message": "Already sealed."}
		if inventory.is_uid_socketed(uid):
			return {"ok": false, "meta": meta, "message": "Unequip first."}
		var gdef: GemData = gem_cat.get_gem(gi.gem_id)
		card = {
			"kind": "gem",
			"id": gi.gem_id,
			"instance_uid": uid,
			"shelf_id": String(gdef.shelf_id) if gdef else String(ShelfDefinition.SHELF_GEM),
			"card_number": gdef.card_number if gdef else 0,
		}
		gi.registered = true
		inventory.remove_gem_uid(uid)
	else:
		return {"ok": false, "meta": meta, "message": "Unknown kind."}

	var cards: Array = meta["registered_cards"] as Array
	cards.append(card)
	meta["registered_cards"] = cards

	var shelf := str(card.get("shelf_id", String(ShelfDefinition.SHELF_RUNE)))
	var num := int(card.get("card_number", 0))
	_mark_open(meta, shelf, num)
	_activate_adjacent(meta, shelf, num)

	var service := ResonanceService.new()
	service.rebuild_main_hand_skills(inventory, rune_cat, gem_cat)
	return {"ok": true, "meta": meta, "card": card, "message": "Registered."}


## Opens every cell on a shelf board (dev / cheat). Does not register cards.
static func open_all_on_shelf(meta: Dictionary, shelf_id: String) -> Dictionary:
	meta = ensure_meta(meta)
	_ensure_shelf_listed(meta, shelf_id)
	for n in range(1, ShelfDefinition.CELL_COUNT + 1):
		_mark_open(meta, shelf_id, n)
	return meta


static func _mark_open(meta: Dictionary, shelf_id: String, card_number: int) -> void:
	if card_number <= 0:
		return
	if not meta.has("open_cards"):
		meta["open_cards"] = []
	var open: Array = meta["open_cards"] as Array
	var key := ShelfDefinition.discovery_key(shelf_id, card_number)
	if not open.has(key):
		open.append(key)
	meta["open_cards"] = open


static func _ensure_shelf_listed(meta: Dictionary, shelf_id: String) -> void:
	if not meta.has("unlocked_shelves"):
		meta["unlocked_shelves"] = []
	var shelves: Array = meta["unlocked_shelves"] as Array
	if not shelves.has(shelf_id):
		shelves.append(shelf_id)
	meta["unlocked_shelves"] = shelves


static func _activate_adjacent(meta: Dictionary, shelf_id: String, card_number: int) -> void:
	for n in ShelfDefinition.neighbor_card_numbers(card_number):
		_mark_open(meta, shelf_id, n)
