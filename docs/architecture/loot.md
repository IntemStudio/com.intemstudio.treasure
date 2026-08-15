# 전리품 / 드랍

방 `win` 후 **보상 타입에 맞는 후보 3택1**.  
설계: [`docs/design/loot.md`](../design/loot.md). 서가 게이트: [`docs/design/bookshelf.md`](../design/bookshelf.md). 카드는 골드 가격 숨김 ([`shop.md`](shop.md)). 게시판 `reward_mult`는 드랍·가격에 쓰지 않음.

**현황:** `RoomData.reward_type` + `LootChoiceOverlay`. 룬/보석 풀 = `open_cards` (시작 각 판 `#1`. shelf.v3). 무기/방어는 게이트 없음.

---

## 위치

| 역할 | 경로 |
|------|------|
| 방 타입 | [`world/dungeon/room_data.gd`](../../world/dungeon/room_data.gd) `RewardType` |
| 할당 | [`floor_generator.gd`](../../world/dungeon/floor_generator.gd) `_assign_reward_types` |
| 롤·지급 | [`data/loot/loot_service.gd`](../../data/loot/loot_service.gd) `roll_offers` / `take_offer` |
| 훅 | [`encounter_director.gd`](../../world/combat/encounter_director.gd) `_begin_loot_choice` |
| UI | [`ui/loot/loot_choice_overlay.tscn`](../../ui/loot/loot_choice_overlay.tscn) · `UIManager.show_loot_choice`. Sheet 1440×800, 상·중·하 밴드 ([`ui-colors.md`](ui-colors.md)) |
| 카드 | [`loot_offer_card.tscn`](../../ui/loot/loot_offer_card.tscn) — 후보 3장에 상세를 그대로 표시. 장비는 같은 슬롯 착용분과 ATK/DEF 비교. `GoldPrice.HIDDEN` |
| 상세 | 장비 `ItemDetailPanel` · 룬/보석 [`modifier_detail_panel.tscn`](../../ui/loot/modifier_detail_panel.tscn) |
| 토스트 | GameHud `granted` 또는 `granted_name` |
| 로그 | `loot.grant` / `loot.skip` |

---

## 흐름

```
FloorGenerator → room.reward_type (weapon|armor|rune|gem)
win
  → HP / 마나 / XP, cleared
  → roll_offers(3)
  → LootChoiceOverlay (pause)
  → take_offer → toast + log
  → BOSS면 return_to_village()
```

RNG: 타입 `hash([seed, cell, "reward"])`, 후보 `hash([seed, cell, "offers"])`.

| type | 풀 |
|------|-----|
| weapon | `ItemCategory.WEAPON` |
| armor | `ItemCategory.ARMOR` |
| rune | `RuneCatalog` ∩ `open_cards` |
| gem | `GemCatalog` ∩ `open_cards` |

장비는 `slots`, 룬/보석은 `runes[]`/`gems[]`. 가방 가득 시 장비 후보 확정 불가.

---

## API

```
LootService.roll_offers(reward_type, catalog, rune_cat, gem_cat, ctx) -> Array[Dictionary]
LootService.take_offer(inventory, offer) -> { ok, granted_name, skipped, granted }
UIManager.show_loot_choice(offers, reward_type, on_done)
InventoryData.equipped_in_same_slot(item) -> ItemData  # 카드 ATK/DEF 비교
```
