class_name WeaponStatRow
extends HBoxContainer

@onready var weapon_label: Label = $Weapon
@onready var base_label: Label = $Base
@onready var attr_bonus_label: Label = $AttrBonus/Value
@onready var other_label: Label = $Other
@onready var total_label: Label = $Total


func setup(data: Dictionary) -> void:
	weapon_label.text = tr(str(data.get("name", "")))
	base_label.text = str(data.get("base", 0))
	attr_bonus_label.text = "+%d" % int(data.get("attr_bonus", 0))
	other_label.text = str(data.get("other", 0))
	total_label.text = str(data.get("total", 0))
