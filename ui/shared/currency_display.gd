class_name CurrencyDisplay
extends HBoxContainer

@onready var gold_label: Label = %GoldLabel
@onready var silver_label: Label = %SilverLabel


func set_currencies(currencies: Dictionary) -> void:
	gold_label.text = str(currencies.get("gold", 0))
	silver_label.text = str(currencies.get("silver", 0))
