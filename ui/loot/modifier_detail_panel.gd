class_name ModifierDetailPanel
extends PanelContainer

## NRFW-inspired detail card for runes and gems (data we already have).

@onready var name_label: Label = %NameLabel
@onready var kind_label: Label = %KindLabel
@onready var rarity_label: Label = %RarityLabel
@onready var blurb_label: Label = %BlurbLabel
@onready var body_label: RichTextLabel = %BodyLabel
@onready var icon_rect: TextureRect = %ItemIcon


func _ready() -> void:
	theme_type_variation = &"ItemDetailPanel"
	clear()


func clear() -> void:
	if name_label:
		name_label.text = ""
	if kind_label:
		kind_label.text = ""
	if rarity_label:
		rarity_label.text = ""
	if blurb_label:
		blurb_label.text = ""
	if body_label:
		body_label.text = ""
	_set_icon(null)


func show_message(message: String) -> void:
	clear()
	if name_label:
		name_label.text = message


func set_rune(rune: RuneData) -> void:
	if rune == null:
		clear()
		return
	var kind := rune.skill_kind if not rune.skill_kind.is_empty() else "strike"
	var active := ResonanceService.ACTIVE_KINDS.has(kind)
	name_label.text = tr(rune.display_name)
	kind_label.text = tr("Rune")
	rarity_label.text = ""
	var blurb_key := "RUNE_BLURB_ACTIVE" if active else "RUNE_BLURB_PASSIVE"
	blurb_label.text = tr(blurb_key) % tr(rune.skill_name)
	var lines: PackedStringArray = []
	lines.append(_row(tr("Type"), tr(_skill_kind_label(kind))))
	lines.append(_row(tr("Cost"), str(rune.mana_cost)))
	lines.append(_row(tr("Fits"), _format_rune_slots(kind)))
	lines.append("")
	var section := tr("Attack") if active else tr("Effect")
	lines.append("[color=%s]%s[/color]" % [UIColors.html(UIColors.RARITY_RARE), section])
	lines.append("  %s" % tr(rune.skill_name))
	lines.append("  %s: %s" % [tr("Skill kind"), tr(_skill_kind_label(kind))])
	var skill_desc := _skill_kind_desc(kind)
	if not skill_desc.is_empty():
		lines.append("[color=%s]  %s[/color]" % [UIColors.html(UIColors.TEXT_MUTED), skill_desc])
	lines.append("")
	if active:
		lines.append(_row(tr("Applies To"), _format_equip_tags(rune.required_equipment_tags)))
	lines.append(_row(tr("RESO_TAGS"), _format_reso_tags(rune.resonance_tags)))
	lines.append("[color=%s]  %s[/color]" % [UIColors.html(UIColors.TEXT_MUTED), tr("RESO_RULE_RUNE")])
	body_label.text = "\n".join(lines)
	_set_icon(rune.icon)


func set_gem(gem: GemData) -> void:
	if gem == null:
		clear()
		return
	name_label.text = tr(gem.display_name)
	kind_label.text = tr("Gem")
	rarity_label.text = ""
	if gem.skill_name_suffix.is_empty():
		blurb_label.text = tr("GEM_BLURB")
	else:
		blurb_label.text = tr("GEM_BLURB_SUFFIX") % tr(gem.skill_name_suffix).strip_edges()
	var lines: PackedStringArray = []
	lines.append(_row(tr("Type"), tr(_gem_type_label(String(gem.gem_type)))))
	lines.append("")
	lines.append("[color=%s]%s[/color]" % [UIColors.html(UIColors.GOLD), tr("GEM_INFUSE")])
	var effect_rows := _grouped_slot_effects(gem.slot_effects)
	if effect_rows.is_empty():
		lines.append("  —")
	else:
		for row in effect_rows:
			lines.append("  %s: %s" % [row["slot"], row["effect"]])
			var desc := str(row.get("desc", ""))
			if not desc.is_empty():
				lines.append("[color=%s]  %s[/color]" % [UIColors.html(UIColors.TEXT_MUTED), desc])
	lines.append("")
	lines.append(_row(tr("RESO_TAGS"), _format_reso_tags(gem.resonance_tags)))
	lines.append("[color=%s]  %s[/color]" % [UIColors.html(UIColors.TEXT_MUTED), tr("RESO_RULE_GEM")])
	body_label.text = "\n".join(lines)
	_set_icon(gem.icon)


func _set_icon(texture: Texture2D) -> void:
	if icon_rect == null:
		return
	icon_rect.texture = texture
	icon_rect.visible = texture != null
	icon_rect.texture_filter = TEXTURE_FILTER_NEAREST


func _row(label: String, value: String) -> String:
	return "[color=%s]%s[/color]  %s" % [UIColors.html(UIColors.TEXT_MUTED), label, value]


func _grouped_slot_effects(slot_effects: Dictionary) -> Array[Dictionary]:
	var seen_labels: Dictionary = {}
	var order: Array[String] = []
	var by_label: Dictionary = {}
	var preferred := [
		"main_hand", "off_hand", "head", "chest", "legs", "ring_1", "ring_2", "tool_1", "tool_2"
	]
	var keys: Array = []
	for k in preferred:
		if slot_effects.has(k):
			keys.append(k)
	for k in slot_effects.keys():
		if not keys.has(k):
			keys.append(k)
	for slot_key in keys:
		var label := tr(_slot_label(str(slot_key)))
		var effect_key := str(slot_effects[slot_key])
		var effect_text := _effect_label(effect_key)
		if seen_labels.has(label) and str(seen_labels[label]) == effect_text:
			continue
		seen_labels[label] = effect_text
		if not by_label.has(label):
			order.append(label)
			by_label[label] = {"effect": effect_text, "desc": _effect_desc(effect_key)}
	var rows: Array[Dictionary] = []
	for label in order:
		var packed: Dictionary = by_label[label]
		rows.append({
			"slot": label,
			"effect": packed["effect"],
			"desc": packed["desc"],
		})
	return rows


func _format_rune_slots(kind: String) -> String:
	var parts: PackedStringArray = []
	for slot in ResonanceService.slots_for_rune_kind(kind):
		parts.append(tr(_slot_label(slot)))
	if parts.is_empty():
		return "—"
	return ", ".join(parts)


func _format_equip_tags(tags: Array[StringName]) -> String:
	if tags.is_empty():
		return "—"
	var parts: PackedStringArray = []
	for t in tags:
		parts.append(tr(_tag_label(String(t))))
	return ", ".join(parts)


func _format_reso_tags(tags: Array[StringName]) -> String:
	if tags.is_empty():
		return "—"
	var parts: PackedStringArray = []
	for t in tags:
		parts.append(tr(_reso_label(String(t))))
	return ", ".join(parts)


func _rarity_text(rarity: ItemData.ItemRarity) -> String:
	return tr(ItemData.locale_key_for_rarity(rarity))


func _skill_kind_label(kind: String) -> String:
	var id := kind if not kind.is_empty() else "strike"
	var key := "SKILL_KIND_%s" % id.to_upper()
	return key if tr(key) != key else id


func _skill_kind_desc(kind: String) -> String:
	var id := kind if not kind.is_empty() else "strike"
	var key := "SKILL_KIND_%s_DESC" % id.to_upper()
	var translated := tr(key)
	return translated if translated != key else ""


func _gem_type_label(gem_type: String) -> String:
	if gem_type.is_empty():
		return gem_type
	var key := "GEM_TYPE_%s" % gem_type.to_upper()
	return key if tr(key) != key else gem_type


func _slot_label(slot: String) -> String:
	match slot:
		"main_hand":
			return "SLOT_WEAPONS"
		"off_hand":
			return "SLOT_OFF_HANDS"
		"head":
			return "SLOT_HELMETS"
		"chest":
			return "SLOT_BODY"
		"legs":
			return "SLOT_PANTS"
		"ring_1", "ring_2":
			return "SLOT_RINGS"
		"tool_1", "tool_2":
			return "SLOT_TOOLS"
		_:
			return slot


func _tag_label(tag: String) -> String:
	if tag.is_empty():
		return tag
	var key := "TAG_%s" % tag.to_upper()
	return key if tr(key) != key else tag


func _reso_label(tag: String) -> String:
	var key := "RESO_%s" % tag.to_upper()
	var translated := tr(key)
	if translated != key:
		return translated
	return tag


func _effect_label(effect: String) -> String:
	var key := "GEM_FX_%s" % effect.to_upper()
	var translated := tr(key)
	if translated != key:
		return translated
	return effect.replace("_", " ")


func _effect_desc(effect: String) -> String:
	var key := "GEM_FX_%s_DESC" % effect.to_upper()
	var translated := tr(key)
	return translated if translated != key else ""
