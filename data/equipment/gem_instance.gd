class_name GemInstance
extends RefCounted

var instance_uid: String = ""
var gem_id: String = ""
var registered: bool = false


static func create(gem_id: String) -> GemInstance:
	var inst := GemInstance.new()
	inst.gem_id = gem_id
	inst.instance_uid = "%s_%d_%d" % [gem_id, Time.get_ticks_msec(), randi()]
	return inst


func to_dict() -> Dictionary:
	return {
		"instance_uid": instance_uid,
		"gem_id": gem_id,
		"registered": registered,
	}


static func from_dict(d: Dictionary) -> GemInstance:
	if d.is_empty():
		return null
	var inst := GemInstance.new()
	inst.instance_uid = str(d.get("instance_uid", ""))
	inst.gem_id = str(d.get("gem_id", ""))
	inst.registered = bool(d.get("registered", false))
	if inst.instance_uid.is_empty() or inst.gem_id.is_empty():
		return null
	return inst
