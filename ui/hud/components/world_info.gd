class_name WorldInfo
extends VBoxContainer

@onready var location_label: Label = %LocationLabel
@onready var version_label: Label = %VersionLabel

var _location_id: String = "LOCATION_TEST"


func _ready() -> void:
	version_label.text = AppVersion.format()
	_refresh_location()
	if LocaleManager:
		LocaleManager.locale_changed.connect(_on_locale_changed)


func set_location(location_id: String) -> void:
	_location_id = location_id if not location_id.is_empty() else "LOCATION_UNKNOWN"
	_refresh_location()


func _on_locale_changed(_locale: String) -> void:
	_refresh_location()


func _refresh_location() -> void:
	if location_label:
		location_label.text = tr(_location_id)
