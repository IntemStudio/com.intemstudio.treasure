class_name InventorySlot
extends PanelContainer

signal slot_pressed(index: int)
signal slot_activated(index: int)

var slot_index: int = -1
var _item: ItemData
var _has_entry: bool = false
var _entry_rarity: ItemData.ItemRarity = ItemData.ItemRarity.COMMON
var _selected: bool = false
var _hovered: bool = false

@onready var name_label: Label = $Content/Name
@onready var quantity_label: Label = $Content/Quantity
@onready var badge_label: Label = %Badge
@onready var icon_rect: TextureRect = $Content/Icon


func _ready() -> void:
	theme_type_variation = &"InventorySlot"
	gui_input.connect(_on_gui_input)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	if icon_rect:
		icon_rect.texture_filter = TEXTURE_FILTER_NEAREST


func setup(index: int) -> void:
	slot_index = index


func set_item(item: ItemData) -> void:
	_item = item
	_has_entry = item != null
	if item:
		_entry_rarity = item.rarity
		name_label.text = tr(item.display_name)
		name_label.visible = true
		quantity_label.visible = item.stackable and item.quantity > 1
		quantity_label.text = str(item.quantity)
		_set_icon(item.icon)
	else:
		name_label.visible = false
		name_label.text = ""
		quantity_label.visible = false
		_entry_rarity = ItemData.ItemRarity.COMMON
		_set_icon(null)
	_set_badge(false)
	_apply_visual_state()


func set_modifier_entry(
	display_name: String,
	rarity: ItemData.ItemRarity,
	socketed: bool = false,
	icon: Texture2D = null
) -> void:
	_item = null
	_has_entry = true
	_entry_rarity = rarity
	name_label.text = display_name
	name_label.visible = true
	quantity_label.visible = false
	_set_badge(socketed)
	_set_icon(icon)
	_apply_visual_state()


func clear_entry() -> void:
	_item = null
	_has_entry = false
	_entry_rarity = ItemData.ItemRarity.COMMON
	name_label.visible = false
	name_label.text = ""
	quantity_label.visible = false
	_set_badge(false)
	_set_icon(null)
	_apply_visual_state()


func _set_icon(texture: Texture2D) -> void:
	if icon_rect == null:
		return
	icon_rect.texture = texture
	icon_rect.visible = texture != null
	name_label.offset_top = 42.0 if texture else 4.0


func _set_badge(socketed: bool) -> void:
	if badge_label == null:
		return
	badge_label.visible = socketed
	if socketed:
		badge_label.text = tr("SOCKETED")


func set_selected(is_selected: bool) -> void:
	_selected = is_selected
	_apply_visual_state()


func _apply_visual_state() -> void:
	remove_theme_stylebox_override("panel")
	if _selected:
		theme_type_variation = &"InventorySlotSelected"
	elif _hovered:
		theme_type_variation = &"InventorySlotHover"
	else:
		theme_type_variation = &"InventorySlot"
		if _has_entry:
			var style := get_theme_stylebox("panel", &"InventorySlot").duplicate() as StyleBoxFlat
			style.border_color = ItemData.color_for_rarity(_entry_rarity)
			add_theme_stylebox_override("panel", style)
	var color := UIColors.GOLD if _selected else UIColors.TEXT_MAIN
	name_label.add_theme_color_override("font_color", color)
	quantity_label.add_theme_color_override("font_color", color)


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			slot_pressed.emit(slot_index)
			if event.double_click:
				slot_activated.emit(slot_index)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			slot_activated.emit(slot_index)


func _on_mouse_entered() -> void:
	_hovered = true
	_apply_visual_state()


func _on_mouse_exited() -> void:
	_hovered = false
	_apply_visual_state()
