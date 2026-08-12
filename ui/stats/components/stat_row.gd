class_name StatRow
extends HBoxContainer

@onready var name_label: Label = $Name
@onready var value_label: Label = $Value


func setup(stat_name: String, value: Variant) -> void:
	name_label.text = stat_name
	if value is float:
		value_label.text = "%.1f" % value
	else:
		value_label.text = str(value)
