class_name SkillSlotRow
extends HBoxContainer

@onready var button_label: Label = $ButtonIcon
@onready var skill_label: Label = $SkillName


func setup(button: String, skill_name: String) -> void:
	button_label.text = "(%s)" % button
	skill_label.text = tr(skill_name) if skill_name != "" else tr("Empty")
