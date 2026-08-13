# HUD 미니맵 — 후속 설계

**v1 현황(구조):** [`docs/architecture/minimap.md`](../architecture/minimap.md)  
이 문서는 **미구현** 로드맵만 다룬다.

스타일 수치의 소스는 [`minimap_style.tres`](../../data/hud/minimap_style.tres).  
관련: [`map.md`](map.md) (특수 방 타입) · [`hud.md`](hud.md).

---

## 로드맵

| 단계 | 범위 | 상태 |
|------|------|------|
| **v1** | `MinimapStyle` + MiniMap `_draw` + GameHud `TopRight` | 구현됨 → 구조 문서 |
| **v1.1** | 창 밖 층에서 변 삼각 강조 | 설계만 |
| **v2** | 특수 방 `!`, 클리어 표시, (선택) 인접 칸 클릭 | 설계만 |

---

## v1.1 — 큰 층 (예정)

`window_cells`(11)보다 넓은 층: 현재 방 중심 클립은 이미 있음.  
잘린 변의 삼각을 `edge_arrow_color`보다 밝게 해서, 창 밖에 방이 있음을 힌트한다.

---

## v2 — 특수 방 (예정)

`RoomData` 타입이 늘어나면 `type_letter()`에 대문자를 추가한다.

| 타입 | 글자 |
|------|------|
| start / normal / boss | `S` / `N` / `B` (현행) |
| 특수·NPC·목표 | 예: `!` 또는 새 이니셜 |

클리어된 특수 방은 글자 흐리게 — 타입 추가 시 확정.  
(선택) 미니맵에서 **인접 미방문만** 클릭 → Map 탭 없이 `enter_room`. 전칸 텔레포트는 비목표.

---

## 비목표 (당분간)

- 미니맵에서 임의 칸 텔레포트 (클릭은 Map 탭 열기)
- 해골·아이템 / NPC 픽셀 아이콘
- `cleared` 별도 색 (특수 방 v2에서만 검토)
- 미니맵 확대·드래그·층 전환
- Map 탭을 미니맵 스타일로 교체
- 세이브 스키마 변경
