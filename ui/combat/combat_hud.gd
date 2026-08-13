class_name CombatHud
extends CanvasLayer

var _session: CombatSession
var _retreat_callback: Callable
var _can_retreat: bool = true

@onready var retreat_button: Button = %RetreatButton
@onready var speed_button: Button = %SpeedButton
@onready var status_label: Label = %StatusLabel


func _ready() -> void:
	layer = 1
	visible = false
	process_mode = Node.PROCESS_MODE_INHERIT
	if retreat_button:
		retreat_button.pressed.connect(_on_retreat_pressed)
	if speed_button:
		speed_button.pressed.connect(_on_speed_pressed)
	_refresh_texts()
	if LocaleManager:
		LocaleManager.locale_changed.connect(_on_locale_changed)


func bind_session(session: CombatSession) -> void:
	if _session and _session.state_changed.is_connected(_on_state_changed):
		_session.state_changed.disconnect(_on_state_changed)
	_session = session
	if _session and not _session.state_changed.is_connected(_on_state_changed):
		_session.state_changed.connect(_on_state_changed)


func set_retreat_callback(cb: Callable) -> void:
	_retreat_callback = cb


func show_combat(state: Dictionary, encounter: EncounterDef = null) -> void:
	visible = true
	_can_retreat = true
	if encounter:
		_can_retreat = encounter.can_retreat
	elif state.has("can_retreat"):
		_can_retreat = bool(state["can_retreat"])
	if retreat_button:
		retreat_button.visible = _can_retreat
		retreat_button.disabled = not _can_retreat
	_refresh_texts()
	_apply_state(state)
	if status_label:
		status_label.text = ""


func hide_combat() -> void:
	visible = false


func _on_locale_changed(_locale: String) -> void:
	_refresh_texts()
	if visible and _session:
		_apply_state(_session.get_state())


func _refresh_texts() -> void:
	if retreat_button:
		retreat_button.text = tr("COMBAT_RETREAT")
	_refresh_speed_label()


func _refresh_speed_label() -> void:
	if speed_button == null:
		return
	var mult := 1.0
	if _session:
		mult = _session.get_speed_mult()
	speed_button.text = tr("COMBAT_SPEED") % _format_speed(mult)


func _format_speed(mult: float) -> String:
	if is_equal_approx(mult, roundf(mult)):
		return "%d×" % int(roundf(mult))
	return "%.1f×" % mult


func _on_retreat_pressed() -> void:
	if not _can_retreat:
		return
	if _retreat_callback.is_valid():
		_retreat_callback.call()
	elif _session:
		_session.request_retreat()


func _on_speed_pressed() -> void:
	if _session == null:
		return
	_session.cycle_speed()
	_refresh_speed_label()


func _on_state_changed() -> void:
	if not visible or _session == null:
		return
	_apply_state(_session.get_state())


func _apply_state(state: Dictionary) -> void:
	_can_retreat = bool(state.get("can_retreat", _can_retreat))
	if retreat_button:
		retreat_button.visible = _can_retreat
	_refresh_speed_label()
