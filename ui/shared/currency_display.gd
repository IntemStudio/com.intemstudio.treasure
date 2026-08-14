class_name CurrencyDisplay
extends HBoxContainer

@onready var gold_label: Label = %GoldLabel
@onready var silver_label: Label = %SilverLabel

var _currencies: Dictionary = {}


func _ready() -> void:
	LocaleManager.locale_changed.connect(_on_locale_changed)
	_apply()


func set_currencies(currencies: Dictionary) -> void:
	_currencies = currencies
	_apply()


func _on_locale_changed(_locale: String) -> void:
	_apply()


func _apply() -> void:
	if gold_label:
		gold_label.text = "%s %d" % [tr("Gold"), int(_currencies.get("gold", 0))]
	if silver_label:
		silver_label.text = "%s %d" % [tr("Silver"), int(_currencies.get("silver", 0))]
