class_name ChallengeBoard
extends Control

signal closed
signal challenge_confirmed(params: Dictionary)

enum FocusColumn { REGION = 0, LENGTH = 1 }

const DUNGEON_SCENE := "res://scenes/dungeon/dungeon.tscn"
const FOOTER_SCENE := preload("res://ui/shared/footer_prompts.tscn")

@onready var title_label: Label = %TitleLabel
@onready var region_section_label: Label = %RegionSectionLabel
@onready var length_section_label: Label = %LengthSectionLabel
@onready var region_list: VBoxContainer = %RegionList
@onready var length_list: VBoxContainer = %LengthList
@onready var detail_title: Label = %DetailTitle
@onready var detail_body: Label = %DetailBody
@onready var footer_host: Control = %FooterHost

var _ui_manager: UIManager
var _footer: FooterPrompts
var _footer_connected: bool = false
var _active: bool = false
var _focus_column: int = FocusColumn.REGION
var _region_index: int = 0
var _length_index: int = 1
var _region_buttons: Array[Button] = []
var _length_buttons: Array[Button] = []


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED
	_build_region_list()
	_build_length_list()
	_ensure_footer()
	LocaleManager.locale_changed.connect(_on_locale_changed)
	_refresh_texts()


func setup(ui_manager: UIManager) -> void:
	_ui_manager = ui_manager


func open() -> void:
	_active = true
	visible = true
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	get_tree().paused = true
	_focus_column = FocusColumn.REGION
	_region_index = 0
	_length_index = 1
	_refresh_texts()
	_apply_focus()
	_sync_footer()
	if _ui_manager:
		_ui_manager.set_challenge_board_open(true)


func close() -> void:
	if not _active:
		return
	_active = false
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED
	get_tree().paused = false
	if _ui_manager:
		_ui_manager.set_challenge_board_open(false)
	closed.emit()


func is_open() -> bool:
	return _active


func _ensure_footer() -> void:
	if footer_host == null:
		return
	if _footer != null:
		return
	_footer = FOOTER_SCENE.instantiate() as FooterPrompts
	footer_host.add_child(_footer)
	_footer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _make_list_button(label_key: String) -> Button:
	var button := Button.new()
	button.flat = true
	button.focus_mode = Control.FOCUS_ALL
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_size_override("font_size", 22)
	button.text = tr(label_key)
	_style_button(button, false, false)
	return button


func _build_region_list() -> void:
	if region_list == null:
		return
	for child in region_list.get_children():
		child.queue_free()
	_region_buttons.clear()
	for i in range(ChallengeDef.REGIONS.size()):
		var region := ChallengeDef.get_region(i)
		var button := _make_list_button(str(region.get("title_key", "")))
		button.pressed.connect(_on_region_pressed.bind(i))
		button.focus_entered.connect(_on_region_focus_entered.bind(i))
		region_list.add_child(button)
		_region_buttons.append(button)


func _build_length_list() -> void:
	if length_list == null:
		return
	for child in length_list.get_children():
		child.queue_free()
	_length_buttons.clear()
	for i in range(ChallengeDef.LENGTHS.size()):
		var length := ChallengeDef.get_length(i)
		var button := _make_list_button(str(length.get("title_key", "")))
		button.pressed.connect(_on_length_pressed.bind(i))
		button.focus_entered.connect(_on_length_focus_entered.bind(i))
		length_list.add_child(button)
		_length_buttons.append(button)


func _refresh_texts() -> void:
	if title_label:
		title_label.text = tr("Challenge")
		title_label.add_theme_color_override("font_color", UIColors.TEXT_MAIN)
	if region_section_label:
		region_section_label.text = tr("Region")
		region_section_label.add_theme_color_override("font_color", UIColors.TEXT_MUTED)
	if length_section_label:
		length_section_label.text = tr("Length")
		length_section_label.add_theme_color_override("font_color", UIColors.TEXT_MUTED)
	if detail_title:
		detail_title.add_theme_color_override("font_color", UIColors.GOLD)
	if detail_body:
		detail_body.add_theme_color_override("font_color", UIColors.TEXT_LORE)
	for i in range(_region_buttons.size()):
		var region := ChallengeDef.get_region(i)
		_region_buttons[i].text = tr(str(region.get("title_key", "")))
	for i in range(_length_buttons.size()):
		var length := ChallengeDef.get_length(i)
		_length_buttons[i].text = tr(str(length.get("title_key", "")))
	_refresh_detail()
	if _active:
		_sync_footer()


func _refresh_detail() -> void:
	var region := ChallengeDef.get_region(_region_index)
	var length := ChallengeDef.get_length(_length_index)
	var region_title := tr(str(region.get("title_key", "")))
	var length_title := tr(str(length.get("title_key", "")))
	if detail_title:
		detail_title.text = "%s · %s" % [region_title, length_title]
	var parts: PackedStringArray = []
	var region_desc := tr(str(region.get("desc_key", "")))
	var length_desc := tr(str(length.get("desc_key", "")))
	if not region_desc.is_empty():
		parts.append(region_desc)
	if not length_desc.is_empty():
		parts.append(length_desc)
	if detail_body:
		detail_body.text = "\n\n".join(parts)


func _style_button(button: Button, selected: bool, column_active: bool) -> void:
	var focused := selected and column_active
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.border_width_left = 3
	style.border_color = UIColors.SELECT_BORDER if focused else Color(0, 0, 0, 0)
	style.content_margin_left = 16
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	style.content_margin_right = 4
	for state_name in ["normal", "hover", "pressed", "focus", "disabled"]:
		button.add_theme_stylebox_override(state_name, style)
	var color := UIColors.GOLD if selected else UIColors.TEXT_MUTED
	button.add_theme_color_override("font_color", color)
	button.add_theme_color_override("font_hover_color", UIColors.GOLD)
	button.add_theme_color_override("font_focus_color", color)


func _apply_focus() -> void:
	_region_index = clampi(_region_index, 0, maxi(_region_buttons.size() - 1, 0))
	_length_index = clampi(_length_index, 0, maxi(_length_buttons.size() - 1, 0))
	for i in range(_region_buttons.size()):
		_style_button(
			_region_buttons[i],
			i == _region_index,
			_focus_column == FocusColumn.REGION
		)
	for i in range(_length_buttons.size()):
		_style_button(
			_length_buttons[i],
			i == _length_index,
			_focus_column == FocusColumn.LENGTH
		)
	var focus_btn: Button = null
	if _focus_column == FocusColumn.REGION and not _region_buttons.is_empty():
		focus_btn = _region_buttons[_region_index]
	elif _focus_column == FocusColumn.LENGTH and not _length_buttons.is_empty():
		focus_btn = _length_buttons[_length_index]
	if focus_btn:
		focus_btn.grab_focus()
	_refresh_detail()


func _sync_footer() -> void:
	_ensure_footer()
	if _footer == null:
		return
	_footer.set_prompts([
		{"button": "Esc", "label": tr("Back"), "action": "back"},
		{"button": "Enter", "label": tr("Challenge"), "action": "challenge"},
	])
	if not _footer_connected:
		_footer.prompt_activated.connect(_on_footer_prompt)
		_footer_connected = true


func _on_footer_prompt(action: String) -> void:
	match action:
		"back":
			close()
		"challenge":
			_confirm_challenge()


func _on_region_pressed(index: int) -> void:
	_focus_column = FocusColumn.REGION
	_region_index = index
	_apply_focus()


func _on_region_focus_entered(index: int) -> void:
	_focus_column = FocusColumn.REGION
	_region_index = index
	_apply_focus()


func _on_length_pressed(index: int) -> void:
	_focus_column = FocusColumn.LENGTH
	_length_index = index
	_apply_focus()


func _on_length_focus_entered(index: int) -> void:
	_focus_column = FocusColumn.LENGTH
	_length_index = index
	_apply_focus()


func _on_locale_changed(_locale: String) -> void:
	_refresh_texts()


func _confirm_challenge() -> void:
	var params := ChallengeDef.build_run_params(_region_index, _length_index)
	if params.is_empty():
		return
	SaveManager.set_pending_run(params)
	challenge_confirmed.emit(params)
	_active = false
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED
	get_tree().paused = false
	if _ui_manager:
		_ui_manager.set_challenge_board_open(false)
	get_tree().change_scene_to_file.call_deferred(DUNGEON_SCENE)


func _unhandled_input(event: InputEvent) -> void:
	if not _active or not visible:
		return
	if event.is_echo():
		return
	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_accept"):
		_confirm_challenge()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_left"):
		_focus_column = FocusColumn.REGION
		_apply_focus()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_right"):
		_focus_column = FocusColumn.LENGTH
		_apply_focus()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_up"):
		if _focus_column == FocusColumn.REGION:
			_region_index = (
				(_region_index - 1 + _region_buttons.size()) % _region_buttons.size()
			)
		else:
			_length_index = (
				(_length_index - 1 + _length_buttons.size()) % _length_buttons.size()
			)
		_apply_focus()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_down"):
		if _focus_column == FocusColumn.REGION:
			_region_index = (_region_index + 1) % _region_buttons.size()
		else:
			_length_index = (_length_index + 1) % _length_buttons.size()
		_apply_focus()
		get_viewport().set_input_as_handled()
