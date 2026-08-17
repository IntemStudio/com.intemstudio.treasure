class_name CategoryTab
extends Button

signal tab_selected(tab_id: String)

var tab_id: String = "weapon"


func setup(id: String, label_text: String, tab_icon: Texture2D = null) -> void:
	tab_id = id
	text = label_text
	if tab_icon:
		icon = tab_icon
		expand_icon = false
		texture_filter = TEXTURE_FILTER_NEAREST
		add_theme_constant_override("icon_max_width", 20)
	if not pressed.is_connected(_on_pressed):
		pressed.connect(_on_pressed)


func set_active(active: bool) -> void:
	if active:
		add_theme_color_override("font_color", UIColors.GOLD)
	else:
		add_theme_color_override("font_color", UIColors.TEXT_MUTED)


func _on_pressed() -> void:
	tab_selected.emit(tab_id)
