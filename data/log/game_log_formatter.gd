class_name GameLogFormatter
extends RefCounted

const COLOR_HIT := "#e88888"
const COLOR_CRIT := "#e6c35a"
const COLOR_EVADE := "#999999"
const COLOR_HEAL := "#7ecb8a"
const COLOR_SYSTEM := "#a8a498"


static func format_bbcode(entry: GameLogEntry) -> String:
	if entry == null or entry.kind.is_empty():
		return ""
	match entry.kind:
		"combat.start":
			return _wrap(COLOR_SYSTEM, _tr("LOG_COMBAT_START") % _joined_names(entry.actor_name))
		"combat.end":
			return _wrap(COLOR_SYSTEM, _end_text(entry.result))
		"evade":
			return _wrap(COLOR_EVADE, _tr("LOG_EVADE") % _name(entry.target_name))
		"death":
			var dead := entry.target_name if not entry.target_name.is_empty() else entry.actor_name
			return _wrap(COLOR_SYSTEM, _tr("LOG_DEATH") % _name(dead))
		"tired":
			return _wrap(COLOR_SYSTEM, _tr("LOG_TIRED") % _name(entry.actor_name))
		"hit":
			return _format_hit(entry)
		"loot.grant":
			return _wrap(COLOR_SYSTEM, _tr("LOOT_GOT") % _joined_names(entry.actor_name))
		"loot.skip":
			return _wrap(COLOR_SYSTEM, _tr("LOOT_INVENTORY_FULL"))
		_:
			return ""


static func _format_hit(entry: GameLogEntry) -> String:
	var actor := _name(entry.actor_name)
	var target := _name(entry.target_name)
	var base: String
	if entry.flags.has("skill") and not entry.skill_name.is_empty():
		base = _tr("LOG_SKILL") % [actor, _tr(entry.skill_name), target, entry.amount]
	else:
		base = _tr("LOG_HIT") % [actor, target, entry.amount]
	var color := COLOR_CRIT if entry.flags.has("crit") else COLOR_HIT
	var line := _wrap(color, base)
	if entry.flags.has("crit"):
		line += _wrap(COLOR_CRIT, _tr("LOG_CRIT_SUFFIX"))
	if entry.heal_amount > 0:
		line += _wrap(COLOR_HEAL, _tr("LOG_VAMP_SUFFIX") % entry.heal_amount)
	if entry.flags.has("counter"):
		line += _wrap(COLOR_SYSTEM, _tr("LOG_COUNTER_SUFFIX"))
	if entry.flags.has("retaliation"):
		line += _wrap(COLOR_SYSTEM, _tr("LOG_RETALIATION_SUFFIX"))
	return line


static func _end_text(result: String) -> String:
	match result:
		"win":
			return _tr("LOG_WIN")
		"lose":
			return _tr("LOG_LOSE")
		"retreat":
			return _tr("LOG_RETREAT")
		_:
			return result


static func _name(raw: String) -> String:
	var trimmed := raw.strip_edges()
	if trimmed.is_empty():
		return trimmed
	return _tr(trimmed)


static func _joined_names(raw: String) -> String:
	var parts := raw.split(", ", false)
	var out: PackedStringArray = PackedStringArray()
	for part in parts:
		var n := str(part).strip_edges()
		if n.is_empty():
			continue
		out.append(_tr(n))
	return ", ".join(out)


static func _tr(key: String) -> String:
	return TranslationServer.translate(key)


static func _wrap(color: String, text: String) -> String:
	return "[color=%s]%s[/color]" % [color, _escape(text)]


static func _escape(text: String) -> String:
	return text.replace("[", "［").replace("]", "］")
