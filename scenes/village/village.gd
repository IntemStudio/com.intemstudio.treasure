extends Node2D

const CHALLENGE_BOARD_SCENE := preload("res://ui/village/challenge_board.tscn")

@onready var player: Node2D = $Player
@onready var camera: Camera2D = $Camera2D
@onready var ui_manager: UIManager = $UIManager
@onready var board: Node2D = $VillageRoom/Board
@onready var board_panel: ColorRect = $VillageRoom/Board/BoardPanel
@onready var board_label: Label = $VillageRoom/Board/BoardLabel
@onready var room_label: Label = $VillageRoom/RoomLabel
@onready var challenge_host: CanvasLayer = $ChallengeHost

var _challenge_board: ChallengeBoard


func _ready() -> void:
	ui_manager.set_hub_mode(true)
	_setup_challenge_board()
	_refresh_labels()
	LocaleManager.locale_changed.connect(_on_locale_changed)
	if board_panel:
		board_panel.gui_input.connect(_on_board_panel_gui_input)
		board_panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if camera:
		camera.make_current()
	if player:
		player.position = Vector2(0, 40)


func _setup_challenge_board() -> void:
	_challenge_board = CHALLENGE_BOARD_SCENE.instantiate() as ChallengeBoard
	challenge_host.add_child(_challenge_board)
	_challenge_board.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_challenge_board.setup(ui_manager)


func _refresh_labels() -> void:
	if board_label:
		board_label.text = tr("BOARD_LABEL")
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
	if event.is_action_pressed("ui_accept"):
		if _is_near_board():
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


func _is_near_board() -> bool:
	if player == null or board == null:
		return true
	return player.global_position.distance_to(board.global_position) <= 200.0


func _open_board() -> void:
	if _challenge_board == null or _challenge_board.is_open():
		return
	if ui_manager:
		ui_manager.close_all()
	_challenge_board.open()
