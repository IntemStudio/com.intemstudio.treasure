class_name HudSlot
extends PanelContainer

@onready var empty_label: Label = %EmptyLabel
@onready var quantity_label: Label = %QuantityLabel
@onready var name_label: Label = %NameLabel


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if empty_label:
		empty_label.text = tr("Empty")
	if LocaleManager:
		LocaleManager.locale_changed.connect(_on_locale_changed)


func _on_locale_changed(_locale: String) -> void:
	if empty_label and empty_label.visible:
		empty_label.text = tr("Empty")


func set_item(item: ItemData) -> void:
	if item == null:
		clear()
		return
	empty_label.visible = false
	name_label.text = item.display_name
	name_label.visible = true
	if item.stackable and item.quantity > 1:
		quantity_label.text = str(item.quantity)
		quantity_label.visible = true
	else:
		quantity_label.visible = false


func set_skill(skill_name: String, _icon: Texture2D = null) -> void:
	var trimmed := skill_name.strip_edges()
	if trimmed.is_empty():
		clear()
		return
	empty_label.visible = false
	name_label.text = trimmed
	name_label.visible = true
	quantity_label.visible = false


func clear() -> void:
	empty_label.visible = true
	empty_label.text = tr("Empty")
	quantity_label.visible = false
	name_label.visible = false
	name_label.text = ""
