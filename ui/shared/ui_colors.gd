class_name UIColors
extends RefCounted

# ponytail: SettingsManager theme swap = replace these values; keep token names.
# Palette: Gruvbox Dark (hex notes in docs/architecture/ui-colors.md).
const PALETTE_ID := "gruvbox_dark"

const BG_OVERLAY := Color(0.114, 0.125, 0.129, 0.72)
const PANEL_BG := Color(0.235, 0.220, 0.212, 0.55)
const SLOT_BG := Color(0.114, 0.125, 0.129, 0.70)
const SLOT_BG_SOLID := Color(0.157, 0.157, 0.157, 1.0)
const SLOT_BORDER := Color(0.486, 0.435, 0.392, 1.0)
const HOVER_BG := Color(0.196, 0.188, 0.184, 0.45)
const SELECT_BG := Color(0.196, 0.188, 0.184, 0.70)

const TEXT_MAIN := Color(0.922, 0.859, 0.698, 1.0)
const TEXT_MUTED := Color(0.573, 0.514, 0.455, 1.0)
const TEXT_LORE := Color(0.835, 0.769, 0.631, 1.0)
const TEXT_INVERSE := Color(0.114, 0.125, 0.129, 1.0)

const GOLD := Color(0.843, 0.600, 0.129, 1.0)
const SELECT_BORDER := Color(0.980, 0.741, 0.184, 0.95)
const POSITIVE := Color(0.722, 0.733, 0.149, 1.0)
const NEGATIVE := Color(0.984, 0.286, 0.204, 1.0)

const RARITY_COMMON := Color(0.486, 0.435, 0.392, 1.0)
const RARITY_UNCOMMON := Color(0.722, 0.733, 0.149, 1.0)
const RARITY_RARE := Color(0.514, 0.647, 0.596, 1.0)
const RARITY_EPIC := Color(0.996, 0.502, 0.098, 1.0)
const RARITY_LEGENDARY := Color(0.980, 0.741, 0.184, 1.0)
const RARE_GLOW := Color(0.514, 0.647, 0.596, 1.0)
const AFFIX_POSITIVE := Color(0.827, 0.525, 0.608, 1.0)
const AFFIX_NEGATIVE := Color(0.984, 0.286, 0.204, 1.0)

const HP_FILL := Color(0.800, 0.141, 0.114, 1.0)
const XP_FILL := Color(0.922, 0.859, 0.698, 1.0)
const MANA_FILL := Color(0.996, 0.502, 0.098, 1.0)
const ATB_FILL := Color(0.659, 0.600, 0.518, 1.0)
const BAR_BG := Color(0.157, 0.157, 0.157, 0.90)

const MAP_START := Color(0.271, 0.522, 0.533, 1.0)
const MAP_NORMAL := Color(0.314, 0.286, 0.271, 1.0)
const MAP_BOSS := Color(0.800, 0.141, 0.114, 1.0)
const MAP_LOCKED := Color(0.114, 0.125, 0.129, 1.0)

const CLEAR := Color(0, 0, 0, 0)
const DIM := Color(1, 1, 1, 0.38)
const OUTLINE := Color(0, 0, 0, 0.50)


static func with_alpha(c: Color, a: float) -> Color:
	return Color(c.r, c.g, c.b, a)


static func html(c: Color) -> String:
	return "#%s" % c.to_html(false)
