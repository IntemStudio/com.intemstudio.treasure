class_name ItemData
extends Resource

enum ItemCategory { WEAPON, ARMOR, CONSUMABLE, MATERIAL, TOOL }
enum ItemRarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }

@export var id: String = ""
@export var display_name: String = ""
@export var item_type: String = ""
@export var category: ItemCategory = ItemCategory.WEAPON
@export var rarity: ItemRarity = ItemRarity.COMMON
@export var icon: Texture2D
@export var tier: int = 1

@export var attack: int = 0
@export var attack_bonus: int = 0
@export var defense: int = 0
@export var defense_bonus: int = 0

@export var scales_with: String = ""
@export var scale_icon: Texture2D

@export var skills: Array[Dictionary] = []
@export var cost: int = 0
@export var gain: int = 0
@export var affixes: Array[Dictionary] = []
@export_multiline var flavor_text: String = ""

@export var required_stat: String = "strength"
@export var required_value: int = 10

@export var durability: int = 100
@export var durability_max: int = 100
@export var weight: float = 0.0

@export var stackable: bool = false
@export var max_stack: int = 1
@export var quantity: int = 1

@export var equip_slot: String = ""
@export var two_handed: bool = false

@export var socket_layout: SocketLayout
@export var compatible_rune_tags: Array[StringName] = []
@export var compatible_gem_tags: Array[StringName] = []
@export var intrinsic_effects: Array[Dictionary] = []
## Socket contents: [{ "kind": "rune"|"core_gem"|"aux_gem", "index": int, "instance_uid": String }]
@export var socketed: Array[Dictionary] = []


func ensure_socket_layout() -> void:
	if socket_layout != null:
		return
	socket_layout = SocketLayout.for_rarity(equip_slot, rarity)


func apply_rarity(new_rarity: ItemRarity) -> void:
	rarity = new_rarity
	socket_layout = SocketLayout.for_rarity(equip_slot, rarity)


func is_two_handed() -> bool:
	if two_handed:
		return true
	var t := item_type.to_lower()
	return t.contains("two handed") or t.contains("two-handed")


static func color_for_rarity(r: ItemRarity) -> Color:
	match r:
		ItemRarity.UNCOMMON:
			return UIColors.RARITY_UNCOMMON
		ItemRarity.RARE:
			return UIColors.RARITY_RARE
		ItemRarity.EPIC:
			return UIColors.RARITY_EPIC
		ItemRarity.LEGENDARY:
			return UIColors.RARITY_LEGENDARY
		_:
			return UIColors.RARITY_COMMON


func get_rarity_color() -> Color:
	return color_for_rarity(rarity)


func rarity_locale_key() -> String:
	match rarity:
		ItemRarity.UNCOMMON:
			return "UNCOMMON"
		ItemRarity.RARE:
			return "RARE"
		ItemRarity.EPIC:
			return "EPIC"
		ItemRarity.LEGENDARY:
			return "LEGENDARY"
		_:
			return "COMMON"
