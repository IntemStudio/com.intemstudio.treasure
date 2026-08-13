# 장비 · 룬 · 보석 · 공명

주무기 소켓에 룬·보석을 두고 `ResonanceService`가 `skills`를 채운다. 전투는 그 결과만 소비한다.  
후속(희귀도 경제·책장 격자·인벤 소켓 UI·특수 방): [`docs/design/equipment.md`](../design/equipment.md).

**현황:** 샘플 인벤에 클레이모어 + Counter Verse + Bloodstone. 인벤에서 직접 꽂는 UI는 없음.

관련: [`inventory.md`](inventory.md) · [`combat.md`](combat.md) · [`hud.md`](hud.md) · [`village.md`](village.md) · [`save-load.md`](save-load.md) · [`loot.md`](loot.md).

---

## 위치

| 역할 | 경로 |
|------|------|
| 소켓 | [`data/equipment/socket_layout.gd`](../../data/equipment/socket_layout.gd) |
| 룬 | [`rune_data.gd`](../../data/equipment/rune_data.gd) · [`rune_instance.gd`](../../data/equipment/rune_instance.gd) · [`rune_catalog.gd`](../../data/equipment/rune_catalog.gd) |
| 보석 | [`gem_data.gd`](../../data/equipment/gem_data.gd) · [`gem_instance.gd`](../../data/equipment/gem_instance.gd) · [`gem_catalog.gd`](../../data/equipment/gem_catalog.gd) |
| 공명 | [`resonance_service.gd`](../../data/equipment/resonance_service.gd) · [`resonance_result.gd`](../../data/equipment/resonance_result.gd) |
| 등록 | [`card_registration_service.gd`](../../data/equipment/card_registration_service.gd) |
| 제단 | [`ui/village/registration_altar.tscn`](../../ui/village/registration_altar.tscn) |
| 가방 | [`InventoryData.runes`](../../ui/inventory/resources/inventory_data.gd) / `gems` |
| 장비 필드 | [`ItemData.socket_layout`](../../ui/inventory/resources/item_data.gd) · `socketed` · 호환 태그 |
| 샘플 | [`item_bootstrap.gd`](../../ui/inventory/resources/item_bootstrap.gd) |

`ItemCategory`에 `RUNE`/`GEM` 없음. 5×6 격자는 `ItemData`만.

---

## 흐름

```
SocketLayout.for_rarity(equip_slot, rarity)
        ↓
ItemData.socketed  [{kind, index, instance_uid}]
        ↓
ResonanceService.rebuild_main_hand_skills
        ↓
equipped.main_hand.skills
        ↓
CombatSession 기술 게이지 + 마나 자동 발동
```

룬은 `main_hand`만. `off_hand`는 보석·접두사. HUD 4칸 소스 = `main_hand.skills`.

| 공명 | 의미 |
|------|------|
| `INACTIVE` | 장비·룬 비호환. 해당 칸 없음 |
| `BASE_SKILL_ONLY` | 룬 기본 기술만 |
| `RESONANT` | 핵심 보석 일치 |
| `COMPLETE` | 보조 보석까지 |

보석은 `CombatStatsBuilder.AFFIX_FIELDS`에 더하지 않는다. 세션은 `behavior_flags` / `gem_id`를 소비.

---

## 소켓 UI

인벤 **상세**에 `SocketLayout.describe()`만 표시 ([`item_detail_panel.gd`](../../ui/inventory/components/item_detail_panel.gd)).  
꽂기·빼기는 `InventoryData.socket_rune` / `socket_gem` API. 샘플 부트스트랩이 클레이모어에 꽂아 둔다.

---

## 카드 등록

마을 제단만. 게시판·MenuShell 탭이 아님.

1. 후보 = 미등록 `runes[]` / `gems[]` 셀 격자
2. 확인 → 개체 제거, **장비는 유지**, `skills`/공명 재계산
3. `meta.registered_cards`에 기록 (`slot_N.json`)

전멸·보스 귀환이 등록 카드를 지우지 않는다.

---

## 세이브

| 파일 | 내용 |
|------|------|
| `slot_N.json` inventory | `runes[]` · `gems[]` · 장비 `socketed` |
| `slot_N.json` meta | `registered_cards` · `unlocked_shelves` · `card_pity` |
| `slot_N_run.json` | 탐험 + `SaveSerializer.run_equipment_snapshot` (런 중 스냅샷) |

마을 복귀 시 런 파일만 삭제 ([`save-load.md`](save-load.md)).

---

## API

```
SocketLayout.for_rarity(equip_slot, rarity) -> SocketLayout
InventoryData.socket_rune(equip_slot, rune_uid, index) -> bool
InventoryData.socket_gem(equip_slot, gem_uid, kind, index) -> bool
ResonanceService.evaluate(...) -> ResonanceResult
ResonanceService.rebuild_main_hand_skills(inventory, rune_cat, gem_cat) -> ResonanceResult
CardRegistrationService.list_registerable(inventory) -> Array
CardRegistrationService.register(inventory, meta, kind, uid, ...) -> {ok, meta}
SaveSerializer.run_equipment_snapshot(inventory) -> {runes, gems, socketed}
```
