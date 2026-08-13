# 마을 허브 / 도전 게시판

**미구현 후속:** v1.1 런 JSON · v2 여관/상점. **v1 현황(구조):** [`docs/architecture/village.md`](../architecture/village.md).  
다키스트 던전 1의 햄릿(허브) + Embark(원정 출발)를 참고한 루프.  
런 파일: [`save-load.md`](save-load.md) v2. 층 생성: [`map.md`](map.md). 전투 종료: [`combat.md`](combat.md).

타이틀·프로필은 그대로 [`title.md`](../architecture/title.md). **게임 플레이의 집**은 `village.tscn`.

---

## 한 줄

프로필을 고르면 **마을**로 들어가고, **도전 게시판(전체화면 메뉴)** 에서 확정한 뒤에만 던전 맵을 생성한다.

---

## 목표 루프

```
타이틀 → 프로필
        ↓
      마을 (고정 맵, FloorGenerator 없음)
        ↓  게시판 열기 → 길이 선택 → 도전 확정
      RunState 작성 → FloorMap.generate → dungeon.tscn
        ↓
      탐험 / 방 전투 (현행)
        ↓  클리어 · 전멸 · (후퇴는 v1.1에서 마을)
      런 정산·삭제 → 마을
```

| 역할 | 다키스트 던전 1 | 이 게임 |
|------|-----------------|---------|
| 허브 | 햄릿 | 마을 씬 |
| 출발 UI | Embark (전체화면) | **도전 게시판 (전체화면 메뉴)** |
| 맵 생성 | Embark 직후 | 게시판 **도전 확정** 직후 |
| 영구 데이터 | 영지·영웅 | 메타 `slot_N.json` |
| 일회 원정 | 퀘스트 던전 | 런 `slot_N_run.json` (v1.1+) |

타이틀은 슬롯 선택만 한다. 패배해도 타이틀이 아니라 마을로 돌아온다.

---

## 로드맵

| 단계 | 범위 | 상태 |
|------|------|------|
| **v1** | 마을 씬, 게시판 전체화면, 확정 시 생성·입장, 전멸→마을 | 구현됨 → [`architecture/village.md`](../architecture/village.md) |
| **v1.1** | 런 JSON, 이어하기 시 던전 복귀, 후퇴=원정 포기, 정산 | 설계만 — save-load v2 |
| **v1.region** | 게시판 지역 4종 + en/ko + 지역별 인카운터 | 구현됨 |
| **v2** | 여관, 상점, 길이별 난이도 | 설계만 |

---

## v1 — 허브 + 게시판

### 위치

| 역할 | 경로 |
|------|------|
| 마을 루트 | [`scenes/village/village.tscn`](../../scenes/village/village.tscn) + [`village.gd`](../../scenes/village/village.gd) |
| 도전 메뉴 | [`ui/village/challenge_board.tscn`](../../ui/village/challenge_board.tscn) |
| 원정 파라미터 | [`data/village/challenge_def.gd`](../../data/village/challenge_def.gd) · `SaveManager.pending_run` |
| 게임 진입 | [`profile_select.gd`](../../scenes/title/profile_select.gd) → `village.tscn` |
| 던전 기동 | [`dungeon.gd`](../../scenes/dungeon/dungeon.gd) — `take_pending_run`으로 `generate` |

`MenuShell` 탭에 게시판을 넣지 않는다. **전용 전체화면 오버레이**.

### 씬 트리 (마을)

```
Village (Node2D)
├── VillageRoom          # 고정. FloorMap / FloorGenerator 없음
│   └── BoardZone        # 게시판. ui_accept 또는 클릭
├── Player
├── Camera2D
├── UIManager            # HUD + MenuShell (인벤/스탯/설정)
└── ChallengeHost (CanvasLayer)
    ├── Dim
    └── ChallengeBoard
        ├── TitleLabel
        ├── Split
        │   ├── LengthList
        │   └── Detail
        └── Footer       # FooterPrompts
```

전투 노드(`CombatSession` / `Arena` / `EncounterDirector`)는 마을에 붙이지 않는다.

에디터에서 `dungeon.tscn`을 직접 실행하면 지금처럼 시드를 만들어 층을 연다 (마을 우회).

### 마을 월드

- 탑다운, 현행 플레이어·카메라·WASD 이동을 재사용한다. 방은 **하나(또는 작은 고정 배치)** 이고 절차 생성하지 않는다.
- 게시판은 눈에 보이는 오브젝트. 존 안 + `ui_accept`, 또는 게시판 클릭으로 메뉴를 연다.
- 중앙 HUD 상호작용 프롬프트는 쓰지 않는다 ([`hud.md`](hud.md) 비목표). 필요하면 게시판 노드에만 짧은 라벨(`게시판` / `Board`).
- 여관·상점은 v2. 회복은 v1에서 **마을 입장 시 HP를 최대로** 맞춘다 (전멸 복귀 포함).

### HUD · 메뉴

| 항목 | 마을 | 던전 |
|------|------|------|
| 자원 바 | 유지 | 유지 |
| 지역명 | `LOCATION_VILLAGE` | 현행 방 타입 |
| 미니맵 | 숨김 (`unbind_dungeon`) | 유지 |
| Map 탭 | 숨기거나 비활성 | 유지 |
| 인벤 / 능력치 / 설정 | 유지 | 유지 |
| 설정 → 나가기 | **타이틀** | v1: 타이틀 유지. v1.1: **마을**(원정 포기 확인) 추가 |

게시판이 열려 있으면 월드 입력 차단, GameHud 숨김 (MenuShell과 동일). 게시판과 MenuShell은 동시에 열지 않는다 — 게시판이 열려 있으면 `ui_cancel`은 게시판만 닫는다.

### 도전 게시판 (전체화면)

다키스트 던전 1 Embark처럼 **마을 위에 덮는 전체화면**. 맵을 미리 보여 주지 않는다. 열기만으로는 `FloorGenerator`를 호출하지 않는다.

설정 화면과 같은 **좌 목록 / 우 설명** + 하단 푸터.

```
ChallengeBoard
├── TitleLabel          # tr("Challenge") → 도전
├── Split
│   ├── LengthList      # 짧음 / 보통 / 긴
│   └── Detail
│       ├── DetailTitle
│       ├── DetailBody  # 방 수, 보상 안내, 플레이버
│       └── (선택) 경고  # HP가 낮으면 문구만. v1은 출발을 막지 않음
└── Footer              # BACK · CHALLENGE
```

#### 지역 · 길이

지역 4종 → `dungeon_id`. 길이 → `room_count`. 문구는 `tr()` + [`locale/ui_strings.csv`](../../locale/ui_strings.csv).

| id | en | ko |
|----|----|----|
| `cemetery` | Cemetery | 묘지 |
| `grove` | Grove | 숲 |
| `mansion` | Mansion | 영지 |
| `battlefield` | Battlefield | 전장 |

| id | 표시 (en / ko) | `room_count` | 보상 배수 (표시만) |
|----|----------------|--------------|-------------------|
| `short` | Short / 짧음 | 8 | ×1 |
| `normal` | Normal / 보통 | 12 | ×1.5 |
| `long` | Long / 긴 | 16 | ×2 |

보상 배수는 **UI 문구**만. XP·드랍·지역별 인카운터는 후속.

게시판 좌측: **지역** 열 + **길이** 열. 우측: 지역·길이 설명. ←/→ 열 전환.

#### 입력

| 조작 | 동작 |
|------|------|
| ← / → | 지역 ↔ 길이 열 |
| 상하 / 클릭 | 해당 열 행 포커스. 우 패널 갱신 |
| `ui_accept` / 푸터 CHALLENGE | **도전 확정** — 생성 + 던전 입장 |
| `ui_cancel` / 푸터 BACK | 메뉴 닫기, 마을 복귀. 맵 없음 |

확정은 한 단계. 설정 나가기식 2단 확인은 쓰지 않는다.

| 키 | en | ko |
|----|----|----|
| `Challenge` | Challenge | 도전 |
| `Region` / `Length` | Region / Length | 지역 / 길이 |
| `REGION_*` | Cemetery, Grove, … | 묘지, 숲, … |
| `CHALLENGE_SHORT` 등 | Short / … | 짧음 / … |
| 푸터 `Back` | 기존 | 기존 |
| `LOCATION_VILLAGE` | Village | 마을 |

### 도전 확정 흐름

맵이 생기는 **유일한** 시점.

```
게시판 CHALLENGE
  → seed = randi()   # 또는 고정 시드 디버그
  → RunParams { dungeon_id, length_id, seed, room_count }
  → (v1) 메모리 / 시그널로 던전에 전달
  → (v1.1) SaveManager.save_run(slot, run)
  → change_scene(dungeon.tscn)
  → dungeon._ready: FloorMap.generate(seed, room_count)  # randi() 직접 호출 금지
  → enter_room(ZERO)
```

게시판을 열거나 길이를 바꾸거나 BACK 해도 생성하지 않는다. 확정 전 미니맵/Map 탭에 층이 보이면 안 된다.

`dungeon.gd`는 런 파라미터가 없을 때만(에디터 직접 실행) 기존처럼 `randi()` + `ROOM_COUNT`로 폴백한다.

### 원정 종료 (v1)

| 결과 | 지금 | v1 |
|------|------|-----|
| 보스 클리어 | 던전에 잔류 | 던전에 잔류해도 됨. 입구 또는 보스 방에 **마을로** 상호작용을 두거나, 클리어 직후 마을로 보내도 됨 — 구현 직전 한쪽만 고른다. **권장:** 보스 승리 후 마을 |
| 후퇴 | 입구 방, 원정 유지 | **유지** (입구) |
| 전멸 | `return_to_title()` | `return_to_village()` — 메타 유지, 이번 층은 버림 |
| 설정 → 메인 메뉴 | 타이틀 | 타이틀 (슬롯 선택으로). 원정 포기는 v1.1 |

`UIManager.return_to_village()`:

- `paused = false` 후 deferred `village.tscn` (타이틀 복귀와 같은 pause 함정)
- `unbind_dungeon`, `in_combat = false`
- `current_slot`은 **유지** (타이틀로 갈 때만 `-1`)
- 런이 있으면 삭제 (v1은 메모리만 버려도 됨)

전멸 후 마을 HP는 최대. XP는 이미 메타 `character`에 반영된 분(클리어한 방)만 남긴다. 미정산 런 전리품은 v1에 없으므로 버릴 것이 없다.

### API (예정)

```
ChallengeBoard.setup(ui_manager)
ChallengeBoard.open()
ChallengeBoard.close()
signal challenge_confirmed(params)  # { dungeon_id, length_id, seed, room_count, reward_mult }

UIManager.return_to_village()
UIManager.set_hub_mode(true)        # 미니맵·Map 탭 숨김, LOCATION_VILLAGE

Village.gd: BoardZone → ChallengeBoard.open()
Dungeon.gd: consume RunParams → floor_map.generate(seed, room_count)
```

전달: `SaveManager.pending_run` (메모리). **디스크 런은 v1.1.**

---

## v1.1 — 런 세이브 · 원정 수명

[`save-load.md`](save-load.md) 레이어 2와 맞춘다.

- 도전 확정 → `save_run` (`dungeon_id`, `length_id`, `seed`, `room_count`, 이후 `current` / `visited` / `cleared`)
- 이어하기: 런 있으면 `dungeon.tscn`(시드로 `generate` 후 플래그 덮어쓰기), 없으면 `village.tscn`
- 보스 클리어 → 정산(배수 적용) → 메타 병합 → `clear_run` → 마을
- 후퇴 → 원정 포기 확인 → 미정산 런 보상 버림 → `clear_run` → 마을 (입구 대기는 제거하거나, 입구에 “마을로”를 둔다)
- 전멸 → 런만 삭제, 메타 유지 → 마을
- 던전 설정에 **마을로 돌아가기**(원정 포기). 타이틀 나가기는 유지

중도 세이브는 던전에서 메타+런을 같이 쓴다. 마을에서는 메타만 있고 런 파일이 없다.

---

## v2 — 햄릿 확장

- 여관: 유료 또는 무료 HP/마나 회복 (입장 시 자동 풀회복을 여관으로 옮길지 구현 직전)
- 상점: 인벤과 별도 NPC. 메뉴 인벤은 유지
- 보급(횃불·식량): 전투 스태미나/피로와 같이 검토 — 새 스탯이 아니라 Stamina 상한/재생 ([`stats.md`](stats.md))
- 파티 편성: 전투 [`combat.md`](combat.md) 다수 아군 이후
- 길이별 적 레벨·방당 랜덤 조우
- 등록 제단·책장: 룬·보석 카드 등록은 마을만. 게시판·MenuShell 탭과 별개 전체화면 ([`equipment.md`](equipment.md))

게시판은 **전체화면 메뉴** 유지. 월드에 퀘스트 목록을 펼치지 않는다.

---

## 관련 문서에 미치는 결정

| 문서 | v1에서 바꿀 점 |
|------|----------------|
| [`title.md`](../architecture/title.md) | 프로필 → `village.tscn`. `dungeon.tscn`은 게시판 확정 후 |
| [`map.md`](map.md) | `dungeon._ready`의 즉시 `generate` 제거. 파라미터 생성 |
| [`save-load.md`](save-load.md) | v1은 런 파일 없이 허브 루프. v1.1이 레이어 2 |
| [`combat.md`](combat.md) | `lose` → `return_to_village()` |
| [`hud.md`](hud.md) | `LOCATION_VILLAGE`, 마을에서 미니맵 숨김 |
| [`settings.md`](../architecture/settings.md) | v1 나가기 타이틀 유지. v1.1 던전→마을 |
| [`equipment.md`](equipment.md) | v2 제단·책장. 던전에서 카드 등록하지 않음 |

---

## 비목표 (당분간)

- 게시판에서 층 미리보기·시드 리롤 (생성 = 확정)
- MenuShell 탭으로 게시판 넣기
- 4인 파티, 스테이지 코치, 스트레스·기벽, 건물 업그레이드, 묘지
- 사이드뷰 햄릿
- 출발 전 보급 쇼핑 강제
- 전멸 시 캐릭터/슬롯 삭제 (퍼마데스)
- 마을 절차 생성, 마을 전투
- 클라우드, 원정 중 전투 세이브
