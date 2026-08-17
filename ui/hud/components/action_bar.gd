class_name ActionBar
extends VBoxContainer

const HUD_SLOT_SCENE := preload("res://ui/hud/components/hud_slot.tscn")

@onready var skill_row: HBoxContainer = %SkillRow
@onready var equip_row: HBoxContainer = %EquipRow

var _skill_slots: Array[HudSlot] = []
var _main_slot: HudSlot
var _off_slot: HudSlot
var _item_slot: HudSlot
var _food_slot: HudSlot
var _pending_inventory: InventoryData
var _resonance := ResonanceService.new()
var _rune_catalog := RuneCatalog.new()
var _gem_catalog := GemCatalog.new()


func _ready() -> void:
	_clear_skill_slots()
	_main_slot = %MainSlot
	_off_slot = %OffSlot
	_item_slot = %ItemSlot
	_food_slot = %FoodSlot
	if _pending_inventory != null:
		var pending := _pending_inventory
		_pending_inventory = null
		set_inventory(pending)


func set_inventory(inventory: InventoryData) -> void:
	if not is_node_ready() or _main_slot == null:
		_pending_inventory = inventory
		return
	if inventory == null:
		_clear_all()
		return

	var main_hand: ItemData = inventory.equipped.get("main_hand") as ItemData
	var off_hand: ItemData = inventory.equipped.get("off_hand") as ItemData
	_main_slot.set_item(main_hand)
	_off_slot.set_item(off_hand)
	_item_slot.set_item(inventory.quick_item)
	_food_slot.set_item(inventory.quick_food)
	_set_skills(_resonance.list_equipped_rune_skills(inventory, _rune_catalog, _gem_catalog))


func _set_skills(skills: Array) -> void:
	_clear_skill_slots()
	for entry in skills:
		if not entry is Dictionary:
			continue
		var skill: Dictionary = entry
		var slot: HudSlot = HUD_SLOT_SCENE.instantiate()
		skill_row.add_child(slot)
		slot.set_skill(str(skill.get("name", "")), _skill_icon(skill))
		_skill_slots.append(slot)


func _skill_icon(skill: Dictionary) -> Texture2D:
	var rune_id := str(skill.get("rune_id", ""))
	if not rune_id.is_empty() and _rune_catalog.has_id(rune_id):
		var rune := _rune_catalog.get_rune(rune_id)
		if rune and rune.icon:
			return rune.icon
	return RuneData.icon_for_kind(str(skill.get("kind", "strike")))


func set_skill_charge(ratio: float, active_index: int = -1) -> void:
	for i in _skill_slots.size():
		var slot := _skill_slots[i]
		var has_skill := slot.name_label != null and slot.name_label.visible
		if not has_skill:
			continue
		slot.set_charge(ratio, i == active_index)


func clear_skill_charge() -> void:
	for slot in _skill_slots:
		slot.set_charge(0.0, false)


func _clear_skill_slots() -> void:
	if skill_row:
		for child in skill_row.get_children():
			skill_row.remove_child(child)
			child.free()
	_skill_slots.clear()


func _clear_all() -> void:
	_clear_skill_slots()
	if _main_slot:
		_main_slot.clear()
	if _off_slot:
		_off_slot.clear()
	if _item_slot:
		_item_slot.clear()
	if _food_slot:
		_food_slot.clear()
