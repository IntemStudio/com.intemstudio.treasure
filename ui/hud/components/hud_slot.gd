class_name HudSlot
extends PanelContainer

@onready var empty_label: Label = %EmptyLabel
@onready var quantity_label: Label = %QuantityLabel
@onready var name_label: Label = %NameLabel
@onready var charge_bar: ProgressBar = %ChargeBar
@onready var icon_rect: TextureRect = %Icon


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if empty_label:
		empty_label.text = tr("Empty")
	if charge_bar:
		charge_bar.visible = false
		charge_bar.value = 0.0
	if icon_rect:
		icon_rect.texture_filter = TEXTURE_FILTER_NEAREST
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
	name_label.text = tr(item.display_name)
	name_label.visible = true
	if charge_bar:
		charge_bar.visible = false
	if item.stackable and item.quantity > 1:
		quantity_label.text = str(item.quantity)
		quantity_label.visible = true
	else:
		quantity_label.visible = false
	_set_icon(item.icon)
	if name_label:
		name_label.offset_bottom = -2.0


func set_skill(skill_name: String, icon: Texture2D = null) -> void:
	var trimmed := skill_name.strip_edges()
	if trimmed.is_empty():
		clear()
		return
	empty_label.visible = false
	name_label.text = tr(trimmed)
	name_label.visible = true
	quantity_label.visible = false
	_set_icon(icon)
	if name_label:
		name_label.offset_bottom = -10.0
	if charge_bar:
		charge_bar.visible = true
		charge_bar.value = 0.0


func set_charge(ratio: float, highlighted: bool = false) -> void:
	if charge_bar == null:
		return
	if not charge_bar.visible:
		return
	charge_bar.value = clampf(ratio, 0.0, 1.0) * 100.0
	if highlighted:
		charge_bar.modulate = UIColors.GOLD
	else:
		charge_bar.modulate = UIColors.RARITY_RARE


func clear() -> void:
	empty_label.visible = true
	empty_label.text = tr("Empty")
	quantity_label.visible = false
	name_label.visible = false
	name_label.text = ""
	_set_icon(null)
	if name_label:
		name_label.offset_bottom = -2.0
	if charge_bar:
		charge_bar.visible = false
		charge_bar.value = 0.0
		charge_bar.modulate = Color.WHITE


func _set_icon(texture: Texture2D) -> void:
	if icon_rect == null:
		return
	icon_rect.texture = texture
	icon_rect.visible = texture != null
	if name_label:
		name_label.offset_top = 28.0 if texture else 2.0
