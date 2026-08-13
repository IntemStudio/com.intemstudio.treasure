class_name GameLogEntry
extends RefCounted

var category: String = "combat"
var kind: String = ""
var actor_id: String = ""
var actor_name: String = ""
var target_id: String = ""
var target_name: String = ""
var amount: int = 0
var heal_amount: int = 0
var flags: PackedStringArray = PackedStringArray()
var skill_name: String = ""
var result: String = ""


static func from_payload(payload: Dictionary) -> GameLogEntry:
	var e := GameLogEntry.new()
	e.category = str(payload.get("category", "combat"))
	e.kind = str(payload.get("kind", ""))
	e.actor_id = str(payload.get("actor_id", ""))
	e.actor_name = str(payload.get("actor_name", ""))
	e.target_id = str(payload.get("target_id", ""))
	e.target_name = str(payload.get("target_name", ""))
	e.amount = int(payload.get("amount", 0))
	e.heal_amount = int(payload.get("heal_amount", 0))
	e.skill_name = str(payload.get("skill_name", ""))
	e.result = str(payload.get("result", ""))
	var raw_flags: Variant = payload.get("flags", PackedStringArray())
	if raw_flags is PackedStringArray:
		e.flags = (raw_flags as PackedStringArray).duplicate()
	elif raw_flags is Array:
		for f in raw_flags:
			e.flags.append(str(f))
	return e
