class_name GemData
extends Resource

@export var gem_id: StringName
@export var display_name: String = ""
@export var shelf_id: StringName = &"shelf_gem"
@export var card_number: int = 0
@export var gem_type: StringName = &"element"
@export var resonance_tags: Array[StringName] = []
## equip_slot -> behavior key (not CombatStats field names)
@export var slot_effects: Dictionary = {}
@export var registration_effects: Array[Dictionary] = []
@export var skill_name_suffix: String = ""
@export var icon: Texture2D


## ponytail: first resonance tag, then gem_type. Per-id cells come later.
static func icon_for(gem: GemData) -> Texture2D:
	if gem:
		for tag in gem.resonance_tags:
			var tex := icon_for_tag(String(tag))
			if tex:
				return tex
		return icon_for_type(String(gem.gem_type))
	return icon_for_type("element")


static func icon_for_tag(tag: String) -> Texture2D:
	match tag:
		"blood":
			return ItemData.sheet_icon(2, 10)
		"frost", "tide":
			return ItemData.sheet_icon(0, 10)
		"fire", "erupt":
			return ItemData.sheet_icon(3, 10)
		"storm", "spark", "wind":
			return ItemData.sheet_icon(10, 10)
		"earth", "thorn":
			return ItemData.sheet_icon(1, 10)
		"holy", "ward", "hymn":
			return ItemData.sheet_icon(13, 10)
		"plague", "grave":
			return ItemData.sheet_icon(5, 10)
		"ash":
			return ItemData.sheet_icon(4, 10)
		"chain":
			return ItemData.sheet_icon(7, 10)
		"counter":
			return ItemData.sheet_icon(8, 10)
		_:
			return null


static func icon_for_type(gem_type: String) -> Texture2D:
	match gem_type:
		"condition":
			return ItemData.sheet_icon(6, 10)
		"mediator":
			return ItemData.sheet_icon(9, 10)
		"explore":
			return ItemData.sheet_icon(12, 10)
		_:
			return ItemData.sheet_icon(0, 10)
