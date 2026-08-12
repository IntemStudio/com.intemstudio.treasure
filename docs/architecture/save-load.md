# 세이브 / 로드

플레이 메타 진행을 `user://` 슬롯 JSON으로 저장·복원하는 **v1 구조**.  
후속(v1.1 무결성, v2 런)은 [`docs/design/save-load.md`](../design/save-load.md).

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

## 레이어 (v1)

| # | 레이어 | 저장소 | v1 |
|---|--------|--------|-----|
| 1 | 메타 진행 | `user://saves/slot_N.json` | O |
| 2 | 런 / 던전 | `slot_N_run.json` | 후속 (설계) |
| 3 | 환경 설정 | `user://settings.cfg` | O (세이브와 분리) |
| 4 | 헤더 | JSON `version` + `meta` | O (체크섬 등은 후속) |

---

## 파일 규약

| 상수 | 값 |
|------|-----|
| `SAVE_DIR` | `user://saves/` |
| `SLOT_COUNT` | `SaveManager.SLOT_COUNT` |
| `SLOT_PATH` | `slot_%d.json` |
| `SAVE_VERSION` | `1` |
| 쓰기 | `*.json.tmp` → rename (원자적) |

슬롯 상태: `empty` / `valid` / `corrupt` / `incompatible`.

---

## JSON (v1)

최상위 키: `version`, `meta`, `character`, `inventory` (`run`·locale 없음).

- **meta:** slot, created_at, updated_at, play_time_sec, character_name, level  
- **character:** name, level, xp, xp_to_next(저장·표시용, 로드 시 [`LevelProgression`](../../data/progression/level_progression.gd) CSV로 재동기화), hp, attribute_points, attributes, weight_current, weapons(임시)  
- **inventory:** currencies, current_category, sort_mode, sparse slots, equipped  
- **아이템:** `id` + quantity / durability 등 인스턴스 오버라이드 (`ItemCatalog`로 베이스 복제)

파생 스탯(`general` / `defense` / `hp_max` / `xp_to_next`)은 테이블·공식으로 복원. 요구 XP: [`data/progression/xp_to_next.csv`](../../data/progression/xp_to_next.csv) (D2 곡선 × 0.1).

---

## API·흐름

```
UIManager.save_to_slot / load_from_slot / start_new_game / apply_save_game
        ↓
SaveManager (new_game, save_game, load_game, delete_slot, list_slots, open_save_folder)
        ↓
SaveSerializer ↔ ItemCatalog → user://saves/slot_N.json
```

- `play_time_sec`: 트리 pause가 아닐 때만 가산  
- 기본 UI 테스트: 세이브 없이 더미 `character_stats.tres` + `ItemBootstrap` 인벤으로 기동  
- 개발 오버레이: 세이브 폴더 절대 경로 표시 + OS에서 열기
