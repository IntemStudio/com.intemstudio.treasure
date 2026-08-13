# 던전 맵 / 방 텔레포트 — 후속 설계

**v1 현황(구조):** [`docs/architecture/map.md`](../architecture/map.md)  
이 문서는 **미구현** 로드맵만 다룬다.

런 세이브(층·시드·탐험 상태): [`save-load.md`](save-load.md) v2.  
미니맵 후속: [`minimap.md`](minimap.md).  
허브에서 도전할 때만 생성: [`village.md`](village.md).

---

## 로드맵

| 단계 | 범위 | 상태 |
|------|------|------|
| **v1** | 생성기 + RoomHost + Map 탭 + 문 + WASD | 구현됨 → 구조 문서 |
| **미니맵 v1** | HUD 우상단 안개 격자 | 구현됨 → [`minimap.md`](../architecture/minimap.md) |
| **v1.1** | 패드 맵 커서, Area2D로 문 보행, (선택) visited-only | 설계만 |
| **v2** | 런에 시드·current·visited·cleared 기록, 특수 방 | 탐험 플래그 쓰기는 구현됨. 이어하기 복원·특수 방은 후속 |

---

## v1.1 — 패드·보행 (예정)

- 방 가장자리 `Door` Area/Body로 걸어 들어가기 (지금은 WASD 한 번으로 즉시 이동)
- 스폰은 이미 진입 반대쪽 문 앞 — 보행 진입과 맞춤 유지
- Map 탭 게임패드 포커스 커서 (마우스는 현행 클릭)
- (선택) 미방문 인접 이동을 끄고 방문 방만 텔레포트

푸터에 층 이름·시드 표시는 런 세이브와 같이 검토.

---

## v2 — 런 연동

쓰기는 구현됨 ([`architecture/map.md`](../architecture/map.md) · [`save-load.md`](save-load.md)). **남은 것:**

- 이어하기: `load_run` → 시드로 `generate` 후 `visited`/`cleared`/`current` 덮어쓰기
- 특수 방 타입(`room_type` 확장). 룬 제단·보석 광맥은 [`equipment.md`](equipment.md) — 현재는 `START`/`NORMAL`/`BOSS`만. 카드 등록은 던전 방이 아니라 마을

에디터 직접 실행 폴백(`randi()` + 12방)은 유지.

---

## 비목표 (당분간)

- 방문/클리어 게이트, 잠금 문, 열쇠
- 맵에서 적·아이템 아이콘
- 층 간 이동(다음 층 포털)
- 절차적 방 **내부** 지형 (v1은 고정 방 씬)
