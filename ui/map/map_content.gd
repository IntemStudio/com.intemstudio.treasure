extends Control

signal request_close

const CELL_SIZE := 48
const CELL_GAP := 8

const COLOR_START := UIColors.MAP_START
const COLOR_NORMAL := UIColors.MAP_NORMAL
const COLOR_BOSS := UIColors.MAP_BOSS
const COLOR_LOCKED := UIColors.MAP_LOCKED

@onready var empty_label: Label = %EmptyLabel
@onready var grid_host: Control = %GridHost

var _ui_manager: UIManager
var _footer: FooterPrompts
var _footer_connected: bool = false
var _floor_map: FloorMap
var _room_host: RoomHost
var _cell_buttons: Dictionary = {}
var _room_changed_connected: bool = false
var _pending_layout: bool = false


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED
	LocaleManager.locale_changed.connect(_on_locale_changed)
	grid_host.resized.connect(_on_grid_host_resized)
	_refresh_empty_label()


func setup(ui_manager: UIManager, footer: FooterPrompts) -> void:
	_ui_manager = ui_manager
	_footer = footer
	if _ui_manager and not _ui_manager.input_device_changed.is_connected(_on_input_device_changed):
		_ui_manager.input_device_changed.connect(_on_input_device_changed)
	if _footer and not _footer_connected:
		_footer.prompt_activated.connect(_on_footer_prompt)
		_footer_connected = true


func activate(_stats: CharacterStats, _inventory: InventoryData) -> void:
	visible = true
	process_mode = Node.PROCESS_MODE_INHERIT
	_bind_dungeon_refs()
	_rebuild_grid()
	_update_footer()


func deactivate() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED
	_disconnect_room_changed()


func _bind_dungeon_refs() -> void:
	_disconnect_room_changed()
	_floor_map = null
	_room_host = null
	if _ui_manager == null:
		return
	_floor_map = _ui_manager.floor_map
	_room_host = _ui_manager.room_host
	if _floor_map and not _floor_map.room_changed.is_connected(_on_room_changed):
		_floor_map.room_changed.connect(_on_room_changed)
		_room_changed_connected = true


func _disconnect_room_changed() -> void:
	if _floor_map and _room_changed_connected and _floor_map.room_changed.is_connected(_on_room_changed):
		_floor_map.room_changed.disconnect(_on_room_changed)
	_room_changed_connected = false


func _on_room_changed(_pos: Vector2i) -> void:
	if visible:
		_rebuild_grid()


func _is_using_gamepad() -> bool:
	return _ui_manager.using_gamepad if _ui_manager else false


func _on_input_device_changed(_using_gamepad: bool) -> void:
	if visible:
		_update_footer.call_deferred()


func _on_locale_changed(_locale: String) -> void:
	_refresh_empty_label()
	if visible:
		_rebuild_grid()
		_update_footer()


func _refresh_empty_label() -> void:
	if empty_label:
		empty_label.text = tr("MAP_NO_DUNGEON")


func _update_footer() -> void:
	if not _footer:
		return
	var using_gamepad := _is_using_gamepad()
	_footer.set_prompts([
		{"action": "close", "button": "B" if using_gamepad else "Esc", "label": tr("CLOSE")},
	])


func _on_footer_prompt(action: String) -> void:
	if not visible:
		return
	if action == "close":
		request_close.emit()


## Visited rooms + neighbors of any visited room (same fog as HUD minimap).
func _collect_known_rooms() -> Dictionary:
	var result: Dictionary = {}
	if _floor_map == null:
		return result
	var rooms: Dictionary = _floor_map.get_rooms()
	for pos in rooms.keys():
		var p: Vector2i = pos
		var room: RoomData = rooms[p]
		if not room.visited:
			continue
		result[p] = room
		for neighbor_pos in room.neighbors.values():
			var np: Vector2i = neighbor_pos
			if result.has(np):
				continue
			if not rooms.has(np):
				continue
			result[np] = rooms[np]
	return result


func _rebuild_grid() -> void:
	var has_map := _floor_map != null and not _floor_map.get_rooms().is_empty()
	empty_label.visible = not has_map
	grid_host.visible = has_map
	if not has_map:
		for child in grid_host.get_children():
			child.queue_free()
		_cell_buttons.clear()
		_pending_layout = false
		return

	if grid_host.size.x <= 1.0 or grid_host.size.y <= 1.0:
		_pending_layout = true
		return

	for child in grid_host.get_children():
		child.queue_free()
	_cell_buttons.clear()

	var all_rooms: Dictionary = _floor_map.get_rooms()
	var known: Dictionary = _collect_known_rooms()
	if known.is_empty():
		_pending_layout = false
		return

	# Bounds from full floor so cell positions stay stable as fog expands
	var min_x := 0
	var max_x := 0
	var min_y := 0
	var max_y := 0
	var first := true
	for pos in all_rooms.keys():
		var p: Vector2i = pos
		if first:
			min_x = p.x
			max_x = p.x
			min_y = p.y
			max_y = p.y
			first = false
		else:
			min_x = mini(min_x, p.x)
			max_x = maxi(max_x, p.x)
			min_y = mini(min_y, p.y)
			max_y = maxi(max_y, p.y)

	var cols := max_x - min_x + 1
	var rows := max_y - min_y + 1
	var grid_w := cols * CELL_SIZE + (cols - 1) * CELL_GAP
	var grid_h := rows * CELL_SIZE + (rows - 1) * CELL_GAP
	var origin := Vector2(
		(grid_host.size.x - grid_w) * 0.5,
		(grid_host.size.y - grid_h) * 0.5
	)

	for pos in known.keys():
		var p: Vector2i = pos
		var room: RoomData = known[p]
		var btn := Button.new()
		btn.focus_mode = Control.FOCUS_NONE
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn.custom_minimum_size = Vector2(CELL_SIZE, CELL_SIZE)
		btn.size = Vector2(CELL_SIZE, CELL_SIZE)
		btn.position = origin + Vector2(
			(p.x - min_x) * (CELL_SIZE + CELL_GAP),
			(p.y - min_y) * (CELL_SIZE + CELL_GAP)
		)
		btn.tooltip_text = "%s (%d, %d)" % [tr("ROOM_TYPE_%s" % room.type_name().to_upper()), p.x, p.y]
		btn.text = room.type_letter()
		btn.add_theme_font_size_override("font_size", 18)
		btn.pressed.connect(_on_cell_pressed.bind(p))
		grid_host.add_child(btn)
		_cell_buttons[p] = btn

	_pending_layout = false
	_refresh_cell_styles()


func _on_grid_host_resized() -> void:
	if visible and _pending_layout:
		_rebuild_grid()


func _refresh_cell_styles() -> void:
	if _floor_map == null:
		return
	var current := _floor_map.get_current()
	for pos in _cell_buttons.keys():
		var p: Vector2i = pos
		var btn: Button = _cell_buttons[p]
		var room := _floor_map.get_room(p)
		if room == null:
			continue
		var reachable := _floor_map.can_enter(p)
		var fill := COLOR_NORMAL
		if not reachable:
			fill = COLOR_LOCKED
		else:
			match room.room_type:
				RoomData.RoomType.START:
					fill = COLOR_START
				RoomData.RoomType.BOSS:
					fill = COLOR_BOSS
				_:
					fill = COLOR_NORMAL
		var border := UIColors.GOLD if p == current else UIColors.SLOT_BORDER
		var border_w := 3 if p == current else 1
		btn.disabled = not reachable
		btn.text = room.type_letter()
		btn.mouse_default_cursor_shape = (
			Control.CURSOR_POINTING_HAND if reachable else Control.CURSOR_ARROW
		)
		_apply_cell_style(btn, fill, border, border_w, reachable)


func _apply_cell_style(
	btn: Button, fill: Color, border: Color, border_w: int, reachable: bool
) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_w)
	style.set_corner_radius_all(2)
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)
	btn.add_theme_stylebox_override("focus", style)
	btn.add_theme_stylebox_override("disabled", style)
	btn.modulate = Color.WHITE if reachable else Color(1, 1, 1, 0.45)
	var letter := UIColors.TEXT_MAIN
	btn.add_theme_color_override("font_color", letter)
	btn.add_theme_color_override("font_hover_color", letter)
	btn.add_theme_color_override("font_pressed_color", letter)
	btn.add_theme_color_override("font_disabled_color", letter)
	btn.add_theme_color_override("font_focus_color", letter)

func _on_cell_pressed(pos: Vector2i) -> void:
	if _room_host == null:
		return
	if _ui_manager and _ui_manager.is_combat_active():
		return
	if _floor_map and not _floor_map.can_enter(pos):
		return
	if _room_host.enter_room(pos):
		if _ui_manager:
			_ui_manager.close_all()
		else:
			request_close.emit()
