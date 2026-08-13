# 전리품 / 드랍

방 `win` 시 장비를 메타 인벤에 넣고, 토스트·게임 로그로 알린다.  
후속(룬·보석·소모품·접두사): [`docs/design/loot.md`](../design/loot.md).

**현황:** v1 장비만. 킬 단위·바닥 픽업 없음.

---

## 위치

| 역할 | 경로 |
|------|------|
| 테이블 | [`data/loot/loot_table.gd`](../../data/loot/loot_table.gd) · [`loot_table.tres`](../../data/loot/loot_table.tres) |
| 지급 | [`data/loot/loot_service.gd`](../../data/loot/loot_service.gd) |
| 풀 | [`save/item_catalog.gd`](../../save/item_catalog.gd) `ids_for_categories` |
| 훅 | [`world/combat/encounter_director.gd`](../../world/combat/encounter_director.gd) `_apply_win` → `_grant_loot` |
| 토스트 | [`ui/hud/game_hud.tscn`](../../ui/hud/game_hud.tscn) `LootToast` · [`UIManager.show_loot_toast`](../../ui/ui_manager.gd) |
| 로그 | [`data/log/game_log_formatter.gd`](../../data/log/game_log_formatter.gd) `loot.grant` / `loot.skip` |

`CombatSession` / `EncounterDef`에 드랍 필드 없음. 방 타입 + 전역 테이블.

---

## 흐름

```
win
  → HP / 마나 / XP
  → LootService.grant(inventory, catalog, table, ctx)
  → show_loot_toast + push_log
  → refresh_character_views
  → BOSS면 return_to_village()  (지급·저장 이후)
```

ctx: `room_type`, `seed` (`FloorMap.seed_value`), `cell` (`RoomData.grid_pos`).  
RNG 시드 = `hash([seed, cell.x, cell.y])`.

| 방 | 개수 (테이블) |
|----|----------------|
| NORMAL | 1~2 |
| BOSS | 2~3 |

풀: `ItemCatalog`의 `WEAPON` / `ARMOR`. 균등. 동일 id 중복 허용. 템플릿 복제.  
가방 가득(`find_empty_slot == -1`)이면 남은 횟수 스킵. 기존 칸 유지.

후퇴·패배·`cleared` 재입장: 드랍 없음.

---

## API

```
LootService.grant(inventory, catalog, table, ctx) -> { granted, skipped }
LootService.default_table() -> LootTable
ItemCatalog.ids_for_categories(categories) -> Array[String]
UIManager.show_loot_toast(result)
GameHud.show_loot_toast(result)
```

로그 payload: `category: loot`, `kind: loot.grant` (`actor_name` = 표시명 나열) / `loot.skip`.  
문자열: `LOOT_GOT` / `LOOT_INVENTORY_FULL`.
