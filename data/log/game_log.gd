class_name GameLog
extends RefCounted

signal entry_added(entry: GameLogEntry)
signal cleared

const MAX_ENTRIES := 200

var entries: Array[GameLogEntry] = []


func push(payload: Dictionary) -> GameLogEntry:
	var entry := GameLogEntry.from_payload(payload)
	entries.append(entry)
	while entries.size() > MAX_ENTRIES:
		entries.pop_front()
	entry_added.emit(entry)
	return entry


func clear() -> void:
	if entries.is_empty():
		cleared.emit()
		return
	entries.clear()
	cleared.emit()
