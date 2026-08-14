class_name EquipmentSlot
extends PanelContainer

signal slot_pressed(slot_id: String)
signal slot_activated(slot_id: String)

@onready var slot_icon: TextureRect = $Content/SlotIcon
@onready var name_label: Label = $Content/Name
@onready var empty_label: Label = $Content/EmptyLabel

var slot_id: String = ""
var _selected: bool = false
var _hovered: bool = false
var _blocked: bool = false
var _item: ItemData


func _ready() -> void:
	theme_type_variation = &"EquipmentSlot"
	gui_input.connect(_on_gui_input)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	empty_label.text = tr("Empty")
	LocaleManager.locale_changed.connect(_on_locale_changed)


func _on_locale_changed(_locale: String) -> void:
	_refresh_labels()


func setup(id: String, slot_texture: Texture2D = null) -> void:
	slot_id = id
	if slot_texture:
		slot_icon.texture = slot_texture


func set_item(item: ItemData) -> void:
	_item = item
	_refresh_labels()
	_apply_visual_state()


func set_blocked(blocked: bool) -> void:
	_blocked = blocked
	_refresh_labels()
	_apply_visual_state()


func _refresh_labels() -> void:
	if _item:
		name_label.text = tr(_item.display_name)
		name_label.visible = true
		empty_label.visible = false
	else:
		name_label.visible = false
		name_label.text = ""
		empty_label.visible = true
		empty_label.text = tr("Two-handed") if _blocked else tr("Empty")


func set_selected(is_selected: bool) -> void:
	_selected = is_selected
	_apply_visual_state()


func _apply_visual_state() -> void:
	remove_theme_stylebox_override("panel")
	if _selected:
		theme_type_variation = &"InventorySlotSelected"
	elif _hovered and _item == null:
		theme_type_variation = &"EquipmentSlotHover"
	else:
		theme_type_variation = &"EquipmentSlot"
		if _item:
			var style := StyleBoxFlat.new()
			style.bg_color = Color(0.08, 0.08, 0.09, 0.85) if _hovered else Color(0.05, 0.05, 0.06, 0.8)
			style.border_color = _item.get_rarity_color()
			style.set_border_width_all(1)
			style.set_content_margin_all(6)
			add_theme_stylebox_override("panel", style)
	var color := UIColors.GOLD if _selected else _item_text_color()
	name_label.add_theme_color_override("font_color", color)
	empty_label.add_theme_color_override(
		"font_color",
		UIColors.GOLD if _selected else (UIColors.TEXT_MUTED if _blocked else Color(0.55, 0.53, 0.5, 1))
	)


func _item_text_color() -> Color:
	if _item == null:
		return UIColors.TEXT_MAIN
	if _item.rarity == ItemData.ItemRarity.COMMON:
		return UIColors.TEXT_MAIN
	return _item.get_rarity_color()


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			slot_pressed.emit(slot_id)
			if event.double_click:
				slot_activated.emit(slot_id)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			slot_activated.emit(slot_id)


func _on_mouse_entered() -> void:
	_hovered = true
	_apply_visual_state()


func _on_mouse_exited() -> void:
	_hovered = false
	_apply_visual_state()
