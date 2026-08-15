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
- **character:** name, level, xp, xp_to_next(저장·표시용, 로드 시 [`LevelProgression`](../../data/progression/level_progression.gd) CSV로 재동기화), hp, attribute_points, attributes, weight_current, weapons(임시)  
- **inventory:** currencies, current_category, sort_mode, sparse slots, equipped, **`runes`**, **`gems`**  
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
- 개발 오버레이 (`` ` ``): 탭 `[캐릭터]` / `[아이템]` / `[서가]` / `[세이브 데이터]`. 서가 탭은 룬·보석 판 `open_cards` 전 칸 해금. 세이브 탭은 폴더 경로·열기 + 슬롯 선택 + 레이어별(메타/`slot_N.json`, 런/`slot_N_run.json`, 설정/`settings.cfg`)·모두 저장/삭제(선택 슬롯만). 아이템 탭에서 장비 희귀도를 바꾸면 `apply_rarity`로 색·가격을 바꾸고 소켓은 부위로 다시 찍는다. 메타에 `rarity`를 저장
