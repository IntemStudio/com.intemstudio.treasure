class_name AffixLine
extends HBoxContainer

@onready var text_label: RichTextLabel = $Text


func setup(text: String, is_positive: bool) -> void:
	var color := "#b38ce6" if is_positive else "#e66666"
	text_label.text = "[color=%s]• %s[/color]" % [color, text]
