class_name EquipmentSlot
extends PanelContainer

signal slot_pressed(slot_id: String)
signal slot_activated(slot_id: String)

@onready var slot_icon: TextureRect = $Content/SlotIcon
@onready var name_label: Label = $Content/Name

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
	LocaleManager.locale_changed.connect(_on_locale_changed)


func _on_locale_changed(_locale: String) -> void:
	_refresh_labels()


func setup(id: String, slot_texture: Texture2D = null) -> void:
	slot_id = id
	if slot_texture:
		slot_icon.texture = slot_texture
	_refresh_labels()


func set_item(item: ItemData) -> void:
	_item = item
	_refresh_labels()
	_apply_visual_state()


func set_blocked(blocked: bool) -> void:
	_blocked = blocked
	_refresh_labels()
	_apply_visual_state()


func _refresh_labels() -> void:
	if name_label == null:
		return
	var top := tr("Two-handed") if _blocked and _item == null else tr("Empty")
	if _item:
		top = tr(_item.display_name)
	name_label.visible = true
	name_label.text = "%s\n(%s)" % [top, tr(_slot_name_key())]


func _slot_name_key() -> String:
	match slot_id:
		"main_hand":
			return "EQUIP_SLOT_MAIN_HAND"
		"off_hand":
			return "EQUIP_SLOT_OFF_HAND"
		"head":
			return "SLOT_HELMETS"
		"chest":
			return "SLOT_BODY"
		"legs":
			return "EQUIP_SLOT_LEGS"
		"ring_1", "ring_2":
			return "SLOT_RINGS"
		"tool_1", "tool_2":
			return "SLOT_TOOLS"
		_:
			return slot_id


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
			style.bg_color = (
				UIColors.with_alpha(UIColors.PANEL_BG, 0.85)
				if _hovered
				else UIColors.with_alpha(UIColors.SLOT_BG_SOLID, 0.80)
			)
			style.border_color = _item.get_rarity_color()
			style.set_border_width_all(1)
			style.set_content_margin_all(6)
			add_theme_stylebox_override("panel", style)
	var color := UIColors.GOLD if _selected else _item_text_color()
	if _item == null and not _selected:
		color = UIColors.TEXT_MUTED
	name_label.add_theme_color_override("font_color", color)


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
