extends Control

signal request_close
signal level_up_pressed
signal insight_pressed

const ATTRIBUTE_ROW_SCENE := preload("res://ui/stats/components/attribute_row.tscn")
const STAT_ROW_SCENE := preload("res://ui/stats/components/stat_row.tscn")
const WEAPON_ROW_SCENE := preload("res://ui/stats/components/weapon_stat_row.tscn")
const PORTRAIT_SHADER := preload("res://ui/stats/shaders/hex_portrait.gdshader")

const GENERAL_STATS: Array[Dictionary] = [
	{"key": "health", "label": "Life Points"},
	{"key": "stamina", "label": "Stamina Points"},
	{"key": "stamina_regen", "label": "Stamina Regen"},
	{"key": "focus", "label": "Focus Points"},
	{"key": "focus_gain", "label": "Focus Gain"},
]

const DEFENSE_STATS: Array[Dictionary] = [
	{"key": "armor", "label": "Armor"},
	{"key": "poise", "label": "Poise"},
	{"key": "heat", "label": "Heat"},
	{"key": "cold", "label": "Cold"},
	{"key": "electric", "label": "Electric"},
	{"key": "plague", "label": "Plague"},
]

var stats: CharacterStats

@onready var portrait: TextureRect = %Portrait
@onready var points_label: Label = %PointsLabel
@onready var points_value_label: Label = %PointsValueLabel
@onready var attribute_list: VBoxContainer = %AttributeList
@onready var general_col: VBoxContainer = %GeneralCol
@onready var defense_col: VBoxContainer = %DefenseCol
@onready var general_title: Label = %GeneralTitle
@onready var defense_title: Label = %DefenseTitle
@onready var weight_title: Label = %WeightTitle
@onready var max_weight_label: Label = %MaxWeightLabel
@onready var current_weight_label: Label = %CurrentWeightLabel
@onready var weight_class_label: Label = %WeightClassLabel
@onready var weight_bar: ProgressBar = %WeightBar
@onready var weapon_rows: VBoxContainer = %WeaponRows
@onready var points_prev_btn: Button = %PointsPrevBtn
@onready var points_next_btn: Button = %PointsNextBtn
@onready var weapon_header: Label = %Weapon
@onready var base_header: Label = %Base
@onready var attr_bonus_header: Label = %AttrBonus
@onready var other_header: Label = %Other
@onready var total_header: Label = %Total

var _ui_manager: UIManager
var _footer: FooterPrompts
var _attribute_rows: Array[AttributeRow] = []
var _selected_attr_index: int = 0
var _footer_connected: bool = false


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED
	_setup_portrait_shader()
	_build_attribute_rows()
	_build_stat_columns()
	LocaleManager.locale_changed.connect(_on_locale_changed)
	points_prev_btn.pressed.connect(_on_points_prev)
	points_next_btn.pressed.connect(_on_points_next)


func setup(ui_manager: UIManager, footer: FooterPrompts) -> void:
	_ui_manager = ui_manager
	_footer = footer
	if _ui_manager and not _ui_manager.input_device_changed.is_connected(_on_input_device_changed):
		_ui_manager.input_device_changed.connect(_on_input_device_changed)
	if _footer and not _footer_connected:
		_footer.prompt_activated.connect(_on_footer_prompt)
		_footer_connected = true


func activate(character_stats: CharacterStats, _inventory: InventoryData) -> void:
	stats = character_stats
	visible = true
	process_mode = Node.PROCESS_MODE_INHERIT
	_selected_attr_index = 0
	_refresh()
	_refresh_footer()
	_update_attribute_selection()


func deactivate() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED


func _is_using_gamepad() -> bool:
	return _ui_manager.using_gamepad if _ui_manager else false


func _on_input_device_changed(_using_gamepad: bool) -> void:
	if visible:
		_refresh_footer.call_deferred()


func _on_locale_changed(_locale: String) -> void:
	_refresh_static_labels()
	if stats:
		_refresh()
	if visible:
		_refresh_footer()


func _refresh_footer() -> void:
	if not _footer:
		return
	var using_gamepad := _is_using_gamepad()
	_footer.set_prompts([
		{"action": "level_up", "button": "A" if using_gamepad else "Enter", "label": tr("LEVEL-UP")},
		{"action": "insight", "button": "X" if using_gamepad else "X", "label": tr("INSIGHT")},
		{"action": "close", "button": "B" if using_gamepad else "Esc", "label": tr("BACK")},
	])


func _on_footer_prompt(action: String) -> void:
	if not visible:
		return
	match action:
		"level_up":
			var attr_id := CharacterStats.ATTRIBUTE_IDS[_selected_attr_index]
			_try_spend_point(attr_id)
		"insight":
			insight_pressed.emit()
		"close":
			request_close.emit()


func _setup_portrait_shader() -> void:
	var material := ShaderMaterial.new()
	material.shader = PORTRAIT_SHADER
	portrait.material = material
	portrait.texture = load("res://icon.svg")


func _build_attribute_rows() -> void:
	for child in attribute_list.get_children():
		child.queue_free()
	_attribute_rows.clear()
	for attr_id in CharacterStats.ATTRIBUTE_IDS:
		var row: AttributeRow = ATTRIBUTE_ROW_SCENE.instantiate()
		attribute_list.add_child(row)
		row.setup(
			attr_id,
			CharacterStats.get_attribute_label(attr_id),
			0,
			load("res://icon.svg")
		)
		row.selected.connect(_on_attribute_selected)
		row.increment_requested.connect(_on_attribute_increment)
		_attribute_rows.append(row)


func _build_stat_columns() -> void:
	for child in general_col.get_children():
		if child.name != "GeneralTitle":
			child.queue_free()
	for child in defense_col.get_children():
		if child.name != "DefenseTitle":
			child.queue_free()
	for entry in GENERAL_STATS:
		var row: StatRow = STAT_ROW_SCENE.instantiate()
		general_col.add_child(row)
		row.name = "Stat_%s" % entry["key"]
	for entry in DEFENSE_STATS:
		var row: StatRow = STAT_ROW_SCENE.instantiate()
		defense_col.add_child(row)
		row.name = "Stat_%s" % entry["key"]


func _refresh() -> void:
	if not stats:
		return
	_refresh_static_labels()
	points_value_label.text = str(stats.attribute_points)
	max_weight_label.text = tr("Max Weight: %.1f") % stats.weight_max
	current_weight_label.text = tr("Current: %.1f") % stats.weight_current
	weight_class_label.text = stats.get_weight_class_label()
	weight_bar.max_value = stats.weight_max
	weight_bar.value = stats.weight_current
	_refresh_attributes()
	_refresh_general_defense()
	_refresh_weapon_table()


func _refresh_static_labels() -> void:
	points_label.text = tr("Attribute Points")
	general_title.text = tr("GENERAL")
	defense_title.text = tr("DEFENSE")
	weight_title.text = tr("WEIGHT")
	weapon_header.text = tr("Weapon")
	base_header.text = tr("Base")
	attr_bonus_header.text = tr("Attr Bonus")
	other_header.text = tr("Other")
	total_header.text = tr("Total")


func _refresh_attributes() -> void:
	for i in range(_attribute_rows.size()):
		var attr_id := CharacterStats.ATTRIBUTE_IDS[i]
		var row := _attribute_rows[i]
		var value := int(stats.attributes.get(attr_id, 0))
		var delta := stats.get_preview_delta(attr_id)
		row.setup(attr_id, CharacterStats.get_attribute_label(attr_id), value)
		row.set_preview_delta(value, delta)
	_update_attribute_selection()


func _refresh_general_defense() -> void:
	for entry in GENERAL_STATS:
		var row: StatRow = general_col.get_node("Stat_%s" % entry["key"])
		row.setup(tr(entry["label"]), stats.general.get(entry["key"], 0))
	for entry in DEFENSE_STATS:
		var row: StatRow = defense_col.get_node("Stat_%s" % entry["key"])
		row.setup(tr(entry["label"]), stats.defense.get(entry["key"], 0))


func _refresh_weapon_table() -> void:
	for child in weapon_rows.get_children():
		child.queue_free()
	for weapon_data in stats.weapons:
		var row: WeaponStatRow = WEAPON_ROW_SCENE.instantiate()
		weapon_rows.add_child(row)
		row.setup(weapon_data)


func _update_attribute_selection() -> void:
	for i in range(_attribute_rows.size()):
		_attribute_rows[i].set_selected(i == _selected_attr_index)


func _on_attribute_selected(attr_id: String) -> void:
	_selected_attr_index = CharacterStats.ATTRIBUTE_IDS.find(attr_id)
	_update_attribute_selection()
	_preview_selected_attribute()


func _on_attribute_increment(attr_id: String) -> void:
	_try_spend_point(attr_id)


func _try_spend_point(attr_id: String) -> void:
	if not stats or not stats.can_spend_point():
		return
	stats.spend_point_on(attr_id)
	_refresh()


func _preview_selected_attribute() -> void:
	if not stats:
		return
	stats.clear_preview_deltas()
	var attr_id := CharacterStats.ATTRIBUTE_IDS[_selected_attr_index]
	if stats.can_spend_point():
		stats.set_preview_delta(attr_id, CharacterStats.ATTR_GAIN_PER_POINT)
	_refresh_attributes()


func _on_points_prev() -> void:
	if stats and stats.attribute_points > 0:
		stats.attribute_points -= 1
		_refresh()


func _on_points_next() -> void:
	if stats:
		stats.attribute_points += 1
		_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		request_close.emit()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept"):
		var attr_id := CharacterStats.ATTRIBUTE_IDS[_selected_attr_index]
		_try_spend_point(attr_id)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("stats_insight"):
		insight_pressed.emit()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_up"):
		_selected_attr_index = maxi(_selected_attr_index - 1, 0)
		_update_attribute_selection()
		_preview_selected_attribute()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_down"):
		_selected_attr_index = mini(_selected_attr_index + 1, _attribute_rows.size() - 1)
		_update_attribute_selection()
		_preview_selected_attribute()
		get_viewport().set_input_as_handled()
