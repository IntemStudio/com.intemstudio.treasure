class_name MinimapStyle
extends Resource

@export var frame_size: int = 180
@export var frame_padding: int = 10
@export var frame_bg: Color = UIColors.with_alpha(UIColors.TEXT_INVERSE, 0.82)
@export var frame_border: Color = UIColors.with_alpha(UIColors.SLOT_BORDER, 0.95)
@export var bracket_color: Color = UIColors.TEXT_MUTED
@export var bracket_length: int = 10
@export var bracket_thickness: int = 2
@export var edge_arrow_color: Color = UIColors.with_alpha(UIColors.TEXT_MUTED, 0.85)
@export var edge_arrow_size: int = 6

@export var cell_size: int = 14
@export var cell_gap: int = 1
@export var window_cells: int = 11
@export var border_visited: int = 2
@export var border_frontier: int = 1

@export var cell_current: Color = UIColors.TEXT_MAIN
@export var cell_visited_fill: Color = UIColors.with_alpha(UIColors.TEXT_INVERSE, 0.92)
@export var cell_visited_border: Color = UIColors.MANA_FILL
@export var cell_frontier_fill: Color = UIColors.with_alpha(UIColors.SLOT_BG_SOLID, 0.75)
@export var cell_frontier_border: Color = UIColors.with_alpha(UIColors.MAP_NORMAL, 0.90)
@export var letter_font_size: int = 9
@export var letter_current: Color = UIColors.TEXT_INVERSE
@export var letter_visited: Color = UIColors.TEXT_MAIN
@export var letter_frontier: Color = UIColors.with_alpha(UIColors.ATB_FILL, 0.95)
