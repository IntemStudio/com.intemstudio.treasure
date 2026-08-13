class_name CombatantActor
extends Node2D

const BODY_SIZE := Vector2(40, 56)
const BAR_SIZE := Vector2(56, 8)
const ATB_SIZE := Vector2(48, 4)
const FLOAT_DURATION := 0.8
const FLOAT_RISE := 48.0

var unit_id: String = ""

var _body: ColorRect
var _name_label: Label
var _hp_bg: ColorRect
var _hp_fill: ColorRect
var _hp_label: Label
var _atb_bg: ColorRect
var _atb_fill: ColorRect
var _float_host: Node2D


func _ready() -> void:
	_build()


func setup(unit: Dictionary) -> void:
	unit_id = str(unit.get("id", ""))
	if _body == null:
		_build()
	_body.color = unit.get("body_color", Color(0.7, 0.3, 0.3, 1))
	apply_unit(unit)


func apply_unit(unit: Dictionary) -> void:
	if _body == null:
		_build()
	var alive := bool(unit.get("alive", true))
	visible = true
	modulate = Color(1, 1, 1, 1) if alive else Color(0.4, 0.4, 0.4, 0.55)
	_name_label.text = _unit_name(unit)
	var hp := maxi(0, int(unit.get("hp", 0)))
	var max_hp := maxi(1, int(unit.get("max_hp", 1)))
	var atb := clampf(float(unit.get("atb", 0.0)), 0.0, 1.0)
	_hp_fill.size = Vector2(BAR_SIZE.x * (float(hp) / float(max_hp)), BAR_SIZE.y)
	_hp_label.text = "%d/%d" % [hp, max_hp]
	_atb_fill.size = Vector2(ATB_SIZE.x * atb, ATB_SIZE.y)
	if not alive and hp <= 0:
		modulate = Color(0.4, 0.4, 0.4, 0.55)


func spawn_damage_float(amount: int) -> void:
	if amount <= 0 or _float_host == null:
		return
	var label := Label.new()
	label.text = str(amount)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(0.96, 0.42, 0.32, 1))
	label.add_theme_color_override("font_outline_color", Color(0.06, 0.03, 0.03, 0.92))
	label.add_theme_constant_override("outline_size", 4)
	label.position = Vector2(-32.0 + randf_range(-8.0, 8.0), -BODY_SIZE.y - 8.0)
	label.size = Vector2(64, 28)
	_float_host.add_child(label)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - FLOAT_RISE, FLOAT_DURATION).set_trans(
		Tween.TRANS_QUAD
	).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, FLOAT_DURATION * 0.7).set_delay(FLOAT_DURATION * 0.3)
	tween.chain().tween_callback(label.queue_free)


func _build() -> void:
	if _body != null:
		return

	_float_host = Node2D.new()
	_float_host.name = "FloatHost"
	_float_host.z_index = 10
	add_child(_float_host)

	_name_label = Label.new()
	_name_label.name = "NameLabel"
	_name_label.position = Vector2(-44, -BODY_SIZE.y - 36)
	_name_label.size = Vector2(88, 16)
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.add_theme_font_size_override("font_size", 11)
	_name_label.add_theme_color_override("font_color", Color(0.96, 0.95, 0.92, 1))
	_name_label.add_theme_color_override("font_outline_color", Color(0.04, 0.04, 0.05, 0.92))
	_name_label.add_theme_constant_override("outline_size", 2)
	_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_name_label)

	_hp_bg = ColorRect.new()
	_hp_bg.name = "HpBg"
	_hp_bg.position = Vector2(-BAR_SIZE.x * 0.5, -BODY_SIZE.y - 18)
	_hp_bg.size = BAR_SIZE
	_hp_bg.color = Color(0.12, 0.12, 0.14, 0.9)
	_hp_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hp_bg)

	_hp_fill = ColorRect.new()
	_hp_fill.name = "HpFill"
	_hp_fill.position = _hp_bg.position
	_hp_fill.size = BAR_SIZE
	_hp_fill.color = Color(0.35, 0.78, 0.42, 1)
	_hp_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hp_fill)

	_hp_label = Label.new()
	_hp_label.name = "HpLabel"
	_hp_label.position = _hp_bg.position
	_hp_label.size = BAR_SIZE
	_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_hp_label.add_theme_font_size_override("font_size", 9)
	_hp_label.add_theme_color_override("font_color", Color(0.96, 0.95, 0.92, 1))
	_hp_label.add_theme_color_override("font_outline_color", Color(0.04, 0.04, 0.05, 0.9))
	_hp_label.add_theme_constant_override("outline_size", 2)
	_hp_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hp_label)

	_atb_bg = ColorRect.new()
	_atb_bg.name = "AtbBg"
	_atb_bg.position = Vector2(-ATB_SIZE.x * 0.5, -BODY_SIZE.y - 8)
	_atb_bg.size = ATB_SIZE
	_atb_bg.color = Color(0.08, 0.08, 0.1, 0.9)
	_atb_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_atb_bg)

	_atb_fill = ColorRect.new()
	_atb_fill.name = "AtbFill"
	_atb_fill.position = _atb_bg.position
	_atb_fill.size = Vector2(0, ATB_SIZE.y)
	_atb_fill.color = Color(0.75, 0.75, 0.78, 1)
	_atb_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_atb_fill)

	_body = ColorRect.new()
	_body.name = "Body"
	_body.position = Vector2(-BODY_SIZE.x * 0.5, -BODY_SIZE.y)
	_body.size = BODY_SIZE
	_body.color = Color(0.7, 0.3, 0.3, 1)
	_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_body)


func _unit_name(unit: Dictionary) -> String:
	var raw := str(unit.get("display_name", "")).strip_edges()
	if raw.is_empty():
		raw = str(unit.get("id", ""))
	if bool(unit.get("is_hero", false)):
		return raw
	return tr(raw)
