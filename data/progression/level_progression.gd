class_name LevelProgression
extends RefCounted

## Diablo II XP-to-next curve scaled for this project (see xp_to_next.csv header rows).
## Source curve: D2 Experience.txt deltas × 0.1, rounded; level 99 = max (0).

const CSV_PATH := "res://data/progression/xp_to_next.csv"
const MAX_LEVEL := 99

static var _xp_to_next: Array[int] = []
static var _loaded: bool = false


static func ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	_xp_to_next.clear()
	_xp_to_next.append(0)  # unused index 0

	var file := FileAccess.open(CSV_PATH, FileAccess.READ)
	if file == null:
		push_error("LevelProgression: failed to open %s" % CSV_PATH)
		return

	var header := file.get_csv_line()
	if header.size() < 2 or header[0] != "level" or header[1] != "xp_to_next":
		push_error("LevelProgression: invalid CSV header in %s" % CSV_PATH)
		return

	while not file.eof_reached():
		var cols := file.get_csv_line()
		if cols.is_empty() or cols[0].is_empty():
			continue
		var level := int(cols[0])
		var xp := int(cols[1]) if cols.size() > 1 else 0
		while _xp_to_next.size() <= level:
			_xp_to_next.append(0)
		_xp_to_next[level] = xp


static func xp_to_next_for(level: int) -> int:
	ensure_loaded()
	if level < 1 or level >= _xp_to_next.size():
		return 0
	return _xp_to_next[level]


static func is_max_level(level: int) -> bool:
	return level >= MAX_LEVEL
