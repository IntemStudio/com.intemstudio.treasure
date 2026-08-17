class_name UISelectStyle
extends RefCounted

# Left-select / focus bar used by settings, challenge board, title, profile.
# Colors stay on UIColors; this only owns the StyleBox geometry.

const BORDER_WIDTH := 3
const MARGIN_LEFT := 16
const MARGIN_Y := 4
const MARGIN_RIGHT := 4
const SELECT_BAR_WIDTH := 3


static func make_left_mark(selected: bool, margin_left: int = MARGIN_LEFT) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = UIColors.CLEAR
	style.border_width_left = BORDER_WIDTH
	style.border_color = UIColors.SELECT_BORDER if selected else UIColors.CLEAR
	style.content_margin_left = margin_left
	style.content_margin_top = MARGIN_Y
	style.content_margin_bottom = MARGIN_Y
	style.content_margin_right = MARGIN_RIGHT
	return style


static func apply_button(
	button: Button,
	selected: bool,
	idle_color: Color = UIColors.TEXT_MAIN,
	set_focus_color: bool = false
) -> void:
	var style := make_left_mark(selected)
	for state_name in ["normal", "hover", "pressed", "focus", "disabled"]:
		button.add_theme_stylebox_override(state_name, style)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	var color := UIColors.GOLD if selected else idle_color
	button.add_theme_color_override("font_color", color)
	button.add_theme_color_override("font_hover_color", UIColors.GOLD if selected else UIColors.TEXT_MAIN)
	if set_focus_color:
		button.add_theme_color_override("font_focus_color", color)


static func apply_label(label: Label, selected: bool, idle_color: Color = UIColors.TEXT_MUTED, margin_h: int = 12) -> void:
	var style := make_left_mark(selected, margin_h)
	style.content_margin_right = margin_h
	label.add_theme_stylebox_override("normal", style)
	label.add_theme_color_override("font_color", UIColors.GOLD if selected else idle_color)


static func apply_button_focus_bar(button: Button, idle_color: Color = UIColors.TEXT_MAIN) -> void:
	# Title/profile: padding on StyleBoxEmpty; focus draws the left bar only.
	var padded := StyleBoxEmpty.new()
	padded.content_margin_left = MARGIN_LEFT
	padded.content_margin_top = MARGIN_Y
	padded.content_margin_bottom = MARGIN_Y
	padded.content_margin_right = MARGIN_RIGHT
	button.flat = true
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.focus_mode = Control.FOCUS_ALL
	for state_name in ["normal", "hover", "pressed", "disabled"]:
		button.add_theme_stylebox_override(state_name, padded)
	var focus_style := make_left_mark(true)
	button.add_theme_stylebox_override("focus", focus_style)
	button.add_theme_color_override("font_color", idle_color)
	button.add_theme_color_override("font_hover_color", UIColors.TEXT_MAIN)
	button.add_theme_color_override("font_focus_color", UIColors.GOLD)


static func make_select_bar() -> ColorRect:
	var bar := ColorRect.new()
	bar.custom_minimum_size = Vector2(SELECT_BAR_WIDTH, 0)
	bar.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.color = UIColors.CLEAR
	return bar


static func set_select_bar(bar: ColorRect, selected: bool) -> void:
	if bar == null:
		return
	bar.color = UIColors.SELECT_BORDER if selected else UIColors.CLEAR
