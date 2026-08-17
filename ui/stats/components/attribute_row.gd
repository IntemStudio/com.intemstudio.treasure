class_name AttributeRow
extends PanelContainer

signal selected(attr_id: String)
signal increment_requested(attr_id: String)

var attr_id: String = ""
var _selected: bool = false
var _hovered: bool = false

@onready var icon_rect: TextureRect = $Row/Icon
@onready var name_label: Label = $Row/Name
@onready var value_label: RichTextLabel = $Row/Value
@onready var plus_btn: Button = $Row/PlusBtn


func _ready() -> void:
	plus_btn.pressed.connect(_on_plus_pressed)
	gui_input.connect(_on_gui_input)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	focus_mode = Control.FOCUS_ALL
	icon_rect.texture_filter = TEXTURE_FILTER_NEAREST


func setup(id: String, display_name: String, value: int, icon: Texture2D = null) -> void:
	attr_id = id
	name_label.text = display_name
	if icon:
		icon_rect.texture = icon
	_refresh_value(value, 0)


func set_selected(is_selected: bool) -> void:
	_selected = is_selected
	plus_btn.visible = is_selected
	_apply_visual_state()


func set_preview_delta(value: int, delta: int) -> void:
	_refresh_value(value, delta)


func _refresh_value(value: int, delta: int) -> void:
	if delta > 0:
		value_label.text = "%d [color=#c9a84c]+%d[/color]" % [value, delta]
	else:
		value_label.text = str(value)


func _apply_visual_state() -> void:
	if _selected:
		theme_type_variation = &"AttributeRowSelected"
	elif _hovered:
		theme_type_variation = &"AttributeRowHover"
	else:
		theme_type_variation = &"AttributeRow"


func _on_plus_pressed() -> void:
	increment_requested.emit(attr_id)


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		selected.emit(attr_id)
		if event.double_click:
			increment_requested.emit(attr_id)


func _on_mouse_entered() -> void:
	_hovered = true
	_apply_visual_state()


func _on_mouse_exited() -> void:
	_hovered = false
	_apply_visual_state()
