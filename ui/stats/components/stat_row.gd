class_name StatRow
extends PanelContainer

signal inspected(stat_key: String)

var stat_key: String = ""
var _selected: bool = false
var _hovered: bool = false

@onready var name_label: Label = $Row/Name
@onready var value_label: Label = $Row/Value


func _ready() -> void:
	gui_input.connect(_on_gui_input)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	theme_type_variation = &"AttributeRow"


func setup(key: String, stat_name: String, value: Variant) -> void:
	stat_key = key
	name_label.text = stat_name
	if value is float:
		value_label.text = "%.1f" % value
	else:
		value_label.text = str(value)


func set_selected(is_selected: bool) -> void:
	_selected = is_selected
	_apply_visual_state()


func _apply_visual_state() -> void:
	if _selected:
		theme_type_variation = &"AttributeRowSelected"
	elif _hovered:
		theme_type_variation = &"AttributeRowHover"
	else:
		theme_type_variation = &"AttributeRow"


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		inspected.emit(stat_key)


func _on_mouse_entered() -> void:
	_hovered = true
	_apply_visual_state()
	if not stat_key.is_empty():
		inspected.emit(stat_key)


func _on_mouse_exited() -> void:
	_hovered = false
	_apply_visual_state()
