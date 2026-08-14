# 상점 / 아이템 가격 — 후속 설계

**현황:** 필드·표시만. `ItemData.cost` / `gain`, 인벤 상세 `Cost %d` / `Gain %d`.  
카탈로그 대부분은 0. 클레이모어 `23` / `9`와 시작 골드 `1250`은 UI 자리값.  
상점 NPC는 마을 v2 ([`village.md`](village.md)).

관련: [`village.md`](village.md) (상점 위치) · [`loot.md`](loot.md) (장비는 던전 3택1) · [`equipment.md`](equipment.md) (`eq.economy`는 소켓·인챈트, 골드가 아님) · [`inventory.md`](../architecture/inventory.md) (상세 표시) · [`save-load.md`](save-load.md) (가격 미저장) · [`hud.md`](hud.md) (재화는 TopBar).

---

## 한 줄

구매·판매가는 아이템마다 적지 않고, `ShopPricing`이 희귀도·티어·슬롯·스탯·접두사 수로 계산한다. `gain`은 구매가의 비율이다.

---

## 확정 결정

| # | 결정 |
|---|------|
| 1 | 가격의 유일 경로는 `ShopPricing`. 인벤 상세·상점 UI가 각자 계산하지 않는다. |
| 2 | `ItemData.cost` / `gain`은 **예외 오버라이드**. 둘 다 0이면 공식. 하나라도 `> 0`이면 그 값을 기본가로 쓴다. |
| 3 | `gain`을 아이템마다 따로 튜닝하지 않는다. 기본 `floor(buy * 0.4)`. 클레이모어 9/23이 이 비율. |
| 4 | 세이브에 가격을 넣지 않는다. 카탈로그 템플릿 + 인스턴스 오버라이드(희귀도·접두사·내구)로 재계산. `ItemData` JSON 덤프 금지와 같다. |
| 5 | 결제는 **골드만**. `silver`는 표시 자리값. 용도는 후속. |
| 6 | 룬·보석에 골드 필드를 넣지 않는다. `mana_cost`는 전투. 카드는 제단 등록 ([`equipment.md`](equipment.md)). |
| 7 | 게시판 `reward_mult`는 가격에 쓰지 않는다. 드랍에도 쓰지 않음 ([`loot.md`](loot.md)). |
| 8 | 장비의 본줄은 던전 3택1. 상점은 보급(소모품·재료·도구)과 소량 장비. 판매는 골드 싱크. |
| 9 | 상점 마크업(`shop_buy_mult`)은 상점 상수. 아이템 필드가 아니다. |
| 10 | `eq.economy`(희귀도별 소켓·인챈트)와 골드는 분리한다. |

---

## 로드맵

| 단계 | 범위 | 상태 | 선행 |
|------|------|------|------|
| 현황 | `cost`/`gain` 필드, 상세 표시, 클레이모어만 값 | 구현됨 | — |
| **shop.price** | `ShopPricing`, 카탈로그 전 아이템 0 아님, 상세가 서비스 호출 | 설계만 | — |
| **shop.npc** | 마을 상점 NPC, 구매·판매, 골드 차감 | 설계만 | shop.price · 마을 v2 |
| **shop.roll** | 접두사 롤러 인스턴스를 공식에 반영 | 설계만 | loot v2 |

---

## 현재 전제

```text
ItemCatalog 템플릿 (rarity, tier, equip_slot, attack/defense, affixes)
        ↓
ShopPricing.buy_price(item) / sell_price(item)
        ↓
인벤 상세 Cost / Gain
        ↓ (마을 v2)
상점 거래 → InventoryData.currencies.gold
```

| 역할 | 현재 |
|------|------|
| `ItemData.cost` / `gain` | 클레이모어만 23 / 9. `ItemDefaults`는 0 |
| 상세 | `item.cost` / `item.gain`을 그대로 표시 |
| 골드 | `InventoryData.currencies.gold` 시작 1250. TopBar만 |
| 세이브 | `id` + quantity / rarity / affixes / durability. 가격 없음 |
| 상점 | 없음 |

시작 골드·클레이모어 숫자는 밸런스가 아니다. shop.price에서 공식이 덮는다.

---

## 공식

시작 골드 1250 기준. 한 번에 커먼 몇 개 또는 에픽 하나.

```text
slot_base:
  head / legs     40
  chest           60
  main_hand       80
  off_hand        50
  ring_*          45
  tool_*          25
  CONSUMABLE      15
  MATERIAL         8
  (슬롯 없음)     20

rarity_mult: COMMON 1.0 / UNCOMMON 1.6 / RARE 2.4 / EPIC 3.6 / LEGENDARY 5.5
tier_mult:   1 + 0.35 * (tier - 1)
stat_term:   attack + attack_bonus + defense + defense_bonus
affix_term:  12 * affixes.size()

formula_buy = (slot_base + stat_term + affix_term) * rarity_mult * tier_mult
buy         = cost > 0 ? cost : round(formula_buy)
sell        = gain > 0 ? gain : floor(buy * SELL_RATIO)
SELL_RATIO  = 0.4
```

`equip_slot`이 있으면 슬롯 기본가, 없으면 `category`. 반지는 `ring_1`/`ring_2` 모두 45.

대략:

| 아이템 | 희귀도 | 구매 | 판매 |
|--------|--------|------|------|
| Iron Longsword | COMMON | ~96 | ~38 |
| Field Pike | UNCOMMON | ~163 | ~65 |
| Widow's Needle | RARE | ~278 | ~111 |
| Warplate | EPIC | ~432 | ~172 |
| Health Potion | COMMON | ~15 | 안 팜 또는 ~6 |

상점에서 살 때 `buy * shop_buy_mult`. 기본 배수는 `1.0`. 판매 플립으로 루트를 대체하지 않게 마크업은 올리지, 판매 비율은 내리지 않는다.

---

## 카테고리

| 종류 | 구매 | 판매 | 이유 |
|------|------|------|------|
| 장비 | 공식 | `buy * 0.4` | 상점 플립 < 던전 루트 |
| 소모품 | 고정 소액(공식) | 안 팔거나 `buy * 0.25` | 여관·보급. 스택이면 **개당** |
| 재료 | 공식 | `buy * 0.75` | 거래 재화 |
| 도구 | 슬롯 기본가 | 장비와 동일 `0.4` | 드랍 풀 밖 ([`loot.md`](loot.md)) |
| 룬·보석 | 없음 | 없음 | 제단. 후속이면 별도 카탈로그 필드 |

내구: 판매만 `durability / durability_max`를 곱한다. 구매는 템플릿(또는 오버라이드) 그대로.  
착용 중·소켓이 찬 장비는 상점에서 팔 수 없다. 먼저 해제·추출.

---

## 오버라이드

특수 가격만 `ItemData.cost` / `gain`에 적는다 (퀘스트, 고정가 물약).

```text
cost > 0  → buy 기본가 = cost. 공식 생략
gain > 0  → sell 기본가 = gain. 비율 생략
둘 다 0   → 공식
```

`ItemDefaults` 팩토리에 숫자를 하나씩 넣지 않는다. 클레이모어 23/9는 shop.price에서 0으로 돌려 공식에 맡기거나, 특수가로 남길지 구현 직전 한쪽만 고른다.

loot v2 접두사 롤러: 인스턴스 `rarity` / `affixes`를 공식에 넣는다. 템플릿 고정가만 있으면 같은 `id`의 가격이 어긋난다.

---

## 표시 · 세이브

인벤·보상 카드 상세는 `ShopPricing` 결과를 보여 준다. `item.cost`를 직접 찍지 않는다.

세이브는 지금처럼 `id` + 인스턴스 오버라이드만. 가격·골드는 `inventory.currencies`만.

은화는 TopBar에 두어도 거래에 쓰지 않는다.

---

## API

```
ShopPricing.buy_price(item) -> int
ShopPricing.sell_price(item) -> int          # 내구 반영. 소모품 정책 포함
ShopPricing.shop_buy_price(item) -> int      # buy * shop_buy_mult
ShopPricing.can_sell(item, inventory) -> bool
```

경로 후보: `data/economy/shop_pricing.gd` (`LootService` / `CombatStatsBuilder`와 같은 데이터 서비스).

마을 v2 상점:

```
ShopService.buy(inventory, item_id, qty) -> { ok, gold }
ShopService.sell(inventory, grid_index, qty) -> { ok, gold }
```

인벤 메뉴에 구매/판매를 넣지 않는다. 상점 NPC 전용. 메뉴 인벤은 유지 ([`village.md`](village.md)).

---

## 검증

- 카탈로그 전 `ItemData`의 표시 구매가가 0이 아닌가 (오버라이드 0 + 공식).
- 같은 템플릿을 두 번 불러도 가격이 같은가.
- 희귀도만 올린 인스턴스는 구매가가 오르는가.
- 내구 50%면 판매가만 절반인가.
- 세이브 왕복 후 가격이 카탈로그·오버라이드로 재현되는가 (JSON에 `cost` 없음).
- 소모품 스택 3 = 개당 × 3인가.
- 착용 중·소켓 찬 장비는 `can_sell`이 거짓인가.
- `reward_mult`를 바꿔도 가격이 같은가.

---

## 관련 문서에 미치는 결정

| 문서 | 바꿀 점 |
|------|---------|
| [`village.md`](village.md) | v2 상점이 `ShopPricing`을 호출. 인벤 탭에 거래 없음 |
| [`equipment.md`](equipment.md) | `cost`/`gain` 유지는 오버라이드. `eq.economy` ≠ 골드 |
| [`loot.md`](loot.md) | `reward_mult`는 가격에도 금지 |
| [`save-load.md`](save-load.md) | 아이템 JSON에 가격 키 추가 금지 |
| [`inventory.md`](../architecture/inventory.md) | 상세 Cost/Gain은 서비스 결과 |

---

## 비목표 (당분간)

- 은화·물물교환·흥정·평판 할인
- 룬·보석 골드 매매, 제단 등록비
- 아이템마다 `gain` 수기 튜닝
- 세이브에 가격 덤프
- 던전 상인, 출발 전 보급 강제 ([`village.md`](village.md))
- 여관 요금 공식 (여관은 마을 v2, 별도)
- 건물 업그레이드로 상점 재고·할인
