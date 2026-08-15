# 장비 · 룬 · 보석 · 공명

주무기 소켓에 룬·보석을 두고 `ResonanceService`가 `skills`를 채운다. 전투는 그 결과만 소비한다.  
후속(패시브 전투 훅·특수 방): [`docs/design/equipment.md`](../design/equipment.md). `eq.economy`(희귀도=소켓)는 **폐기**.  
서가: [`docs/design/bookshelf.md`](../design/bookshelf.md) (`shelf.v3`).

**현황:** 새 프로필은 Iron Longsword + Splintered Buckler만 장착. 인벤에서 룬·보석을 소켓에 꽂고 뺄 수 있다. 마을 **서가** 탭 룬|보석. 룻은 `open_cards` (시작 각 판 `#1`만. 봉인 시 인접 OPEN). 룬·보석 희귀도 없음. `RuneCatalog` / `GemCatalog`는 서가당 템플릿 25개(card_number 1–25, 5×5).

관련: [`inventory.md`](inventory.md) · [`combat.md`](combat.md) · [`hud.md`](hud.md) · [`village.md`](village.md) · [`save-load.md`](save-load.md) · [`loot.md`](loot.md) · [`shop.md`](shop.md) (`cost`/`gain`은 오버라이드. 소켓 수 ≠ 골드).

---

## 위치

| 역할 | 경로 |
|------|------|
| 소켓 | [`data/equipment/socket_layout.gd`](../../data/equipment/socket_layout.gd) |
| 룬 | [`rune_data.gd`](../../data/equipment/rune_data.gd) · [`rune_instance.gd`](../../data/equipment/rune_instance.gd) · [`rune_catalog.gd`](../../data/equipment/rune_catalog.gd) |
| 보석 | [`gem_data.gd`](../../data/equipment/gem_data.gd) · [`gem_instance.gd`](../../data/equipment/gem_instance.gd) · [`gem_catalog.gd`](../../data/equipment/gem_catalog.gd) |
| 공명 | [`resonance_service.gd`](../../data/equipment/resonance_service.gd) · [`resonance_result.gd`](../../data/equipment/resonance_result.gd) |
| 등록 | [`card_registration_service.gd`](../../data/equipment/card_registration_service.gd) |
| 서가 정의 | [`shelf_definition.gd`](../../data/equipment/shelf_definition.gd) |
| 서가 UI | [`ui/village/bookshelf.tscn`](../../ui/village/bookshelf.tscn) (도감+봉인) |
| 검증 | [`verify_bookshelf.gd`](../../data/equipment/verify_bookshelf.gd) · [`verify_socket_layout.gd`](../../data/equipment/verify_socket_layout.gd) |
| 가방 | [`InventoryData.runes`](../../ui/inventory/resources/inventory_data.gd) / `gems` |
| 장비 필드 | [`ItemData.socket_layout`](../../ui/inventory/resources/item_data.gd) · `two_handed` · `socketed` · 호환 태그 |
| 샘플 | [`item_bootstrap.gd`](../../ui/inventory/resources/item_bootstrap.gd) · 카탈로그 기본 장비는 [`item_defaults.gd`](../../ui/inventory/resources/item_defaults.gd) |

`ItemCategory`에 `RUNE`/`GEM` 없음. 장비 가방은 탭별 `bags` 5×5 (`ItemData`만). `MOD`는 `runes[]`/`gems[]` 합산 25.

---

## 흐름

```
SocketLayout.for_slot(equip_slot)
        ↓
ItemData.socketed  [{kind, index, instance_uid}]
        ↓
ResonanceService.list_equipped_rune_skills
  (main_hand 0·1 → off_hand → head → chest → legs, 꽂힌 룬만)
        ↓
HUD SkillRow 0~6  +  CombatSession 게이지
        ↓
마나 되는 첫 액티브(strike/combo/aoe) 발동. 패시브는 표시만
```

룬 액티브(`strike`/`combo`/`aoe`)는 `main_hand`만. 패시브(`heal`/`ward`/`thorns`/`buff`/`debuff`/`counter`/`convert`)는 `off_hand`·머리·가슴·다리. 반지·도구는 룬 없음. HUD 위줄 = 장착 룬 목록. 아이템 상세에 XYAB 없음 (소켓 행만).  
룬 상세(`ModifierDetailPanel`)는 `ResonanceService.slots_for_rune_kind`로 장착 부위를 표시. 액티브는 `Applies To` 태그(무기 종류), 패시브는 부위만.  
양손(`ItemData.two_handed`, 클레이모어·필드 파이크): 장착 시 주·보조를 모두 해제. 착용 중 보조를 끼면 양손이 가방으로 가고 주무기 칸은 빈다. 양손도 주무기 액티브 세트 2개만 (방패 패시브 없음).

장비 희귀도 4단: COMMON / UNCOMMON / RARE / LEGENDARY. **소켓 개수는 희귀도가 아니라 부위.** 색·접두사·상점가만 희귀도.

| 부위 | 룬 | 핵심 | 보조 |
|------|----|------|------|
| 주무기 | 2 (액티브 세트 A/B) | 2 | 2 |
| 갑옷 / 보조무기 | 1 (패시브) | 1 | 1 |
| 반지 / 도구 | 0 | 1 | 0 |

인덱스 짝: `rune` i ↔ `core_gem` i ↔ `aux_gem` i. 갑옷·방패 패시브 룬은 HUD에 이름이 올라가지만 이번 패스에서 게이지 발동·전투 훅은 없다.

공명 상태:

| 공명 | 의미 |
|------|------|
| `INACTIVE` | 장비·룬 비호환. 해당 칸 없음 |
| `BASE_SKILL_ONLY` | 룬 기본 기술만 |
| `RESONANT` | 핵심 보석 일치 |
| `COMPLETE` | 보조 보석까지 |

보석은 `CombatStatsBuilder.AFFIX_FIELDS`에 더하지 않는다. 세션은 `behavior_flags` / `gem_id`를 소비.

---

## 소켓 UI

인벤 **상세**에 소켓 행(`SocketRow`)을 표시한다 ([`item_detail_panel.gd`](../../ui/inventory/components/item_detail_panel.gd) · [`socket_row.gd`](../../ui/inventory/components/socket_row.gd)). 무기 행 순서: `rune0`, `core0`, `aux0`, `rune1`, `core1`, `aux1` (`InventoryData.list_socket_rows`).

| 흐름 | 조작 |
|------|------|
| 장비 → MOD | 빈 소켓 확인 → 호환 룬/보석만 강조 → 꽂기. 찬 소켓 확인 → 빼기 |
| MOD → 장비 | SOCKET → 호환 장비만 강조 → 빈 칸 1개면 즉시, 여러 개면 소켓 행에서 선택 |

호환은 `ResonanceService.can_socket_*`. 꽂기/빼기 후 `rebuild_main_hand_skills`(주무기 `item.skills` 세트 2개) + HUD는 `list_equipped_rune_skills`로 `refresh_hud` (인벤 선택 유지).

---

## 카드 등록 · 서가 (shelf.v3)

`VillageShell` **[서가]** → `UIManager.open_tab(SHELF)` Sheet. 내부 탭 **룬 | 보석**. 제단 단독 UI 없음. 오른쪽 상세는 인벤과 같은 `ModifierDetailPanel` (OPEN·REGISTERED만 능력; FOG는 힌트만). 룬은 `skill_kind`로 장착 부위. 보석은 `slot_effects` 주입 효과+설명. 봉인 상태 문구는 `DetailStatus`.

1. 격자 = 5×5, 1칸 1템플릿. 상태: FOG / OPEN / REGISTERED / EMPTY  
2. 보유·미소켓 uid → 봉인 → `registered_cards`, self+인접 `open_cards` (동 판만)  
3. 룻 풀 = `(shelf_id, card_number) ∈ open_cards` (시작 각 판 `#1`)  
4. 동 id 재봉인 불가. 희귀도 단·E1 없음  
5. legacy `shelf_common|uncommon|rare` → open 리셋 후 `#1` 시드  

전멸·보스 귀환이 등록 카드를 지우지 않는다.

---

## 세이브

| 파일 | 내용 |
|------|------|
| `slot_N.json` inventory | `runes[]` · `gems[]` · 장비 `socketed` |
| `slot_N.json` meta | `registered_cards` · `open_cards` · `unlocked_shelves`(`shelf_rune`,`shelf_gem`) · `card_pity`(미사용) |
| `slot_N_run.json` | 탐험 + `SaveSerializer.run_equipment_snapshot` (런 중 스냅샷) |

마을 복귀 시 런 파일만 삭제 ([`save-load.md`](save-load.md)).

---

## API

```
ResonanceService.list_equipped_rune_skills(inventory, rune_cat, gem_cat) -> Array  # HUD·세션
ResonanceService.rebuild_main_hand_skills(inventory, rune_cat, gem_cat) -> ResonanceResult  # 주무기 item.skills
ResonanceService.slots_for_rune_kind(kind) -> PackedStringArray
ResonanceService.can_socket_rune / can_socket_gem
SocketLayout.for_slot(equip_slot) -> SocketLayout
ItemData.trim_socketed_to_layout()  # 레이아웃 밖 index 삭제. 가방 반환 없음

CardRegistrationService.ensure_meta_seeded(meta, rune_cat?, gem_cat?) -> Dictionary
CardRegistrationService.is_open / is_discovered(meta, shelf_id, card_number) -> bool
CardRegistrationService.is_shelf_unlocked(meta, shelf_id) -> bool
CardRegistrationService.cell_state(...) -> CellState
CardRegistrationService.loot_pool_ids(meta, kind, catalog) -> Array[String]
CardRegistrationService.open_all_on_shelf(meta, shelf_id) -> Dictionary  # 전 칸 open (DevOverlay)
CardRegistrationService.first_owned_uid(inventory, kind, id) -> String  # 미소켓만
CardRegistrationService.register(inventory, meta, kind, uid, ...) -> {ok, meta}
```

`godot --headless --path . -s res://data/equipment/verify_bookshelf.gd`  
`godot --headless --path . -s res://data/equipment/verify_socket_layout.gd`