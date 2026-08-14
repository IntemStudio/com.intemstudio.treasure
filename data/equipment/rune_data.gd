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


func to_skill_dict() -> Dictionary:
	return {
		"button": button,
		"name": skill_name,
		"kind": skill_kind if not skill_kind.is_empty() else "strike",
		"mana_cost": mana_cost,
		"rune_id": String(rune_id),
	}
