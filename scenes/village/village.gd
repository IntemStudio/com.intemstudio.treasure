extends Node2D

const CHALLENGE_BOARD_SCENE := preload("res://ui/village/challenge_board.tscn")
const REGISTRATION_ALTAR_SCENE := preload("res://ui/village/registration_altar.tscn")

@onready var player: Node2D = $Player
@onready var camera: Camera2D = $Camera2D
@onready var ui_manager: UIManager = $UIManager
@onready var board: Node2D = $VillageRoom/Board
@onready var board_panel: ColorRect = $VillageRoom/Board/BoardPanel
@onready var board_label: Label = $VillageRoom/Board/BoardLabel
@onready var altar: Node2D = $VillageRoom/Altar
@onready var altar_panel: ColorRect = $VillageRoom/Altar/AltarPanel
@onready var altar_label: Label = $VillageRoom/Altar/AltarLabel
@onready var room_label: Label = $VillageRoom/RoomLabel
@onready var challenge_host: CanvasLayer = $ChallengeHost

var _challenge_board: ChallengeBoard
var _registration_altar: RegistrationAltar


func _ready() -> void:
	ui_manager.set_hub_mode(true)
	_setup_challenge_board()
	_setup_registration_altar()
	_refresh_labels()
	LocaleManager.locale_changed.connect(_on_locale_changed)
	if board_panel:
		board_panel.gui_input.connect(_on_board_panel_gui_input)
		board_panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if altar_panel:
		altar_panel.gui_input.connect(_on_altar_panel_gui_input)
		altar_panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if camera:
		camera.make_current()
	if player:
		player.position = Vector2(0, 40)


func _setup_challenge_board() -> void:
	_challenge_board = CHALLENGE_BOARD_SCENE.instantiate() as ChallengeBoard
	challenge_host.add_child(_challenge_board)
	_challenge_board.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_challenge_board.setup(ui_manager)


func _setup_registration_altar() -> void:
	_registration_altar = REGISTRATION_ALTAR_SCENE.instantiate() as RegistrationAltar
	challenge_host.add_child(_registration_altar)
	_registration_altar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_registration_altar.setup(ui_manager)


func _refresh_labels() -> void:
	if board_label:
		board_label.text = tr("BOARD_LABEL")
	if altar_label:
		altar_label.text = tr("ALTAR_LABEL")
	if room_label:
		room_label.text = tr("LOCATION_VILLAGE")


func _on_locale_changed(_locale: String) -> void:
	_refresh_labels()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	if ui_manager and ui_manager.is_world_input_blocked():
		return
	if _challenge_board and _challenge_board.is_open():
		return
	if _registration_altar and _registration_altar.is_open():
		return
	if event.is_action_pressed("ui_accept"):
		if _is_near_altar():
			_open_altar()
			get_viewport().set_input_as_handled()
		elif _is_near_board():
			_open_board()
			get_viewport().set_input_as_handled()


func _on_board_panel_gui_input(event: InputEvent) -> void:
	if ui_manager and ui_manager.is_world_input_blocked():
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			_open_board()
			board_panel.accept_event()


func _on_altar_panel_gui_input(event: InputEvent) -> void:
	if ui_manager and ui_manager.is_world_input_blocked():
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			_open_altar()
			altar_panel.accept_event()


func _is_near_board() -> bool:
	if player == null or board == null:
		return true
	return player.global_position.distance_to(board.global_position) <= 200.0


func _is_near_altar() -> bool:
	if player == null or altar == null:
		return false
	return player.global_position.distance_to(altar.global_position) <= 200.0


func _open_board() -> void:
	if _challenge_board == null or _challenge_board.is_open():
		return
	if _registration_altar and _registration_altar.is_open():
		return
	_challenge_board.open()


func _open_altar() -> void:
	if _registration_altar == null or _registration_altar.is_open():
		return
	if _challenge_board and _challenge_board.is_open():
		return
	_registration_altar.open()
