# 마을 허브 / 도전 게시판

프로필 선택 후 **마을**이 플레이 허브. 걸어다니지 않는다. 상·하·우 프레임이 상시이고, 소문·서가·대장간·인벤·스탯·설정은 각각 `MenuShell` Sheet 팝업. 도전 확정 뒤에만 던전 맵을 생성한다.  
후속(이어하기 던전 복귀·여관·상점): [`docs/design/village.md`](../design/village.md). 서가: [`equipment.md`](equipment.md) · [`docs/design/bookshelf.md`](../design/bookshelf.md). 상점 가격: [`shop.md`](shop.md).

---

## 위치

| 역할 | 경로 |
|------|------|
| 마을 루트 | [`scenes/village/village.tscn`](../../scenes/village/village.tscn) + [`village.gd`](../../scenes/village/village.gd) |
| 마을 셸 | [`ui/village/village_shell.tscn`](../../ui/village/village_shell.tscn) + [`village_shell.gd`](../../ui/village/village_shell.gd) |
| 도전 메뉴 | [`ui/village/challenge_board.tscn`](../../ui/village/challenge_board.tscn) + [`challenge_board.gd`](../../ui/village/challenge_board.gd) |
| 서가 | [`ui/village/bookshelf.tscn`](../../ui/village/bookshelf.tscn) + [`bookshelf.gd`](../../ui/village/bookshelf.gd) |
| 대장간 | [`ui/village/smithy.tscn`](../../ui/village/smithy.tscn) + [`smithy.gd`](../../ui/village/smithy.gd) |
| 길이 정의 | [`data/village/challenge_def.gd`](../../data/village/challenge_def.gd) |
| 원정 파라미터 | [`SaveManager`](../../autoload/save_manager.gd) `pending_run` + `save_run` |
| 프로필 진입 | [`profile_select.gd`](../../scenes/title/profile_select.gd) → `village.tscn` |
| 던전 생성 | [`dungeon.gd`](../../scenes/dungeon/dungeon.gd) `take_pending_run()` |
| 허브 UI | [`ui_manager.gd`](../../ui/ui_manager.gd) `set_hub_mode` / `return_to_village` |

---

## 씬 트리 (마을)

```
Village (Node2D)
├── VillageRoom          # 고정 배경. FloorMap / Player 없음
│   ├── Board            # 장식
│   └── Altar            # 장식
├── Camera2D
├── UIManager            # MenuShell Sheet: 인벤/맵/스탯/설정/소문/서가/대장간
└── ChallengeHost (CanvasLayer 0)
    └── VillageShell
        ├── TopBar
        ├── GameLogView
        └── HubNav       # [소문] [서가] [대장간] [인벤토리] [스탯] [설정] → open_tab
```

전투 노드 없음. 미니맵·Map·GameHud는 허브에서 숨김.

---

## 화면

| 구간 | 내용 |
|------|------|
| 상단 | `TopBar` 재화 · 위치 · 체력. 탭 없음 |
| 하단 | 허브 이동 → 각 Sheet 팝업 |
| 오른쪽 | `GameLogView` (`UIManager.game_log`) |
| 가운데 | `VillageRoom` 배경 |

소문·서가·대장간·인벤·스탯·설정은 각각 `UIManager.open_tab` → `MenuShell` Sheet (제목만, 탭 순환 없음).

---

## 흐름

1. 타이틀 → 프로필 → `village.tscn`
2. `UIManager.set_hub_mode(true)` — `LOCATION_VILLAGE`, HP 풀, GameHud 숨김
3. 하단 [소문]/[서가]/… → `UIManager.open_tab` (pause)
4. 지역·길이 선택 → CHALLENGE → `set_pending_run` + `save_run` → `dungeon.tscn`
5. `dungeon._ready` → `take_pending_run` → `FloorMap.generate(seed, room_count)` · 방 이동 시 런 JSON 갱신
6. 보스 승리 / 전멸 → `return_to_village()` (메타 저장, **`clear_run`**). 후퇴는 입구 유지
7. 설정 → 메인 메뉴는 타이틀 (`return_to_title`)

에디터에서 `dungeon.tscn` 직접 실행 시 `pending_run`이 없으면 `randi()` + 12방 폴백.

Esc / BACK은 열린 Sheet만 닫는다. 허브 크롬은 남는다.

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
SaveManager.save_run / clear_run
UIManager.set_hub_mode(bool)            # GameHud 숨김, LOCATION_VILLAGE
UIManager.set_challenge_board_open(bool)   # 룻 선택 오버레이 등
UIManager.open_tab(BOARD|SHELF|SMITHY|INVENTORY|STATS|SETTINGS)
UIManager.refresh_bookshelf()
UIManager.return_to_village()   # clear_run, save slot, keep current_slot, village.tscn
VillageShell.refresh_bookshelf()  # → UIManager
```

`return_to_village`는 씬 전환 전 `clear_run` + `save_to_slot`을 호출한다 (`UIManager._ready`가 디스크에서 다시 로드하므로).

---

## 비범위

- 이어하기 시 런 파일로 던전 복귀
- 여관·상점·제작
- 마을 내 이동/카메라 팬
