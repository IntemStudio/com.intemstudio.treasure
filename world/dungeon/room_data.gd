class_name RoomData
extends RefCounted

enum RoomType { START, NORMAL, BOSS }
enum RewardType { NONE, WEAPON, ARMOR, RUNE, GEM }

const TYPE_NAMES := {
	RoomType.START: "start",
	RoomType.NORMAL: "normal",
	RoomType.BOSS: "boss",
}

const REWARD_TYPE_KEYS := {
	RewardType.NONE: "none",
	RewardType.WEAPON: "weapon",
	RewardType.ARMOR: "armor",
	RewardType.RUNE: "rune",
	RewardType.GEM: "gem",
}

var grid_pos: Vector2i = Vector2i.ZERO
var room_type: RoomType = RoomType.NORMAL
## Direction key ("N"/"E"/"S"/"W") -> neighbor Vector2i
var neighbors: Dictionary = {}
var visited: bool = false
var cleared: bool = false
## Loot pool for this room. START stays NONE.
var reward_type: RewardType = RewardType.NONE


func type_name() -> String:
	return TYPE_NAMES.get(room_type, "normal")


func reward_type_key() -> String:
	return REWARD_TYPE_KEYS.get(reward_type, "none")


func type_letter() -> String:
	match room_type:
		RoomType.START:
			return "S"
		RoomType.BOSS:
			return "B"
		_:
			return "N"
