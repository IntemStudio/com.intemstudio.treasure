# 세이브 / 로드

플레이 메타 진행을 `user://` 슬롯 JSON으로 저장·복원한다.  
런 파일은 **쓰고 지운다**. 이어하기 시 던전 복귀는 후속 ([`docs/design/save-load.md`](../design/save-load.md)).

---

## 위치

| 역할 | 경로 |
|------|------|
| Autoload | [`autoload/save_manager.gd`](../../autoload/save_manager.gd) |
| DTO / 직렬화 | [`save/save_game.gd`](../../save/save_game.gd), [`save_serializer.gd`](../../save/save_serializer.gd), [`item_catalog.gd`](../../save/item_catalog.gd) |
| 연동 | [`ui/ui_manager.gd`](../../ui/ui_manager.gd) |
| 슬롯 UI | [`scenes/title/profile_select.tscn`](../../scenes/title/profile_select.tscn) ([`title.md`](title.md)) |
| 개발 오버레이 | [`ui/dev/dev_overlay.tscn`](../../ui/dev/dev_overlay.tscn) (`` ` `` 토글) |
| 캐릭터 템플릿 | [`ui/stats/resources/character_stats.tres`](../../ui/stats/resources/character_stats.tres) |
| 설정 (분리) | [`autoload/settings_manager.gd`](../../autoload/settings_manager.gd) → `user://settings.cfg` ([`settings.md`](settings.md)) |

---

## 레이어

| # | 레이어 | 저장소 | 현황 |
|---|--------|--------|------|
| 1 | 메타 진행 | `user://saves/slot_N.json` | O |
| 2 | 런 / 던전 | `slot_N_run.json` | O (쓰기·삭제). 로드 후 던전 복귀는 후속 |
| 3 | 환경 설정 | `user://settings.cfg` | O (세이브와 분리) |
| 4 | 헤더 | JSON `version` + `meta` | O (체크섬 등은 후속) |

---

## 파일 규약

| 상수 | 값 |
|------|-----|
| `SAVE_DIR` | `user://saves/` |
| `SLOT_COUNT` | `SaveManager.SLOT_COUNT` |
| `SLOT_PATH` | `slot_%d.json` |
| `RUN_PATH` | `slot_%d_run.json` |
| `SAVE_VERSION` | `1` |
| 쓰기 | `*.json.tmp` → rename (원자적) |

슬롯 상태: `empty` / `valid` / `corrupt` / `incompatible`.

---

## JSON — 메타 (`slot_N.json`)

최상위 키: `version`, `meta`, `character`, `inventory` (locale 없음).

- **meta:** slot, created_at, updated_at, play_time_sec, level, **`registered_cards`**, `open_cards`, `unlocked_shelves`(`shelf_rune`,`shelf_gem`), `card_pity` ([`equipment.md`](equipment.md))  
- **character:** name, level, xp, xp_to_next(저장·표시용, 로드 시 [`LevelProgression`](../../data/progression/level_progression.gd) CSV로 재동기화), hp, attribute_points, attributes, weight_current, weapons(임시). `attributes`는 [`ATTRIBUTE_IDS`](../../ui/stats/resources/character_stats.gd)만 읽고 모르는 키는 버린다. 옛 `faith`가 10을 넘으면 초과분을 `attribute_points`로 환급 (`SAVE_VERSION` 그대로)  
- **inventory:** currencies, current_category, sort_mode, sparse slots, equipped, 미소켓 **`runes`**, **`gems`**. 꽂힌 룬·보석은 장비 `socketed`에만 (`rune_id`/`gem_id`). 옛 세이브는 로드 시 가방에서 떼어 장비로 옮김  
- **아이템:** `id` + quantity / durability / `socketed` / `rarity` 등 인스턴스 오버라이드 (`ItemCatalog`로 베이스 복제). `rarity`가 있으면 소켓은 `SocketLayout.for_slot`로 재구성한 뒤 `trim_socketed_to_layout` (넘친 uid는 **삭제**, 가방 반환 없음). 옛 세이브 `rarity` 3(EPIC)·4는 `LEGENDARY`로 clamp. `cost` / `gain`은 저장하지 않음 ([`shop.md`](shop.md))

파생 스탯(`general` / `defense` / `hp_max` / `xp_to_next`)은 테이블·공식으로 복원. 요구 XP: [`data/progression/xp_to_next.csv`](../../data/progression/xp_to_next.csv) (D2 곡선 × 0.1).

전투 승패의 HP·XP·가방 장비는 `character` / `inventory`에 남는다. 방 클리어 전리품은 메타 인벤에 바로 넣는다 ([`loot.md`](loot.md)).

---

## JSON — 런 (`slot_N_run.json`)

도전 확정·방 이동 때 기록. 마을 복귀(`return_to_village`)·슬롯 삭제·새 게임 때 `clear_run`.

| 키 | 내용 |
|----|------|
| `dungeon_id` / `length_id` / `seed` / `room_count` | 게시판 파라미터 |
| `current` | `{x, y}` 현재 방 |
| `visited` / `cleared` | `"x,y"` 문자열 배열 |
| `runes` / `gems` / `socketed` | [`SaveSerializer.run_equipment_snapshot`](../../save/save_serializer.gd) |

프로필 → 마을만. **런이 있어도 던전으로 이어하지 않는다** (시드 재현·플래그 덮어쓰기는 후속).

---

## API·흐름

```
UIManager.save_to_slot / load_from_slot / start_new_game / apply_save_game
        ↓
SaveManager (new_game, save_game, load_game, delete_slot, clear_meta, list_slots, open_save_folder)
        ↓
SaveSerializer ↔ ItemCatalog → user://saves/slot_N.json
SaveManager.save_run / load_run / clear_run / has_run → slot_N_run.json
SettingsManager.save_settings / reset_settings → user://settings.cfg
```

- `play_time_sec`: 트리 pause가 아닐 때만 가산  
- `new_game`: [`character_stats.tres`](../../ui/stats/resources/character_stats.tres) 복제 후 `apply_new_game_start()` → **레벨 1, XP 0**, `xp_to_next`는 CSV. 기존 런 파일 삭제  
- 기본 UI 테스트: 세이브 없이 더미 `character_stats.tres` + `ItemBootstrap` 인벤으로 기동  
- 소켓 인스턴스는 장비 `socketed`에만. 로드 시 `ensure_socketed_on_items`  
- 검증: `godot --headless --path . -s res://save/verify_save_v1.gd`  
- 개발 오버레이: 아래 절

---

## 개발 오버레이

`` ` `` 토글. `UIManager`가 [`ui/dev/dev_overlay.tscn`](../../ui/dev/dev_overlay.tscn)을 `layer = 100`에 붙인다. Dialog `760×480` (`UIPopupLayout.DIALOG_SIZE`). 크롬(딤·테두리·제목) = `MAP_START` ([`hud.md`](hud.md) · [`ui-colors.md`](ui-colors.md)).

| 탭 | 내용 |
|----|------|
| 캐릭터 | 강제 레벨 ±, 강제 조우 / 승리 / 패배 / 후퇴 ([`combat.md`](combat.md)) |
| 아이템 | 카탈로그 지급 (아래) |
| 서가 | 룬/보석 판 `open_cards` 전 칸 해금 (`CardRegistrationService.open_all_on_shelf`) |
| 세이브 데이터 | 폴더 경로·열기 + 슬롯 선택 + 레이어별(메타/`slot_N.json`, 런/`slot_N_run.json`, 설정/`settings.cfg`)·모두 저장/삭제(선택 슬롯만) |

### 아이템 탭

부위 하위 탭: 무기·보조·투구·갑옷·다리·반지·도구·보석·룬 (`SLOT_*` / `Gem` / `Rune`). 칸은 해당 카탈로그만 — 인벤처럼 25칸 패딩 없음.

```
ItemPanel
├── ItemSubTabRow (HFlow)
└── ItemBody (HBox)
    ├── ItemGridScroll → ItemGrid (InventorySlot, columns = 3, 아이콘+이름)
    └── ItemDetailColumn
        ├── ItemDetailScroll → ItemDetailPanel | ModifierDetailPanel
        └── GrantRow → EquipRarityOption + EquipGrantButton
```

슬롯·상세는 인벤 컴포넌트 재사용 ([`inventory.md`](inventory.md)). 장비 상세는 골드 숨김 (`GoldPrice.HIDDEN`). 보석·룬은 `ModifierDetailPanel`, 희귀도 Option 숨김.

획득: 장비 `try_place_item` (`apply_rarity` → 색·가격, 소켓은 부위로 다시 찍고 넘친 칸 트림) / 보석 `try_add_gem` / 룬 `try_add_rune`. 가방 가득이면 `LOOT_INVENTORY_FULL`. 메타에 `rarity`를 저장.
