class_name ResonanceService
extends RefCounted


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
	var rune_data: RuneData = null
	var core_gem: GemData = null
	var aux_gems: Array[GemData] = []

	for entry in main.socketed:
		if not entry is Dictionary:
			continue
		var d: Dictionary = entry
		var kind := str(d.get("kind", ""))
		var uid := str(d.get("instance_uid", ""))
		if kind == "rune" and rune_data == null:
			var ri: RuneInstance = runes_by_uid.get(uid) as RuneInstance
			if ri and rune_catalog and not ri.registered:
				rune_data = rune_catalog.get_rune(ri.rune_id)
		elif kind == "core_gem" and core_gem == null:
			var gi: GemInstance = gems_by_uid.get(uid) as GemInstance
			if gi and gem_catalog and not gi.registered:
				core_gem = gem_catalog.get_gem(gi.gem_id)
		elif kind == "aux_gem":
			var agi: GemInstance = gems_by_uid.get(uid) as GemInstance
			if agi and gem_catalog and not agi.registered:
				var g := gem_catalog.get_gem(agi.gem_id)
				if g:
					aux_gems.append(g)

	if rune_data == null:
		# Keep bootstrap / intrinsic skills when no rune socketed.
		return ResonanceResult.base_only(main.skills.duplicate(true), "No rune socketed.")

	var result := evaluate(main, rune_data, core_gem, aux_gems)
	if result.state == ResonanceResult.State.INACTIVE:
		main.skills = _empty_skills()
	else:
		main.skills = _pad_skills(result.skills)
	return result


func can_socket_rune(equipment: ItemData, rune: RuneData) -> bool:
	return equipment != null and rune != null and _supports_rune(equipment, rune)


func can_socket_gem(equipment: ItemData, gem: GemData) -> bool:
	return equipment != null and gem != null and _supports_gem(equipment, gem)


func _supports_rune(equipment: ItemData, rune: RuneData) -> bool:
	if equipment.equip_slot != "main_hand":
		return false
	equipment.ensure_socket_layout()
	if equipment.socket_layout == null or equipment.socket_layout.rune_slots <= 0:
		return false
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


func _empty_skills() -> Array[Dictionary]:
	return [
		{"button": "X", "name": ""},
		{"button": "Y", "name": ""},
		{"button": "B", "name": ""},
		{"button": "A", "name": ""},
	]


func _pad_skills(skills: Array) -> Array[Dictionary]:
	var buttons := ["X", "Y", "B", "A"]
	var out: Array[Dictionary] = []
	for i in 4:
		if i < skills.size() and skills[i] is Dictionary:
			var d: Dictionary = (skills[i] as Dictionary).duplicate(true)
			if not d.has("button"):
				d["button"] = buttons[i]
			out.append(d)
		else:
			out.append({"button": buttons[i], "name": ""})
	return out
