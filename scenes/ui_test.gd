extends Node2D

const HINT_LINE_KEYS: Array[String] = [
	"UI_TEST_HINT_1",
	"UI_TEST_HINT_2",
	"UI_TEST_HINT_3",
	"UI_TEST_HINT_4",
	"UI_TEST_HINT_5",
	"UI_TEST_HINT_6",
]

@onready var ui_manager: Node = $UIManager
@onready var hint: Label = $Hint
@onready var background: ColorRect = $Background


func _ready() -> void:
	_fit_background_to_viewport()
	get_viewport().size_changed.connect(_fit_background_to_viewport)
	if ui_manager.has_signal("popup_visibility_changed"):
		ui_manager.popup_visibility_changed.connect(_on_popup_visibility_changed)
	LocaleManager.locale_changed.connect(_on_locale_changed)
	_refresh_hint()


func _fit_background_to_viewport() -> void:
	background.size = get_viewport_rect().size


func _on_popup_visibility_changed(is_open: bool) -> void:
	hint.visible = not is_open


func _on_locale_changed(_locale: String) -> void:
	_refresh_hint()


func _refresh_hint() -> void:
	var lines: PackedStringArray = []
	for key in HINT_LINE_KEYS:
		lines.append(tr(key))
	hint.text = "\n".join(lines)
