class_name RuneInstance
extends RefCounted

var instance_uid: String = ""
var rune_id: String = ""
var registered: bool = false


static func create(rune_id: String) -> RuneInstance:
	var inst := RuneInstance.new()
	inst.rune_id = rune_id
	inst.instance_uid = "%s_%d_%d" % [rune_id, Time.get_ticks_msec(), randi()]
	return inst


func to_dict() -> Dictionary:
	return {
		"instance_uid": instance_uid,
		"rune_id": rune_id,
		"registered": registered,
	}


static func from_dict(d: Dictionary) -> RuneInstance:
	if d.is_empty():
		return null
	var inst := RuneInstance.new()
	inst.instance_uid = str(d.get("instance_uid", ""))
	inst.rune_id = str(d.get("rune_id", ""))
	inst.registered = bool(d.get("registered", false))
	if inst.instance_uid.is_empty() or inst.rune_id.is_empty():
		return null
	return inst
