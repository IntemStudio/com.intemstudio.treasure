extends Node

signal save_completed(slot: int, ok: bool)
signal load_completed(slot: int, ok: bool)
signal slot_deleted(slot: int)

const SAVE_VERSION := 1
const SLOT_COUNT := 4
const SAVE_DIR := "user://saves/"
const TMP_SUFFIX := ".tmp"
const CHARACTER_TEMPLATE_PATH := "res://ui/stats/resources/character_stats.tres"

var current_slot: int = -1
var play_time_sec: float = 0.0

var _catalog: ItemCatalog
var _slot_created_at: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_catalog = ItemCatalog.new()
	ensure_save_dir()


func _process(delta: float) -> void:
	var tree := get_tree()
	if tree == null or tree.paused:
		return
	play_time_sec += delta


func ensure_save_dir() -> void:
	if DirAccess.dir_exists_absolute(SAVE_DIR):
		return
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)


func get_save_dir_global_path() -> String:
	ensure_save_dir()
	return ProjectSettings.globalize_path(SAVE_DIR)


func open_save_folder() -> Error:
	var absolute := get_save_dir_global_path()
	var err := OS.shell_open(absolute)
	if err != OK:
		push_warning("SaveManager: failed to open save folder '%s' (%s)" % [absolute, error_string(err)])
	return err


func get_slot_path(slot: int) -> String:
	return SAVE_DIR.path_join("slot_%d.json" % slot)


func has_save(slot: int) -> bool:
	if not _is_valid_slot(slot):
		return false
	return FileAccess.file_exists(get_slot_path(slot))


func get_slot_info(slot: int) -> Dictionary:
	if not _is_valid_slot(slot):
		return {"status": "empty", "meta": {}}
	var path := get_slot_path(slot)
	if not FileAccess.file_exists(path):
		return {"status": "empty", "meta": {}}

	var parsed := _read_json_file(path)
	if parsed.is_empty():
		return {"status": "corrupt", "meta": {}}

	var version := int(parsed.get("version", -1))
	if version < 1:
		return {"status": "corrupt", "meta": {}}
	if version > SAVE_VERSION:
		return {"status": "incompatible", "meta": parsed.get("meta", {})}

	if not parsed.has("character") or not parsed.has("inventory"):
		return {"status": "corrupt", "meta": parsed.get("meta", {})}

	return {
		"status": "valid",
		"meta": (parsed.get("meta", {}) as Dictionary).duplicate(true),
	}


func list_slots() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for slot in range(SLOT_COUNT):
		var info := get_slot_info(slot)
		info["slot"] = slot
		result.append(info)
	return result


func new_game(slot: int) -> SaveGame:
	if not _is_valid_slot(slot):
		return null
	var save := SaveGame.new()
	save.version = SAVE_VERSION
	save.character = load(CHARACTER_TEMPLATE_PATH).duplicate(true)
	save.character.apply_new_game_start()
	save.inventory = ItemBootstrap.create_sample_inventory()
	save.meta = {
		"slot": slot,
		"created_at": _now_iso(),
		"updated_at": _now_iso(),
		"play_time_sec": 0,
		"character_name": save.character.character_name,
		"level": save.character.level,
	}
	current_slot = slot
	play_time_sec = 0.0
	_slot_created_at[slot] = save.meta["created_at"]
	var err := save_game(slot, save.character, save.inventory)
	if err != OK:
		return null
	return save


func save_game(slot: int, character: CharacterStats, inventory: InventoryData) -> Error:
	if not _is_valid_slot(slot):
		save_completed.emit(slot, false)
		return ERR_INVALID_PARAMETER
	if character == null or inventory == null:
		save_completed.emit(slot, false)
		return ERR_INVALID_PARAMETER

	ensure_save_dir()
	var created_at := str(_slot_created_at.get(slot, ""))
	if created_at.is_empty():
		var existing := get_slot_info(slot)
		if existing.get("status") == "valid":
			created_at = str((existing.get("meta", {}) as Dictionary).get("created_at", ""))
	if created_at.is_empty():
		created_at = _now_iso()
	_slot_created_at[slot] = created_at

	var meta := {
		"slot": slot,
		"created_at": created_at,
		"updated_at": _now_iso(),
		"play_time_sec": int(play_time_sec),
		"character_name": character.character_name,
		"level": character.level,
	}
	var data := SaveSerializer.to_dict(character, inventory, meta, SAVE_VERSION)
	var err := _write_atomic(get_slot_path(slot), data)
	var ok := err == OK
	if ok:
		current_slot = slot
	save_completed.emit(slot, ok)
	return err


func load_game(slot: int) -> SaveGame:
	if not _is_valid_slot(slot):
		load_completed.emit(slot, false)
		return null
	var path := get_slot_path(slot)
	if not FileAccess.file_exists(path):
		load_completed.emit(slot, false)
		return null

	var data := _read_json_file(path)
	if data.is_empty():
		load_completed.emit(slot, false)
		return null

	var version := int(data.get("version", -1))
	if version < 1:
		load_completed.emit(slot, false)
		return null
	if version > SAVE_VERSION:
		load_completed.emit(slot, false)
		return null
	if version < SAVE_VERSION:
		data = _migrate(data, version)
		if data.is_empty():
			load_completed.emit(slot, false)
			return null

	if not data.has("character") or not data.has("inventory"):
		load_completed.emit(slot, false)
		return null

	var save := SaveSerializer.from_dict(data, _catalog)
	current_slot = slot
	play_time_sec = float((save.meta as Dictionary).get("play_time_sec", 0))
	_slot_created_at[slot] = str(save.meta.get("created_at", _now_iso()))
	load_completed.emit(slot, true)
	return save


func delete_slot(slot: int) -> Error:
	if not _is_valid_slot(slot):
		return ERR_INVALID_PARAMETER
	var path := get_slot_path(slot)
	if FileAccess.file_exists(path):
		var err := DirAccess.remove_absolute(path)
		if err != OK:
			return err
	_slot_created_at.erase(slot)
	if current_slot == slot:
		current_slot = -1
		play_time_sec = 0.0
	slot_deleted.emit(slot)
	return OK


func _is_valid_slot(slot: int) -> bool:
	return slot >= 0 and slot < SLOT_COUNT


func _migrate(data: Dictionary, from_version: int) -> Dictionary:
	var v := from_version
	while v < SAVE_VERSION:
		match v:
			1:
				pass
			_:
				push_error("SaveManager: no migrator for version %d" % v)
				return {}
		v += 1
	data["version"] = SAVE_VERSION
	return data


func _write_atomic(path: String, data: Dictionary) -> Error:
	var tmp_path := path + TMP_SUFFIX
	var json_text := JSON.stringify(data, "\t")
	var file := FileAccess.open(tmp_path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(json_text)
	file.close()

	if FileAccess.file_exists(path):
		var remove_err := DirAccess.remove_absolute(path)
		if remove_err != OK:
			DirAccess.remove_absolute(tmp_path)
			return remove_err
	var rename_err := DirAccess.rename_absolute(tmp_path, path)
	if rename_err != OK:
		DirAccess.remove_absolute(tmp_path)
		return rename_err
	return OK


func _read_json_file(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var text := file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed as Dictionary


func _now_iso() -> String:
	return Time.get_datetime_string_from_system(true)
