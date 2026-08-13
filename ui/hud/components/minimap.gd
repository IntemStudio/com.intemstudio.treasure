class_name MiniMap
extends Control

signal map_open_requested

const STYLE_PATH := "res://data/hud/minimap_style.tres"

var _style: MinimapStyle
var _floor_map: FloorMap
var _room_changed_connected: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_ensure_style()
	_apply_size()
	visible = false


func _gui_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			map_open_requested.emit()
			accept_event()


func set_floor_map(floor_map: FloorMap) -> void:
	_disconnect_room_changed()
	_floor_map = floor_map
	if _floor_map and not _floor_map.room_changed.is_connected(_on_room_changed):
		_floor_map.room_changed.connect(_on_room_changed)
		_room_changed_connected = true
	_refresh_visibility()
	queue_redraw()


func clear_floor_map() -> void:
	_disconnect_room_changed()
	_floor_map = null
	visible = false
	queue_redraw()


func _ensure_style() -> void:
	if _style != null:
		return
	_style = load(STYLE_PATH) as MinimapStyle
	if _style == null:
		_style = MinimapStyle.new()


func _apply_size() -> void:
	_ensure_style()
	var s := float(_style.frame_size)
	custom_minimum_size = Vector2(s, s)
	size = Vector2(s, s)


func _disconnect_room_changed() -> void:
	if _floor_map and _room_changed_connected and _floor_map.room_changed.is_connected(_on_room_changed):
		_floor_map.room_changed.disconnect(_on_room_changed)
	_room_changed_connected = false


func _on_room_changed(_pos: Vector2i) -> void:
	_refresh_visibility()
	queue_redraw()


func _refresh_visibility() -> void:
	var has_map := (
		_floor_map != null
		and not _floor_map.get_rooms().is_empty()
	)
	visible = has_map


func _draw() -> void:
	_ensure_style()
	if not visible or _floor_map == null:
		return

	var visible_cells := _collect_visible_cells()
	if visible_cells.is_empty():
		return

	var frame := float(_style.frame_size)
	var pad := float(_style.frame_padding)
	draw_rect(Rect2(0, 0, frame, frame), _style.frame_bg, true)
	draw_rect(Rect2(0, 0, frame, frame), _style.frame_border, false, 1.0)
	_draw_brackets(frame)
	_draw_edge_arrows(frame)

	var inner := Rect2(pad, pad, frame - pad * 2.0, frame - pad * 2.0)
	var origin := _compute_grid_origin(visible_cells, inner)
	var current := _floor_map.get_current()
	var step := float(_style.cell_size + _style.cell_gap)

	for pos in visible_cells.keys():
		var p: Vector2i = pos
		var room: RoomData = visible_cells[p]
		var cell_pos := Vector2(
			round(origin.x + float(p.x) * step),
			round(origin.y + float(p.y) * step)
		)
		var cell_rect := Rect2(cell_pos, Vector2(_style.cell_size, _style.cell_size))
		if (
			cell_rect.end.x < inner.position.x
			or cell_rect.position.x > inner.end.x
			or cell_rect.end.y < inner.position.y
			or cell_rect.position.y > inner.end.y
		):
			continue

		var is_current := p == current
		var is_visited := room.visited
		var letter_color: Color
		if is_current:
			draw_rect(cell_rect, _style.cell_current, true)
			letter_color = _style.letter_current
		elif is_visited:
			draw_rect(cell_rect, _style.cell_visited_fill, true)
			draw_rect(cell_rect, _style.cell_visited_border, false, float(_style.border_visited))
			letter_color = _style.letter_visited
		else:
			draw_rect(cell_rect, _style.cell_frontier_fill, true)
			draw_rect(cell_rect, _style.cell_frontier_border, false, float(_style.border_frontier))
			letter_color = _style.letter_frontier

		# Type letter on visited and adjacent (frontier) cells
		_draw_type_letter(cell_rect, room.type_letter(), letter_color)


func _collect_visible_cells() -> Dictionary:
	var result: Dictionary = {}
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


func _compute_grid_origin(visible_cells: Dictionary, inner: Rect2) -> Vector2:
	var min_x := 0
	var max_x := 0
	var min_y := 0
	var max_y := 0
	var first := true
	for pos in visible_cells.keys():
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
	var step := float(_style.cell_size + _style.cell_gap)
	var window := _style.window_cells
	var current := _floor_map.get_current()

	if cols <= window and rows <= window:
		var grid_w := float(cols) * float(_style.cell_size) + float(maxi(cols - 1, 0)) * float(_style.cell_gap)
		var grid_h := float(rows) * float(_style.cell_size) + float(maxi(rows - 1, 0)) * float(_style.cell_gap)
		return Vector2(
			round(inner.position.x + (inner.size.x - grid_w) * 0.5 - float(min_x) * step),
			round(inner.position.y + (inner.size.y - grid_h) * 0.5 - float(min_y) * step)
		)

	var view_min_x := current.x - window / 2
	var view_min_y := current.y - window / 2
	var grid_w_full := float(window) * float(_style.cell_size) + float(window - 1) * float(_style.cell_gap)
	return Vector2(
		round(inner.position.x + (inner.size.x - grid_w_full) * 0.5 - float(view_min_x) * step),
		round(inner.position.y + (inner.size.y - grid_w_full) * 0.5 - float(view_min_y) * step)
	)


func _draw_brackets(frame: float) -> void:
	var len_f := float(_style.bracket_length)
	var thick := float(_style.bracket_thickness)
	var c := _style.bracket_color
	var inset := 2.0
	draw_rect(Rect2(inset, inset, len_f, thick), c, true)
	draw_rect(Rect2(inset, inset, thick, len_f), c, true)
	draw_rect(Rect2(frame - inset - len_f, inset, len_f, thick), c, true)
	draw_rect(Rect2(frame - inset - thick, inset, thick, len_f), c, true)
	draw_rect(Rect2(inset, frame - inset - thick, len_f, thick), c, true)
	draw_rect(Rect2(inset, frame - inset - len_f, thick, len_f), c, true)
	draw_rect(Rect2(frame - inset - len_f, frame - inset - thick, len_f, thick), c, true)
	draw_rect(Rect2(frame - inset - thick, frame - inset - len_f, thick, len_f), c, true)


func _draw_edge_arrows(frame: float) -> void:
	var s := float(_style.edge_arrow_size)
	var c := _style.edge_arrow_color
	var mid := frame * 0.5
	var m := 4.0
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(mid, m),
			Vector2(mid - s * 0.5, m + s * 0.6),
			Vector2(mid + s * 0.5, m + s * 0.6),
		]),
		c
	)
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(mid, frame - m),
			Vector2(mid - s * 0.5, frame - m - s * 0.6),
			Vector2(mid + s * 0.5, frame - m - s * 0.6),
		]),
		c
	)
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(m, mid),
			Vector2(m + s * 0.6, mid - s * 0.5),
			Vector2(m + s * 0.6, mid + s * 0.5),
		]),
		c
	)
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(frame - m, mid),
			Vector2(frame - m - s * 0.6, mid - s * 0.5),
			Vector2(frame - m - s * 0.6, mid + s * 0.5),
		]),
		c
	)


func _draw_type_letter(cell_rect: Rect2, letter: String, color: Color) -> void:
	if letter.is_empty():
		return
	var font := ThemeDB.fallback_font
	var fs := _style.letter_font_size
	var height := font.get_height(fs)
	var ascent := font.get_ascent(fs)
	var baseline := cell_rect.position.y + (cell_rect.size.y - height) * 0.5 + ascent
	draw_string(
		font,
		Vector2(cell_rect.position.x, round(baseline)),
		letter,
		HORIZONTAL_ALIGNMENT_CENTER,
		cell_rect.size.x,
		fs,
		color
	)
