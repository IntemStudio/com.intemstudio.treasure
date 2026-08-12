# 던전 맵 / 방 텔레포트

메뉴 셸 **Map** 탭에서 방 칸을 클릭하면 해당 방으로 텔레포트한다.  
설계: [`docs/design/map.md`](../design/map.md).

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
| 바인딩 | [`ui/ui_manager.gd`](../../ui/ui_manager.gd) `bind_dungeon` / `unbind_dungeon` |

게임 진입: [`profile_select.gd`](../../scenes/title/profile_select.gd) → `dungeon.tscn`.

---

## 씬 트리 (던전)

```
Dungeon (Node2D)
├── FloorMap
├── RoomHost
│   └── BasicRoom (현재 방만)
├── Player
├── Camera2D
└── UIManager
```

---

## 흐름

1. `FloorMap.generate(seed, 12)` — 아이작식 격자 + start/boss
2. `UIManager.bind_dungeon(floor_map, room_host)`
3. `RoomHost.enter_room(Vector2i.ZERO)`
4. Map 탭 클릭 → `enter_room(pos)` → `close_all()`
5. `room_changed` → HUD `set_location` (`LOCATION_ROOM_START` / `LOCATION_DUNGEON` / `LOCATION_ROOM_BOSS`)

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
`MenuShell`이 `Tab.MAP`을 마운트하고, `TopBar.CYCLEABLE_TABS`에 Map 포함.

이동 불가 칸은 비활성·흐리게 표시. `RoomHost.enter_room`도 `can_enter`를 검사한다. 문 이동·런 세이브는 후속.
