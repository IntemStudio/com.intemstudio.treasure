# 자동 전투 — 후속 설계

**v2 현황(구조):** [`docs/architecture/combat.md`](../architecture/combat.md)  
이 문서는 **미구현** 로드맵만 다룬다.

방 안 ATB·머리 위 HP/ATB·배속/후퇴·승패는 구현됨.  
관련: [`map.md`](map.md) (`cleared` 런 세이브) · [`hud.md`](hud.md) (퀵/기술 실사용) · [`village.md`](village.md) (전멸 → 마을) · [`stats.md`](stats.md) (속성→`CombatStats`) · [`equipment.md`](equipment.md) (공명은 세션 밖, 마을 책장 ≠ 전투 카드) · [`loot.md`](loot.md) (방 `win` 장비) · [`game-log.md`](game-log.md) (인게임 텍스트 로그).

---

## 로드맵

| 단계 | 범위 | 상태 |
|------|------|------|
| 구 v1 | 사이드뷰 오버레이 ATB | 폐기됨 |
| **v2a / v2b** | 방 안 전장, CombatHud, GameHud 유지 | 구현됨 → 구조 문서 |
| **v2.region** | 지역별 유닛·인카운터 (`dungeon_id`) | 구현됨 → 구조 문서 |
| **v2c** | 선택 유닛 하단 스탯, 전투 줌, 다수 아군 슬롯 | 설계만 |
| **v2.stats** | 회피·크리·흡혈·반격·리젠·Magic HP·스태미나 | 구현됨 → 구조 문서 |
| **loot v1** | 방 `win` 장비 드랍 | 구현됨 → [`loot.md`](loot.md) / [`architecture/loot.md`](../architecture/loot.md) |
| **게임 로그** | `action_resolved` → 우하 텍스트. `unit_hit` 유지 | 구현됨 → [`game-log.md`](../architecture/game-log.md) |
| **기술 게이지** | 평타와 별도 ATB, 마나 자동 발동, HUD 충전 | 구현됨 → [`equipment.md`](equipment.md) · 구조 문서 |

---

## v2c — 표현·편성 (예정)

데스폿의 **하단 유닛 스탯·다수 편성**만 가져온다. 드래프트·시너지·FIGHT 준비는 비목표.

| 항목 | 방향 |
|------|------|
| 하단 패널 | 유닛 클릭(또는 포커스) 시 이름·HP·ATB·주요 스탯. 탐험 인벤/스탯 탭과 별개 |
| 전투 줌 | 방 중심 유지하되 전투 중 살짝 확대. 수치·연출은 구현 직전 확정 |
| 다수 아군 | `AllySlot1+` 사용. 히어로 외 아군 소스는 파티 시스템이 생긴 뒤 |
| 소모품 | HUD 퀵 슬롯 실사용과 맞춤 ([`hud.md`](hud.md) v1.1) |

`CombatSession` 공식·인카운터 리소스는 유지. 뷰·슬롯만 확장.

---

## v2.stats — 고급 스탯

구현됨. 히어로 스냅샷은 `CombatStatsBuilder.build` ([`stats.md`](stats.md) v1.1). 세션은 회피·크리·흡혈·반격·리젠·Magic HP·스태미나/Tired를 적용. 기술 게이지는 구현됨 ([`equipment.md`](equipment.md)). 룬·공명 결과는 `ResonanceService`가 만들고 세션은 소비만 한다.

---

## 전멸 목적지

`lose` → `UIManager.return_to_village()` — 메타 유지, 런 삭제. 타이틀은 설정 나가기·프로필 선택만.

후퇴는 입구 잔류. 원정 포기→마을은 [`village.md`](village.md) 후속.

---

## 비목표 (당분간)

- 데스폿식 유닛 드래프트·시너지·FIGHT 준비 페이즈
- 전투 중 자유 이동·히트박스 실시간 위치전 (ATB + 슬롯 고정)
- 루프/타일/카드, 낮밤 스폰
- 전투 중 세이브·ATB 직렬화
- 스킬 4칸·퀵 아이템 실사용 (HUD v1.1)
