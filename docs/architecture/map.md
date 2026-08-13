# 던전 맵 / 방 텔레포트

메뉴 셸 **Map** 탭에서 방 칸을 클릭하면 해당 방으로 텔레포트한다.  
후속: [`docs/design/map.md`](../design/map.md).

---

## 위치

| 역할 | 경로 |
|------|------|
| 방 데이터 | [`world/dungeon/room_data.gd`](../../world/dungeon/room_data.gd) |
| 생성기 | [`world/dungeon/floor_generator.gd`](../../world/dungeon/floor_generator.gd) |
| 층 상태 | [`world/dungeon/floor_map.gd`](../../world/dungeon/floor_map.gd) |
| 던전 루트 | [`scenes/dungeon/dungeon.tscn`](../../scenes/dungeon/dungeon.tscn) + [`dungeon.gd`](../../scenes/dungeon/dungeon.gd) |
| 방 호스트 | [`scenes/dungeon/room_host.tscn`](../../scenes/dungeon/room_host.tscn) |
| 공용 방 | [`scenes/dungeon/rooms/basic_room.tscn`](../../scenes/dungeon/rooms/basic_room.tscn) |
| 플레이어 | [`scenes/dungeon/player.tscn`](../../scenes/dungeon/player.tscn) |
| Map UI | [`ui/map/map_content.tscn`](../../ui/map/map_content.tscn) + [`map_content.gd`](../../ui/map/map_content.gd) |
| 바인딩 | [`ui/ui_manager.gd`](../../ui/ui_manager.gd) `bind_dungeon` / `unbind_dungeon` (HUD 미니맵에 `FloorMap` 전달) |

게임 진입: [`profile_select.gd`](../../scenes/title/profile_select.gd) → [`village.tscn`](../../scenes/village/village.tscn).  
던전은 도전 게시판 확정 후 ([`village.md`](village.md)). `dungeon.gd`가 `SaveManager.take_pending_run()`으로 시드·방 수를 받아 `generate`.  
전투: [`combat.md`](combat.md).

---

## 씬 트리 (던전)

씬 파일 + `_ready`에서 붙는 전투 노드:

```
Dungeon (Node2D)
├── FloorMap
├── RoomHost
│   └── BasicRoom (현재 방만)
├── Player
├── Camera2D
├── UIManager
├── CombatSession          # _ready
├── CombatArena            # _ready
├── CombatHud              # _ready, layer 1
└── EncounterDirector      # _ready
```

---

## 흐름

1. `FloorMap.generate(seed, room_count)` — 게시판 길이(또는 에디터 폴백 12) · 아이작식 격자 + start/boss
2. `UIManager.bind_dungeon(floor_map, room_host)` · `bind_combat(director)`
3. `RoomHost.enter_room(Vector2i.ZERO)`
4. Map 탭 클릭 **또는** WASD 문 이동 → `enter_room`  
5. `room_changed` → HUD `set_location` + 미니맵 redraw ([`minimap.md`](minimap.md))  
6. `EncounterDirector.on_room_entered` — `start`/`cleared`가 아니면 전투 ([`combat.md`](combat.md))

---

## RoomData

| 필드 | 설명 |
|------|------|
| `grid_pos` / `room_type` / `neighbors` | 격자·타입(`START`/`NORMAL`/`BOSS`)·사방 링크 |
| `visited` | `set_current` 시 true. 안개·맵 이동 |
| `cleared` | 전투 승리 시 true. 재입장 조우 스킵 ([`combat.md`](combat.md)) |

`type_letter()`: `S` / `N` / `B`.

---

## FloorMap API

| 메서드 | 설명 |
|--------|------|
| `generate(seed, room_count)` | 방 그래프 생성, current = start |
| `has_room` / `get_room` / `get_rooms` | 조회 |
| `get_current` / `set_current` | 현재 방 + `visited` + `room_changed` |
| `can_enter(pos)` | 방문 방 자유 이동; 미방문은 현재 방 인접만 |

---

## Map 탭

패널 계약: `setup` / `activate` / `deactivate` / `request_close` (다른 탭과 동일).  
`MenuShell`이 `Tab.MAP`을 마운트하고, `TopBar.CYCLEABLE_TABS`에 Map 포함 (Q/E 순환에 들어감).

이동 불가 칸은 비활성·흐리게 표시. **안개:** 방문+이웃만 칸·타입 글자 표시 (미니맵과 동일). `RoomHost.enter_room`도 `can_enter`를 검사한다.  
전투 중 칸 클릭은 `UIManager.is_combat_active()`에서 거부.

런 파일: `dungeon.gd`가 방 이동마다 `seed` / `current` / `visited` / `cleared`를 `slot_N_run.json`에 쓴다 ([`save-load.md`](save-load.md)). `_ready`는 `pending_run`으로 `generate` 후 **입구부터** 시작한다. 저장된 `current`·플래그로 이어하지 않는다.

---

## 방 문 · WASD

[`basic_room.gd`](../../scenes/dungeon/rooms/basic_room.gd)가 `neighbors`의 `N`/`E`/`S`/`W`만 문을 켜고, 키캡 `W`/`D`/`S`/`A`를 그린다.  
[`dungeon.gd`](../../scenes/dungeon/dungeon.gd)가 `ui_up/right/down/left`(WASD) → [`RoomHost.try_enter_direction`](../../scenes/dungeon/room_host.gd). 스폰은 진입 반대쪽 문 앞. 맵 텔레포트는 중앙.  
`UIManager.is_world_input_blocked()`이면 무시 (메뉴·전투·개발 오버레이).
