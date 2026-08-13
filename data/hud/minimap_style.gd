class_name MinimapStyle
extends Resource

@export var frame_size: int = 180
@export var frame_padding: int = 10
@export var frame_bg: Color = Color(0.06, 0.07, 0.10, 0.82)
@export var frame_border: Color = Color(0.30, 0.34, 0.42, 0.95)
@export var bracket_color: Color = Color(0.42, 0.48, 0.58, 1)
@export var bracket_length: int = 10
@export var bracket_thickness: int = 2
@export var edge_arrow_color: Color = Color(0.32, 0.36, 0.44, 0.85)
@export var edge_arrow_size: int = 6

@export var cell_size: int = 14
@export var cell_gap: int = 1
@export var window_cells: int = 11
@export var border_visited: int = 2
@export var border_frontier: int = 1

@export var cell_current: Color = Color(0.95, 0.95, 0.98, 1)
@export var cell_visited_fill: Color = Color(0.08, 0.07, 0.06, 0.92)
@export var cell_visited_border: Color = Color(0.92, 0.50, 0.16, 1)
@export var cell_frontier_fill: Color = Color(0.12, 0.12, 0.14, 0.75)
@export var cell_frontier_border: Color = Color(0.22, 0.22, 0.26, 0.90)
@export var letter_font_size: int = 9
@export var letter_current: Color = Color(0.12, 0.12, 0.14, 1)
@export var letter_visited: Color = Color(0.96, 0.96, 0.98, 1)
@export var letter_frontier: Color = Color(0.72, 0.74, 0.78, 0.95)
