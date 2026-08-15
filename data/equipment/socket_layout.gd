class_name SocketLayout
extends Resource

@export var rune_slots: int = 0
@export var core_gem_slots: int = 0
@export var aux_gem_slots: int = 0


static func for_slot(equip_slot: String) -> SocketLayout:
	var layout := SocketLayout.new()
	if equip_slot == "main_hand":
		layout.rune_slots = 2
		layout.core_gem_slots = 2
		layout.aux_gem_slots = 2
	elif equip_slot == "off_hand" or equip_slot in ["head", "chest", "legs"]:
		layout.rune_slots = 1
		layout.core_gem_slots = 1
		layout.aux_gem_slots = 1
	elif equip_slot.begins_with("ring") or equip_slot.begins_with("tool"):
		layout.core_gem_slots = 1
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
