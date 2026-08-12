class_name FooterPromptLabel
extends HBoxContainer

signal pressed

@onready var key_label: Label = %KeyLabel
@onready var action_label: Label = %ActionLabel


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


func setup(button_text: String, label_text: String) -> void:
	if key_label == null:
		key_label = %KeyLabel
	if action_label == null:
		action_label = %ActionLabel
	key_label.text = button_text
	action_label.text = label_text


func set_hovered(hovered: bool) -> void:
	if action_label == null:
		return
	if hovered:
		action_label.add_theme_color_override("font_color", UIColors.GOLD)
	else:
		action_label.remove_theme_color_override("font_color")


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pressed.emit()
		accept_event()
