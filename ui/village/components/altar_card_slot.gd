class_name AltarCardSlot
extends PanelContainer

signal slot_pressed(index: int)
signal slot_activated(index: int)

var slot_index: int = -1
var _selected: bool = false
var _hovered: bool = false
var _rarity: ItemData.ItemRarity = ItemData.ItemRarity.COMMON
var _has_entry: bool = false
var _registered: bool = false
var _owned: bool = false
var _shelf_state: int = -1  # CardRegistrationService.CellState or -1 for altar mode

@onready var kind_label: Label = %KindLabel
@onready var name_label: Label = %NameLabel
@onready var equipped_label: Label = %EquippedLabel
@onready var icon_rect: TextureRect = %Icon


func _ready() -> void:
	theme_type_variation = &"InventorySlot"
	gui_input.connect(_on_gui_input)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	if icon_rect:
		icon_rect.texture_filter = TEXTURE_FILTER_NEAREST
	clear()


func setup(index: int) -> void:
	slot_index = index


func clear() -> void:
	_has_entry = false
	_registered = false
	_owned = false
	_shelf_state = -1
	if kind_label:
		kind_label.text = ""
		kind_label.visible = false
	if name_label:
		name_label.text = ""
		name_label.visible = false
	if equipped_label:
		equipped_label.visible = false
	_set_icon(null)
	_apply_visual_state()


func set_card(
	display_name: String,
	rarity: ItemData.ItemRarity,
	equipped: bool,
	registered: bool = false,
	owned: bool = true,
	icon: Texture2D = null
) -> void:
	_has_entry = true
	_shelf_state = -1
	_rarity = rarity
	_registered = registered
	_owned = owned
	if kind_label:
		kind_label.visible = false
	if name_label:
		name_label.visible = true
		name_label.text = display_name
	if equipped_label:
		if registered:
			equipped_label.visible = true
			equipped_label.text = tr("Registered")
		elif equipped:
			equipped_label.visible = true
			equipped_label.text = tr("Equipped")
		else:
			equipped_label.visible = false
	_set_icon(icon)
	_apply_visual_state()


func set_shelf_cell(
	state: int,
	display_name: String = "",
	rarity: ItemData.ItemRarity = ItemData.ItemRarity.COMMON,
	icon: Texture2D = null
) -> void:
	_shelf_state = state
	_rarity = rarity
	_registered = state == CardRegistrationService.CellState.REGISTERED
	_owned = (
		state == CardRegistrationService.CellState.OPEN
		or state == CardRegistrationService.CellState.REGISTERED
	)
	match state:
		CardRegistrationService.CellState.EMPTY:
			clear()
			return
		CardRegistrationService.CellState.SHELF_LOCKED:
			_has_entry = true
			if name_label:
				name_label.visible = true
				name_label.text = "—"
			if equipped_label:
				equipped_label.visible = true
				equipped_label.text = tr("SHELF_LOCKED")
		CardRegistrationService.CellState.FOG:
			_has_entry = true
			if name_label:
				name_label.visible = true
				name_label.text = "?"
			if equipped_label:
				equipped_label.visible = false
		CardRegistrationService.CellState.OPEN:
			_has_entry = true
			if name_label:
				name_label.visible = true
				name_label.text = display_name if not display_name.is_empty() else "?"
			if equipped_label:
				equipped_label.visible = false
		CardRegistrationService.CellState.REGISTERED:
			_has_entry = true
			if name_label:
				name_label.visible = true
				name_label.text = display_name if not display_name.is_empty() else "?"
			if equipped_label:
				equipped_label.visible = true
				equipped_label.text = tr("Registered")
	if kind_label:
		kind_label.visible = false
	var show_icon := (
		state == CardRegistrationService.CellState.OPEN
		or state == CardRegistrationService.CellState.REGISTERED
	)
	_set_icon(icon if show_icon else null)
	_apply_visual_state()


func set_selected(is_selected: bool) -> void:
	_selected = is_selected
	_apply_visual_state()


func _set_icon(texture: Texture2D) -> void:
	if icon_rect == null:
		return
	icon_rect.texture = texture
	icon_rect.visible = texture != null
	if name_label:
		name_label.offset_top = 40.0 if texture else 8.0


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
			if _shelf_state == CardRegistrationService.CellState.SHELF_LOCKED:
				style.border_color = UIColors.MAP_LOCKED
			elif _shelf_state == CardRegistrationService.CellState.FOG:
				style.border_color = UIColors.SLOT_BG_SOLID
			elif _registered:
				style.border_color = UIColors.GOLD
			elif not _owned:
				style.border_color = UIColors.SLOT_BG_SOLID
			else:
				style.border_color = ItemData.color_for_rarity(_rarity)
			add_theme_stylebox_override("panel", style)
	var color := UIColors.GOLD if _selected else UIColors.TEXT_MAIN
	if (
		_shelf_state == CardRegistrationService.CellState.SHELF_LOCKED
		or _shelf_state == CardRegistrationService.CellState.FOG
	):
		color = UIColors.TEXT_MUTED
	elif not _owned and not _registered and not _selected:
		color = UIColors.TEXT_MUTED
	if name_label:
		name_label.add_theme_color_override("font_color", color)
	if equipped_label:
		equipped_label.add_theme_color_override(
			"font_color",
			UIColors.GOLD if _selected else UIColors.TEXT_LORE
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
