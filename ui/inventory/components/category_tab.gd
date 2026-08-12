class_name CategoryTab
extends Button

signal tab_selected(category: ItemData.ItemCategory)

var category: ItemData.ItemCategory = ItemData.ItemCategory.WEAPON


func setup(cat: ItemData.ItemCategory, label_text: String) -> void:
	category = cat
	text = label_text
	pressed.connect(_on_pressed)


func set_active(active: bool) -> void:
	if active:
		add_theme_color_override("font_color", UIColors.GOLD)
	else:
		add_theme_color_override("font_color", UIColors.TEXT_MUTED)


func _on_pressed() -> void:
	tab_selected.emit(category)
