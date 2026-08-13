class_name CardRegistrationService
extends RefCounted

## Meta progression for registered rune/gem cards (village only).


static func ensure_meta(meta: Dictionary) -> Dictionary:
	var out := meta.duplicate(true)
	if not out.has("registered_cards"):
		out["registered_cards"] = []
	if not out.has("unlocked_shelves"):
		out["unlocked_shelves"] = ["shelf_common"]
	if not out.has("card_pity"):
		out["card_pity"] = {}
	return out


static func list_registerable(inventory: InventoryData) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if inventory == null:
		return out
	for ri in inventory.runes:
		if ri is RuneInstance and not (ri as RuneInstance).registered:
			out.append({"kind": "rune", "uid": (ri as RuneInstance).instance_uid, "id": (ri as RuneInstance).rune_id})
	for gi in inventory.gems:
		if gi is GemInstance and not (gi as GemInstance).registered:
			out.append({"kind": "gem", "uid": (gi as GemInstance).instance_uid, "id": (gi as GemInstance).gem_id})
	return out


static func register(
	inventory: InventoryData,
	meta: Dictionary,
	kind: String,
	uid: String,
	rune_catalog: RuneCatalog = null,
	gem_catalog: GemCatalog = null
) -> Dictionary:
	meta = ensure_meta(meta)
	if inventory == null or uid.is_empty():
		return {"ok": false, "meta": meta, "message": "Invalid."}

	var card := {}
	if kind == "rune":
		var ri := inventory.find_rune(uid)
		if ri == null or ri.registered:
			return {"ok": false, "meta": meta, "message": "Rune not found."}
		var def: RuneData = rune_catalog.get_rune(ri.rune_id) if rune_catalog else null
		card = {
			"kind": "rune",
			"id": ri.rune_id,
			"instance_uid": uid,
			"shelf_id": String(def.shelf_id) if def else "shelf_common",
			"card_number": def.card_number if def else 0,
			"rarity": int(def.rarity) if def else 0,
		}
		ri.registered = true
		inventory.remove_rune_uid(uid)
	elif kind == "gem":
		var gi := inventory.find_gem(uid)
		if gi == null or gi.registered:
			return {"ok": false, "meta": meta, "message": "Gem not found."}
		var gdef: GemData = gem_catalog.get_gem(gi.gem_id) if gem_catalog else null
		card = {
			"kind": "gem",
			"id": gi.gem_id,
			"instance_uid": uid,
			"shelf_id": String(gdef.shelf_id) if gdef else "shelf_common",
			"card_number": gdef.card_number if gdef else 0,
			"rarity": int(gdef.rarity) if gdef else 0,
		}
		gi.registered = true
		inventory.remove_gem_uid(uid)
	else:
		return {"ok": false, "meta": meta, "message": "Unknown kind."}

	var cards: Array = meta["registered_cards"] as Array
	cards.append(card)
	meta["registered_cards"] = cards

	var shelf := str(card.get("shelf_id", "shelf_common"))
	var shelves: Array = meta["unlocked_shelves"] as Array
	if not shelves.has(shelf):
		# Common registration never unlocks higher shelves.
		if shelf == "shelf_common" or shelves.has("shelf_common"):
			if shelf == "shelf_common":
				pass
			# Only unlock same shelf if already present path; higher needs explicit key.
	_activate_adjacent(meta, shelf, int(card.get("card_number", 0)))

	var service := ResonanceService.new()
	service.rebuild_main_hand_skills(
		inventory,
		rune_catalog if rune_catalog else RuneCatalog.new(),
		gem_catalog if gem_catalog else GemCatalog.new()
	)
	return {"ok": true, "meta": meta, "card": card, "message": "Registered."}


static func _activate_adjacent(meta: Dictionary, shelf_id: String, card_number: int) -> void:
	if not meta.has("discovered_cards"):
		meta["discovered_cards"] = []
	var discovered: Array = meta["discovered_cards"] as Array
	# Same-shelf 4-neighbor discovery only (no higher-shelf unlock).
	for n in [card_number - 1, card_number + 1, card_number - 10, card_number + 10]:
		if n <= 0:
			continue
		var key := "%s:%d" % [shelf_id, n]
		if not discovered.has(key):
			discovered.append(key)
	meta["discovered_cards"] = discovered
