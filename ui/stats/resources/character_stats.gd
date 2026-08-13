class_name CharacterStats
extends Resource

const ATTR_GAIN_PER_POINT := 1
const ATTR_POINTS_PER_LEVEL := 3
const MIN_LEVEL := 1

const ATTRIBUTE_IDS: Array[String] = [
	"health", "stamina", "strength", "dexterity",
	"intelligence", "faith", "focus", "equip_load",
]

const ATTRIBUTE_LABELS: Dictionary = {
	"health": "Health",
	"stamina": "Stamina",
	"strength": "Strength",
	"dexterity": "Dexterity",
	"intelligence": "Intelligence",
	"faith": "Faith",
	"focus": "Focus",
	"equip_load": "Equip Load",
}

@export var character_name: String = "Kirin"
@export var level: int = 1
@export var xp: int = 0
## Derived from LevelProgression CSV; keep in sync via sync_xp_to_next().
@export var xp_to_next: int = 50
@export var hp: int = 38
@export var hp_max: int = 64
@export var mana: int = 50
@export var mana_max: int = 50

@export var attribute_points: int = 1
@export var attributes: Dictionary = {
	"health": 10,
	"stamina": 10,
	"strength": 10,
	"dexterity": 10,
	"intelligence": 10,
	"faith": 10,
	"focus": 10,
	"equip_load": 10,
}

@export var general: Dictionary = {
	"health": 64,
	"stamina": 100,
	"stamina_regen": 12.5,
	"focus": 50,
	"focus_gain": 8.0,
}

@export var defense: Dictionary = {
	"defense": 0.0,
	"poise": 18,
	"heat": 10,
	"cold": 10,
	"electric": 10,
	"plague": 10,
}

@export var weight_max: float = 80.0
@export var weight_current: float = 42.4

@export var weapons: Array[Dictionary] = [
	{
		"name": "Brothers Keepers",
		"base": 42,
		"attr_bonus": 8,
		"attr_icon": "dexterity",
		"other": 0,
		"total": 50,
	},
	{
		"name": "Blood-Rusted Sword",
		"base": 28,
		"attr_bonus": 5,
		"attr_icon": "strength",
		"other": 2,
		"total": 35,
	},
]

var preview_deltas: Dictionary = {}


func get_weight_ratio() -> float:
	if weight_max <= 0.0:
		return 0.0
	return weight_current / weight_max


func get_weight_class() -> String:
	var ratio := get_weight_ratio()
	if ratio < 0.3:
		return "Light"
	if ratio < 0.7:
		return "Normal"
	return "Heavy"


func get_weight_class_label() -> String:
	var ratio := get_weight_ratio()
	return tr("%s (%d%%)") % [tr(get_weight_class()), int(round(ratio * 100.0))]


static func get_attribute_label(attr_id: String) -> String:
	return TranslationServer.translate(str(ATTRIBUTE_LABELS.get(attr_id, attr_id)))


func get_preview_delta(attr_id: String) -> int:
	return int(preview_deltas.get(attr_id, 0))


func set_preview_delta(attr_id: String, delta: int) -> void:
	if delta <= 0:
		preview_deltas.erase(attr_id)
	else:
		preview_deltas[attr_id] = delta


func clear_preview_deltas() -> void:
	preview_deltas.clear()


func can_spend_point() -> bool:
	return attribute_points > 0


func spend_point_on(attr_id: String) -> bool:
	if not can_spend_point() or not attributes.has(attr_id):
		return false
	attributes[attr_id] = int(attributes[attr_id]) + ATTR_GAIN_PER_POINT
	attribute_points -= 1
	preview_deltas.erase(attr_id)
	recalculate_derived()
	return true


func recalculate_derived() -> void:
	_recalculate_derived()


func apply_new_game_start() -> void:
	level = MIN_LEVEL
	xp = 0
	recalculate_derived()


func sync_xp_to_next() -> void:
	xp_to_next = LevelProgression.xp_to_next_for(level)


## Grant XP from combat; level up while remaining XP fills the next bar.
func add_xp(amount: int) -> int:
	if amount <= 0 or LevelProgression.is_max_level(level):
		return 0
	var gained := 0
	xp += amount
	gained += amount
	sync_xp_to_next()
	while xp >= xp_to_next and xp_to_next > 0 and not LevelProgression.is_max_level(level):
		xp -= xp_to_next
		level += 1
		attribute_points += ATTR_POINTS_PER_LEVEL
		sync_xp_to_next()
		recalculate_derived()
	if LevelProgression.is_max_level(level):
		xp = 0
		xp_to_next = 0
	return gained


## Debug / cheat: +1 level, reset XP bar, grant attribute points.
func force_level_up() -> bool:
	if LevelProgression.is_max_level(level):
		return false
	level += 1
	xp = 0
	attribute_points += ATTR_POINTS_PER_LEVEL
	sync_xp_to_next()
	recalculate_derived()
	return true


## Debug / cheat: -1 level, reset XP bar, remove unspent points only.
func force_level_down() -> bool:
	if level <= MIN_LEVEL:
		return false
	level -= 1
	xp = 0
	attribute_points = maxi(0, attribute_points - ATTR_POINTS_PER_LEVEL)
	sync_xp_to_next()
	recalculate_derived()
	return true


func _recalculate_derived() -> void:
	sync_xp_to_next()
	general["health"] = 54 + int(attributes["health"]) * 1
	general["stamina"] = 80 + int(attributes["stamina"]) * 2
	general["stamina_regen"] = 10.0 + int(attributes["stamina"]) * 0.25
	general["focus"] = 40 + int(attributes["focus"]) * 1
	general["focus_gain"] = 6.0 + int(attributes["focus"]) * 0.2
	# Combat Defense comes from CombatStatsBuilder (gear + STR). Keep display keys only.
	if defense.has("armor") and not defense.has("defense"):
		defense["defense"] = float(defense["armor"])
	defense.erase("armor")
	if not defense.has("defense"):
		defense["defense"] = 0.0
	defense["poise"] = 10 + int(attributes["faith"]) + int(attributes["strength"]) / 2
	weight_max = 60.0 + float(attributes["equip_load"]) * 2.0
	hp_max = int(general["health"])
	hp = mini(hp, hp_max)
	mana_max = int(general["focus"])
	mana = mini(mana, mana_max)
