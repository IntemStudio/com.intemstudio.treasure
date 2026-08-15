# 상점 가격

구매·판매가는 `ShopPricing`이 희귀도·티어·슬롯·스탯·접두사 수로 계산한다.  
후속(마을 상점 NPC·접두사 롤러): [`docs/design/shop.md`](../design/shop.md).

**현황:** `shop.price`. 인벤 상세는 `판매 가격 N골드`만. 구매가는 상점 후보(`구매 가격 N골드`). 룻 카드는 골드 숨김. 거래 UI 없음.

관련: [`inventory.md`](inventory.md) · [`village.md`](village.md) · [`loot.md`](loot.md) · [`equipment.md`](equipment.md) · [`save-load.md`](save-load.md).

---

## 위치

| 역할 | 경로 |
|------|------|
| 공식 | [`data/economy/shop_pricing.gd`](../../data/economy/shop_pricing.gd) |
| 검증 | [`verify_shop_pricing.gd`](../../data/economy/verify_shop_pricing.gd) |
| 상세 | [`item_detail_panel.gd`](../../ui/inventory/components/item_detail_panel.gd) |
| 오버라이드 | [`ItemData.cost`](../../ui/inventory/resources/item_data.gd) / `gain` (둘 다 0이면 공식) |

Autoload 아님. `LootService` / `CombatStatsBuilder`와 같은 데이터 서비스.

---

## 흐름

```
ItemCatalog 인스턴스 (rarity, tier, slot, stats, affixes, cost/gain)
        ↓
ShopPricing.buy_price / sell_price
        ↓
ItemDetailPanel.set_gold_price
  인벤 → 판매 가격 N골드 (`sell_price`)
  상점 → 구매 가격 N골드 (`buy_price`)  (NPC 후속)
  룻  → 숨김
```

세이브 JSON에 가격 키 없음. 로드 후 카탈로그 + 인스턴스 오버라이드로 재계산.

---

## 공식

```
slot_base: head/legs 40, chest 60, main_hand 80, off_hand 50,
           ring_* 45, tool_* 25, CONSUMABLE 15, MATERIAL 8, else 20
rarity_mult: COMMON 1.0 / UNCOMMON 1.6 / RARE 2.4 / LEGENDARY 5.5
tier_mult: 1 + 0.35 * (tier - 1)
buy  = cost > 0 ? cost : round((slot_base + stats + 12 * affixes) * rarity * tier)
sell = gain > 0 ? gain : floor(buy * ratio)
       그다음 floor(sell * durability / durability_max)
ratio: 소모품 0.25 / 재료 0.75 / 그 외 0.4
```

판매가는 **개당**. 스택 총액은 `sell_price * quantity`.  
`shop_buy_mult`는 `1.0` (마을 상점 마크업. NPC는 후속).

착용 중·소켓이 찬 장비는 `can_sell` 거짓. 룬·보석은 골드 없음.

---

## API

```
ShopPricing.buy_price(item) -> int
ShopPricing.sell_price(item) -> int
ShopPricing.shop_buy_price(item) -> int
ShopPricing.can_sell(item, inventory) -> bool
```

`godot --headless --path . -s res://data/economy/verify_shop_pricing.gd`

---

## 비범위

- 상점 NPC, `ShopService.buy/sell`, 인벤 탭 거래
- 은화·룬/보석 골드 매매
- 게시판 `reward_mult` (가격·드랍 모두 금지)
- 소켓 수 변경 (부위 고정. 골드 아님)
