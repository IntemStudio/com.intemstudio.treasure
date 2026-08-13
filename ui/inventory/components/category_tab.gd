class_name CategoryTab
extends Button

signal tab_selected(tab_id: String)

var tab_id: String = "weapon"


func setup(id: String, label_text: String) -> void:
	tab_id = id
	text = label_text
	if not pressed.is_connected(_on_pressed):
		pressed.connect(_on_pressed)


func set_active(active: bool) -> void:
	if active:
		add_theme_color_override("font_color", UIColors.GOLD)
	else:
		add_theme_color_override("font_color", UIColors.TEXT_MUTED)


func _on_pressed() -> void:
	tab_selected.emit(tab_id)
