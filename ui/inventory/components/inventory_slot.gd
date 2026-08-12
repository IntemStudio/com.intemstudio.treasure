class_name InventorySlot
extends PanelContainer

signal slot_pressed(index: int)
signal slot_activated(index: int)
signal slot_discard_requested(index: int)

var slot_index: int = -1
var _item: ItemData
var _selected: bool = false
var _hovered: bool = false

@onready var icon_rect: TextureRect = $Content/Icon
@onready var quantity_label: Label = $Content/Quantity
@onready var selection_frame: NinePatchRect = $Content/SelectionFrame


func _ready() -> void:
	theme_type_variation = &"InventorySlot"
	gui_input.connect(_on_gui_input)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func setup(index: int) -> void:
	slot_index = index


func set_item(item: ItemData) -> void:
	_item = item
	if item:
		icon_rect.texture = item.icon if item.icon else load("res://icon.svg")
		icon_rect.visible = true
		quantity_label.visible = item.stackable and item.quantity > 1
		quantity_label.text = str(item.quantity)
	else:
		icon_rect.visible = false
		quantity_label.visible = false
	_apply_visual_state()


func set_selected(is_selected: bool) -> void:
	_selected = is_selected
	selection_frame.visible = is_selected
	_apply_visual_state()


func _apply_visual_state() -> void:
	remove_theme_stylebox_override("panel")
	if _selected:
		theme_type_variation = &"InventorySlotSelected"
	elif _hovered:
		theme_type_variation = &"InventorySlotHover"
	else:
		theme_type_variation = &"InventorySlot"
		if _item:
			var style := StyleBoxFlat.new()
			style.bg_color = Color(0.06, 0.06, 0.07, 0.7)
			style.border_color = _item.get_rarity_color()
			style.set_border_width_all(1)
			style.set_content_margin_all(4)
			add_theme_stylebox_override("panel", style)


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			slot_pressed.emit(slot_index)
			if event.double_click:
				slot_activated.emit(slot_index)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			slot_discard_requested.emit(slot_index)


func _on_mouse_entered() -> void:
	_hovered = true
	_apply_visual_state()


func _on_mouse_exited() -> void:
	_hovered = false
	_apply_visual_state()
