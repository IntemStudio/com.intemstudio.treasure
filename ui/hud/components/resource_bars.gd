class_name ResourceBars
extends VBoxContainer

@onready var xp_bar: ProgressBar = %XpBar
@onready var xp_label: Label = %XpLabel
@onready var mana_bar: ProgressBar = %ManaBar
@onready var mana_label: Label = %ManaLabel
@onready var hp_bar: ProgressBar = %HpBar
@onready var hp_label: Label = %HpLabel

var _xp: int = 0
var _xp_to_next: int = 0
var _mana: int = 0
var _mana_max: int = 0
var _hp: int = 0
var _hp_max: int = 0
var _has_stats: bool = false


func _ready() -> void:
	_style_bar(xp_bar, UIColors.XP_FILL)
	_style_bar(mana_bar, UIColors.MANA_FILL)
	_style_bar(hp_bar, UIColors.HP_FILL)
	if LocaleManager:
		LocaleManager.locale_changed.connect(_on_locale_changed)


func set_stats(stats: CharacterStats) -> void:
	if stats == null:
		return
	stats.sync_xp_to_next()
	_xp = stats.xp
	_xp_to_next = stats.xp_to_next
	_mana = stats.mana
	_mana_max = stats.mana_max
	_hp = stats.hp
	_hp_max = stats.hp_max
	_has_stats = true
	_refresh_labels()


func _on_locale_changed(_locale: String) -> void:
	if _has_stats:
		_refresh_labels()


func _refresh_labels() -> void:
	_set_xp_bar(_xp, _xp_to_next)
	_set_bar(mana_bar, mana_label, "MP", _mana, _mana_max)
	_set_bar(hp_bar, hp_label, "HP", _hp, _hp_max)


func _set_xp_bar(value: int, max_value: int) -> void:
	if max_value <= 0:
		xp_bar.max_value = 1
		xp_bar.value = 1
		xp_label.text = "%s %s" % [tr("EXP"), tr("MAX")]
		return
	xp_bar.max_value = max_value
	xp_bar.value = clampi(value, 0, max_value)
	xp_label.text = "%s %d/%d" % [tr("EXP"), value, max_value]


func _set_bar(bar: ProgressBar, label: Label, key: String, value: int, max_value: int) -> void:
	bar.max_value = maxi(max_value, 1)
	bar.value = clampi(value, 0, int(bar.max_value))
	label.text = "%s %d/%d" % [tr(key), value, max_value]


func _style_bar(bar: ProgressBar, fill: Color) -> void:
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.08, 0.08, 0.09, 0.75)
	bg.set_content_margin_all(0)
	var fg := StyleBoxFlat.new()
	fg.bg_color = fill
	fg.set_content_margin_all(0)
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fg)
	bar.show_percentage = false
