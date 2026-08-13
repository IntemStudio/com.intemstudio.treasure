class_name SettingsToggleRow
extends HBoxContainer

signal value_changed(enabled: bool)
signal focused

var label: Label
var _value_row: HBoxContainer
var _box: PanelContainer
var _mark: Label
var _value_label: Label

var _enabled: bool = false
var _selected: bool = false
var _empty_style: StyleBoxEmpty
var _box_style: StyleBoxFlat
var _select_bar: ColorRect


func _ready() -> void:
	_ensure_nodes()


func setup(label_text: String, enabled: bool) -> void:
	_ensure_nodes()
	label.text = label_text
	set_enabled(enabled, false)
	_apply_selection_style()


func set_selected(selected: bool) -> void:
	_selected = selected
	_apply_selection_style()


func is_selected() -> bool:
	return _selected


func is_enabled() -> bool:
	return _enabled


func set_enabled(enabled: bool, emit_change: bool = true) -> void:
	_enabled = enabled
	_refresh_value()
	if emit_change:
		value_changed.emit(_enabled)


func toggle() -> void:
	set_enabled(not _enabled, true)


func set_label_text(text: String) -> void:
	_ensure_nodes()
	label.text = text


func _ensure_nodes() -> void:
	if label != null:
		return
	_empty_style = StyleBoxEmpty.new()
	_box_style = StyleBoxFlat.new()
	_box_style.bg_color = Color(0.06, 0.06, 0.07, 0.92)
	_box_style.set_border_width_all(1)
	_box_style.border_color = Color(0.88, 0.88, 0.9, 0.95)
	_box_style.set_corner_radius_all(2)

	add_theme_constant_override("separation", 16)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	_select_bar = ColorRect.new()
	_select_bar.custom_minimum_size = Vector2(3, 0)
	_select_bar.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_select_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_select_bar.color = Color(0, 0, 0, 0)
	add_child(_select_bar)

	label = Label.new()
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(label)

	_value_row = HBoxContainer.new()
	_value_row.add_theme_constant_override("separation", 10)
	_value_row.alignment = BoxContainer.ALIGNMENT_END
	add_child(_value_row)

	_box = PanelContainer.new()
	_box.custom_minimum_size = Vector2(18, 18)
	_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box.add_theme_stylebox_override("panel", _box_style)
	_value_row.add_child(_box)

	_mark = Label.new()
	_mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mark.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mark.add_theme_font_size_override("font_size", 12)
	_box.add_child(_mark)

	_value_label = Label.new()
	_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_value_label.custom_minimum_size = Vector2(48, 0)
	_value_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_value_row.add_child(_value_label)

	gui_input.connect(_on_gui_input)
	mouse_entered.connect(_on_mouse_entered)


func _refresh_value() -> void:
	_mark.text = "✓" if _enabled else ""
	_value_label.text = tr("On") if _enabled else tr("Off")
	_box_style.bg_color = (
		Color(0.78, 0.66, 0.3, 0.35) if _enabled else Color(0.06, 0.06, 0.07, 0.92)
	)
	_box.add_theme_stylebox_override("panel", _box_style)


func _apply_selection_style() -> void:
	var color := UIColors.GOLD if _selected else UIColors.TEXT_MAIN
	label.add_theme_color_override("font_color", color)
	_value_label.add_theme_color_override("font_color", color)
	_mark.add_theme_color_override("font_color", color)
	_box_style.border_color = color
	_box.add_theme_stylebox_override("panel", _box_style)
	if _select_bar:
		_select_bar.color = UIColors.SELECT_BORDER if _selected else Color(0, 0, 0, 0)


func _on_mouse_entered() -> void:
	focused.emit()


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		focused.emit()
		toggle()
		accept_event()
