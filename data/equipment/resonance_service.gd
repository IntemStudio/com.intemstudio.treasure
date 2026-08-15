class_name ResonanceService
extends RefCounted

const ACTIVE_KINDS: Array[String] = ["strike", "combo", "aoe"]
const PASSIVE_KINDS: Array[String] = [
	"heal", "ward", "thorns", "buff", "debuff", "counter", "convert"
]
const HUD_RUNE_SLOTS: Array[String] = [
	"main_hand", "off_hand", "head", "chest", "legs"
]


func evaluate(
	equipment: ItemData,
	rune: RuneData,
	core_gem: GemData = null,
	auxiliary_gems: Array[GemData] = []
) -> ResonanceResult:
	if equipment == null or rune == null:
		return ResonanceResult.inactive("Missing equipment or rune.")
	if not _supports_rune(equipment, rune):
		return ResonanceResult.inactive("Equipment and rune are incompatible.")

	var base_skill := rune.to_skill_dict()
	var skills: Array = [base_skill]

	if core_gem == null:
		return ResonanceResult.base_only(skills, "Rune only.")

	if not _supports_gem(equipment, core_gem):
		return ResonanceResult.base_only(skills, "Gem incompatible with equipment.")

	if not _tags_match(rune.resonance_tags, core_gem.resonance_tags):
		return ResonanceResult.base_only(skills, "Resonance tags do not match.")

	var resonant_skill := base_skill.duplicate(true)
	var suffix := str(core_gem.skill_name_suffix)
	if not suffix.is_empty():
		resonant_skill["name"] = str(resonant_skill.get("name", "")) + suffix
	resonant_skill["gem_id"] = String(core_gem.gem_id)
	resonant_skill["resonance"] = "resonant"
	var flags: Array[StringName] = []
	_append_slot_flag(flags, core_gem, equipment.equip_slot)

	var aux_ok := false
	for aux in auxiliary_gems:
		if aux == null:
			continue
		if not _supports_gem(equipment, aux):
			continue
		aux_ok = true
		_append_slot_flag(flags, aux, equipment.equip_slot)
		var aux_suffix := str(aux.skill_name_suffix)
		if not aux_suffix.is_empty() and not str(resonant_skill.get("name", "")).ends_with(aux_suffix):
			resonant_skill["name"] = str(resonant_skill.get("name", "")) + aux_suffix

	var flag_strings: Array = []
	for f in flags:
		flag_strings.append(String(f))
	resonant_skill["behavior_flags"] = flag_strings
	skills = [resonant_skill]
	if aux_ok:
		resonant_skill["resonance"] = "complete"
		return ResonanceResult.complete(skills, flags, "Complete resonance.")
	return ResonanceResult.resonant(skills, flags, "Resonant.")


func rebuild_main_hand_skills(
	inventory: InventoryData,
	rune_catalog: RuneCatalog,
	gem_catalog: GemCatalog
) -> ResonanceResult:
	if inventory == null:
		return ResonanceResult.inactive()
	var main: ItemData = inventory.equipped.get("main_hand") as ItemData
	if main == null:
		return ResonanceResult.inactive("No main hand.")
	main.ensure_socket_layout()

	var runes_by_uid := _index_runes(inventory)
	var gems_by_uid := _index_gems(inventory)
	var runes: Array = [null, null]
	var cores: Array = [null, null]
	var auxes: Array = [[], []]

	for entry in main.socketed:
		if not entry is Dictionary:
			continue
		var d: Dictionary = entry
		var kind := str(d.get("kind", ""))
		var uid := str(d.get("instance_uid", ""))
		var index := int(d.get("index", 0))
		if index < 0 or index > 1:
			continue
		if kind == "rune" and runes[index] == null:
			var ri: RuneInstance = runes_by_uid.get(uid) as RuneInstance
			if ri and rune_catalog and not ri.registered:
				runes[index] = rune_catalog.get_rune(ri.rune_id)
		elif kind == "core_gem" and cores[index] == null:
			var gi: GemInstance = gems_by_uid.get(uid) as GemInstance
			if gi and gem_catalog and not gi.registered:
				cores[index] = gem_catalog.get_gem(gi.gem_id)
		elif kind == "aux_gem":
			var agi: GemInstance = gems_by_uid.get(uid) as GemInstance
			if agi and gem_catalog and not agi.registered:
				var g := gem_catalog.get_gem(agi.gem_id)
				if g:
					(auxes[index] as Array).append(g)

	if runes[0] == null and runes[1] == null:
		# Keep bootstrap / intrinsic skills when no rune socketed.
		return ResonanceResult.base_only(main.skills.duplicate(true), "No rune socketed.")

	var combined: Array[Dictionary] = []
	var last: ResonanceResult = ResonanceResult.inactive("No rune socketed.")
	for i in 2:
		var rune_i: RuneData = runes[i] as RuneData
		if rune_i == null:
			continue
		var aux_i: Array[GemData] = []
		for g in auxes[i] as Array:
			if g is GemData:
				aux_i.append(g as GemData)
		last = evaluate(main, rune_i, cores[i] as GemData, aux_i)
		if last.state == ResonanceResult.State.INACTIVE:
			continue
		if last.skills.size() > 0 and last.skills[0] is Dictionary:
			combined.append((last.skills[0] as Dictionary).duplicate(true))

	if combined.is_empty():
		main.skills = []
		return ResonanceResult.inactive("Equipment and rune are incompatible.")
	main.skills = combined
	return last


func list_equipped_rune_skills(
	inventory: InventoryData,
	rune_catalog: RuneCatalog,
	gem_catalog: GemCatalog
) -> Array:
	var out: Array = []
	if inventory == null:
		return out
	var runes_by_uid := _index_runes(inventory)
	var gems_by_uid := _index_gems(inventory)
	for slot in HUD_RUNE_SLOTS:
		var item: ItemData = inventory.equipped.get(slot) as ItemData
		if item == null:
			continue
		item.ensure_socket_layout()
		var rune_cap := item.socket_layout.rune_slots if item.socket_layout else 0
		for i in range(rune_cap):
			var rune := _socketed_rune_at(item, i, runes_by_uid, rune_catalog)
			if rune == null:
				continue
			if slot == "main_hand":
				var core := _socketed_core_at(item, i, gems_by_uid, gem_catalog)
				var aux_i: Array[GemData] = _socketed_aux_at(item, i, gems_by_uid, gem_catalog)
				var result := evaluate(item, rune, core, aux_i)
				if result.state == ResonanceResult.State.INACTIVE:
					continue
				if result.skills.size() > 0 and result.skills[0] is Dictionary:
					out.append((result.skills[0] as Dictionary).duplicate(true))
			else:
				out.append(rune.to_skill_dict())
	return out


static func slots_for_rune_kind(kind: String) -> PackedStringArray:
	var k := kind if not kind.is_empty() else "strike"
	if ACTIVE_KINDS.has(k):
		return PackedStringArray(["main_hand"])
	if PASSIVE_KINDS.has(k):
		return PackedStringArray(["off_hand", "head", "chest", "legs"])
	return PackedStringArray()


func can_socket_rune(equipment: ItemData, rune: RuneData) -> bool:
	return equipment != null and rune != null and _supports_rune(equipment, rune)


func can_socket_gem(equipment: ItemData, gem: GemData) -> bool:
	return equipment != null and gem != null and _supports_gem(equipment, gem)


func _supports_rune(equipment: ItemData, rune: RuneData) -> bool:
	equipment.ensure_socket_layout()
	if equipment.socket_layout == null or equipment.socket_layout.rune_slots <= 0:
		return false
	var slot := equipment.equip_slot
	var kind := rune.skill_kind if not rune.skill_kind.is_empty() else "strike"
	if not slots_for_rune_kind(kind).has(slot):
		return false
	if slot != "main_hand":
		return true
	if rune.required_equipment_tags.is_empty():
		return true
	for tag in rune.required_equipment_tags:
		if equipment.compatible_rune_tags.has(tag):
			return true
	return false


func _supports_gem(equipment: ItemData, gem: GemData) -> bool:
	equipment.ensure_socket_layout()
	if equipment.socket_layout == null or equipment.socket_layout.total_gem_slots() <= 0:
		return false
	if equipment.compatible_gem_tags.is_empty():
		return true
	for tag in gem.resonance_tags:
		if equipment.compatible_gem_tags.has(tag):
			return true
	if equipment.compatible_gem_tags.has(gem.gem_type):
		return true
	# Soft match: weapon gems on weapons, armor gems on armor slots.
	var slot := equipment.equip_slot
	if slot == "main_hand" or slot == "off_hand":
		return equipment.compatible_gem_tags.has(&"weapon") or equipment.compatible_gem_tags.has(&"element")
	if slot in ["head", "chest", "legs"]:
		return equipment.compatible_gem_tags.has(&"armor") or equipment.compatible_gem_tags.has(&"defense")
	if slot.begins_with("tool"):
		return equipment.compatible_gem_tags.has(&"tool") or equipment.compatible_gem_tags.has(&"explore")
	return false


func _tags_match(a: Array[StringName], b: Array[StringName]) -> bool:
	for t in a:
		if b.has(t):
			return true
	return false


func _append_slot_flag(flags: Array[StringName], gem: GemData, equip_slot: String) -> void:
	var effect: Variant = gem.slot_effects.get(equip_slot, "")
	var key := str(effect)
	if key.is_empty():
		return
	var sn := StringName(key)
	if not flags.has(sn):
		flags.append(sn)


func _index_runes(inventory: InventoryData) -> Dictionary:
	var out := {}
	for ri in inventory.runes:
		if ri is RuneInstance:
			out[(ri as RuneInstance).instance_uid] = ri
	return out


func _index_gems(inventory: InventoryData) -> Dictionary:
	var out := {}
	for gi in inventory.gems:
		if gi is GemInstance:
			out[(gi as GemInstance).instance_uid] = gi
	return out


func _socketed_rune_at(
	item: ItemData,
	index: int,
	runes_by_uid: Dictionary,
	rune_catalog: RuneCatalog
) -> RuneData:
	var uid := _socket_uid(item, "rune", index)
	if uid.is_empty() or rune_catalog == null:
		return null
	var ri: RuneInstance = runes_by_uid.get(uid) as RuneInstance
	if ri == null or ri.registered:
		return null
	return rune_catalog.get_rune(ri.rune_id)


func _socketed_core_at(
	item: ItemData,
	index: int,
	gems_by_uid: Dictionary,
	gem_catalog: GemCatalog
) -> GemData:
	var uid := _socket_uid(item, "core_gem", index)
	if uid.is_empty() or gem_catalog == null:
		return null
	var gi: GemInstance = gems_by_uid.get(uid) as GemInstance
	if gi == null or gi.registered:
		return null
	return gem_catalog.get_gem(gi.gem_id)


func _socketed_aux_at(
	item: ItemData,
	index: int,
	gems_by_uid: Dictionary,
	gem_catalog: GemCatalog
) -> Array[GemData]:
	var out: Array[GemData] = []
	if item == null or gem_catalog == null:
		return out
	for entry in item.socketed:
		if not entry is Dictionary:
			continue
		var d: Dictionary = entry
		if str(d.get("kind", "")) != "aux_gem" or int(d.get("index", -1)) != index:
			continue
		var gi: GemInstance = gems_by_uid.get(str(d.get("instance_uid", ""))) as GemInstance
		if gi == null or gi.registered:
			continue
		var g := gem_catalog.get_gem(gi.gem_id)
		if g:
			out.append(g)
	return out


func _socket_uid(item: ItemData, kind: String, index: int) -> String:
	if item == null:
		return ""
	for entry in item.socketed:
		if not entry is Dictionary:
			continue
		var d: Dictionary = entry
		if str(d.get("kind", "")) == kind and int(d.get("index", -1)) == index:
			return str(d.get("instance_uid", ""))
	return ""
