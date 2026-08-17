# 마을 허브 / 도전 게시판

프로필 선택 후 **마을**이 플레이 허브. 걸어다니지 않는다. 상·하·우 프레임이 상시이고, 게시판·제단·서가·대장간은 `MenuShell` Sheet **상단 4탭**. 인벤·맵·스탯·설정은 풀스크린 플레이어 메뉴(상단 4탭). 도전 확정 뒤에만 던전 맵을 생성한다.  
후속(이어하기 던전 복귀·여관·상점): [`docs/design/village.md`](../design/village.md). 분지 수색(이름돌·제단 아래): [`docs/design/basin.md`](../design/basin.md). 서가: [`equipment.md`](equipment.md) · [`docs/design/bookshelf.md`](../design/bookshelf.md). 제단 봉인: [`docs/design/altar.md`](../design/altar.md). 상점 가격: [`shop.md`](shop.md).

---

## 위치

| 역할 | 경로 |
|------|------|
| 마을 루트 | [`scenes/village/village.tscn`](../../scenes/village/village.tscn) + [`village.gd`](../../scenes/village/village.gd) |
| 마을 셸 | [`ui/village/village_shell.tscn`](../../ui/village/village_shell.tscn) + [`village_shell.gd`](../../ui/village/village_shell.gd) |
| 도전 메뉴 | [`ui/village/challenge_board.tscn`](../../ui/village/challenge_board.tscn) + [`challenge_board.gd`](../../ui/village/challenge_board.gd) |
| 제단 | [`ui/village/altar.tscn`](../../ui/village/altar.tscn) + [`altar.gd`](../../ui/village/altar.gd) |
| 서가 | [`ui/village/bookshelf.tscn`](../../ui/village/bookshelf.tscn) + [`bookshelf.gd`](../../ui/village/bookshelf.gd) |
| 대장간 | [`ui/village/smithy.tscn`](../../ui/village/smithy.tscn) + [`smithy.gd`](../../ui/village/smithy.gd) |
| 구역 정의 | [`data/village/challenge_def.gd`](../../data/village/challenge_def.gd) · [`data/village/basin_progress.gd`](../../data/village/basin_progress.gd) |
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
├── UIManager            # MenuShell: 플레이어 메뉴 4탭 + 마을 Sheet 4탭(게시판/제단/서가/대장간)
└── ChallengeHost (CanvasLayer 0)
    └── VillageShell
        ├── TopBar               # 오른쪽 끝 [메뉴] → 플레이어 메뉴
        └── HubNav       # [게시판] (Q) [제단] (W) [서가] (E) [대장간] (R)
```

전투 노드 없음. 미니맵·Map·GameHud는 허브에서 숨김.

---

## 화면

| 구간 | 내용 |
|------|------|
| 상단 | `TopBar` 재화 · 위치 · 체력 · 오른쪽 끝 `[메뉴] (TAB)` → 플레이어 메뉴 |
| 하단 | 허브 이동 → 마을 Sheet. `[게시판] (Q)` `[제단] (W)` `[서가] (E)` `[대장간] (R)` |
| 가운데 | `VillageRoom` 배경 |

게시판·제단·서가·대장간은 `UIManager.open_tab` → 같은 `MenuShell` Sheet. 단축키 Q/W/E/R (같은 키를 다시 누르면 닫힘). 패드 LB/RB는 시트 안에서 탭 순환. 인벤·맵·스탯·설정은 상단 `[메뉴] (TAB)` / I 키. 게시판/서가/대장간 본문 맨 위는 이름+대사 한 줄 (펠·난·브람). 제단은 NPC 없이 힌트만.

---

## 흐름

1. 타이틀 → 프로필 → `village.tscn`
2. `UIManager.set_hub_mode(true)` — `LOCATION_VILLAGE`, HP 풀, GameHud 숨김
3. 하단 [게시판]/[제단]/[서가]/[대장간] → `UIManager.open_tab` (pause)
4. 상처·이름돌 선택 → CHALLENGE → `set_pending_run` + `save_run` → `dungeon.tscn`
5. `dungeon._ready` → `take_pending_run` → `FloorMap.generate(seed, room_count)` · 방 이동 시 런 JSON 갱신. 중간 구역 START에서 구절 읽기
6. 보스 승리 → `unlock_next` 후 `return_to_village()` (메타 저장, **`clear_run`**). 제단 아래는 결말 3택 후 마을. 전멸은 돌 없이 마을. 후퇴는 입구 유지
7. 설정 → 메인 메뉴는 타이틀 (`return_to_title`)

에디터에서 `dungeon.tscn` 직접 실행 시 `pending_run`이 없으면 `cemetery` + `graves` + 8방 폴백.

Esc / BACK은 열린 Sheet만 닫는다. 허브 크롬은 남는다.

---

## 지역 (ChallengeDef.REGIONS)

| id | en | ko |
|----|----|----|
| `cemetery` | Cemetery | 묘지 |
| `grove` | Grove | 숲 |
| `mansion` | Mansion | 영지 |
| `battlefield` | Battlefield | 전장 |

`pending_run.dungeon_id` + `zone_id`에 저장. 인카운터: [`combat.md`](combat.md) `RegionEncounters`.

---

## 이름돌 (ChallengeDef.ZONES)

한 원정 = 한 구역. 게시판은 분지 나침반 + 해금된 이름돌. 길이 열 없음.

나침반: 북 `cemetery` · 서 `grove` · 동 `mansion` · 남 `battlefield`. 가운데는 구절 3행이면 `altar_below`, 아니면 `SHELTER_LABEL`(비활성). 우패널: 구역 설명 + 읽은 구절(안 읽은 행은 안개).

시작 돌: `cemetery:graves`, `grove:path`, `mansion:garden`, `battlefield:field`. 보스 승리 시 `BasinProgress.unlock_next`. 구절 3행이면 `altar_below` 점.

던전 HUD 위치는 방 타입(Entrance/Boss)이 아니라 `ZONE_TITLE_*` / `LOCATION_ALTAR_BELOW`.

상세: [`docs/design/basin.md`](../design/basin.md).

---

## API

```
ChallengeDef.build_run_params(dungeon_id, zone_id, seed=-1) -> Dictionary
# { dungeon_id, zone_id, seed, room_count }
BasinProgress.seed_meta / unlock_next / try_read_verse / can_open_altar / apply_ending
SaveManager.set_pending_run(params) / take_pending_run() / clear_pending_run()
SaveManager.save_run / clear_run
UIManager.set_hub_mode(bool)            # GameHud 숨김, LOCATION_VILLAGE
UIManager.set_challenge_board_open(bool)   # 룻 선택 오버레이 등
UIManager.open_tab(BOARD|ALTAR|SHELF|SMITHY|INVENTORY|STATS|SETTINGS)
UIManager.open_player_menu()        # 마지막 플레이어 탭. HUD/마을 [메뉴]
UIManager.refresh_bookshelf()
UIManager.return_to_village()   # clear_run, save slot, keep current_slot, village.tscn
VillageShell.refresh_bookshelf()  # → UIManager
```

`return_to_village`는 씬 전환 전 `clear_run` + `save_to_slot`을 호출한다 (`UIManager._ready`가 디스크에서 다시 로드하므로).

검증: `godot --headless --path . -s res://data/village/verify_basin_progress.gd`

---

## 비범위

- 이어하기 시 런 파일로 던전 복귀
- 여관·상점·제작
- 마을 내 이동/카메라 팬
