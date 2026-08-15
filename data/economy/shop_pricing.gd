class_name ShopPricing
extends RefCounted

const SELL_RATIO := 0.4
const CONSUMABLE_SELL_RATIO := 0.25
const MATERIAL_SELL_RATIO := 0.75
const AFFIX_PRICE := 12
## ponytail: village shop markup. Raise this, do not lower sell ratios. NPC is village v2.
const SHOP_BUY_MULT := 1.0


static func buy_price(item: ItemData) -> int:
	if item == null:
		return 0
	if item.cost > 0:
		return item.cost
	var formula := float(_slot_base(item) + _stat_term(item) + _affix_term(item))
	formula *= _rarity_mult(item.rarity)
	formula *= _tier_mult(item.tier)
	return int(round(formula))


static func sell_price(item: ItemData) -> int:
	if item == null:
		return 0
	var sell_base := 0
	if item.gain > 0:
		sell_base = item.gain
	else:
		sell_base = int(floor(float(buy_price(item)) * _sell_ratio(item)))
	return int(floor(float(sell_base) * _durability_ratio(item)))


static func shop_buy_price(item: ItemData) -> int:
	return int(round(float(buy_price(item)) * SHOP_BUY_MULT))


static func can_sell(item: ItemData, inventory: InventoryData) -> bool:
	if item == null:
		return false
	if not item.socketed.is_empty():
		return false
	if inventory == null:
		return true
	for slot_id in InventoryData.EQUIP_SLOTS:
		if inventory.equipped.get(slot_id) == item:
			return false
	return true


static func _slot_base(item: ItemData) -> int:
	var slot := item.equip_slot
	if slot.is_empty():
		match item.category:
			ItemData.ItemCategory.CONSUMABLE:
				return 15
			ItemData.ItemCategory.MATERIAL:
				return 8
			_:
				return 20
	if slot == "head" or slot == "legs":
		return 40
	if slot == "chest":
		return 60
	if slot == "main_hand":
		return 80
	if slot == "off_hand":
		return 50
	if slot.begins_with("ring_"):
		return 45
	if slot.begins_with("tool_"):
		return 25
	return 20


static func _stat_term(item: ItemData) -> int:
	return item.attack + item.attack_bonus + item.defense + item.defense_bonus


static func _affix_term(item: ItemData) -> int:
	return AFFIX_PRICE * item.affixes.size()


static func _rarity_mult(rarity: ItemData.ItemRarity) -> float:
	match rarity:
		ItemData.ItemRarity.UNCOMMON:
			return 1.6
		ItemData.ItemRarity.RARE:
			return 2.4
		ItemData.ItemRarity.LEGENDARY:
			return 5.5
		_:
			return 1.0


static func _tier_mult(tier: int) -> float:
	return 1.0 + 0.35 * float(maxi(tier, 1) - 1)


static func _sell_ratio(item: ItemData) -> float:
	match item.category:
		ItemData.ItemCategory.CONSUMABLE:
			return CONSUMABLE_SELL_RATIO
		ItemData.ItemCategory.MATERIAL:
			return MATERIAL_SELL_RATIO
		_:
			return SELL_RATIO


static func _durability_ratio(item: ItemData) -> float:
	if item.durability_max <= 0:
		return 0.0
	return clampf(float(item.durability) / float(item.durability_max), 0.0, 1.0)
