class_name ResonanceResult
extends RefCounted

enum State { INACTIVE, BASE_SKILL_ONLY, RESONANT, COMPLETE }

var state: State = State.INACTIVE
var message: String = ""
var skills: Array = []
var behavior_flags: Array[StringName] = []


static func inactive(msg: String = "") -> ResonanceResult:
	var r := ResonanceResult.new()
	r.state = State.INACTIVE
	r.message = msg
	return r


static func base_only(skills: Array, msg: String = "") -> ResonanceResult:
	var r := ResonanceResult.new()
	r.state = State.BASE_SKILL_ONLY
	r.skills = skills.duplicate(true)
	r.message = msg
	return r


static func resonant(skills: Array, flags: Array[StringName], msg: String = "") -> ResonanceResult:
	var r := ResonanceResult.new()
	r.state = State.RESONANT
	r.skills = skills.duplicate(true)
	r.behavior_flags = flags.duplicate()
	r.message = msg
	return r


static func complete(skills: Array, flags: Array[StringName], msg: String = "") -> ResonanceResult:
	var r := ResonanceResult.new()
	r.state = State.COMPLETE
	r.skills = skills.duplicate(true)
	r.behavior_flags = flags.duplicate()
	r.message = msg
	return r


func state_key() -> String:
	match state:
		State.INACTIVE:
			return "INACTIVE"
		State.BASE_SKILL_ONLY:
			return "BASE_SKILL_ONLY"
		State.RESONANT:
			return "RESONANT"
		State.COMPLETE:
			return "COMPLETE"
		_:
			return "INACTIVE"
