# HUD 미니맵

탐험 HUD 우상단의 층 격자 미니맵. 표시만 하며, 텔레포트는 Map 탭.

후속: [`docs/design/minimap.md`](../design/minimap.md).  
스타일 수치: [`minimap_style.tres`](../../data/hud/minimap_style.tres).

---

## 위치

| 역할 | 경로 |
|------|------|
| 스타일 | [`data/hud/minimap_style.gd`](../../data/hud/minimap_style.gd) · [`minimap_style.tres`](../../data/hud/minimap_style.tres) |
| 뷰 | [`ui/hud/components/minimap.tscn`](../../ui/hud/components/minimap.tscn) + [`minimap.gd`](../../ui/hud/components/minimap.gd) |
| 소유 | [`ui/hud/game_hud.tscn`](../../ui/hud/game_hud.tscn) `TopRight` |
| 바인딩 | [`ui/ui_manager.gd`](../../ui/ui_manager.gd) `bind_dungeon` → `GameHud.bind_floor_map` |

메뉴가 열리면 `GameHud`와 함께 숨겨진다. **전투 중에는 유지** ([`combat.md`](combat.md)).  
클릭 → `GameHud.map_open_requested` → `UIManager.open_tab(MAP)`. 전투 중 클릭은 `is_combat_active()`에서 무시. 칸 텔레포트는 없음.

---

## 씬 트리

```
GameHud / Root
├── ResourceBars
├── TopRight (VBox)
│   ├── WorldInfo
│   └── MiniMap
├── ActionBar
└── GameLogView
```

---

## 안개 · 표시

보이는 칸 = `visited` ∪ 방문한 방의 `neighbors`.

| 상태 | 표시 |
|------|------|
| 현재 | 흰 실면 + 타입 글자 (어두운 `S`/`N`/`B`) |
| 방문 | 어두운 채움 + 주황 테두리 + 타입 글자 |
| 미방문 프론티어 | 어두운 실루엣 + 타입 글자 (인접 타입 공개) |

글자: `RoomData.type_letter()` — `S` start / `N` normal / `B` boss.  
카메라: 보이는 AABB가 `window_cells`(11) 이하면 군집 중앙, 아니면 현재 방 중심 클립.

---

## API

```
GameHud.bind_floor_map(floor_map)
GameHud.unbind_floor_map()
MiniMap.set_floor_map(floor_map)
MiniMap.clear_floor_map()
signal MiniMap.map_open_requested
signal GameHud.map_open_requested
```

`FloorMap.room_changed` → `queue_redraw`. 맵 없으면 미니맵 `visible = false`.  
탐험 중 클릭 → Map 탭. 전투 중 클릭은 무시.
