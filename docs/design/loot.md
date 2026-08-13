# 전리품 / 드랍 — 후속 설계

**현황(구조):** [`docs/architecture/loot.md`](../architecture/loot.md)  
**v1.1 방 보상 타입 + 3택1**이 현재 구현이다.

관련: [`combat.md`](combat.md) · [`equipment.md`](equipment.md) · [`village.md`](village.md) · [`hud.md`](hud.md) · [`game-log.md`](game-log.md) · [`save-load.md`](save-load.md) · [`map.md`](map.md) (`reward_type`).

---

## 한 줄

방마다 보상 타입(무기/방어구/룬/보석)이 정해지고, 전투 승리 후 그 타입 후보 3개 중 하나를 고른다.

---

## 확정 결정

| # | 결정 |
|---|------|
| 1 | 킬마다 떨어뜨리지 않는다. `win`일 때만. 후퇴·패배는 없음. |
| 2 | 종류 축은 `weapon` / `armor` / `rune` / `gem`. `ItemCategory`에 `RUNE`/`GEM`을 넣지 않는다. |
| 3 | **방 `reward_type` 1개** (맵 생성 시 균등). `START`는 `NONE`. |
| 4 | `win` → 후보 **3개** → **1택**. 스킵 없음. 가능하면 id 중복 없음. |
| 5 | 무기/방어 = `ItemCatalog` → `slots`. 룬/보석 = 인스턴스 → `runes[]`/`gems[]`. |
| 6 | 가방이 가득하면 장비 후보 확정 불가. 룬·보석은 한도 없음. |
| 7 | 메타 인벤에 넣는다. 전멸·보스 귀환 후에도 남는다. |
| 8 | 선택 UI는 가운데 **상세 카드 3장** 오버레이(일시정지). 확정 후 토스트·로그. |
| 9 | 장착은 기존 메뉴. **다음 방** 전투부터 스탯 반영. |
| 10 | 보스는 같은 3택1 후 `return_to_village()`. |
| 11 | 게시판 `reward_mult`는 드랍에 쓰지 않는다. |

---

## 로드맵

| 단계 | 범위 | 상태 |
|------|------|------|
| **v1** | 장비 1~N 자동 지급 | 폐기 (v1.1로 대체) |
| **v1.1** | `reward_type` + 3택1, 룬·보석 풀 | 구현됨 |
| **v2** | 접두사 롤러, 보스 희귀도, 미니맵 타입 아이콘, 지역 풀 | 설계만 |

---

## v1.1 — 방 타입 + 3택1

```
win → XP/HP, cleared → roll_offers(3) → LootChoiceOverlay → take_offer → toast/log
→ BOSS면 return_to_village()
```

| reward_type | 풀 |
|-------------|-----|
| weapon | `ItemCategory.WEAPON` |
| armor | `ItemCategory.ARMOR` |
| rune | `RuneCatalog` |
| gem | `GemCatalog` |

---

## 검증

- 후보 3개가 방 `reward_type`과 맞는가.
- 1택만 들어가는가. 재입장에 두 번째 보상이 없는가.
- 가방 가득 시 장비 Take가 막히는가.
- BOSS: 선택 후 마을.
- 시드·좌표 재현.

---

## 비목표 (당분간)

- 킬 드랍, 바닥 픽업, 미니맵 타입 아이콘
- 접두사 롤러, `reward_mult`, 지역 풀
- 가방 가득 교체 UI
