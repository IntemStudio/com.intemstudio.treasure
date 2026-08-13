class_name SocketLayout
extends Resource

@export var rune_slots: int = 0
@export var core_gem_slots: int = 0
@export var aux_gem_slots: int = 0


static func for_rarity(equip_slot: String, rarity: ItemData.ItemRarity) -> SocketLayout:
	var layout := SocketLayout.new()
	var is_weapon := equip_slot == "main_hand"
	var is_armor := equip_slot in ["head", "chest", "legs"]
	var is_ring := equip_slot.begins_with("ring")
	var is_tool := equip_slot.begins_with("tool")
	var is_off := equip_slot == "off_hand"

	match rarity:
		ItemData.ItemRarity.COMMON:
			if is_weapon:
				layout.rune_slots = 4
				layout.core_gem_slots = 1
				layout.aux_gem_slots = 1
			elif is_armor or is_off:
				layout.core_gem_slots = 1
				layout.aux_gem_slots = 1
			elif is_ring or is_tool:
				layout.core_gem_slots = 1
		ItemData.ItemRarity.UNCOMMON:
			if is_weapon:
				layout.rune_slots = 2
				layout.core_gem_slots = 1
			elif is_armor or is_off or is_ring or is_tool:
				layout.core_gem_slots = 1
		ItemData.ItemRarity.RARE:
			if is_weapon:
				layout.rune_slots = 2
				layout.core_gem_slots = 1
			elif is_armor or is_off:
				layout.core_gem_slots = 1
			elif is_ring or is_tool:
				layout.core_gem_slots = 1
		ItemData.ItemRarity.EPIC:
			if is_weapon:
				layout.rune_slots = 1
				layout.core_gem_slots = 1
			elif is_armor or is_off or is_ring:
				layout.core_gem_slots = 1
		ItemData.ItemRarity.LEGENDARY:
			if is_weapon:
				layout.rune_slots = 1
				layout.core_gem_slots = 0
			elif is_armor or is_ring:
				layout.core_gem_slots = 0
		_:
			pass
	return layout


func total_gem_slots() -> int:
	return maxi(0, core_gem_slots) + maxi(0, aux_gem_slots)


func describe() -> String:
	var parts: PackedStringArray = []
	if rune_slots > 0:
		parts.append("Rune x%d" % rune_slots)
	if core_gem_slots > 0:
		parts.append("Core Gem x%d" % core_gem_slots)
	if aux_gem_slots > 0:
		parts.append("Aux Gem x%d" % aux_gem_slots)
	if parts.is_empty():
		return "No sockets"
	return ", ".join(parts)
