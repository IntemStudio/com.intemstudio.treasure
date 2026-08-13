class_name GameLogView
extends Control

@onready var scroll: ScrollContainer = %Scroll
@onready var log_label: RichTextLabel = %LogLabel

var _log: GameLog
var _pending_log: GameLog
var _follow_bottom: bool = true


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	if LocaleManager and not LocaleManager.locale_changed.is_connected(_on_locale_changed):
		LocaleManager.locale_changed.connect(_on_locale_changed)
	if _pending_log != null:
		bind_log(_pending_log)
		_pending_log = null
	else:
		_rebuild()


func bind_log(log: GameLog) -> void:
	if not is_node_ready():
		_pending_log = log
		return
	_unbind_log()
	_log = log
	if _log:
		if not _log.entry_added.is_connected(_on_entry_added):
			_log.entry_added.connect(_on_entry_added)
		if not _log.cleared.is_connected(_on_cleared):
			_log.cleared.connect(_on_cleared)
	_follow_bottom = true
	_rebuild()
	_scroll_to_bottom()


func _unbind_log() -> void:
	if _log:
		if _log.entry_added.is_connected(_on_entry_added):
			_log.entry_added.disconnect(_on_entry_added)
		if _log.cleared.is_connected(_on_cleared):
			_log.cleared.disconnect(_on_cleared)
	_log = null


func _on_entry_added(_entry: GameLogEntry) -> void:
	_follow_bottom = _is_at_bottom()
	_rebuild()
	if _follow_bottom:
		_scroll_to_bottom()


func _on_cleared() -> void:
	_follow_bottom = true
	_rebuild()


func _on_locale_changed(_locale: String) -> void:
	_rebuild()


func _rebuild() -> void:
	if log_label == null:
		return
	if _log == null or _log.entries.is_empty():
		log_label.text = ""
		return
	var lines: PackedStringArray = PackedStringArray()
	for entry in _log.entries:
		var line := GameLogFormatter.format_bbcode(entry)
		if not line.is_empty():
			lines.append(line)
	log_label.text = "\n".join(lines)


func _is_at_bottom() -> bool:
	if scroll == null:
		return true
	var bar := scroll.get_v_scroll_bar()
	if bar == null:
		return true
	return bar.value >= bar.max_value - bar.page - 8.0


func _scroll_to_bottom() -> void:
	if scroll == null:
		return
	await get_tree().process_frame
	if not is_instance_valid(scroll):
		return
	var bar := scroll.get_v_scroll_bar()
	if bar:
		scroll.scroll_vertical = int(bar.max_value)
