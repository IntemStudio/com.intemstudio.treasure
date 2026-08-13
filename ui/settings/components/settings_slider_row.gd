class_name SettingsSliderRow
extends HBoxContainer

signal value_changed(value: float)
signal focused

const STEP := 0.05

var label: Label
var slider: HSlider
var value_label: Label

var _selected: bool = false
var _empty_style: StyleBoxEmpty
var _select_bar: ColorRect


func _ready() -> void:
	_ensure_nodes()


func setup(label_text: String, value: float) -> void:
	_ensure_nodes()
	label.text = label_text
	set_value(value, false)
	_apply_selection_style()


func set_selected(selected: bool) -> void:
	_selected = selected
	_apply_selection_style()


func is_selected() -> bool:
	return _selected


func get_value() -> float:
	return float(slider.value)


func set_value(value: float, emit_change: bool = true) -> void:
	_ensure_nodes()
	slider.set_value_no_signal(clampf(value, 0.0, 1.0))
	_refresh_value_label()
	if emit_change:
		value_changed.emit(get_value())


func nudge(direction: int) -> void:
	set_value(get_value() + STEP * direction, true)


func set_label_text(text: String) -> void:
	_ensure_nodes()
	label.text = text


func _ensure_nodes() -> void:
	if label != null:
		return
	_empty_style = StyleBoxEmpty.new()
	add_theme_constant_override("separation", 16)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL

	_select_bar = ColorRect.new()
	_select_bar.custom_minimum_size = Vector2(3, 0)
	_select_bar.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_select_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_select_bar.color = Color(0, 0, 0, 0)
	add_child(_select_bar)

	label = Label.new()
	label.custom_minimum_size = Vector2(160, 0)
	add_child(label)

	slider = HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = STEP
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.focus_mode = Control.FOCUS_NONE
	slider.value_changed.connect(_on_slider_changed)
	add_child(slider)

	value_label = Label.new()
	value_label.custom_minimum_size = Vector2(64, 0)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(value_label)

	gui_input.connect(_on_gui_input)
	mouse_entered.connect(_on_mouse_entered)
	slider.gui_input.connect(_on_gui_input)
	slider.mouse_entered.connect(_on_mouse_entered)


func _refresh_value_label() -> void:
	value_label.text = "%d%%" % int(round(get_value() * 100.0))


func _apply_selection_style() -> void:
	var color := UIColors.GOLD if _selected else UIColors.TEXT_MAIN
	label.add_theme_color_override("font_color", color)
	value_label.add_theme_color_override("font_color", color)
	if _select_bar:
		_select_bar.color = UIColors.SELECT_BORDER if _selected else Color(0, 0, 0, 0)


func _on_slider_changed(_value: float) -> void:
	_refresh_value_label()
	focused.emit()
	value_changed.emit(get_value())


func _on_mouse_entered() -> void:
	focused.emit()


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		focused.emit()
