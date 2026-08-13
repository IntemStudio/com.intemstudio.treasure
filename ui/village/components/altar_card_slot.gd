class_name AltarCardSlot
extends PanelContainer

signal slot_pressed(index: int)
signal slot_activated(index: int)

var slot_index: int = -1
var _selected: bool = false
var _hovered: bool = false
var _rarity: ItemData.ItemRarity = ItemData.ItemRarity.COMMON
var _has_entry: bool = false

@onready var kind_label: Label = %KindLabel
@onready var name_label: Label = %NameLabel
@onready var equipped_label: Label = %EquippedLabel


func _ready() -> void:
	theme_type_variation = &"InventorySlot"
	gui_input.connect(_on_gui_input)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	clear()


func setup(index: int) -> void:
	slot_index = index


func clear() -> void:
	_has_entry = false
	if kind_label:
		kind_label.text = ""
		kind_label.visible = false
	if name_label:
		name_label.text = ""
		name_label.visible = false
	if equipped_label:
		equipped_label.visible = false
	_apply_visual_state()


func set_card(
	display_name: String,
	kind: String,
	rarity: ItemData.ItemRarity,
	equipped: bool
) -> void:
	_has_entry = true
	_rarity = rarity
	if kind_label:
		kind_label.visible = true
		kind_label.text = tr("Rune") if kind == "rune" else tr("Gem")
	if name_label:
		name_label.visible = true
		name_label.text = display_name
	if equipped_label:
		equipped_label.visible = equipped
		equipped_label.text = tr("Equipped")
	_apply_visual_state()


func set_selected(is_selected: bool) -> void:
	_selected = is_selected
	_apply_visual_state()


func _rarity_color() -> Color:
	match _rarity:
		ItemData.ItemRarity.UNCOMMON:
			return Color(0.45, 0.85, 0.55)
		ItemData.ItemRarity.RARE:
			return UIColors.RARE_GLOW
		ItemData.ItemRarity.EPIC:
			return Color(0.85, 0.55, 0.25)
		ItemData.ItemRarity.LEGENDARY:
			return UIColors.GOLD
		_:
			return Color(0.35, 0.34, 0.33)


func _apply_visual_state() -> void:
	remove_theme_stylebox_override("panel")
	if _selected:
		theme_type_variation = &"InventorySlotSelected"
	elif _hovered:
		theme_type_variation = &"InventorySlotHover"
	else:
		theme_type_variation = &"InventorySlot"
		if _has_entry:
			var style := StyleBoxFlat.new()
			style.bg_color = Color(0.06, 0.06, 0.07, 0.7)
			style.border_color = _rarity_color()
			style.set_border_width_all(2 if _selected else 1)
			style.set_content_margin_all(4)
			add_theme_stylebox_override("panel", style)
	var color := UIColors.GOLD if _selected else UIColors.TEXT_MAIN
	if name_label:
		name_label.add_theme_color_override("font_color", color)
	if kind_label:
		var kind_color := Color(0.55, 0.75, 0.95) if kind_label.text == tr("Rune") else Color(0.85, 0.65, 0.45)
		if _selected:
			kind_color = UIColors.GOLD
		kind_label.add_theme_color_override("font_color", kind_color)
	if equipped_label:
		equipped_label.add_theme_color_override(
			"font_color",
			Color(0.95, 0.75, 0.35) if not _selected else UIColors.GOLD
		)


func _on_gui_input(event: InputEvent) -> void:
	if not _has_entry:
		return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			slot_pressed.emit(slot_index)
			if event.double_click:
				slot_activated.emit(slot_index)


func _on_mouse_entered() -> void:
	_hovered = true
	_apply_visual_state()


func _on_mouse_exited() -> void:
	_hovered = false
	_apply_visual_state()
