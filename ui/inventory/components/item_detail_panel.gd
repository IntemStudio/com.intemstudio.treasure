class_name ItemDetailPanel
extends PanelContainer

const AFFIX_SCENE := preload("res://ui/inventory/components/affix_line.tscn")
const SKILL_SCENE := preload("res://ui/inventory/components/skill_slot_row.tscn")

@onready var item_name_label: Label = %ItemName
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
@onready var socket_label: Label = %SocketLabel

var _item: ItemData
var _compare_with: ItemData


func _ready() -> void:
	theme_type_variation = &"ItemDetailPanel"
	LocaleManager.locale_changed.connect(_on_locale_changed)
	set_item(null)


func _on_locale_changed(_locale: String) -> void:
	set_item(_item, _compare_with)


func set_item(item: ItemData, compare_with: ItemData = null) -> void:
	_item = item
	_compare_with = compare_with if compare_with != item else null
	attack_label.text = tr("ATK")
	defense_label.text = tr("DEF")
	if not item:
		item_name_label.text = ""
		item_type_label.text = tr("Select an item")
		attack_value.text = "-"
		_set_delta_label(attack_delta_label, 0)
		defense_value.text = "-"
		_set_delta_label(defense_delta_label, 0)
		scaling_label.text = ""
		if socket_label:
			socket_label.text = ""
		cost_label.text = ""
		gain_label.text = ""
		flavor_text.text = ""
		requirements_label.text = ""
		durability_bar.value = 0
		weight_label.text = ""
		_clear_container(skill_slots)
		_clear_container(affix_list)
		return

	item_name_label.text = tr(item.display_name).to_upper()
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
	item.ensure_socket_layout()
	if socket_label:
		if item.socket_layout:
			socket_label.text = "%s: %s" % [tr("Sockets"), item.socket_layout.describe()]
		else:
			socket_label.text = ""
	cost_label.text = tr("Cost %d") % item.cost
	gain_label.text = tr("Gain %d") % item.gain
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


func _clear_container(container: Node) -> void:
	for child in container.get_children():
		child.queue_free()
