class_name SocketRow
extends PanelContainer

signal row_pressed(kind: String, index: int)
signal row_activated(kind: String, index: int)

var socket_kind: String = ""
var socket_index: int = 0
var _selected: bool = false
var _hovered: bool = false
var _filled: bool = false
var _rarity: ItemData.ItemRarity = ItemData.ItemRarity.COMMON

@onready var kind_label: Label = %KindLabel
@onready var value_label: Label = %ValueLabel


func _ready() -> void:
	theme_type_variation = &"InventorySlot"
	gui_input.connect(_on_gui_input)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	_apply_visual_state()


func setup(
	kind: String,
	index: int,
	display_name: String = "",
	rarity: ItemData.ItemRarity = ItemData.ItemRarity.COMMON
) -> void:
	socket_kind = kind
	socket_index = index
	_rarity = rarity
	_filled = not display_name.is_empty()
	if kind_label:
		kind_label.text = _kind_label(kind, index)
	if value_label:
		if _filled:
			value_label.text = display_name
			value_label.add_theme_color_override("font_color", _rarity_text_color())
		else:
			value_label.text = tr("Empty")
			value_label.add_theme_color_override("font_color", UIColors.TEXT_MUTED)
	_apply_visual_state()


func set_selected(is_selected: bool) -> void:
	_selected = is_selected
	_apply_visual_state()


func _kind_label(kind: String, index: int) -> String:
	var base := ""
	match kind:
		"rune":
			base = tr("Rune")
		"core_gem":
			base = tr("Core Gem")
		"aux_gem":
			base = tr("Aux Gem")
		_:
			base = tr(kind)
	return "%s %d" % [base, index + 1]


func _rarity_text_color() -> Color:
	if _rarity == ItemData.ItemRarity.COMMON:
		return UIColors.TEXT_MAIN
	return ItemData.color_for_rarity(_rarity)


func _apply_visual_state() -> void:
	remove_theme_stylebox_override("panel")
	if _selected:
		theme_type_variation = &"InventorySlotSelected"
	elif _hovered:
		theme_type_variation = &"InventorySlotHover"
	else:
		theme_type_variation = &"InventorySlot"
		if _filled:
			var style := get_theme_stylebox("panel", &"InventorySlot").duplicate() as StyleBoxFlat
			style.border_color = ItemData.color_for_rarity(_rarity)
			add_theme_stylebox_override("panel", style)
	var color := UIColors.GOLD if _selected else UIColors.TEXT_MUTED
	if kind_label:
		kind_label.add_theme_color_override("font_color", color)
	if value_label and _selected:
		value_label.add_theme_color_override("font_color", UIColors.GOLD)
	elif value_label and _filled:
		value_label.add_theme_color_override("font_color", _rarity_text_color())
	elif value_label:
		value_label.add_theme_color_override("font_color", UIColors.TEXT_MUTED)


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			row_pressed.emit(socket_kind, socket_index)
			if event.double_click:
				row_activated.emit(socket_kind, socket_index)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			row_activated.emit(socket_kind, socket_index)


func _on_mouse_entered() -> void:
	_hovered = true
	_apply_visual_state()


func _on_mouse_exited() -> void:
	_hovered = false
	_apply_visual_state()
