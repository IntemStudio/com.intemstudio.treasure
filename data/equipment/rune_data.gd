class_name RuneData
extends Resource

@export var rune_id: StringName
@export var display_name: String = ""
@export var shelf_id: StringName = &"shelf_rune"
@export var card_number: int = 0
@export var required_equipment_tags: Array[StringName] = []
@export var skill_name: String = ""
@export var skill_kind: String = "strike"
@export var mana_cost: int = 10
@export var button: String = "X"
@export var resonance_tags: Array[StringName] = []
@export var registration_effects: Array[Dictionary] = []
@export var icon: Texture2D


func to_skill_dict() -> Dictionary:
	return {
		"button": button,
		"name": skill_name,
		"kind": skill_kind if not skill_kind.is_empty() else "strike",
		"mana_cost": mana_cost,
		"rune_id": String(rune_id),
	}


## ponytail: skill kind → sheet cell. Per-rune cells come later.
static func icon_for_kind(kind: String) -> Texture2D:
	match kind if not kind.is_empty() else "strike":
		"combo":
			return ItemData.sheet_icon(2, 64)
		"aoe":
			return ItemData.sheet_icon(5, 48)
		"heal":
			return ItemData.sheet_icon(8, 16)
		"ward":
			return ItemData.sheet_icon(3, 40)
		"thorns":
			return ItemData.sheet_icon(2, 16)
		"buff":
			return ItemData.sheet_icon(6, 40)
		"debuff":
			return ItemData.sheet_icon(7, 40)
		"counter":
			return ItemData.sheet_icon(15, 40)
		"convert":
			return ItemData.sheet_icon(4, 48)
		_:
			return ItemData.sheet_icon(10, 64)
