class_name SettingsCycleRow
extends HBoxContainer

signal value_changed(index: int)
signal focused

var label: Label
var value_label: Label
var left_button: Button
var right_button: Button

var _options: Array = []
var _index: int = 0
var _selected: bool = false
var _empty_style: StyleBoxEmpty
var _select_bar: ColorRect


func _ready() -> void:
	_ensure_nodes()


func setup(label_text: String, options: Array, initial_index: int = 0) -> void:
	_ensure_nodes()
	_options = options.duplicate()
	_index = clampi(initial_index, 0, maxi(_options.size() - 1, 0))
	label.text = label_text
	_refresh_value()
	_apply_selection_style()


func set_selected(selected: bool) -> void:
	_selected = selected
	_apply_selection_style()


func is_selected() -> bool:
	return _selected


func get_option_index() -> int:
	return _index


func set_option_index(index: int, emit_change: bool = true) -> void:
	if _options.is_empty():
		return
	_index = clampi(index, 0, _options.size() - 1)
	_refresh_value()
	if emit_change:
		value_changed.emit(_index)


func cycle(direction: int) -> void:
	if _options.is_empty():
		return
	var next := (_index + direction + _options.size()) % _options.size()
	set_option_index(next, true)


func set_label_text(text: String) -> void:
	_ensure_nodes()
	label.text = text


func set_options(options: Array, keep_index: bool = true) -> void:
	_ensure_nodes()
	var prev := _index
	_options = options.duplicate()
	if keep_index:
		_index = clampi(prev, 0, maxi(_options.size() - 1, 0))
	else:
		_index = 0
	_refresh_value()


func _ensure_nodes() -> void:
	if label != null:
		return
	_empty_style = StyleBoxEmpty.new()
	add_theme_constant_override("separation", 16)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL

	_select_bar = _make_select_bar()
	add_child(_select_bar)

	label = Label.new()
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(label)

	var controls := HBoxContainer.new()
	controls.add_theme_constant_override("separation", 8)
	controls.alignment = BoxContainer.ALIGNMENT_END
	add_child(controls)

	left_button = _make_flat_button("‹")
	left_button.pressed.connect(_on_left)
	controls.add_child(left_button)

	value_label = Label.new()
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_label.custom_minimum_size = Vector2(180, 0)
	controls.add_child(value_label)

	right_button = _make_flat_button("›")
	right_button.pressed.connect(_on_right)
	controls.add_child(right_button)

	gui_input.connect(_on_gui_input)
	mouse_entered.connect(_on_mouse_entered)


func _make_flat_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.flat = true
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_stylebox_override("normal", _empty_style)
	button.add_theme_stylebox_override("hover", _empty_style)
	button.add_theme_stylebox_override("pressed", _empty_style)
	button.add_theme_stylebox_override("focus", _empty_style)
	return button


func _make_select_bar() -> ColorRect:
	var bar := ColorRect.new()
	bar.custom_minimum_size = Vector2(3, 0)
	bar.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.color = Color(0, 0, 0, 0)
	return bar


func _refresh_value() -> void:
	if _options.is_empty():
		value_label.text = "-"
		return
	value_label.text = str(_options[_index])


func _apply_selection_style() -> void:
	var color := UIColors.GOLD if _selected else UIColors.TEXT_MAIN
	label.add_theme_color_override("font_color", color)
	value_label.add_theme_color_override("font_color", color)
	left_button.add_theme_color_override("font_color", color)
	right_button.add_theme_color_override("font_color", color)
	if _select_bar:
		_select_bar.color = UIColors.SELECT_BORDER if _selected else Color(0, 0, 0, 0)


func _on_left() -> void:
	focused.emit()
	cycle(-1)


func _on_right() -> void:
	focused.emit()
	cycle(1)


func _on_mouse_entered() -> void:
	focused.emit()


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		focused.emit()
