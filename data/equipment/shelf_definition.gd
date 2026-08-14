class_name ShelfDefinition
extends RefCounted

## Village bookshelf layout. card_number is 1-based; square grid of WIDTH×WIDTH.
## Boards: shelf_rune / shelf_gem (one template per cell).

const WIDTH := 5
const CELL_COUNT := WIDTH * WIDTH

const SHELF_RUNE := &"shelf_rune"
const SHELF_GEM := &"shelf_gem"

const ALL_SHELF_IDS: Array[StringName] = [
	SHELF_RUNE,
	SHELF_GEM,
]

const LABEL_KEYS := {
	SHELF_RUNE: "SHELF_RUNE",
	SHELF_GEM: "SHELF_GEM",
}

const LEGACY_SHELF_IDS: Array[String] = [
	"shelf_common",
	"shelf_uncommon",
	"shelf_rare",
]


static func label_key(shelf_id: StringName) -> String:
	return str(LABEL_KEYS.get(shelf_id, "SHELF_LABEL"))


static func is_legacy_shelf_id(shelf_id: String) -> bool:
	return LEGACY_SHELF_IDS.has(shelf_id)


static func neighbor_card_numbers(card_number: int, width: int = WIDTH) -> Array[int]:
	var out: Array[int] = []
	if card_number <= 0 or width <= 0:
		return out
	var idx := card_number - 1
	var row := int(idx / width)
	var col := idx % width
	if col > 0:
		out.append(card_number - 1)
	if col < width - 1:
		out.append(card_number + 1)
	if row > 0:
		out.append(card_number - width)
	if row < width - 1:
		out.append(card_number + width)
	return out


static func discovery_key(shelf_id: String, card_number: int) -> String:
	return "%s:%d" % [shelf_id, card_number]
