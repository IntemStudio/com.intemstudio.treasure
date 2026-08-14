extends Node2D

const VILLAGE_SHELL_SCENE := preload("res://ui/village/village_shell.tscn")

@onready var camera: Camera2D = $Camera2D
@onready var ui_manager: UIManager = $UIManager
@onready var board_label: Label = $VillageRoom/Board/BoardLabel
@onready var altar_label: Label = $VillageRoom/Altar/AltarLabel
@onready var room_label: Label = $VillageRoom/RoomLabel
@onready var challenge_host: CanvasLayer = $ChallengeHost
@onready var board_panel: ColorRect = $VillageRoom/Board/BoardPanel
@onready var altar_panel: ColorRect = $VillageRoom/Altar/AltarPanel

var _village_shell: VillageShell


func _ready() -> void:
	ui_manager.set_hub_mode(true)
	_setup_village_shell()
	_refresh_labels()
	LocaleManager.locale_changed.connect(_on_locale_changed)
	if board_panel:
		board_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if altar_panel:
		altar_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if camera:
		camera.make_current()


func _setup_village_shell() -> void:
	_village_shell = VILLAGE_SHELL_SCENE.instantiate() as VillageShell
	challenge_host.add_child(_village_shell)
	_village_shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_village_shell.setup(ui_manager)


func _refresh_labels() -> void:
	if board_label:
		board_label.text = tr("BOARD_LABEL")
	if altar_label:
		altar_label.text = tr("ALTAR_LABEL")
	if room_label:
		room_label.text = tr("LOCATION_VILLAGE")


func _on_locale_changed(_locale: String) -> void:
	_refresh_labels()
