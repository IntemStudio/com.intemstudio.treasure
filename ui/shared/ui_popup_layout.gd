class_name UIPopupLayout
extends RefCounted

# Modal popup geometry. Dim stays fullscreen; panel is centered Sheet/Dialog.
# See docs/architecture/ui-colors.md (popup layout).

const MARGIN := 80
const SHEET_SIZE := Vector2(1440, 800)
const DIALOG_SIZE := Vector2(760, 480)
const PANEL_INSET := 24
const PANEL_BORDER := 2
const COLUMN_PANEL_INSET := 16
const BAND_HEIGHT := 72
const BAND_PAD_H := 16
const MID_PAD_V := 16
# Scroll/clip parents cut StyleBox AA + selected shadow on flush grids.
const SLOT_GRID_PAD := 8


static func apply_slot_grid_pad(margin: MarginContainer) -> void:
	margin.add_theme_constant_override("margin_left", SLOT_GRID_PAD)
	margin.add_theme_constant_override("margin_top", SLOT_GRID_PAD)
	margin.add_theme_constant_override("margin_right", SLOT_GRID_PAD)
	margin.add_theme_constant_override("margin_bottom", SLOT_GRID_PAD)


static func apply_outer_margin(margin: MarginContainer) -> void:
	margin.add_theme_constant_override("margin_left", MARGIN)
	margin.add_theme_constant_override("margin_top", MARGIN)
	margin.add_theme_constant_override("margin_right", MARGIN)
	margin.add_theme_constant_override("margin_bottom", MARGIN)


static func make_sheet_style() -> StyleBoxFlat:
	# ponytail: no panel texture yet — StyleBoxFlat reads as the Sheet frame.
	# Content inset = border width so Top/Bottom bands sit flush inside the
	# frame without painting over the border stroke.
	var style := StyleBoxFlat.new()
	style.bg_color = UIColors.with_alpha(UIColors.SLOT_BG_SOLID, 0.96)
	style.border_color = UIColors.SLOT_BORDER
	style.set_border_width_all(PANEL_BORDER)
	style.set_corner_radius_all(0)
	style.set_content_margin_all(PANEL_BORDER)
	return style


static func make_band_style(bottom_edge: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = UIColors.with_alpha(UIColors.TEXT_INVERSE, 0.88)
	style.border_color = UIColors.with_alpha(UIColors.SLOT_BORDER, 0.4)
	if bottom_edge:
		style.border_width_bottom = 1
	else:
		style.border_width_top = 1
	style.content_margin_left = BAND_PAD_H
	style.content_margin_right = BAND_PAD_H
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	return style


static func apply_sheet_size(panel: Control) -> void:
	panel.custom_minimum_size = SHEET_SIZE


static func apply_dialog_size(panel: Control) -> void:
	panel.custom_minimum_size = DIALOG_SIZE


static func apply_sheet_panel(panel: PanelContainer) -> void:
	apply_sheet_size(panel)
	panel.add_theme_stylebox_override("panel", make_sheet_style())


static func apply_dialog_panel(panel: PanelContainer) -> void:
	apply_dialog_size(panel)
	panel.add_theme_stylebox_override("panel", make_sheet_style())


static func make_column_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = UIColors.PANEL_BG
	style.border_color = UIColors.SLOT_BORDER
	style.set_border_width_all(PANEL_BORDER)
	style.set_corner_radius_all(0)
	style.anti_aliasing = false
	style.set_content_margin_all(COLUMN_PANEL_INSET)
	return style


static func apply_column_panel(panel: PanelContainer) -> void:
	if panel == null:
		return
	panel.add_theme_stylebox_override("panel", make_column_panel_style())


static func apply_column_panels(panels: Array) -> void:
	var style := make_column_panel_style()
	for panel in panels:
		if panel is PanelContainer:
			(panel as PanelContainer).add_theme_stylebox_override("panel", style)


static func flatten_inner_panel(panel: PanelContainer) -> void:
	if panel == null:
		return
	panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())


static func apply_sheet_bands(top_band: Control, mid_band: Control, bottom_band: Control) -> void:
	# Anchor layout (not VBox): top/bottom fixed strips, mid fills the gap.
	# Avoids MidBand painting under TopBand and clipping tabs / weapon slots.
	if top_band:
		top_band.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
		top_band.offset_top = 0
		top_band.offset_bottom = BAND_HEIGHT
		top_band.z_index = 0
		if top_band is PanelContainer:
			(top_band as PanelContainer).add_theme_stylebox_override("panel", make_band_style(true))
	if bottom_band:
		bottom_band.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
		bottom_band.offset_top = -BAND_HEIGHT
		bottom_band.offset_bottom = 0
		bottom_band.z_index = 0
		if bottom_band is PanelContainer:
			(bottom_band as PanelContainer).add_theme_stylebox_override("panel", make_band_style(false))
	if mid_band:
		mid_band.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		mid_band.offset_top = BAND_HEIGHT
		mid_band.offset_bottom = -BAND_HEIGHT
		mid_band.z_index = 0
		mid_band.clip_contents = true
		_apply_mid_inset(mid_band)


static func _apply_mid_inset(mid_band: Control) -> void:
	if mid_band is MarginContainer:
		var margin := mid_band as MarginContainer
		margin.add_theme_constant_override("margin_left", PANEL_INSET)
		margin.add_theme_constant_override("margin_right", PANEL_INSET)
		margin.add_theme_constant_override("margin_top", MID_PAD_V)
		margin.add_theme_constant_override("margin_bottom", MID_PAD_V)
		return
	for child in mid_band.get_children():
		if child is Control:
			var c := child as Control
			c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			c.offset_left = PANEL_INSET
			c.offset_top = MID_PAD_V
			c.offset_right = -PANEL_INSET
			c.offset_bottom = -MID_PAD_V
			c.clip_contents = true
