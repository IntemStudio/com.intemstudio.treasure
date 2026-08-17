class_name AffixLine
extends HBoxContainer

@onready var text_label: RichTextLabel = $Text


func setup(text: String, is_positive: bool, desc: String = "") -> void:
	var color := "#b38ce6" if is_positive else "#e66666"
	var body := "[color=%s]• %s[/color]" % [color, text]
	if not desc.is_empty():
		body += "\n[color=%s]  %s[/color]" % [UIColors.html(UIColors.TEXT_MUTED), desc]
	text_label.text = body
