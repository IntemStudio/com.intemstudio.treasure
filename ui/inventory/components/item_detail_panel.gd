class_name ItemDetailPanel
extends PanelContainer

const AFFIX_SCENE := preload("res://ui/inventory/components/affix_line.tscn")
const SKILL_SCENE := preload("res://ui/inventory/components/skill_slot_row.tscn")

@onready var item_name_label: Label = %ItemName
@onready var item_type_label: Label = %ItemType
@onready var attack_label: Label = %AttackLabel
@onready var attack_value: Label = %AttackValue
@onready var attack_bonus: Label = %AttackBonus
@onready var defense_label: Label = %DefenseLabel
@onready var defense_value: Label = %DefenseValue
@onready var defense_bonus: Label = %DefenseBonus
@onready var scaling_label: Label = %ScalingLabel
@onready var skill_slots: VBoxContainer = %SkillSlots
@onready var cost_label: Label = %CostLabel
@onready var gain_label: Label = %GainLabel
@onready var affix_list: VBoxContainer = %AffixList
@onready var flavor_text: Label = %FlavorText
@onready var requirements_label: Label = %RequirementsLabel
@onready var durability_bar: ProgressBar = %DurabilityBar
@onready var weight_label: Label = %WeightLabel

var _item: ItemData


func _ready() -> void:
	theme_type_variation = &"ItemDetailPanel"
	LocaleManager.locale_changed.connect(_on_locale_changed)
	set_item(null)


func _on_locale_changed(_locale: String) -> void:
	set_item(_item)


func set_item(item: ItemData) -> void:
	_item = item
	attack_label.text = tr("ATK")
	defense_label.text = tr("DEF")
	if not item:
		item_name_label.text = ""
		item_type_label.text = tr("Select an item")
		attack_value.text = "-"
		attack_bonus.text = ""
		defense_value.text = "-"
		defense_bonus.text = ""
		scaling_label.text = ""
		cost_label.text = ""
		gain_label.text = ""
		flavor_text.text = ""
		requirements_label.text = ""
		durability_bar.value = 0
		weight_label.text = ""
		_clear_container(skill_slots)
		_clear_container(affix_list)
		return

	item_name_label.text = item.display_name.to_upper()
	item_type_label.text = item.item_type
	attack_value.text = str(item.attack)
	attack_bonus.text = "+%d" % item.attack_bonus if item.attack_bonus > 0 else ""
	attack_bonus.visible = item.attack_bonus > 0
	defense_value.text = str(item.defense)
	defense_bonus.text = "+%d" % item.defense_bonus if item.defense_bonus > 0 else ""
	defense_bonus.visible = item.defense_bonus > 0
	if item.scales_with != "":
		scaling_label.text = tr("Scales with: %s") % CharacterStats.get_attribute_label(item.scales_with)
	else:
		scaling_label.text = ""
	cost_label.text = tr("Cost %d") % item.cost
	gain_label.text = tr("Gain %d") % item.gain
	flavor_text.text = item.flavor_text
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
		row.setup(str(affix.get("text", "")), bool(affix.get("positive", true)))


func _clear_container(container: Node) -> void:
	for child in container.get_children():
		child.queue_free()
