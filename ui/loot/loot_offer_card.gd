class_name LootOfferCard
extends PanelContainer

## One of three centered reward cards — full detail is shown in-place.

signal card_pressed(index: int)
signal card_activated(index: int)

const DETAIL_SCENE := preload("res://ui/inventory/components/item_detail_panel.tscn")
const MODIFIER_DETAIL_SCENE := preload("res://ui/loot/modifier_detail_panel.tscn")

var card_index: int = -1
var _selected: bool = false
var _hovered: bool = false
var _rarity: ItemData.ItemRarity = ItemData.ItemRarity.COMMON
var _has_offer: bool = false
var _item_detail: ItemDetailPanel
var _modifier_detail: ModifierDetailPanel

@onready var content_host: Control = %ContentHost


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	gui_input.connect(_on_gui_input)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	var scroll := get_node_or_null("Scroll") as ScrollContainer
	if scroll:
		scroll.gui_input.connect(_on_gui_input)
		scroll.mouse_entered.connect(_on_mouse_entered)
		scroll.mouse_exited.connect(_on_mouse_exited)
	_apply_visual_state()


func setup(index: int) -> void:
	card_index = index


func clear_offer() -> void:
	_has_offer = false
	_rarity = ItemData.ItemRarity.COMMON
	if _item_detail:
		_item_detail.visible = false
		_item_detail.set_item(null)
	if _modifier_detail:
		_modifier_detail.visible = false
		_modifier_detail.clear()
	_apply_visual_state()


func set_offer(offer: Dictionary, compare_with: ItemData = null) -> void:
	_has_offer = true
	_rarity = _offer_rarity(offer)
	_ensure_panels()
	var kind := str(offer.get("kind", ""))
	if kind == "weapon" or kind == "armor":
		if _modifier_detail:
			_modifier_detail.visible = false
			_modifier_detail.clear()
		if _item_detail:
			_item_detail.visible = true
			_item_detail.set_item(offer.get("item") as ItemData, compare_with)
			_ignore_mouse_tree(_item_detail)
	elif kind == "rune":
		if _item_detail:
			_item_detail.visible = false
			_item_detail.set_item(null)
		if _modifier_detail:
			_modifier_detail.visible = true
			_modifier_detail.set_rune(offer.get("rune") as RuneData)
			_ignore_mouse_tree(_modifier_detail)
	elif kind == "gem":
		if _item_detail:
			_item_detail.visible = false
			_item_detail.set_item(null)
		if _modifier_detail:
			_modifier_detail.visible = true
			_modifier_detail.set_gem(offer.get("gem") as GemData)
			_ignore_mouse_tree(_modifier_detail)
	else:
		clear_offer()
		return
	_apply_visual_state()


func set_selected(selected: bool) -> void:
	_selected = selected
	_apply_visual_state()


func _ensure_panels() -> void:
	if content_host == null:
		return
	if _item_detail == null:
		_item_detail = DETAIL_SCENE.instantiate() as ItemDetailPanel
		content_host.add_child(_item_detail)
		_item_detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_flatten_inner_panel(_item_detail)
		_ignore_mouse_tree(_item_detail)
	if _modifier_detail == null:
		_modifier_detail = MODIFIER_DETAIL_SCENE.instantiate() as ModifierDetailPanel
		content_host.add_child(_modifier_detail)
		_modifier_detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_flatten_inner_panel(_modifier_detail)
		_ignore_mouse_tree(_modifier_detail)


func _flatten_inner_panel(panel: PanelContainer) -> void:
	var empty := StyleBoxEmpty.new()
	panel.add_theme_stylebox_override("panel", empty)


func _ignore_mouse_tree(node: Node) -> void:
	if node is Control:
		(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_ignore_mouse_tree(child)

func _offer_rarity(offer: Dictionary) -> ItemData.ItemRarity:
	var item: ItemData = offer.get("item") as ItemData
	if item:
		return item.rarity
	var rune: RuneData = offer.get("rune") as RuneData
	if rune:
		return rune.rarity
	var gem: GemData = offer.get("gem") as GemData
	if gem:
		return gem.rarity
	return ItemData.ItemRarity.COMMON


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
			return Color(0.45, 0.44, 0.42)


func _apply_visual_state() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.06, 0.92)
	style.set_content_margin_all(10)
	if _selected:
		style.border_color = UIColors.SELECT_BORDER
		style.set_border_width_all(3)
	elif _hovered and _has_offer:
		style.border_color = _rarity_color()
		style.set_border_width_all(2)
	elif _has_offer:
		style.border_color = _rarity_color()
		style.set_border_width_all(1)
	else:
		style.border_color = Color(0.25, 0.25, 0.28, 1)
		style.set_border_width_all(1)
	add_theme_stylebox_override("panel", style)
	if _modifier_detail and _modifier_detail.visible and _modifier_detail.rarity_label:
		_modifier_detail.rarity_label.add_theme_color_override("font_color", _rarity_color())


func _on_gui_input(event: InputEvent) -> void:
	if not _has_offer:
		return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			card_pressed.emit(card_index)
			if event.double_click:
				card_activated.emit(card_index)


func _on_mouse_entered() -> void:
	_hovered = true
	_apply_visual_state()


func _on_mouse_exited() -> void:
	_hovered = false
	_apply_visual_state()
