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


func get_rarity_color() -> Color:
	match rarity:
		ItemRarity.UNCOMMON:
			return Color(0.45, 0.85, 0.55)
		ItemRarity.RARE:
			return UIColors.RARE_GLOW
		ItemRarity.EPIC:
			return Color(0.85, 0.55, 0.25)
		ItemRarity.LEGENDARY:
			return UIColors.GOLD
		_:
			return Color(0.35, 0.34, 0.33)
