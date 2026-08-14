class_name PlayerVitals
extends HBoxContainer

@onready var name_label: Label = %NameLabel
@onready var level_label: Label = %LevelLabel
@onready var xp_bar: ProgressBar = %XpBar
@onready var xp_label: Label = %XpLabel
@onready var hp_label: Label = %HpLabel


func set_stats(data: CharacterStats) -> void:
	if not data:
		return
	data.sync_xp_to_next()
	if name_label:
		name_label.visible = false
		name_label.text = ""
	level_label.text = tr("Level %d") % data.level
	var xp_max := data.xp_to_next
	xp_bar.max_value = maxi(xp_max, 1)
	xp_bar.value = clampi(data.xp, 0, int(xp_bar.max_value))
	if xp_max <= 0:
		xp_label.text = "%s %s" % [tr("Experience"), tr("MAX")]
		xp_bar.value = xp_bar.max_value
	else:
		xp_label.text = "%s %d / %d" % [tr("Experience"), data.xp, xp_max]
	hp_label.text = "%s %d/%d" % [tr("Health"), data.hp, data.hp_max]
