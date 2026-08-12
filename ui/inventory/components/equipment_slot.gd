class_name EquipmentSlot
extends PanelContainer

signal slot_pressed(slot_id: String)
signal slot_activated(slot_id: String)

@onready var slot_icon: TextureRect = $Row/SlotIcon
@onready var item_icon: TextureRect = $Row/ItemIcon
@onready var empty_label: Label = $Row/EmptyLabel

var slot_id: String = ""
var _selected: bool = false
var _hovered: bool = false


func _ready() -> void:
	theme_type_variation = &"EquipmentSlot"
	gui_input.connect(_on_gui_input)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	empty_label.text = tr("Empty")
	LocaleManager.locale_changed.connect(_on_locale_changed)


func _on_locale_changed(_locale: String) -> void:
	empty_label.text = tr("Empty")


func setup(id: String, slot_texture: Texture2D = null) -> void:
	slot_id = id
	if slot_texture:
		slot_icon.texture = slot_texture


func set_item(item: ItemData) -> void:
	if item:
		item_icon.texture = item.icon if item.icon else load("res://icon.svg")
		item_icon.visible = true
		empty_label.visible = false
	else:
		item_icon.visible = false
		empty_label.visible = true


func set_selected(is_selected: bool) -> void:
	_selected = is_selected
	_apply_visual_state()


func _apply_visual_state() -> void:
	if _selected:
		theme_type_variation = &"InventorySlotSelected"
	elif _hovered:
		theme_type_variation = &"EquipmentSlotHover"
	else:
		theme_type_variation = &"EquipmentSlot"


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		slot_pressed.emit(slot_id)
		if event.double_click:
			slot_activated.emit(slot_id)


func _on_mouse_entered() -> void:
	_hovered = true
	_apply_visual_state()


func _on_mouse_exited() -> void:
	_hovered = false
	_apply_visual_state()
