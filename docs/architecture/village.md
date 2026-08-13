# 마을 허브 / 도전 게시판

프로필 선택 후 **마을**이 플레이 허브. 도전 게시판(전체화면)에서 확정한 뒤에만 던전 맵을 생성한다.  
후속(런 JSON·여관): [`docs/design/village.md`](../design/village.md).

---

## 위치

| 역할 | 경로 |
|------|------|
| 마을 루트 | [`scenes/village/village.tscn`](../../scenes/village/village.tscn) + [`village.gd`](../../scenes/village/village.gd) |
| 도전 메뉴 | [`ui/village/challenge_board.tscn`](../../ui/village/challenge_board.tscn) + [`challenge_board.gd`](../../ui/village/challenge_board.gd) |
| 길이 정의 | [`data/village/challenge_def.gd`](../../data/village/challenge_def.gd) |
| 원정 파라미터 | [`SaveManager`](../../autoload/save_manager.gd) `pending_run` (메모리, v1) |
| 프로필 진입 | [`profile_select.gd`](../../scenes/title/profile_select.gd) → `village.tscn` |
| 던전 생성 | [`dungeon.gd`](../../scenes/dungeon/dungeon.gd) `take_pending_run()` |
| 허브 UI | [`ui_manager.gd`](../../ui/ui_manager.gd) `set_hub_mode` / `return_to_village` |

---

## 씬 트리 (마을)

```
Village (Node2D)
├── VillageRoom          # 고정 ColorRect. FloorMap 없음
│   └── Board            # 클릭 / 근처 ui_accept
├── Player
├── Camera2D
├── UIManager
└── ChallengeHost (CanvasLayer, WHEN_PAUSED)
    └── ChallengeBoard
```

전투 노드 없음. 미니맵·Map 탭은 허브에서 숨김.

---

## 흐름

1. 타이틀 → 프로필 → `village.tscn`
2. `UIManager.set_hub_mode(true)` — `LOCATION_VILLAGE`, HP 풀, Map 탭 숨김
3. 게시판 클릭 또는 근처 `ui_accept` → `ChallengeBoard.open()` (pause)
4. 지역·길이 선택 → CHALLENGE → `SaveManager.set_pending_run` → `dungeon.tscn`
5. `dungeon._ready` → `take_pending_run` → `FloorMap.generate(seed, room_count)`
6. 보스 승리 / 전멸 → `return_to_village()` (슬롯 저장 후). 후퇴는 입구 유지
7. 설정 → 메인 메뉴는 타이틀 (`return_to_title`)

에디터에서 `dungeon.tscn` 직접 실행 시 `pending_run`이 없으면 `randi()` + 12방 폴백.

---

## 지역 (ChallengeDef.REGIONS)

| id | en | ko |
|----|----|----|
| `cemetery` | Cemetery | 묘지 |
| `grove` | Grove | 숲 |
| `mansion` | Mansion | 영지 |
| `battlefield` | Battlefield | 전장 |

`pending_run.dungeon_id`에 저장. 인카운터: [`combat.md`](combat.md) `RegionEncounters`.

---

## 길이 (ChallengeDef.LENGTHS)

| id | room_count | 보상 배수 (문구만) |
|----|------------|-------------------|
| short | 8 | ×1 |
| normal | 12 | ×1.5 |
| long | 16 | ×2 |

게시판: 좌측 **지역** · **길이** 목록, 우측 설명. ←/→ 열 전환, ↑/↓ 행 이동.

---

## API

```
ChallengeDef.build_run_params(region_index, length_index, seed=-1) -> Dictionary
# { dungeon_id, length_id, seed, room_count, reward_mult }
SaveManager.set_pending_run(params) / take_pending_run() / clear_pending_run()
UIManager.set_hub_mode(bool)
UIManager.set_challenge_board_open(bool)
UIManager.return_to_village()   # save slot, keep current_slot, village.tscn
ChallengeBoard.open() / close() / is_open()
```

`return_to_village`는 씬 전환 전 `save_to_slot`을 호출한다 (`UIManager._ready`가 디스크에서 다시 로드하므로).

---

## 비범위 (v1)

- `slot_N_run.json`, 이어하기 시 던전 복귀
- 후퇴 = 원정 포기, 여관·상점
- 길이별 적 레벨·랜덤 조우 가중치
