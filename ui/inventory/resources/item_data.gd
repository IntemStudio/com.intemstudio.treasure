class_name ItemData
extends Resource

enum ItemCategory { WEAPON, ARMOR, CONSUMABLE, MATERIAL, TOOL }
enum ItemRarity { COMMON, UNCOMMON, RARE, LEGENDARY }

const ICON_SHEET := preload("res://assets/icons/32x32.png")
const ICON_SIZE := 32
const ICON_COLS := 16

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
	socket_layout = SocketLayout.for_slot(equip_slot)


func apply_rarity(new_rarity: ItemRarity) -> void:
	rarity = new_rarity
	socket_layout = SocketLayout.for_slot(equip_slot)
	trim_socketed_to_layout()


func trim_socketed_to_layout() -> void:
	ensure_socket_layout()
	if socket_layout == null:
		socketed = []
		return
	var kept: Array[Dictionary] = []
	for entry in socketed:
		if not entry is Dictionary:
			continue
		var d: Dictionary = entry
		var kind := str(d.get("kind", ""))
		var index := int(d.get("index", -1))
		var cap := 0
		match kind:
			"rune":
				cap = socket_layout.rune_slots
			"core_gem":
				cap = socket_layout.core_gem_slots
			"aux_gem":
				cap = socket_layout.aux_gem_slots
			_:
				continue
		if index >= 0 and index < cap:
			kept.append(d)
	socketed = kept


func is_two_handed() -> bool:
	if two_handed:
		return true
	var t := item_type.to_lower()
	return t.contains("two handed") or t.contains("two-handed")


## 32px cells, 16 columns. ponytail: type-based cells, not a per-id atlas map.
static func sheet_icon(col: int, row: int) -> AtlasTexture:
	var tex := AtlasTexture.new()
	tex.atlas = ICON_SHEET
	var cols := ICON_COLS
	var rows := 1
	if ICON_SHEET:
		cols = maxi(1, ICON_SHEET.get_width() / ICON_SIZE)
		rows = maxi(1, ICON_SHEET.get_height() / ICON_SIZE)
	tex.region = Rect2(
		clampi(col, 0, cols - 1) * ICON_SIZE,
		clampi(row, 0, rows - 1) * ICON_SIZE,
		ICON_SIZE,
		ICON_SIZE
	)
	tex.filter_clip = true
	return tex


static func color_for_rarity(r: ItemRarity) -> Color:
	match r:
		ItemRarity.UNCOMMON:
			return UIColors.RARITY_UNCOMMON
		ItemRarity.RARE:
			return UIColors.RARITY_RARE
		ItemRarity.LEGENDARY:
			return UIColors.RARITY_LEGENDARY
		_:
			return UIColors.RARITY_COMMON


func get_rarity_color() -> Color:
	return color_for_rarity(rarity)


func rarity_locale_key() -> String:
	return locale_key_for_rarity(rarity)


static func locale_key_for_rarity(r: ItemRarity) -> String:
	match r:
		ItemRarity.UNCOMMON:
			return "UNCOMMON"
		ItemRarity.RARE:
			return "RARE"
		ItemRarity.LEGENDARY:
			return "LEGENDARY"
		_:
			return "COMMON"
