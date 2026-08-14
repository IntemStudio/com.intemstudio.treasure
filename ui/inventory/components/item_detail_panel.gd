class_name ItemDetailPanel
extends PanelContainer

signal socket_row_pressed(kind: String, index: int)
signal socket_row_activated(kind: String, index: int)

const AFFIX_SCENE := preload("res://ui/inventory/components/affix_line.tscn")
const SKILL_SCENE := preload("res://ui/inventory/components/skill_slot_row.tscn")
const SOCKET_SCENE := preload("res://ui/inventory/components/socket_row.tscn")

@onready var item_name_label: Label = %ItemName
@onready var rarity_label: Label = %RarityLabel
@onready var item_type_label: Label = %ItemType
@onready var attack_label: Label = %AttackLabel
@onready var attack_value: Label = %AttackValue
@onready var attack_delta_label: Label = %AttackBonus
@onready var defense_label: Label = %DefenseLabel
@onready var defense_value: Label = %DefenseValue
@onready var defense_delta_label: Label = %DefenseBonus
@onready var scaling_label: Label = %ScalingLabel
@onready var skill_slots: VBoxContainer = %SkillSlots
@onready var cost_label: Label = %CostLabel
@onready var gain_label: Label = %GainLabel
@onready var affix_list: VBoxContainer = %AffixList
@onready var flavor_text: Label = %FlavorText
@onready var requirements_label: Label = %RequirementsLabel
@onready var durability_bar: ProgressBar = %DurabilityBar
@onready var weight_label: Label = %WeightLabel
@onready var socket_header: Label = %SocketHeader
@onready var socket_list: VBoxContainer = %SocketList
@onready var resonance_label: Label = %ResonanceLabel

var _item: ItemData
var _compare_with: ItemData
var _inventory: InventoryData
var _rune_catalog: RuneCatalog
var _gem_catalog: GemCatalog
var _resonance_key: String = ""
var _selected_socket_kind: String = ""
var _selected_socket_index: int = -1
var _socket_rows: Array[SocketRow] = []


func _ready() -> void:
	theme_type_variation = &"ItemDetailPanel"
	LocaleManager.locale_changed.connect(_on_locale_changed)
	set_item(null)


func _on_locale_changed(_locale: String) -> void:
	set_item(_item, _compare_with)


func bind_socket_context(
	inventory: InventoryData,
	rune_catalog: RuneCatalog,
	gem_catalog: GemCatalog
) -> void:
	_inventory = inventory
	_rune_catalog = rune_catalog
	_gem_catalog = gem_catalog


func set_resonance_state(state_key: String) -> void:
	_resonance_key = state_key
	_refresh_resonance_label()


func set_selected_socket(kind: String, index: int) -> void:
	_selected_socket_kind = kind
	_selected_socket_index = index
	for row in _socket_rows:
		row.set_selected(row.socket_kind == kind and row.socket_index == index)


func get_socket_row_count() -> int:
	return _socket_rows.size()


func get_socket_row_at(i: int) -> Dictionary:
	if i < 0 or i >= _socket_rows.size():
		return {}
	var row := _socket_rows[i]
	return {"kind": row.socket_kind, "index": row.socket_index}


func find_socket_row_index(kind: String, index: int) -> int:
	for i in range(_socket_rows.size()):
		var row := _socket_rows[i]
		if row.socket_kind == kind and row.socket_index == index:
			return i
	return -1


func set_item(item: ItemData, compare_with: ItemData = null) -> void:
	_item = item
	_compare_with = compare_with if compare_with != item else null
	attack_label.text = tr("ATK")
	defense_label.text = tr("DEF")
	if not item:
		item_name_label.text = ""
		item_name_label.remove_theme_color_override("font_color")
		if rarity_label:
			rarity_label.text = ""
		item_type_label.text = tr("Select an item")
		attack_value.text = "-"
		_set_delta_label(attack_delta_label, 0)
		defense_value.text = "-"
		_set_delta_label(defense_delta_label, 0)
		scaling_label.text = ""
		if socket_header:
			socket_header.text = ""
		if resonance_label:
			resonance_label.text = ""
		cost_label.text = ""
		gain_label.text = ""
		flavor_text.text = ""
		requirements_label.text = ""
		durability_bar.value = 0
		weight_label.text = ""
		_clear_container(skill_slots)
		_clear_container(affix_list)
		_clear_socket_rows()
		return

	item_name_label.text = tr(item.display_name).to_upper()
	var rarity_color := _rarity_text_color(item)
	item_name_label.add_theme_color_override("font_color", rarity_color)
	if rarity_label:
		rarity_label.text = tr(item.rarity_locale_key())
		rarity_label.add_theme_color_override("font_color", rarity_color)
	item_type_label.text = tr(item.item_type) if not item.item_type.is_empty() else ""
	attack_value.text = str(item.attack)
	defense_value.text = str(item.defense)
	if _compare_with:
		_set_delta_label(attack_delta_label, item.attack - _compare_with.attack)
		_set_delta_label(defense_delta_label, item.defense - _compare_with.defense)
	else:
		_set_delta_label(attack_delta_label, 0)
		_set_delta_label(defense_delta_label, 0)
	if item.scales_with != "":
		scaling_label.text = tr("Scales with: %s") % CharacterStats.get_attribute_label(item.scales_with)
	else:
		scaling_label.text = ""
	cost_label.text = tr("Cost %d") % ShopPricing.buy_price(item)
	gain_label.text = tr("Gain %d") % ShopPricing.sell_price(item)
	flavor_text.text = tr(item.flavor_text) if not item.flavor_text.is_empty() else ""
	requirements_label.text = "%s %d" % [
		CharacterStats.get_attribute_label(item.required_stat),
		item.required_value,
	]
	durability_bar.max_value = item.durability_max
	durability_bar.value = item.durability
	weight_label.text = tr("Weight %.1f") % item.weight
	_populate_skills(item)
	_populate_affixes(item)
	_populate_sockets(item)
	_refresh_resonance_label()


func _populate_sockets(item: ItemData) -> void:
	_clear_socket_rows()
	if socket_header == null or socket_list == null:
		return
	item.ensure_socket_layout()
	var rows: Array[Dictionary] = []
	if _inventory:
		rows = _inventory.list_socket_rows(item)
	elif item.socket_layout:
		for i in range(item.socket_layout.rune_slots):
			rows.append({"kind": "rune", "index": i, "instance_uid": ""})
		for i in range(item.socket_layout.core_gem_slots):
			rows.append({"kind": "core_gem", "index": i, "instance_uid": ""})
		for i in range(item.socket_layout.aux_gem_slots):
			rows.append({"kind": "aux_gem", "index": i, "instance_uid": ""})
	if rows.is_empty():
		socket_header.text = ""
		return
	socket_header.text = tr("Sockets")
	for row_data in rows:
		var kind := str(row_data.get("kind", ""))
		var index := int(row_data.get("index", 0))
		var uid := str(row_data.get("instance_uid", ""))
		var display := ""
		var rarity := ItemData.ItemRarity.COMMON
		if not uid.is_empty() and _inventory:
			if kind == "rune":
				var ri := _inventory.find_rune(uid)
				if ri and _rune_catalog:
					var rd := _rune_catalog.get_rune(ri.rune_id)
					if rd:
						display = tr(rd.display_name)
			else:
				var gi := _inventory.find_gem(uid)
				if gi and _gem_catalog:
					var gd := _gem_catalog.get_gem(gi.gem_id)
					if gd:
						display = tr(gd.display_name)
		var row: SocketRow = SOCKET_SCENE.instantiate()
		socket_list.add_child(row)
		row.setup(kind, index, display, rarity)
		row.row_pressed.connect(_on_socket_row_pressed)
		row.row_activated.connect(_on_socket_row_activated)
		row.set_selected(kind == _selected_socket_kind and index == _selected_socket_index)
		_socket_rows.append(row)


func _refresh_resonance_label() -> void:
	if resonance_label == null:
		return
	if _item == null or _item.equip_slot != "main_hand" or _resonance_key.is_empty():
		resonance_label.text = ""
		return
	var key := _resonance_key
	if key == "BASE_SKILL_ONLY" or key == "RESONANT" or key == "COMPLETE" or key == "INACTIVE":
		resonance_label.text = "%s: %s" % [tr("Resonance"), tr(key)]
	else:
		resonance_label.text = ""


func _on_socket_row_pressed(kind: String, index: int) -> void:
	set_selected_socket(kind, index)
	socket_row_pressed.emit(kind, index)


func _on_socket_row_activated(kind: String, index: int) -> void:
	set_selected_socket(kind, index)
	socket_row_activated.emit(kind, index)


func _populate_skills(item: ItemData) -> void:
	_clear_container(skill_slots)
	var skills := item.skills.duplicate()
	while skills.size() < 4:
		skills.append({"button": ["X", "Y", "B", "A"][skills.size()], "name": ""})
	for skill_data in skills:
		var row: SkillSlotRow = SKILL_SCENE.instantiate()
		skill_slots.add_child(row)
		row.setup(str(skill_data.get("button", "")), str(skill_data.get("name", "")))


func _populate_affixes(item: ItemData) -> void:
	_clear_container(affix_list)
	for affix in item.affixes:
		var row: AffixLine = AFFIX_SCENE.instantiate()
		affix_list.add_child(row)
		var text := str(affix.get("text", ""))
		row.setup(tr(text) if not text.is_empty() else "", bool(affix.get("positive", true)))


func _rarity_text_color(item: ItemData) -> Color:
	if item.rarity == ItemData.ItemRarity.COMMON:
		return UIColors.TEXT_MUTED
	return item.get_rarity_color()


func _set_delta_label(label: Label, delta: int) -> void:
	if delta == 0:
		label.text = ""
		label.visible = false
		return
	label.visible = true
	if delta > 0:
		label.text = "+%d" % delta
		label.add_theme_color_override("font_color", UIColors.POSITIVE)
	else:
		label.text = str(delta)
		label.add_theme_color_override("font_color", UIColors.NEGATIVE)


func _clear_socket_rows() -> void:
	_socket_rows.clear()
	if socket_list:
		_clear_container(socket_list)


func _clear_container(container: Node) -> void:
	for child in container.get_children():
		child.queue_free()
