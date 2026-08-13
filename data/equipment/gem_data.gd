class_name GemData
extends Resource

@export var gem_id: StringName
@export var display_name: String = ""
@export var rarity: ItemData.ItemRarity = ItemData.ItemRarity.COMMON
@export var shelf_id: StringName = &"shelf_common"
@export var card_number: int = 0
@export var gem_type: StringName = &"element"
@export var resonance_tags: Array[StringName] = []
## equip_slot -> behavior key (not CombatStats field names)
@export var slot_effects: Dictionary = {}
@export var registration_effects: Array[Dictionary] = []
@export var skill_name_suffix: String = ""
