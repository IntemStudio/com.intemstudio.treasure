class_name SaveGame
extends RefCounted

var version: int = 1
var meta: Dictionary = {}
var character: CharacterStats
var inventory: InventoryData


func is_empty() -> bool:
	return character == null
