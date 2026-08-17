extends Control

signal request_close
signal level_up_pressed

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

const DEFENSE_BASE: Array[Dictionary] = [
	{"key": "defense", "label": "Defense"},
]

const COMBAT_STATS: Array[Dictionary] = [
	{"key": "damage", "label": "Damage"},
	{"key": "attack_speed", "label": "Attack Speed"},
	{"key": "crit_chance", "label": "Critical Chance"},
	{"key": "crit_damage", "label": "Critical Damage"},
	{"key": "magic_damage", "label": "Magic Damage"},
	{"key": "damage_all", "label": "Damage to All"},
	{"key": "vampirism", "label": "Vampirism"},
	{"key": "regen_per_sec", "label": "Regen"},
	{"key": "counter_chance", "label": "Counter"},
	{"key": "evasion", "label": "Evasion"},
	{"key": "magic_hp", "label": "Magic HP"},
	{"key": "retaliation", "label": "Retaliation"},
]

var stats: CharacterStats
var inventory: InventoryData
var _combat_snapshot: CombatStats

@onready var portrait: TextureRect = %Portrait
@onready var points_label: Label = %PointsLabel
@onready var points_value_label: Label = %PointsValueLabel
@onready var attribute_list: VBoxContainer = %AttributeList
@onready var general_col: VBoxContainer = %GeneralCol
@onready var combat_col: VBoxContainer = %CombatCol
@onready var defense_col: VBoxContainer = %DefenseCol
@onready var general_title: Label = %GeneralTitle
@onready var combat_title: Label = %CombatTitle
@onready var defense_title: Label = %DefenseTitle
@onready var insight_hint: Label = %InsightHint
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
var _stat_cols: Array = []
var _inspect_stat: bool = false
var _stat_col: int = 0
var _stat_row: int = 0


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED
	UIPopupLayout.apply_column_panels([$Body/LeftPanel, $Body/RightPanel])
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


func activate(character_stats: CharacterStats, inv: InventoryData) -> void:
	stats = character_stats
	inventory = inv
	visible = true
	process_mode = Node.PROCESS_MODE_INHERIT
	_selected_attr_index = 0
	_inspect_stat = false
	_stat_col = 0
	_stat_row = 0
	_refresh()
	_refresh_footer()
	_update_attribute_selection()
	_update_stat_selection()


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
		{"action": "close", "button": "B" if using_gamepad else "Esc", "label": tr("BACK")},
	])


func _on_footer_prompt(action: String) -> void:
	if not visible:
		return
	match action:
		"level_up":
			var attr_id := CharacterStats.ATTRIBUTE_IDS[_selected_attr_index]
			_try_spend_point(attr_id)
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
			_attribute_icon(attr_id)
		)
		row.selected.connect(_on_attribute_selected)
		row.increment_requested.connect(_on_attribute_increment)
		_attribute_rows.append(row)


func _attribute_icon(attr_id: String) -> Texture2D:
	match attr_id:
		"health":
			return ItemData.sheet_icon(2, 41)
		"stamina":
			return ItemData.sheet_icon(15, 42)
		"strength":
			return ItemData.sheet_icon(0, 41)
		"dexterity":
			return ItemData.sheet_icon(1, 41)
		"intelligence":
			return ItemData.sheet_icon(8, 0)
		"focus":
			return ItemData.sheet_icon(4, 5)
		"equip_load":
			return ItemData.sheet_icon(5, 0)
		_:
			return ItemData.sheet_icon(5, 0)


func _build_stat_columns() -> void:
	_stat_cols = [[], [], []]
	_clear_col_rows(general_col, "GeneralTitle")
	_clear_col_rows(combat_col, "CombatTitle")
	_clear_col_rows(defense_col, "DefenseTitle")
	for entry in GENERAL_STATS:
		_add_stat_row(general_col, "Stat_%s" % entry["key"], entry["key"], 0)
	for entry in COMBAT_STATS:
		_add_stat_row(combat_col, "Combat_%s" % entry["key"], entry["key"], 1)
	for entry in DEFENSE_BASE:
		_add_stat_row(defense_col, "Stat_%s" % entry["key"], entry["key"], 2)


func _clear_col_rows(col: VBoxContainer, keep_title: String) -> void:
	var to_free: Array[Node] = []
	for child in col.get_children():
		if child.name == keep_title:
			continue
		to_free.append(child)
	for child in to_free:
		col.remove_child(child)
		child.free()


func _add_stat_row(col: VBoxContainer, row_name: String, key: String, col_index: int) -> void:
	var row: StatRow = STAT_ROW_SCENE.instantiate()
	col.add_child(row)
	row.name = row_name
	row.stat_key = key
	var row_index: int = _stat_cols[col_index].size()
	row.inspected.connect(func(_key: String) -> void: _on_stat_inspected(col_index, row_index))
	_stat_cols[col_index].append(row)


func _refresh() -> void:
	if not stats:
		return
	_combat_snapshot = CombatStatsBuilder.build(stats, inventory)
	_refresh_static_labels()
	points_value_label.text = str(stats.attribute_points)
	max_weight_label.text = tr("Max Weight: %.1f") % stats.weight_max
	current_weight_label.text = tr("Current: %.1f") % stats.weight_current
	weight_class_label.text = stats.get_weight_class_label()
	weight_bar.max_value = stats.weight_max
	weight_bar.value = stats.weight_current
	_refresh_attributes()
	_refresh_general_defense()
	_refresh_combat()
	_refresh_weapon_table()


func _refresh_static_labels() -> void:
	points_label.text = tr("Attribute Points")
	general_title.text = tr("GENERAL")
	combat_title.text = tr("COMBAT")
	defense_title.text = tr("DEFENSE")
	weight_title.text = tr("WEIGHT")
	weapon_header.text = tr("Weapon")
	base_header.text = tr("Base")
	attr_bonus_header.text = tr("Attr Bonus")
	other_header.text = tr("Other")
	total_header.text = tr("Total")
	_refresh_insight_hint()


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
		var row: StatRow = general_col.get_node_or_null("Stat_%s" % entry["key"])
		if row:
			row.setup(entry["key"], tr(entry["label"]), stats.general.get(entry["key"], 0))
	for entry in DEFENSE_BASE:
		var row: StatRow = defense_col.get_node_or_null("Stat_%s" % entry["key"])
		if row:
			var value: Variant = stats.defense.get(entry["key"], 0)
			if entry["key"] == "defense" and _combat_snapshot:
				value = _combat_snapshot.defense
			row.setup(entry["key"], tr(entry["label"]), _format_stat(value))


func _refresh_combat() -> void:
	if _combat_snapshot == null:
		return
	var c := _combat_snapshot
	var values := {
		"damage": "%d-%d" % [c.damage_min, c.damage_max],
		"attack_speed": c.attack_speed,
		"crit_chance": c.crit_chance,
		"crit_damage": "×%.2f" % c.crit_damage,
		"magic_damage": c.magic_damage,
		"damage_all": c.damage_all,
		"vampirism": c.vampirism,
		"regen_per_sec": c.regen_per_sec,
		"counter_chance": c.counter_chance,
		"evasion": c.evasion,
		"magic_hp": c.magic_hp,
		"retaliation": c.retaliation,
	}
	for entry in COMBAT_STATS:
		var row: StatRow = combat_col.get_node_or_null("Combat_%s" % entry["key"])
		if row == null:
			continue
		var raw: Variant = values.get(entry["key"], 0)
		row.setup(entry["key"], tr(entry["label"]), _format_combat_value(entry["key"], raw))


func _format_combat_value(key: String, raw: Variant) -> Variant:
	match key:
		"damage", "crit_damage", "magic_hp":
			return raw
		"vampirism", "evasion", "counter_chance", "crit_chance", "attack_speed":
			if raw is float or raw is int:
				return "%.1f%%" % (float(raw) * 100.0) if key != "attack_speed" else "+%.0f%%" % (float(raw) * 100.0)
	return _format_stat(raw)


func _format_stat(value: Variant) -> Variant:
	if value is float:
		var f := float(value)
		if is_equal_approx(f, roundf(f)):
			return int(roundf(f))
		return snappedf(f, 0.1)
	return value


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
	_refresh_insight_hint()


func _update_stat_selection() -> void:
	for col_index in range(_stat_cols.size()):
		var rows: Array = _stat_cols[col_index]
		for row_index in range(rows.size()):
			var row: StatRow = rows[row_index]
			row.set_selected(_inspect_stat and col_index == _stat_col and row_index == _stat_row)
	_refresh_insight_hint()


func _refresh_insight_hint() -> void:
	if not insight_hint:
		return
	if _inspect_stat:
		var entry := _stat_entry_at(_stat_col, _stat_row)
		if entry.is_empty():
			insight_hint.text = ""
			return
		var key := str(entry["key"])
		insight_hint.text = "%s — %s" % [tr(str(entry["label"])), tr("STAT_DESC_%s" % key)]
		return
	if _selected_attr_index < 0 or _selected_attr_index >= CharacterStats.ATTRIBUTE_IDS.size():
		insight_hint.text = ""
		return
	var attr_id := CharacterStats.ATTRIBUTE_IDS[_selected_attr_index]
	var label := CharacterStats.get_attribute_label(attr_id)
	insight_hint.text = "%s — %s" % [label, tr("ATTR_DESC_%s" % attr_id)]


func _stat_entry_at(col_index: int, row_index: int) -> Dictionary:
	var groups: Array = [GENERAL_STATS, COMBAT_STATS, DEFENSE_BASE]
	if col_index < 0 or col_index >= groups.size():
		return {}
	var entries: Array = groups[col_index]
	if row_index < 0 or row_index >= entries.size():
		return {}
	return entries[row_index]


func _clamp_stat_row() -> void:
	if _stat_col < 0 or _stat_col >= _stat_cols.size():
		_stat_row = 0
		return
	var size: int = _stat_cols[_stat_col].size()
	_stat_row = clampi(_stat_row, 0, maxi(0, size - 1))


func _move_stat_col(delta: int) -> void:
	_stat_col = clampi(_stat_col + delta, 0, _stat_cols.size() - 1)
	_clamp_stat_row()
	_update_stat_selection()


func _move_stat_row(delta: int) -> void:
	if _stat_col < 0 or _stat_col >= _stat_cols.size():
		return
	var size: int = _stat_cols[_stat_col].size()
	_stat_row = clampi(_stat_row + delta, 0, maxi(0, size - 1))
	_update_stat_selection()


func _on_stat_inspected(col_index: int, row_index: int) -> void:
	_inspect_stat = true
	_stat_col = col_index
	_stat_row = row_index
	_update_stat_selection()


func _on_attribute_selected(attr_id: String) -> void:
	_selected_attr_index = CharacterStats.ATTRIBUTE_IDS.find(attr_id)
	_inspect_stat = false
	_update_attribute_selection()
	_update_stat_selection()
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
	elif event.is_action_pressed("ui_up"):
		if _inspect_stat:
			_move_stat_row(-1)
		else:
			_selected_attr_index = maxi(_selected_attr_index - 1, 0)
			_update_attribute_selection()
			_preview_selected_attribute()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_down"):
		if _inspect_stat:
			_move_stat_row(1)
		else:
			_selected_attr_index = mini(_selected_attr_index + 1, _attribute_rows.size() - 1)
			_update_attribute_selection()
			_preview_selected_attribute()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_right"):
		if _inspect_stat:
			_move_stat_col(1)
		else:
			_inspect_stat = true
			_stat_col = 0
			_stat_row = 0
			_update_stat_selection()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_left"):
		if _inspect_stat:
			if _stat_col <= 0:
				_inspect_stat = false
				_update_stat_selection()
				_refresh_insight_hint()
			else:
				_move_stat_col(-1)
			get_viewport().set_input_as_handled()
