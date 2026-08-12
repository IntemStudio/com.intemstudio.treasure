# 던전 맵 / 방 텔레포트 — 설계

메뉴 셸 **Map** 탭과 던전 층 데이터·방 호스트를 묶는 스펙.  
v1 목표는 아이작식 **방 격자 생성** + **맵에서 방 클릭 시 텔레포트**.

**현황:** v1 구현됨 → 구조 문서 [`docs/architecture/map.md`](../architecture/map.md).  
런 세이브(층·시드·탐험 상태): [`save-load.md`](save-load.md) v2.

---

## 목표

1. 시드 기반 층에서 **방 그래프**를 만든다.
2. Map 탭에서 방을 보면 **클릭한 방으로 즉시 이동**한다.
3. 문 통과 이동은 후속으로 두고, **같은 `enter_room` API**를 재사용한다.

---

## 확정 결정

| 항목 | 결정 |
|------|------|
| 이동 방식 (v1) | 맵 클릭 = 텔레포트 |
| 방 로드 | 한 번에 **현재 방만** 인스턴스 (`RoomHost`) |
| 공유 상태 | `FloorMap` 하나를 UI·월드가 공유 |
| 메뉴 | 텔레포트 성공 시 Map 탭 닫기 (`MenuShell.close`) |
| 문 이동 | v1 비목표. v1.1에서 `enter_room(neighbor)` |
| 미니맵(HUD) | 비목표 — HUD 설계와 동일 ([`hud.md`](hud.md)) |
| 클릭 제한 | **방문한 방**은 자유 이동. **미방문 방**은 현재 방과 **인접**할 때만 (`FloorMap.can_enter`) |

---

## 구성

```
FloorMap (데이터: rooms, current, seed)
    ↑ 읽기              ↑ set_current / room_changed
MapContent (메뉴 Map 탭)     RoomHost (월드: 방 씬 교체 + 플레이어 스폰)
         └─ click ───────→ enter_room(grid_pos)
```

| 역할 | 예정 경로 | 책임 |
|------|-----------|------|
| 층 데이터 | `world/dungeon/floor_map.gd` (+ `room_data.gd`) | 생성, 조회, `current`, `room_changed` |
| 생성기 | `world/dungeon/floor_generator.gd` | 시드·방 수 → 격자 + 이웃 링크 |
| 방 호스트 | `scenes/dungeon/room_host.tscn` | `enter_room`, 방 씬 swap, 스폰 |
| 방 씬 | `scenes/dungeon/rooms/*.tscn` | 레이아웃·스폰 마커 (v1은 공용 1종 가능) |
| Map UI | `ui/map/map_content.tscn` | 격자 표시, 클릭 → `enter_room` |
| 셸 | `ui/shell/menu_shell.gd` | `Tab.MAP` 마운트·`open_tab` 허용 |
| TopBar | `ui/shared/top_bar.gd` | `CYCLEABLE_TABS`에 Map(`1`) 포함 |

소유: 던전 씬이 `FloorMap` + `RoomHost`를 들고, `UIManager`가 Map 콘텐츠에 참조를 넘긴다 (Autoload 필수는 아님).

---

## 데이터

### RoomData

| 필드 | 타입 | 설명 |
|------|------|------|
| `grid_pos` | `Vector2i` | 층 격자 좌표 |
| `room_type` | enum/String | `start` / `normal` / `boss` / (후속 special) |
| `neighbors` | `Dictionary` | 방향 → `Vector2i` (`N`/`E`/`S`/`W`) |
| `visited` | `bool` | 입장 시 true |
| `cleared` | `bool` | v1 미사용 가능. 전투 후속 |

### FloorMap

| API | 설명 |
|-----|------|
| `generate(seed, room_count)` | 생성기로 rooms 채움, `current` = start |
| `has_room(pos) -> bool` | |
| `get_room(pos) -> RoomData` | |
| `get_rooms() -> Dictionary` | `Vector2i` → `RoomData` |
| `get_current() -> Vector2i` | |
| `set_current(pos)` | `visited` 갱신 + `room_changed` |
| `can_enter(pos) -> bool` | 방문했거나 현재 방 neighbor이면 true |

시그널: `room_changed(pos: Vector2i)` — Map 하이라이트, HUD 지역명([`UIManager.set_location`](../../ui/ui_manager.gd)).

### 생성 (아이작식, v1)

1. `(0,0)` start 배치.
2. 큐 확장: 상하좌우 빈 칸에 방 추가 (최대 `room_count`, 겹침 금지).
3. start에서 맨해튼(또는 BFS) 최원 → `boss` (선택).
4. 인접한 방끼리 `neighbors` 양방향 연결.

특수 방·잠금 문·아이템 방은 후속.

---

## RoomHost

```
enter_room(pos: Vector2i) -> void
  - has_room 아니면 return
  - 현재 방 자식 queue_free
  - room_type(또는 공용) PackedScene instantiate
  - FloorMap.set_current(pos)
  - 플레이어를 SpawnMarker(없으면 방 중앙)에 배치
  - (선택) UIManager.set_location(...)
```

문 트리거(v1.1)와 Map 클릭은 **둘 다 `enter_room`만** 호출한다.

---

## Map 탭 UI

메뉴 셸 BodyHost에 Inventory 등과 동일한 계약:

`setup(ui_manager, footer)` → `activate(...)` / `deactivate()` → Esc·CLOSE 시 `request_close`.

### 화면

```
┌─ TopBar: [인벤][맵][스탯][설정] ─────────────────────┐
│                                                     │
│              ■ ■                                    │
│            ■ ■ ■ ■     ← 방 격자 (현재 칸 강조)      │
│              ■ ■                                    │
│                                                     │
└─ Footer: CLOSE ─────────────────────────────────────┘
```

| 동작 | 내용 |
|------|------|
| 표시 | `FloorMap`의 모든 방. 타입별 색/아이콘(start/boss/normal). 이동 불가 칸은 어둡게·비활성 |
| 현재 방 | 테두리·금색 등 강조 (`room_changed` 구독) |
| 클릭 | `can_enter`인 칸만 `RoomHost.enter_room(pos)` → 성공 시 셸 `close` |
| 입력 | 마우스 클릭 우선. 게임패드 포커스 이동은 v1.1 |

푸터: v1은 `CLOSE`만. (후속: 층 이름·시드 표시 등)

---

## 셸 / TopBar 연동

| 파일 | 변경 |
|------|------|
| `menu_shell.gd` | `MAP_CONTENT_PATH` 마운트, `_contents[Tab.MAP]`, `open_tab`에서 MAP 허용 |
| `top_bar.gd` | `CYCLEABLE_TABS`에 `1` 추가 |
| `ui_manager.gd` | Map 탭 열기 경로가 있으면 동일 enum(`Tab.MAP = 1`) 사용 |

Map 활성화 시 `FloorMap` / `RoomHost`가 없으면 빈 안내(또는 탭 비활성) — 타이틀·프로필만 있는 장면에서는 Map을 열지 않거나 no-op.

---

## 게임 진입

프로필 선택 후 [`dungeon.tscn`](../../scenes/dungeon/dungeon.tscn)이 `RoomHost` + 플레이어 + `FloorMap.generate`를 수행한다. [`ui_test.tscn`](../../scenes/ui_test.tscn)는 UI 회귀용으로 유지.

HUD 지역명: `room_changed` → `UIManager.set_location` (`LOCATION_ROOM_START` / `LOCATION_DUNGEON` / `LOCATION_ROOM_BOSS`).

---

## 비목표 (당분간)

- 문·복도로 걸어 들어가기 (v1.1)
- HUD 미니맵
- 방문/클리어 게이트, 잠금 문, 열쇠
- 맵에서 적·아이템 아이콘
- 층 간 이동(다음 층 포털)
- 런 JSON 저장([`save-load.md`](save-load.md) v2와 맞춤)
- 절차적 방 **내부** 지형(v1은 고정 방 씬)

---

## 로드맵

| 단계 | 범위 | 상태 |
|------|------|------|
| 설계 | 텔레포트 Map, FloorMap·RoomHost 계약 | 완료 (본 문서) |
| **v1** | 생성기 + RoomHost + `map_content` + 셸 Map 탭 | 구현됨 → 구조 문서 |
| **v1.1** | 문 통과 → `enter_room`, 패드 맵 커서, (선택) visited-only | 설계만 |
| **v2** | 런 세이브에 시드·current·visited, 특수 방 | 설계만 — save-load v2 |

---

## v1.1 — 문 이동 (예정)

- 방 가장자리 `Door` Area/Body → 방향별 neighbor `enter_room`
- 스폰을 **진입 반대쪽 문** 앞으로 배치
- Map 텔레포트와 공존 (제한 정책은 별도 토글 가능)

---

## v2 — 런 연동 (예정)

[`save-load.md`](save-load.md) `slot_N_run.json` 후보와 정렬:

- `dungeon_id`, `floor`, `seed`
- `current: Vector2i`, 방별 `visited` / `cleared`

로드 시 `generate` 재현 후 탐험 플래그만 덮어쓰거나, 방 목록을 직렬화할지 구현 직전에 확정한다.
