class_name ItemDetailPanel
extends PanelContainer

signal socket_row_pressed(kind: String, index: int)
signal socket_row_activated(kind: String, index: int)

const AFFIX_SCENE := preload("res://ui/inventory/components/affix_line.tscn")
const SOCKET_SCENE := preload("res://ui/inventory/components/socket_row.tscn")

enum GoldPrice { HIDDEN, BUY, SELL }

@onready var item_name_label: Label = %ItemName
@onready var item_icon: TextureRect = %ItemIcon
@onready var rarity_label: Label = %RarityLabel
@onready var item_type_label: Label = %ItemType
@onready var attack_label: Label = %AttackLabel
@onready var attack_value: Label = %AttackValue
@onready var attack_delta_label: Label = %AttackBonus
@onready var defense_label: Label = %DefenseLabel
@onready var defense_value: Label = %DefenseValue
@onready var defense_delta_label: Label = %DefenseBonus
@onready var scaling_label: Label = %ScalingLabel
@onready var resource_cost: HBoxContainer = %ResourceCost
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
@onready var effect_header: Label = %EffectHeader
@onready var effect_list: VBoxContainer = %EffectList

var _item: ItemData
var _compare_with: ItemData
var _gold_price: GoldPrice = GoldPrice.SELL
var _inventory: InventoryData
var _rune_catalog: RuneCatalog
var _gem_catalog: GemCatalog
var _resonance_key: String = ""
var _selected_socket_kind: String = ""
var _selected_socket_index: int = -1
var _socket_rows: Array[SocketRow] = []
var _resonance := ResonanceService.new()


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


func set_gold_price(kind: GoldPrice) -> void:
	_gold_price = kind
	_refresh_gold_labels()


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
		if item_icon:
			item_icon.texture = null
			item_icon.visible = false
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
		_refresh_gold_labels()
		flavor_text.text = ""
		requirements_label.text = ""
		durability_bar.value = 0
		weight_label.text = ""
		_clear_container(affix_list)
		_clear_socket_rows()
		_clear_socket_effects()
		return

	item_name_label.text = tr(item.display_name).to_upper()
	if item_icon:
		item_icon.texture = item.icon
		item_icon.visible = item.icon != null
		item_icon.texture_filter = TEXTURE_FILTER_NEAREST
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
	_refresh_gold_labels()
	flavor_text.text = tr(item.flavor_text) if not item.flavor_text.is_empty() else ""
	requirements_label.text = "%s %d" % [
		CharacterStats.get_attribute_label(item.required_stat),
		item.required_value,
	]
	durability_bar.max_value = item.durability_max
	durability_bar.value = item.durability
	weight_label.text = tr("Weight %.1f") % item.weight
	_populate_affixes(item)
	_populate_sockets(item)
	_populate_socket_effects(item)
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
		var layout: SocketLayout = item.socket_layout
		var n := maxi(layout.rune_slots, maxi(layout.core_gem_slots, layout.aux_gem_slots))
		for i in range(n):
			if i < layout.rune_slots:
				rows.append({"kind": "rune", "index": i, "instance_uid": ""})
			if i < layout.core_gem_slots:
				rows.append({"kind": "core_gem", "index": i, "instance_uid": ""})
			if i < layout.aux_gem_slots:
				rows.append({"kind": "aux_gem", "index": i, "instance_uid": ""})
	if rows.is_empty():
		socket_header.text = ""
		return
	socket_header.text = tr("Sockets")
	for row_data in rows:
		var kind := str(row_data.get("kind", ""))
		var index := int(row_data.get("index", 0))
		var uid := str(row_data.get("instance_uid", ""))
		var rune_id := str(row_data.get("rune_id", ""))
		var gem_id := str(row_data.get("gem_id", ""))
		var display := ""
		var rarity := ItemData.ItemRarity.COMMON
		var icon: Texture2D = null
		if kind == "rune":
			if rune_id.is_empty() and not uid.is_empty() and _inventory:
				var ri := _inventory.find_rune(uid)
				if ri:
					rune_id = ri.rune_id
			if not rune_id.is_empty() and _rune_catalog:
				var rd := _rune_catalog.get_rune(rune_id)
				if rd:
					display = tr(rd.display_name)
					icon = rd.icon
		elif not uid.is_empty() or not gem_id.is_empty():
			if gem_id.is_empty() and _inventory:
				var gi := _inventory.find_gem(uid)
				if gi:
					gem_id = gi.gem_id
			if not gem_id.is_empty() and _gem_catalog:
				var gd := _gem_catalog.get_gem(gem_id)
				if gd:
					display = tr(gd.display_name)
					icon = gd.icon
		var row: SocketRow = SOCKET_SCENE.instantiate()
		socket_list.add_child(row)
		row.setup(kind, index, display, rarity, icon)
		row.row_pressed.connect(_on_socket_row_pressed)
		row.row_activated.connect(_on_socket_row_activated)
		row.set_selected(kind == _selected_socket_kind and index == _selected_socket_index)
		_socket_rows.append(row)


func _populate_socket_effects(item: ItemData) -> void:
	_clear_socket_effects()
	if effect_list == null or item == null:
		return
	_ensure_catalogs()
	item.ensure_socket_layout()
	var lines: Array[Dictionary] = []
	var seen: Dictionary = {}
	var rune_cap := item.socket_layout.rune_slots if item.socket_layout else 0
	for i in range(rune_cap):
		var rune := _socketed_rune(item, i)
		if rune == null:
			continue
		var skill := tr(rune.skill_name) if not rune.skill_name.is_empty() else tr(rune.display_name)
		if item.equip_slot == "main_hand":
			var core := _socketed_core(item, i)
			var auxes := _socketed_aux(item, i)
			var result := _resonance.evaluate(item, rune, core, auxes)
			if result.state != ResonanceResult.State.INACTIVE:
				if core and not core.skill_name_suffix.is_empty():
					skill += tr(core.skill_name_suffix)
				for aux in auxes:
					if aux and not aux.skill_name_suffix.is_empty():
						var extra := tr(aux.skill_name_suffix)
						if not skill.ends_with(extra):
							skill += extra
		var kind := rune.skill_kind if not rune.skill_kind.is_empty() else "strike"
		var line := "%s — %s" % [skill, _skill_kind_label(kind)]
		if seen.has(line):
			continue
		seen[line] = true
		lines.append({"text": line, "desc": _skill_kind_desc(kind)})
	for entry in item.socketed:
		if not entry is Dictionary:
			continue
		var kind := str(entry.get("kind", ""))
		if kind != "core_gem" and kind != "aux_gem":
			continue
		var gem := _gem_from_entry(entry)
		if gem == null:
			continue
		var fx := _gem_slot_effect_row(gem, item.equip_slot)
		var fx_text := str(fx.get("text", ""))
		if fx_text.is_empty() or seen.has(fx_text):
			continue
		seen[fx_text] = true
		lines.append(fx)
	if effect_header:
		effect_header.text = tr("SOCKET_EFFECTS") if not lines.is_empty() else ""
	for line in lines:
		var row: AffixLine = AFFIX_SCENE.instantiate()
		effect_list.add_child(row)
		row.setup(str(line.get("text", "")), true, str(line.get("desc", "")))


func _ensure_catalogs() -> void:
	if _rune_catalog == null:
		_rune_catalog = RuneCatalog.new()
	if _gem_catalog == null:
		_gem_catalog = GemCatalog.new()


func _socketed_rune(item: ItemData, index: int) -> RuneData:
	var rune_id := _socket_field(item, "rune", index, "rune_id")
	if rune_id.is_empty() or _rune_catalog == null:
		return null
	return _rune_catalog.get_rune(rune_id)


func _socketed_core(item: ItemData, index: int) -> GemData:
	return _gem_from_ids(_socket_field(item, "core_gem", index, "gem_id"))


func _socketed_aux(item: ItemData, index: int) -> Array[GemData]:
	var out: Array[GemData] = []
	for entry in item.socketed:
		if not entry is Dictionary:
			continue
		var d: Dictionary = entry
		if str(d.get("kind", "")) != "aux_gem" or int(d.get("index", -1)) != index:
			continue
		var gem := _gem_from_entry(d)
		if gem:
			out.append(gem)
	return out


func _socket_field(item: ItemData, kind: String, index: int, key: String) -> String:
	for entry in item.socketed:
		if not entry is Dictionary:
			continue
		var d: Dictionary = entry
		if str(d.get("kind", "")) == kind and int(d.get("index", -1)) == index:
			return str(d.get(key, ""))
	return ""


func _gem_from_entry(entry: Dictionary) -> GemData:
	return _gem_from_ids(str(entry.get("gem_id", "")))


func _gem_from_ids(gem_id: String) -> GemData:
	if gem_id.is_empty() or _gem_catalog == null:
		return null
	return _gem_catalog.get_gem(gem_id)


func _gem_slot_effect_row(gem: GemData, equip_slot: String) -> Dictionary:
	var raw := str(gem.slot_effects.get(equip_slot, ""))
	if raw.is_empty():
		return {}
	var key := "GEM_FX_%s" % raw.to_upper()
	var translated := tr(key)
	var text := translated if translated != key else raw.replace("_", " ")
	var desc_key := "%s_DESC" % key
	var desc := tr(desc_key)
	if desc == desc_key:
		desc = ""
	return {"text": text, "desc": desc}


func _skill_kind_label(kind: String) -> String:
	var id := kind if not kind.is_empty() else "strike"
	var key := "SKILL_KIND_%s" % id.to_upper()
	var translated := tr(key)
	return translated if translated != key else id


func _skill_kind_desc(kind: String) -> String:
	var id := kind if not kind.is_empty() else "strike"
	var key := "SKILL_KIND_%s_DESC" % id.to_upper()
	var translated := tr(key)
	return translated if translated != key else ""


func _clear_socket_effects() -> void:
	if effect_header:
		effect_header.text = ""
	if effect_list:
		_clear_container(effect_list)


func _refresh_gold_labels() -> void:
	if cost_label == null or gain_label == null:
		return
	var show_buy := _item != null and _gold_price == GoldPrice.BUY
	var show_sell := _item != null and _gold_price == GoldPrice.SELL
	cost_label.visible = show_buy
	gain_label.visible = show_sell
	if show_buy:
		cost_label.text = tr("Buy Price %d Gold") % ShopPricing.buy_price(_item)
	else:
		cost_label.text = ""
	if show_sell:
		gain_label.text = tr("Sell Price %d Gold") % ShopPricing.sell_price(_item)
	else:
		gain_label.text = ""
	if resource_cost:
		resource_cost.visible = show_buy or show_sell


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


func _populate_affixes(item: ItemData) -> void:
	_clear_container(affix_list)
	for affix in item.affixes:
		var row: AffixLine = AFFIX_SCENE.instantiate()
		affix_list.add_child(row)
		var text := str(affix.get("text", ""))
		row.setup(
			tr(text) if not text.is_empty() else "",
			bool(affix.get("positive", true)),
			_affix_stat_desc(str(affix.get("id", "")))
		)


func _affix_stat_desc(stat_id: String) -> String:
	if stat_id.is_empty() or not CombatStatsBuilder.AFFIX_FIELDS.has(stat_id):
		return ""
	var key := "STAT_DESC_%s" % stat_id
	var translated := tr(key)
	return translated if translated != key else ""


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
