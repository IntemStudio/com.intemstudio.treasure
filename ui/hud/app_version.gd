class_name AppVersion
extends RefCounted

const MAJOR := 0
const MINOR := 1
const PATCH := 0


static func format() -> String:
	return "%d  %d  %d" % [MAJOR, MINOR, PATCH]
