class_name ItemCatalog
extends RefCounted

const ITEMS_DIR := "res://ui/inventory/resources/items/"

var _templates: Dictionary = {}


func _init() -> void:
	_register_bootstrap()
	_register_tres_fallback()


func has_id(item_id: String) -> bool:
	return _templates.has(item_id)


func get_item(item_id: String) -> ItemData:
	if not _templates.has(item_id):
		return null
	return (_templates[item_id] as ItemData).duplicate(true)


func _register_bootstrap() -> void:
	var factories: Array[Callable] = [
		ItemBootstrap.create_claymore,
		ItemBootstrap.create_blood_rusted_sword,
		ItemBootstrap.create_iron_helm,
		ItemBootstrap.create_chain_chest,
		ItemBootstrap.create_health_potion,
		ItemBootstrap.create_dried_fish,
		ItemBootstrap.create_iron_ore,
		ItemBootstrap.create_fishing_rod,
		ItemBootstrap.create_rare_dagger,
	]
	for factory in factories:
		var item: ItemData = factory.call()
		if item and not item.id.is_empty():
			_templates[item.id] = item


func _register_tres_fallback() -> void:
	var dir := DirAccess.open(ITEMS_DIR)
	if dir == null:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var path := ITEMS_DIR.path_join(file_name)
			var loaded := load(path)
			if loaded is ItemData:
				var item := loaded as ItemData
				if not item.id.is_empty() and not _templates.has(item.id):
					_templates[item.id] = item
		file_name = dir.get_next()
	dir.list_dir_end()
