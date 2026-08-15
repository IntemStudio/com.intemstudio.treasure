# 인게임 HUD — 후속 설계

**v1 현황(구조):** [`docs/architecture/hud.md`](../architecture/hud.md)  
이 문서는 **미구현** 로드맵만 다룬다.

전투 중 HUD 유지·메뉴 시 숨김은 구현됨. 미니맵 후속: [`minimap.md`](minimap.md).  
마나·기술 칸 의미: [`stats.md`](stats.md). 장착 룬 0~6·게이지: [`equipment.md`](equipment.md).  
방 클리어 획득 토스트: [`loot.md`](loot.md). 우하 텍스트 로그: [`game-log.md`](game-log.md).

---

## 로드맵

| 단계 | 범위 | 상태 |
|------|------|------|
| **v1** | 표시 레이아웃 + stats/인벤 바인딩, 퀵 4칸·장착 룬 행 | 구현됨 → 구조 문서 |
| **미니맵 v1** | 우상단 격자 미니맵 | 구현됨 → [`minimap.md`](../architecture/minimap.md) |
| **기술 게이지** | HUD 기술 칸 충전 바, 전투 중 마나 바 갱신 | 구현됨 — [`equipment.md`](equipment.md) · [`combat.md`](../architecture/combat.md) |
| **v1.1** | 퀵/기술 사용 입력, 지역 id 월드 연동 | 설계만 |
| **loot 토스트** | 방 `win` 짧은 획득 문구. 인벤 자동 오픈 없음 | 구현됨 — [`loot.md`](loot.md) |
| **게임 로그** | 우하 스크롤. 전투 이산 행동·승패. 메뉴 시 숨김 | 구현됨 → [`game-log.md`](../architecture/game-log.md) |
| **v2** | 스탯 Focus→Mana 정렬, 인벤 퀵 슬롯 UI | 설계만 |

---

## v1.1 — 입력 (예정)

- 퀵 아이템/음식 사용 액션 + 개수 감소
- 기술 슬롯: 전투 중은 **자동 발동** 충전 표시 (구현됨, [`stats.md`](stats.md) v1.3). 키/패드 바인딩은 탐험 소모품. 전투 중 룬 버튼은 비목표
- 월드 존이 `UIManager.set_location` 호출 (지금은 방 타입만)
- 마을 허브: `LOCATION_VILLAGE`, 미니맵 숨김 ([`village.md`](village.md))

전투 중 소모품은 [`combat.md`](combat.md) v2c와 맞춤.

---

## v2 — 표기·편집 (예정)

- 스탯 탭 Focus 라벨과 HUD 마나 표기 이름 정렬 ([`stats.md`](stats.md) v1.3, GENERAL: Mana / Mana Regen)
- 인벤 UI에서 퀵 슬롯(아이템·음식) 장착/교체

---

## 비목표 (당분간)

- 중앙 상호작용 프롬프트, NPC 이름표, 대사 자막
- 퀘스트 트래커, 버프 아이콘 열
- 재화(골드) 상시 표시 — 메뉴 TopBar `CurrencyDisplay` 유지
- 초상화, 시계, 우상 장식 아이콘
- 중앙 전투 로그·채팅창 (로그는 우하, [`game-log.md`](game-log.md))
