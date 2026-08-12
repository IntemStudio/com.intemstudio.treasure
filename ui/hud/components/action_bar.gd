class_name ActionBar
extends VBoxContainer

const SKILL_COUNT := 4
const HUD_SLOT_SCENE := preload("res://ui/hud/components/hud_slot.tscn")

@onready var skill_row: HBoxContainer = %SkillRow
@onready var equip_row: HBoxContainer = %EquipRow

var _skill_slots: Array[HudSlot] = []
var _main_slot: HudSlot
var _off_slot: HudSlot
var _item_slot: HudSlot
var _food_slot: HudSlot
var _pending_inventory: InventoryData


func _ready() -> void:
	_skill_slots.clear()
	for child in skill_row.get_children():
		child.queue_free()
	for i in SKILL_COUNT:
		var slot: HudSlot = HUD_SLOT_SCENE.instantiate()
		skill_row.add_child(slot)
		_skill_slots.append(slot)

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
	_set_skills(main_hand)


func _set_skills(main_hand: ItemData) -> void:
	var skills: Array = []
	if main_hand:
		skills = main_hand.skills
	for i in SKILL_COUNT:
		var slot := _skill_slots[i]
		if i < skills.size() and skills[i] is Dictionary:
			var entry: Dictionary = skills[i]
			slot.set_skill(str(entry.get("name", "")), main_hand.icon if main_hand else null)
		else:
			slot.clear()


func _clear_all() -> void:
	for slot in _skill_slots:
		slot.clear()
	if _main_slot:
		_main_slot.clear()
	if _off_slot:
		_off_slot.clear()
	if _item_slot:
		_item_slot.clear()
	if _food_slot:
		_food_slot.clear()
